import 'vm_config.dart';

enum VmState { stopped, starting, running, stopping, error }

class VmInstance {
  final String id;
  final VmConfig config;
  final VmState state;
  final String overlayPath;
  final String dataDiskPath;
  final String? baseImagePath;
  final String? logPath;
  final int? pid;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? lastStoppedAt;

  const VmInstance({
    required this.id,
    required this.config,
    this.state = VmState.stopped,
    required this.overlayPath,
    required this.dataDiskPath,
    this.baseImagePath,
    this.logPath,
    this.pid,
    this.createdAt,
    this.startedAt,
    this.lastStoppedAt,
  });

  factory VmInstance.fromJson(Map<String, dynamic> json) {
    return VmInstance(
      id: json['id'] as String,
      config: VmConfig.fromJson(json['config'] as Map<String, dynamic>),
      state: _vmStateFromJson(json['state'] as String? ?? 'stopped'),
      overlayPath: json['overlayPath'] as String,
      dataDiskPath: json['dataDiskPath'] as String,
      baseImagePath: json['baseImagePath'] as String?,
      logPath: json['logPath'] as String?,
      pid: json['pid'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      lastStoppedAt: json['lastStoppedAt'] != null ? DateTime.parse(json['lastStoppedAt'] as String) : null,
    );
  }
}

VmState _vmStateFromJson(String value) {
  switch (value) {
    case 'stopped': return VmState.stopped;
    case 'starting': return VmState.starting;
    case 'running': return VmState.running;
    case 'stopping': return VmState.stopping;
    case 'error': return VmState.error;
    default: return VmState.stopped;
  }
}