import 'dart:io';
import '../models/guest_os_image.dart';

class QemuBinaryResolver {
  static String? resolveBinaryPath(
    bool isChromeOS,
    bool isWindows,
    bool isMacOS,
    bool isLinux,
    CpuArch nativeArch,
  ) {
    if (isChromeOS) {
      final archDir = nativeArch == CpuArch.aarch64 ? 'arm64' : 'x86_64';
      return 'assets/qemu/android/$archDir/qemu-system-x86_64';
    }

    if (isWindows) {
      return 'assets/qemu/windows/x86_64/qemu-system-x86_64.exe';
    }

    if (isMacOS) {
      if (nativeArch == CpuArch.aarch64) {
        return null;
      }
      return 'assets/qemu/macos/x86_64/qemu-system-x86_64';
    }

    if (isLinux) {
      return _findSystemQemu();
    }

    return null;
  }

  static String? resolveSystemBinaryPath() {
    try {
      final result = Process.runSync('which', ['qemu-system-x86_64']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}
    return null;
  }

  static String? _findSystemQemu() {
    final systemPath = resolveSystemBinaryPath();
    if (systemPath != null && systemPath.isNotEmpty) {
      return systemPath;
    }
    
    return 'assets/qemu/linux/x86_64/qemu-system-x86_64';
  }

  static String? resolveBinaryForArch(
    CpuArch arch,
    bool isChromeOS,
  ) {
    if (isChromeOS) {
      final archDir = arch == CpuArch.aarch64 ? 'arm64' : 'x86_64';
      return 'assets/qemu/android/$archDir/qemu-system-x86_64';
    }
    return null;
  }
}