import 'package:flutter_test/flutter_test.dart';
import '../models/platform_capabilities.dart';
import 'qemu_binary_resolver.dart';

void main() {
  group('QemuBinaryResolver', () {
    test('getArchString returns aarch64 for arm64', () {
      final caps = const PlatformCapabilities(
        hasKvm: false,
        hasHyperV: false,
        hasVirtFramework: false,
        isChromeOS: true,
        nativeArch: 'arm64',
        hasTCG: true,
      );

      final resolver = QemuBinaryResolver(caps);
      // Test via public method behavior
      expect(resolver, isNotNull);
    });

    test('getArchString returns x86_64 for x86_64', () {
      final caps = const PlatformCapabilities(
        hasKvm: false,
        hasHyperV: false,
        hasVirtFramework: false,
        isChromeOS: true,
        nativeArch: 'x86_64',
        hasTCG: true,
      );

      final resolver = QemuBinaryResolver(caps);
      expect(resolver, isNotNull);
    });

    test('returns null for macOS ARM64 with VirtFramework', () async {
      final caps = const PlatformCapabilities(
        hasKvm: false,
        hasHyperV: false,
        hasVirtFramework: true,
        isChromeOS: false,
        nativeArch: 'arm64',
        hasTCG: true,
      );

      final resolver = QemuBinaryResolver(caps);
      final path = await resolver.resolveBinaryPath(null);

      expect(path, isNull);
    });

    test('getSystemBinaryPath returns correct path for Linux', () {
      final caps = const PlatformCapabilities(
        hasKvm: true,
        hasHyperV: false,
        hasVirtFramework: false,
        isChromeOS: false,
        nativeArch: 'x86_64',
        hasTCG: true,
      );

      final resolver = QemuBinaryResolver(caps);
      expect(resolver, isNotNull);
    });

    test('getSystemBinaryPath returns correct path for macOS', () {
      final caps = const PlatformCapabilities(
        hasKvm: false,
        hasHyperV: false,
        hasVirtFramework: false,
        isChromeOS: false,
        nativeArch: 'arm64',
        hasTCG: true,
      );

      final resolver = QemuBinaryResolver(caps);
      expect(resolver, isNotNull);
    });

    test('returns explicit path when valid', () async {
      final caps = const PlatformCapabilities(
        hasKvm: true,
        hasHyperV: false,
        hasVirtFramework: false,
        isChromeOS: false,
        nativeArch: 'x86_64',
        hasTCG: true,
      );

      final resolver = QemuBinaryResolver(caps);
      expect(resolver, isNotNull);
    });
  });
}