import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

class WebdavServer {
  static const int defaultWebdavPort = 9999;

  final String vmId;
  final String hostFolder;
  final String? authToken;

  HttpServer? _server;
  bool _isRunning = false;

  WebdavServer({
    required this.vmId,
    required this.hostFolder,
    this.authToken,
  });

  bool get isRunning => _isRunning;
  int? get port => _server?.port;

  Future<void> start() async {
    if (_isRunning) return;

    final canonicalPath = p.canonicalize(hostFolder);
    if (!await Directory(canonicalPath).exists()) {
      throw StateError('Shared folder does not exist: $canonicalPath');
    }

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, defaultWebdavPort);
    _isRunning = true;

    _server!.listen(_handleRequest, onError: (e) {
      _isRunning = false;
    });
  }

  Future<void> stop() async {
    _isRunning = false;
    await _server?.close();
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    final method = request.method;
    final uri = request.uri;

    if (authToken != null) {
      final providedToken = request.headers.value('authorization');
      if (providedToken != 'Bearer $authToken') {
        response
          ..statusCode = HttpStatus.unauthorized
          ..write('Unauthorized')
          ..close();
        return;
      }
    }

    try {
      switch (method) {
        case 'PROPFIND':
          await _handlePropFind(response, uri);
        case 'GET':
          await _handleGet(response, uri, request);
        case 'PUT':
          await _handlePut(response, uri, request);
        case 'MKCOL':
          await _handleMkcol(response, uri);
        case 'DELETE':
          await _handleDelete(response, uri);
        case 'COPY':
          await _handleCopy(response, request);
        case 'MOVE':
          await _handleMove(response, request);
        default:
          response
            ..statusCode = HttpStatus.methodNotAllowed
            ..close();
      }
    } catch (e) {
      response
        ..statusCode = HttpStatus.internalServerError
        ..write('Error: $e')
        ..close();
    }
  }

  Future<void> _handlePropFind(HttpResponse response, Uri uri) async {
    final path = _resolvePath(uri.path);

    if (await File(path).exists()) {
      response
        ..headers.contentType = ContentType.xml
        ..statusCode = HttpStatus.ok
        ..write(_buildFileResponse(path))
        ..close();
    } else if (await Directory(path).exists()) {
      response
        ..headers.contentType = ContentType.xml
        ..statusCode = HttpStatus.ok
        ..write(_buildDirectoryResponse(path))
        ..close();
    } else {
      response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }

  Future<void> _handleGet(HttpResponse response, Uri uri, HttpRequest request) async {
    final path = _resolvePath(uri.path);
    final file = File(path);

    if (!await file.exists()) {
      response
        ..statusCode = HttpStatus.notFound
        ..close();
      return;
    }

    final content = await file.readAsBytes();
    response
      ..headers.contentLength = content.length
      ..headers.set('Last-Modified', file.lastModifiedSync().toUtc().toRfc850String())
      ..statusCode = HttpStatus.ok
      ..add(content)
      ..close();
  }

  Future<void> _handlePut(HttpResponse response, Uri uri, HttpRequest request) async {
    final path = _resolvePath(uri.path);
    final parent = p.dirname(path);

    await Directory(parent).create(recursive: true);

    final file = File(path);
    final content = await request.toList();
    final bytes = content.expand((chunk) => chunk).toList();

    await file.writeAsBytes(bytes);

    response
      ..statusCode = HttpStatus.created
      ..close();
  }

  Future<void> _handleMkcol(HttpResponse response, Uri uri) async {
    final path = _resolvePath(uri.path);
    await Directory(path).create(recursive: true);
    response
      ..statusCode = HttpStatus.created
      ..close();
  }

  Future<void> _handleDelete(HttpResponse response, Uri uri) async {
    final path = _resolvePath(uri.path);
    final file = File(path);
    final dir = Directory(path);

    if (await file.exists()) {
      await file.delete();
    } else if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    response
      ..statusCode = HttpStatus.noContent
      ..close();
  }

  Future<void> _handleCopy(HttpResponse response, HttpRequest request) async {
    final destination = request.headers.value('destination');
    if (destination == null) {
      response
        ..statusCode = HttpStatus.badRequest
        ..close();
      return;
    }

    final sourcePath = _resolvePath(request.uri.path);
    final destPath = _resolvePath(Uri.parse(destination).path);

    await _copyPath(sourcePath, destPath);
    response
      ..statusCode = HttpStatus.created
      ..close();
  }

  Future<void> _handleMove(HttpResponse response, HttpRequest request) async {
    final destination = request.headers.value('destination');
    if (destination == null) {
      response
        ..statusCode = HttpStatus.badRequest
        ..close();
      return;
    }

    final sourcePath = _resolvePath(request.uri.path);
    final destPath = _resolvePath(Uri.parse(destination).path);

    await _copyPath(sourcePath, destPath);
    await _deletePath(sourcePath);
    response
      ..statusCode = HttpStatus.created
      ..close();
  }

  String _resolvePath(String uriPath) {
    final cleanPath = uriPath == '/' ? '' : uriPath;
    return p.join(hostFolder, cleanPath);
  }

  Future<void> _copyPath(String source, String destination) async {
    final sourceFile = File(source);
    final sourceDir = Directory(source);

    if (await sourceFile.exists()) {
      await sourceFile.copy(destination);
    } else if (await sourceDir.exists()) {
      await Directory(source).create(recursive: true);
      await for (final entity in Directory(source).list(recursive: true)) {
        if (entity is File) {
          final relative = p.relative(entity.path, source);
          final destFile = File(p.join(destination, relative));
          await destFile.parent.create(recursive: true);
          await entity.copy(destFile.path);
        }
      }
    }
  }

  Future<void> _deletePath(String path) async {
    final file = File(path);
    final dir = Directory(path);

    if (await file.exists()) {
      await file.delete();
    } else if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  String _buildFileResponse(String path) {
    final file = File(path);
    final size = file.lengthSync();
    final modified = file.lastModifiedSync().toIso8601String();

    return '''<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>${Uri.encodeComponent(path)}</D:href>
    <D:propstat>
      <D:prop>
        <D:resourcetype><D:collection/></D:resourcetype>
        <D:getcontentlength>$size</D:getcontentlength>
        <D:getlastmodified>$modified</D:getlastmodified>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
  </D:response>
</D:multistatus>''';
  }

String _buildDirectoryResponse(String path) {
    return '''<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>/</D:href>
    <D:propstat>
      <D:prop>
        <D:resourcetype><D:collection/></D:resourcetype>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
  </D:response>
</D:multistatus>''';
  }
}