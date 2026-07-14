import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'vm_storage_manager.dart';

void main() {
  group('VmStorageManager', () {
    late VmStorageManager manager;
    late String tempDir;

    setUp(() async {
      tempDir = (await Directory.systemTemp.createTemp('vm_storage_test')).path;
    });

    tearDown(() async {
      await Directory(tempDir).delete(recursive: true);
    });

    test('generates correct VM directory path', () {
      manager = VmStorageManager('vm-123');
      final vmDir = manager.getVmDirectory();
      expect(vmDir, contains('vm-123'));
    });

    test('generates correct overlay and data disk paths', () {
      manager = VmStorageManager('vm-456');
      expect(manager.getOverlayPath(), endsWith('overlay.qcow2'));
      expect(manager.getDataDiskPath(), endsWith('data-disk.qcow2'));
    });

    test('generates log path', () {
      manager = VmStorageManager('vm-789');
      final logPath = manager.getLogPath();
      expect(logPath, contains('logs'));
      expect(logPath, endsWith('qemu.log'));
    });

    test('generates config path', () {
      manager = VmStorageManager('vm-config');
      final configPath = manager.getConfigPath();
      expect(configPath, endsWith('config.json'));
    });
  });
}