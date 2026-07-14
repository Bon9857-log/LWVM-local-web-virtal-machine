import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/guest_os_image.dart';

class OfflineModeService {
  static const String _webdavPortEnv = 'LWVM_WEBDAV_PORT';
  static const int _defaultWebdavPort = 9999;
  static const String _pkgCacheDirName = 'pkg-cache';

  bool _offlineMode = false;
  int? _webdavPort;
  Process? _webdavProcess;

  bool get isOfflineMode => _offlineMode;
  
  Future<void> setOfflineMode(bool enabled) async {
    _offlineMode = enabled;
    if (enabled) {
      await _startPackageMirror();
    } else {
      await _stopPackageMirror();
    }
  }

  bool shouldAllowNetworkOperation() {
    return !_offlineMode;
  }

  Future<List<GuestOSImage>> filterCachedImages(List<GuestOSImage> images) async {
    if (!_offlineMode) return images;
    
    final cachedPaths = await _getCachedImagePaths();
    return images.where((image) => cachedPaths.contains(image.id)).toList();
  }

  Future<Set<String>> _getCachedImagePaths() async {
    final cacheDir = await getPkgCacheDir();
    if (!await cacheDir.exists()) {
      return {};
    }
    final files = await cacheDir.list().toList();
    return files.map((f) => p.basename(f.path)).toSet();
  }

  Future<Directory> getPkgCacheDir() async {
    final home = await _getHomeDir();
    return Directory(p.join(home, '.lwvm', _pkgCacheDirName));
  }

  Future<String> getPackageMirrorUrl() async {
    final port = await _getWebdavPort();
    return 'http://10.0.2.2:$port/packages';
  }

  Future<int> _getWebdavPort() async {
    if (_webdavPort != null) return _webdavPort!;
    
    final portStr = Platform.environment[_webdavPortEnv];
    _webdavPort = int.tryParse(portStr ?? '') ?? _defaultWebdavPort;
    return _webdavPort!;
  }

  Future<void> _startPackageMirror() async {
    final cacheDir = await getPkgCacheDir();
    await cacheDir.create(recursive: true);
    
    final port = await _getWebdavPort();
    _webdavProcess = await Process.start('python3', [
      '-m',
      'http.server',
      '$port',
      '--directory',
      cacheDir.path,
    ]);
  }

  Future<void> _stopPackageMirror() async {
    if (_webdavProcess != null) {
      _webdavProcess!.kill(ProcessSignal.sigterm);
      _webdavProcess = null;
    }
  }

  static Future<String> _getHomeDir() async {
    var home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      home = Platform.environment['USERPROFILE'];
    }
    return home ?? '.';
  }

  Future<void> cachePackages(List<String> packages) async {
    final cacheDir = await getPkgCacheDir();
    await cacheDir.create(recursive: true);
    
    for (final pkg in packages) {
      final pkgFile = File(p.join(cacheDir.path, p.basename(pkg)));
      if (!await pkgFile.exists()) {
        // Download package
      }
    }
  }

  void dispose() {
    _stopPackageMirror();
  }
}