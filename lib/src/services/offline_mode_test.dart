import 'package:test/test.dart';
import '../models/guest_os_image.dart';
import 'offline_mode.dart';

void main() {
  group('OfflineModeService', () {
    late OfflineModeService service;

    setUp(() {
      service = OfflineModeService();
    });

    tearDown(() {
      service.dispose();
    });

    group('setOfflineMode', () {
      test('sets offline mode to true', () async {
        expect(service.isOfflineMode, isFalse);
        await service.setOfflineMode(true);
        expect(service.isOfflineMode, isTrue);
      });

      test('sets offline mode to false', () async {
        await service.setOfflineMode(true);
        expect(service.isOfflineMode, isTrue);
        await service.setOfflineMode(false);
        expect(service.isOfflineMode, isFalse);
      });
    });

    group('shouldAllowNetworkOperation', () {
      test('returns true when not in offline mode', () {
        expect(service.shouldAllowNetworkOperation(), isTrue);
      });

      test('returns false when in offline mode', () async {
        await service.setOfflineMode(true);
        expect(service.shouldAllowNetworkOperation(), isFalse);
      });
    });

    group('getPackageMirrorUrl', () {
      test('returns URL with default port', () async {
        final url = await service.getPackageMirrorUrl();
        expect(url, equals('http://10.0.2.2:9999/packages'));
      });
    });

    group('getPkgCacheDir', () {
      test('returns path with pkg-cache subdirectory', () async {
        final cacheDir = await service.getPkgCacheDir();
        expect(cacheDir.path, contains('pkg-cache'));
        expect(cacheDir.path, contains('.lwvm'));
      });
    });

    group('filterCachedImages', () {
      test('returns all images when not in offline mode', () async {
        final images = [
          const GuestOSImage(
            id: 'image1',
            name: 'Ubuntu',
            arch: 'arm64',
            url: 'http://example.com/ubuntu.iso',
            sha256: 'abc123',
          ),
          const GuestOSImage(
            id: 'image2',
            name: 'Debian',
            arch: 'arm64',
            url: 'http://example.com/debian.iso',
            sha256: 'def456',
          ),
        ];

        final result = await service.filterCachedImages(images);
        expect(result.length, equals(2));
      });
    });
  });
}