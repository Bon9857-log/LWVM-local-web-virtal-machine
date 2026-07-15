import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/platform_capabilities.dart';
import '../models/vm_config.dart';
import '../models/vm_instance.dart';
import '../models/guest_os_image.dart';
import 'qemu_binary_resolver.dart';
import 'qemu_command_builder.dart';

class ProvisioningService {
  final QemuBinaryResolver binaryResolver;
  final QemuCommandBuilder commandBuilder;

  ProvisioningService(PlatformCapabilities capabilities)
      : binaryResolver = QemuBinaryResolver(capabilities),
        commandBuilder = QemuCommandBuilder(capabilities);

  Future<VmInstance> createVm(VmConfig config, {String? vmId}) async {
    final id = vmId ?? 'vm-${DateTime.now().millisecondsSinceEpoch}';
    final vmDir = await _vmDirectory(id);
    final overlayPath = p.join(vmDir, 'overlay.qcow2');
    final dataDiskPath = p.join(vmDir, 'data.qcow2');

    await Directory(vmDir).create(recursive: true);

    await _createOverlayDisk(overlayPath);

    await _createDataDisk(dataDiskPath, config.diskSize);

    return VmInstance(
      id: id,
      config: config,
      overlayPath: overlayPath,
      dataDiskPath: dataDiskPath,
    );
  }

  Future<void> _createOverlayDisk(String path) async {
    final baseImagePath = await _getBaseImagePath();
    final args = ['create', '-f', 'qcow2', '-b', baseImagePath, path];

    final qemuPath = await binaryResolver.resolveBinaryPath('qemu-img');
    if (qemuPath != null) {
      await Process.run(qemuPath, args);
    }
  }

  Future<void> _createDataDisk(String path, int sizeGb) async {
    final args = ['create', '-f', 'qcow2', path, '${sizeGb}G'];
    final qemuPath = await binaryResolver.resolveBinaryPath('qemu-img');
    if (qemuPath != null) {
      await Process.run(qemuPath, args);
    }
  }

  Future<String> _getBaseImagePath() async {
    final cacheDir = await _getImageCacheDir();
    final images = {
      GuestOS.alpine: 'alpine.qcow2',
      GuestOS.ubuntu: 'ubuntu.qcow2',
      GuestOS.zorin: 'zorin.qcow2',
    };
    
    final imageName = images[GuestOS.alpine]!;
    return p.join(cacheDir, imageName);
  }

  static Future<String> _vmDirectory(String vmId) async {
    final home = await _getHomeDir();
    return p.join(home, '.lwvm', 'vms', vmId);
  }

  static Future<String> _getImageCacheDir() async {
    final home = await _getHomeDir();
    return p.join(home, '.lwvm', 'images');
  }

  static Future<String> _getHomeDir() async {
    var home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      home = Platform.environment['USERPROFILE'];
    }
    return home ?? '.';
  }

  Future<void> cacheImage(GuestOSImage image) async {
    final cacheDir = await _getImageCacheDir();
    final imagePath = p.join(cacheDir, p.basename(image.url));
    await Directory(cacheDir).create(recursive: true);

    if (!await File(imagePath).exists()) {
      // Download image
      // Verify SHA256
    }
  }
}