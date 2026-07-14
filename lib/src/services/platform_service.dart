import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/platform_capabilities.dart';

class PlatformService {
  static Future<PlatformCapabilities> detect() async {
    if (kIsWeb) {
      return const PlatformCapabilities(
        hasKvm: false,
        hasHyperV: false,
        hasVirtFramework: false,
        isChromeOS: false,
        nativeArch: 'unknown',
        hasTCG: true,
      );
    }

    final isAndroid = Platform.isAndroid;
    final isChromeOS = await _detectChromeOS();
    final nativeArch = _detectNativeArch();
    final hasKvm = isAndroid ? false : await _detectKvm();
    final hasHyperV = await _detectHyperV();
    final hasVirtFramework = await _detectVirtFramework();

    return PlatformCapabilities(
      hasKvm: hasKvm,
      hasHyperV: hasHyperV,
      hasVirtFramework: hasVirtFramework,
      isChromeOS: isChromeOS,
      nativeArch: nativeArch,
      hasTCG: true,
    );
  }

  static Future<bool> _detectChromeOS() async {
    if (!Platform.isAndroid) return false;

    try {
      final file = File('/proc/sys/kernel/chrome.platform');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.contains('chromebook') || content.contains('chrome')) {
          return true;
        }
      }
    } catch (_) {}

    try {
      if (Platform.environment['chrome']?.toLowerCase().contains('os') == true) {
        return true;
      }
      if (Platform.environment['arc'] != null) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  static String _detectNativeArch() {
    if (Platform.isAndroid) {
      return _getAndroidArch();
    }
    if (Platform.isIOS) return 'arm64';
    if (Platform.isMacOS) {
      return _isAppleSilicon() ? 'arm64' : 'x86_64';
    }
    if (Platform.isWindows) return 'x86_64';
    if (Platform.isLinux) return 'x86_64';
    if (Platform.isFuchsia) return 'arm64';
    return 'unknown';
  }

  static String _getAndroidArch() {
    final abi = Platform.environment['ro.product.cpu.abi'] ?? '';
    if (abi.contains('arm64') || abi.contains('aarch64')) return 'arm64';
    if (abi.contains('x86_64') || abi.contains('amd64')) return 'x86_64';
    if (abi.contains('armeabi') || abi.contains('arm')) return 'arm';
    return 'unknown';
  }

  static bool _isAppleSilicon() {
    try {
      final file = File('/sys/class/dmi/id/chassis_type');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        return content.contains('arm') || content.contains('30');
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> _detectKvm() async {
    if (Platform.isLinux) {
      final kvmFile = File('/dev/kvm');
      return await kvmFile.exists() &&
          (await Process.run('test', ['-r', '/dev/kvm']).then((r) => r.exitCode == 0));
    }
    return false;
  }

  static Future<bool> _detectHyperV() async {
    if (!Platform.isWindows) return false;
    try {
      final result = await Process.run('powershell', [
        '-Command',
        'Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model',
      ]);
      return result.exitCode == 0 &&
          (result.stdout.toString().contains('Virtual') ||
              result.stdout.toString().contains('Virtual Machine'));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _detectVirtFramework() async {
    if (!Platform.isMacOS) return false;
    try {
      final result = await Process.run('sysctl', ['-n', 'hw.optional.arm64']);
      return result.exitCode == 0 && result.stdout.toString().trim() == '1';
    } catch (_) {
      return false;
    }
  }
}