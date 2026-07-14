import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../models/platform_capabilities.dart';

class AndroidQemuExtractor {
  static const String _androidAssetsPath = 'assets/qemu/android';

  static Future<String?> extractQemuBinary(String arch) async {
    final qemuArch = arch == 'arm64' ? 'aarch64' : 'x86_64';
    final appDocDir = await _getAppDocDir();
    final targetPath = p.join(appDocDir, 'qemu-system-$qemuArch');

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.setExecutable();
      return targetPath;
    }

    final assetPath = '$_androidAssetsPath/$qemuArch/qemu-system-$qemuArch';
    
    try {
      final bytes = await rootBundle.load(assetPath);
      final buffer = bytes.buffer;
      await targetFile.writeAsBytes(
        buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      await targetFile.setExecutable();
      
      if (Platform.isAndroid) {
        await Process.run('chmod', ['700', targetPath]);
      }
      
      return targetPath;
    } catch (_) {
      return null;
    }
  }

  static Future<String> _getAppDocDir() async {
    if (Platform.isAndroid) {
      return '/data/data/com.lwvm.app/files';
    }
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    return home.isEmpty ? '.' : home;
  }
}

    final assetPath = '$_androidAssetsPath/$qemuArch/qemu-system-$qemuArch';
    
    try {
      final bytes = await rootBundle.load(assetPath);
      final buffer = bytes.buffer;
      await targetFile.writeAsBytes(
        buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      await targetFile.setExecutable();
      
      if (Platform.isAndroid) {
        await Process.run('chmod', ['700', targetPath]);
      }
      
      return targetPath;
    } catch (e) {
      return null;
    }
  }

  static Future<String> _getAppDocDir() async {
    if (Platform.isAndroid) {
      return '/data/data/com.lwvm.app/files';
    }
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    return home.isEmpty ? '.' : home;
  }
}