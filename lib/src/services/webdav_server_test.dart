import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'webdav_server.dart';

void main() {
  group('WebdavServer', () {
    late Directory tempDir;
    late String testFolder;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('webdav_test');
      testFolder = p.join(tempDir.path, 'shared');
      await Directory(testFolder).create(recursive: true);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('start creates server bound to loopback', () async {
      final server = WebdavServer(vmId: 'test-vm', hostFolder: testFolder);

      await server.start();
      expect(server.isRunning, isTrue);
      expect(server.port, equals(9999));

      await server.stop();
      expect(server.isRunning, isFalse);
    });

    test('throws error if folder does not exist', () async {
      final server = WebdavServer(vmId: 'test-vm', hostFolder: '/nonexistent/folder');

      expect(server.start(), throwsA(isA<StateError>()));
    });

    test('has correct default port', () {
      expect(WebdavServer.defaultWebdavPort, equals(9999));
    });
  });
}