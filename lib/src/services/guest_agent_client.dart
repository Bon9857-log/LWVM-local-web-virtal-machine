import 'dart:async';
import 'dart:convert';
import 'dart:io';

class GuestAgentClient {
  final String socketPath;
  final Duration timeout;

  int _requestId = 0;

  GuestAgentClient(this.socketPath, {this.timeout = const Duration(seconds: 5)});

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
    if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
      return _connectUnixSocket();
    }
    return _connectTcpSocket();
  }

  Future<Socket> _connectUnixSocket() async {
    throw UnimplementedError('Unix socket support requires platform-specific implementation');
  }

  Future<Socket> _connectTcpSocket() async {
    return Socket.connect(InternetAddress.loopbackIPv4, 0).timeout(timeout);
  }

  Future<Map<String, dynamic>> _readResponse(Socket socket) async {
    final data = await socket.transform(utf8.decoder).join().timeout(timeout);
    return jsonDecode(data) as Map<String, dynamic>;
  }
}