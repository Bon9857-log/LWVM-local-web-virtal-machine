import 'dart:async';
import 'dart:convert';
import 'dart:io';

class GuestAgentClient {
  final String socketPath;
  final int? tcpPort;
  final Duration timeout;

  int _requestId = 0;

  GuestAgentClient(this.socketPath, {this.tcpPort, this.timeout = const Duration(seconds: 5)});

  Future<bool> ping() async {
    try {
      await _call('guest-ping');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getGuestInfo() async {
    return _call('guest-info');
  }

  Future<bool> shutdown() async {
    try {
      await _call('guest-shutdown');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> exec(String path, List<String>? args, {Map<String, String>? env, String? input}) async {
    final params = <String, dynamic>{
      'path': path,
      'args': args ?? [],
    };
    if (env != null) {
      params['env'] = env;
    }
    if (input != null) {
      params['input-data'] = base64Encode(utf8.encode(input));
    }
    final result = await _call('guest-exec', params: params);
    return result ?? <String, dynamic>{};
  }

  Future<String> readFile(String path, {int? count, int? offset}) async {
    final params = <String, dynamic>{'path': path};
    if (count != null) params['count'] = count;
    if (offset != null) params['offset'] = offset;

    final result = await _call('guest-file-open', params: params);
    final handle = result?['return'] as int? ?? 0;

    try {
      final readResult = await _call('guest-file-read', params: {'handle': handle, 'count': count ?? 4096});
      final data = readResult?['return']?['buf-b64'] as String? ?? '';
      return utf8.decode(base64Decode(data));
    } finally {
      await _call('guest-file-close', params: {'handle': handle});
    }
  }

  Future<void> writeFile(String path, String content, {bool append = false}) async {
    final params = <String, dynamic>{
      'path': path,
      'mode': append ? 'a' : 'w',
    };
    final result = await _call('guest-file-open', params: params);
    final handle = result?['return'] as int? ?? 0;

    try {
      final data = base64Encode(utf8.encode(content));
      await _call('guest-file-write', params: {'handle': handle, 'buf-b64': data});
    } finally {
      await _call('guest-file-close', params: {'handle': handle});
    }
  }

  Future<Map<String, dynamic>?> _call(String method, {Map<String, dynamic>? params}) async {
    _requestId++;
    final id = _requestId;

    final request = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      'id': id,
    };
    if (params != null) {
      request['params'] = params;
    }

    final socket = await _connect();

    socket.writeln(jsonEncode(request));
    await socket.flush();

    final response = await _readResponse(socket).timeout(
      timeout,
      onTimeout: () {
        socket.close();
        throw TimeoutException('Guest agent timeout');
      },
    );

    socket.close();
    return response;
  }

  Future<Socket> _connect() async {
    if (tcpPort != null) {
      return Socket.connect(InternetAddress.loopbackIPv4, tcpPort!).timeout(timeout);
    }
    if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
      return _connectUnixSocket();
    }
    if (Platform.isWindows) {
      return _connectTcpSocket();
    }
    throw UnsupportedError('Unsupported platform for guest agent connection');
  }

  Future<Socket> _connectUnixSocket() async {
    final socketFile = File(socketPath);
    if (!socketFile.existsSync()) {
      throw Exception('Guest agent socket not found at $socketPath');
    }
    final address = InternetAddress(socketPath, type: InternetAddressType.unix);
    return Socket.connect(address, 0).timeout(timeout);
  }

  Future<Socket> _connectTcpSocket() async {
    return Socket.connect(InternetAddress.loopbackIPv4, 0).timeout(timeout);
  }

  Future<Map<String, dynamic>> _readResponse(Socket socket) async {
    final completer = Completer<Map<String, dynamic>>();
    final buffer = StringBuffer();
    late StreamSubscription<List<int>> subscription;

    subscription = socket.listen(
      (data) {
        buffer.write(utf8.decode(data));
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          try {
            final data = buffer.toString();
            completer.complete(jsonDecode(data) as Map<String, dynamic>);
          } catch (e) {
            completer.completeError(e);
          }
        }
      },
      cancelOnError: true,
    );

    final response = await completer.future.timeout(timeout);
    await subscription.cancel();
    return response;
  }
}
  }

  Future<Map<String, dynamic>?> getGuestInfo() async {
    return _call('guest-info');
  }

  Future<bool> shutdown() async {
    try {
      await _call('guest-shutdown');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> exec(String path, List<String>? args, {Map<String, String>? env, String? input}) async {
    final params = <String, dynamic>{
      'path': path,
      'args': args ?? [],
    };
    if (env != null) {
      params['env'] = env;
    }
    if (input != null) {
      params['input-data'] = base64Encode(utf8.encode(input));
    }
    final result = await _call('guest-exec', params: params);
    return result ?? <String, dynamic>{};
  }

  Future<String> readFile(String path, {int? count, int? offset}) async {
    final params = <String, dynamic>{'path': path};
    if (count != null) params['count'] = count;
    if (offset != null) params['offset'] = offset;

    final result = await _call('guest-file-open', params: params);
    final handle = result?['return'] as int? ?? 0;

    try {
      final readResult = await _call('guest-file-read', params: {'handle': handle, 'count': count ?? 4096});
      final data = readResult?['return']?['buf-b64'] as String? ?? '';
      return utf8.decode(base64Decode(data));
    } finally {
      await _call('guest-file-close', params: {'handle': handle});
    }
  }

  Future<void> writeFile(String path, String content, {bool append = false}) async {
    final params = <String, dynamic>{
      'path': path,
      'mode': append ? 'a' : 'w',
    };
    final result = await _call('guest-file-open', params: params);
    final handle = result?['return'] as int? ?? 0;

    try {
      final data = base64Encode(utf8.encode(content));
      await _call('guest-file-write', params: {'handle': handle, 'buf-b64': data});
    } finally {
      await _call('guest-file-close', params: {'handle': handle});
    }
  }

  Future<Map<String, dynamic>?> _call(String method, {Map<String, dynamic>? params}) async {
    _requestId++;
    final id = _requestId;

    final request = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      'id': id,
    };
    if (params != null) {
      request['params'] = params;
    }

    final socket = await _connect();

    socket.writeln(jsonEncode(request));
    await socket.flush();

    final response = await _readResponse(socket).timeout(
      timeout,
      onTimeout: () {
        socket.close();
        throw TimeoutException('Guest agent timeout');
      },
    );

    socket.close();
    return response;
  }

  Future<Socket> _connect() async {
    if (tcpPort != null) {
      return Socket.connect(InternetAddress.loopbackIPv4, tcpPort!).timeout(timeout);
    }
    if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
      return _connectUnixSocket();
    }
    if (Platform.isWindows) {
      return _connectTcpSocket();
    }
    throw UnsupportedError('Unsupported platform for guest agent connection');
  }

  Future<Socket> _connectUnixSocket() async {
    final socketFile = File(socketPath);
    if (!socketFile.existsSync()) {
      throw Exception('Guest agent socket not found at $socketPath');
    }
    final address = InternetAddress(socketPath, type: InternetAddressType.unix);
    return Socket.connect(address, 0).timeout(timeout);
  }

  Future<Socket> _connectTcpSocket() async {
    return Socket.connect(InternetAddress.loopbackIPv4, 0).timeout(timeout);
  }

  Future<Map<String, dynamic>> _readResponse(Socket socket) async {
    final completer = Completer<Map<String, dynamic>>();
    final buffer = StringBuffer();
    late StreamSubscription subscription;
    
    subscription = socket.listen(
      (data) {
        buffer.writeAll(data.map(utf8.decode));
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          try {
            final data = buffer.toString();
            completer.complete(jsonDecode(data) as Map<String, dynamic>);
          } catch (e) {
            completer.completeError(e);
          }
        }
      },
      cancelOnError: true,
    );
    
    final response = await completer.future.timeout(timeout);
    await subscription.cancel();
    return response;
  }
}