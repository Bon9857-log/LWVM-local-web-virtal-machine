import 'package:freezed_annotation/freezed_annotation.dart';

part 'platform_capabilities.freezed.dart';
part 'platform_capabilities.g.dart';

@freezed
class PlatformCapabilities with _$PlatformCapabilities {
  const factory PlatformCapabilities({
    required bool hasKvm,
    required bool hasHyperV,
    required bool hasVirtFramework,
    required bool isChromeOS,
    required String nativeArch,
    @Default(false) bool hasTCG,
    @Default(false) bool hasHugePages,
    @Default(false) bool hasVirgl,
    @Default(false) bool virtiofsSupported,
  }) = _PlatformCapabilities;

  factory PlatformCapabilities.fromJson(Map<String, dynamic> json) =>
      _$PlatformCapabilitiesFromJson(json);
}