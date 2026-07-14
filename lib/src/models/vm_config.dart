import 'package:freezed_annotation/freezed_annotation.dart';
import 'guest_os_image.dart';

part 'vm_config.freezed.dart';
part 'vm_config.g.dart';

@freezed
class VmConfig with _$VmConfig {
  const factory VmConfig({
    @Default(2) int cpus,
    @Default(2048) int ram,
    @Default(20480) int disk,
    @Default(false) bool networkEnabled,
    @Default(true) bool graphicsEnabled,
    @Default(true) bool guestAgentEnabled,
    required GuestOSImage guestOs,
  }) = _VmConfig;

  factory VmConfig.fromJson(Map<String, dynamic> json) => _$VmConfigFromJson(json);
}