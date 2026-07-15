import 'dart:io';
import '../models/platform_capabilities.dart';

class QemuBinaryResolver {
  static const String _androidAssetsPath = 'assets/qemu/android';
  static const String _windowsAssetsPath = 'assets/qemu/windows';
  static const String _macosAssetsPath = 'assets/qemu/macos';

  final PlatformCapabilities capabilities;

  QemuBinaryResolver(this.capabilities);

  Future<String?> resolveBinaryPath(String? explicitPath) async {
    if (explicitPath != null && explicitPath.isNotEmpty) {
      final file = File(explicitPath);
      if (await file.exists()) {
        return explicitPath;
      }
    }

    if (capabilities.isChromeOS) {
      final arch = capabilities.nativeArch == 'arm64' ? 'aarch64' : 'x86_64';
      final bundledPath = _getBundledBinaryPath(Platform.isAndroid, arch);
      if (await _binaryExists(bundledPath)) {
        return bundledPath;
      }
    }

    if (capabilities.hasVirtFramework) {
      return null;
    }

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final systemPath = _getSystemBinaryPath();
      if (await _binaryExists(systemPath)) {
        return systemPath;
      }

      final bundledPath = _getBundledBinaryPath(
        Platform.isAndroid,
        capabilities.nativeArch,
      );
      if (await _binaryExists(bundledPath)) {
        return bundledPath;
      }
    }

    return null;
  }

  String _getSystemBinaryPath() {
    if (Platform.isWindows) {
      return Platform.environment['LOCALAPPDATA'] != null
          ? '${Platform.environment['LOCALAPPDATA']}/qemu/qemu-system-x86_64.exe'
          : 'C:\\Program Files\\qemu\\qemu-system-x86_64.exe';
    }
    return '/usr/bin/qemu-system-x86_64';
  }

  String _getBundledBinaryPath(bool isAndroid, String arch) {
    if (isAndroid) {
      return '$_androidAssetsPath/$arch/qemu-system-$arch';
    }
    if (Platform.isWindows) {
      return '$_windowsAssetsPath/x86_64/qemu-system-x86_64.exe';
    }
    if (Platform.isMacOS) {
      return '$_macosAssetsPath/x86_64/qemu-system-x86_64';
    }
    return 'qemu-system-x86_64';
  }

  Future<bool> _binaryExists(String path) async {
    if (Platform.isAndroid) {
      return true;
    }
    return File(path).exists();
  }

  Future<bool> makeExecutable(String path) async {
    if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
      try {
        await Process.run('chmod', ['+x', path]);
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }
}