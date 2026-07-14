import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/guest_os_image.dart';
import '../models/vm_config.dart';
import '../models/vm_instance.dart';

class VmStorageManager {
  static const String overlayFileName = 'overlay.qcow2';
  static const String dataDiskFileName = 'data-disk.qcow2';

  final String vmId;

  VmStorageManager(this.vmId);

  String getVmDirectory() {
    final home = _homeDirectory();
    return p.join(home, '.lwvm', 'vms', vmId);
  }

  String getOverlayPath() {
    return p.join(getVmDirectory(), overlayFileName);
  }

  String getDataDiskPath() {
    return p.join(getVmDirectory(), dataDiskFileName);
  }

  String getLogPath() {
    return p.join(getVmDirectory(), 'logs', 'qemu.log');
  }

  String getConfigPath() {
    return p.join(getVmDirectory(), 'config.json');
  }

  Future<VmInstance> create(VmConfig config, {String? baseImagePath}) async {
    final vmDir = getVmDirectory();
    final overlayPath = getOverlayPath();
    final dataDiskPath = getDataDiskPath();

    await Directory(p.dirname(getLogPath())).create(recursive: true);

    if (baseImagePath != null) {
      final baseImage = File(baseImagePath);
      if (!await baseImage.exists()) {
        throw StateError('Base image not found: $baseImagePath');
      }
      await createOverlay(baseImagePath, overlayPath);
    }

    await createDataDisk(dataDiskPath, config.diskSize);

    final instance = VmInstance(
      id: vmId,
      config: config,
      overlayPath: overlayPath,
      dataDiskPath: dataDiskPath,
      baseImagePath: baseImagePath,
    );

    await saveConfig(instance);

    return instance;
  }

  Future<void> createOverlay(String baseImagePath, String overlayPath) async {
    final baseImage = File(baseImagePath);
    final overlayDir = p.dirname(overlayPath);

    await Directory(overlayDir).create(recursive: true);

    final args = [
      '-f', 'qcow2',
      '-o', 'backing_file=$baseImagePath',
      overlayPath,
    ];

    final result = await Process.run('qemu-img', ['create'] + args);

    if (result.exitCode != 0) {
      throw StateError('Failed to create overlay: ${result.stderr}');
    }
  }

  Future<void> createDataDisk(String dataDiskPath, int sizeGb) async {
    final dataDiskDir = p.dirname(dataDiskPath);
    await Directory(dataDiskDir).create(recursive: true);

    final result = await Process.run(
      'qemu-img',
      ['create', '-f', 'qcow2', dataDiskPath, '${sizeGb}G'],
    );

    if (result.exitCode != 0) {
      final fallbackResult = await Process.run(
        'qemu-img',
        ['create', '-f', 'qcow2', dataDiskPath, '${sizeGb}G'],
      );
      if (fallbackResult.exitCode != 0) {
        throw StateError('Failed to create data disk: ${fallbackResult.stderr}');
      }
    }
  }

  Future<void> saveConfig(VmInstance instance) async {
    final configFile = File(getConfigPath());
    await configFile.parent.create(recursive: true);
    await configFile.writeAsString(jsonEncode(instance.toJson()));
  }

  Future<VmInstance?> loadConfig() async {
    final configFile = File(getConfigPath());
    if (!await configFile.exists()) {
      return null;
    }

    final content = await configFile.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return VmInstance.fromJson(json);
  }

  Future<void> delete() async {
    final vmDir = Directory(getVmDirectory());
    if (await vmDir.exists()) {
      await vmDir.delete(recursive: true);
    }
  }

  Future<void> resetOverlay({required String baseImagePath}) async {
    final overlayPath = getOverlayPath();
    await deleteOverlay();
    await createOverlay(baseImagePath, overlayPath);
  }

  Future<void> deleteOverlay() async {
    final overlay = File(getOverlayPath());
    if (await overlay.exists()) {
      await overlay.delete();
    }
  }

  Future<bool> overlayExists() async {
    return File(getOverlayPath()).exists();
  }

  Future<bool> dataDiskExists() async {
    return File(getDataDiskPath()).exists();
  }

  static String _homeDirectory() {
    final envHome = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    return envHome.isEmpty ? '.' : envHome;
  }
}