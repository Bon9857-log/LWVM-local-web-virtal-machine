import 'dart:io';
import 'package:path/path.dart' as p;
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

    if (capabilities.isChromeOS || Platform.isAndroid) {
      final arch = _getArchString(capabilities.nativeArch);
      final extractedPath = await _extractBinaryIfNeeded(arch);
      if (extractedPath != null) {
        return extractedPath;
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
        false,
        capabilities.nativeArch,
      );
      if (await _binaryExists(bundledPath)) {
        return bundledPath;
      }
    }

    return null;
  }

  String _getArchString(String nativeArch) {
    if (nativeArch == 'arm64') return 'aarch64';
    return 'x86_64';
  }

  Future<String?> _extractBinaryIfNeeded(String arch) async {
    try {
      final appDocDir = await _getAppDocDir();
      final binaryName = 'qemu-system-$arch';
      final targetPath = p.join(appDocDir, binaryName);

      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.setExecutable();
        return targetPath;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _getAppDocDir() async {
    if (Platform.isAndroid) {
      return '/data/data/com.lwvm.app/files';
    }
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    return home.isEmpty ? '.' : home;
  }

  String _getSystemBinaryPath() {
    if (Platform.isWindows) {
      return Platform.environment['LOCALAPPDATA'] != null
          ? '${Platform.environment['LOCALAPPDATA']}/qemu/qemu-system-x86_64.exe'
          : 'C:\\Program Files\\qemu\\qemu-system-x86_64.exe';
    }
    if (Platform.isMacOS) {
      return '/usr/local/bin/qemu-system-x86_64';
    }
    return '/usr/bin/qemu-system-x86_64';
  }

  String _getBundledBinaryPath(bool isAndroid, String arch) {
    final qemuArch = arch == 'arm64' ? 'aarch64' : 'x86_64';
    if (isAndroid) {
      return '${_androidAssetsPath}/$qemuArch/qemu-system-$qemuArch';
    }
    if (Platform.isWindows) {
      return '${_windowsAssetsPath}/x86_64/qemu-system-x86_64.exe';
    }
    if (Platform.isMacOS) {
      return '${_macosAssetsPath}/x86_64/qemu-system-x86_64';
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