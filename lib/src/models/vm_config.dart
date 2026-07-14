import 'package:freezed_annotation/freezed_annotation.dart';

part 'vm_config.freezed.dart';
part 'vm_config.g.dart';

enum GuestOS { alpine, ubuntu, zorin }

enum GraphicsBackend { spice, vnc }

@freezed
class VmConfig with _$VmConfig {
  const factory VmConfig({
    @Default(2) int cpus,
    @Default(2048) int ram,
    @Default(20) int diskSize,
    @Default(GuestOS.alpine) GuestOS guestOS,
    @Default(GraphicsBackend.spice) GraphicsBackend graphics,
    String? sshPort,
    String? webPort,
    String? httpsPort,
    String? rdpPort,
    Map<String, int>? customPortForwards,
  }) = _VmConfig;

  factory VmConfig.fromJson(Map<String, dynamic> json) => _$VmConfigFromJson(json);
}

extension VmConfigExtension on VmConfig {
  Map<String, int> getAllPortForwards() {
    final forwards = {
      if (sshPort != null) 22: int.parse(sshPort!),
      if (webPort != null) 80: int.parse(webPort!),
      if (httpsPort != null) 443: int.parse(httpsPort!),
      if (rdpPort != null) 3389: int.parse(rdpPort!),
    };
    if (customPortForwards != null) {
      forwards.addAll(customPortForwards!);
    }
    return forwards;
  }
}