import 'dart:io';
import '../models/platform_capabilities.dart';
import '../models/guest_os_image.dart';

class PlatformService {
  static Future<PlatformCapabilities> detect() async {
    final isAndroid = Platform.isAndroid;
    final isWindows = Platform.isWindows;
    final isMacOS = Platform.isMacOS;
    final isLinux = Platform.isLinux;

    bool isChromeOS = false;
    if (isAndroid) {
      isChromeOS = await _detectChromeOS();
    }

    bool hasKvm = false;
    bool hasHyperV = false;
    bool hasVirtFramework = false;

    if (isLinux && !isChromeOS) {
      hasKvm = await _checkKvmAccess();
    }

    if (isWindows) {
      hasHyperV = await _checkHyperV();
    }

    if (isMacOS) {
      hasVirtFramework = await _checkVirtFramework();
    }

    final nativeArch = await _detectNativeArch();
    final qemuBinaryPath = QemuBinaryResolver.resolveBinaryPath(isChromeOS, isWindows, isMacOS, isLinux, nativeArch);

    return PlatformCapabilities(
      hasKvm: hasKvm,
      hasHyperV: hasHyperV,
      hasVirtFramework: hasVirtFramework,
      isChromeOS: isChromeOS,
      nativeArch: nativeArch,
      qemuBinaryPath: qemuBinaryPath,
    );
  }

  static Future<bool> _detectChromeOS() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await Process.run('getprop', ['ro.product.board']);
      return result.stdout.toString().contains('crosvm') ||
             result.stdout.toString().contains('eve') ||
             result.exitCode == 0;
    } catch (_) {
      try {
        final arcResult = await Process.run('getprop', ['ro.boot.arc']);
        return arcResult.exitCode == 0;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> _checkKvmAccess() async {
    try {
      final kvmFile = File('/dev/kvm');
      final exists = await kvmFile.exists();
      if (!exists) return false;
      final stat = await kvmFile.stat();
      return stat.mode & 0o400 != 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _checkHyperV() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        'Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -ErrorAction SilentlyContinue | Select-Object -ExpandProperty State',
      ]);
      return result.stdout.toString().trim() == 'Enabled';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _checkVirtFramework() async {
    try {
      final result = await Process.run('xcrun', [
        '--sdk', 'macosx', '--show-framework', 'Virtualization',
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<CpuArch> _detectNativeArch() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return CpuArch.aarch64;
    }
    try {
      final result = await Process.run('uname', ['-m']);
      final arch = result.stdout.toString().trim();
      if (arch == 'aarch64' || arch == 'arm64') {
        return CpuArch.aarch64;
      }
      return CpuArch.x86_64;
    } catch (_) {
      return CpuArch.x86_64;
    }
  }
}