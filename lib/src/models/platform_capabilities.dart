import 'package:freezed_annotation/freezed_annotation.dart';
import 'guest_os_image.dart';

part 'platform_capabilities.freezed.dart';
part 'platform_capabilities.g.dart';

@freezed
class PlatformCapabilities with _$PlatformCapabilities {
  const factory PlatformCapabilities({
    @Default(false) bool hasKvm,
    @Default(false) bool hasHyperV,
    @Default(false) bool hasVirtFramework,
    @Default(false) bool isChromeOS,
    required CpuArch nativeArch,
    String? qemuBinaryPath,
  }) = _PlatformCapabilities;

  factory PlatformCapabilities.fromJson(Map<String, dynamic> json) =>
      _$PlatformCapabilitiesFromJson(json);
}