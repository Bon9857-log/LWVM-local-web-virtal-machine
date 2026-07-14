import 'package:flutter_test/flutter_test.dart';
import '../models/platform_capabilities.dart';
import 'platform_service.dart';

void main() {
  group('PlatformService', () {
    test('detect() returns PlatformCapabilities', () async {
      final caps = await PlatformService.detect();
      
      expect(caps.hasKvm, isA<bool>());
      expect(caps.hasHyperV, isA<bool>());
      expect(caps.hasVirtFramework, isA<bool>());
      expect(caps.isChromeOS, isA<bool>());
      expect(caps.nativeArch, isNotEmpty);
      expect(caps.hasTCG, isTrue);
    });

    test('PlatformCapabilities supports JSON serialization', () {
      const caps = PlatformCapabilities(
        hasKvm: true,
        hasHyperV: false,
        hasVirtFramework: false,
        isChromeOS: false,
        nativeArch: 'x86_64',
        hasTCG: true,
      );

      final json = caps.toJson();
      expect(json['hasKvm'], isTrue);
      expect(json['nativeArch'], equals('x86_64'));

      final fromJson = PlatformCapabilities.fromJson(json);
      expect(fromJson.hasKvm, isTrue);
      expect(fromJson.nativeArch, equals('x86_64'));
    });
  });
}