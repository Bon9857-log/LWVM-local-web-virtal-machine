import 'package:freezed_annotation/freezed_annotation.dart';
import 'vm_config.dart';

part 'vm_instance.freezed.dart';
part 'vm_instance.g.dart';

enum VmState { stopped, starting, running, stopping, error }

@freezed
class VmInstance with _$VmInstance {
  const factory VmInstance({
    required String id,
    required VmConfig config,
    @Default(VmState.stopped) VmState state,
    required String overlayPath,
    required String dataDiskPath,
  }) = _VmInstance;

  factory VmInstance.fromJson(Map<String, dynamic> json) =>
      _$VmInstanceFromJson(json);
}