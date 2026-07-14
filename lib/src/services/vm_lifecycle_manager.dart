import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:rxdart/rxdart.dart';
import 'package:path/path.dart' as p;
import '../models/platform_capabilities.dart';
import '../models/vm_config.dart';
import '../models/vm_instance.dart';
import 'guest_agent_client.dart';
import 'qemu_command_builder.dart';
import 'qemu_binary_resolver.dart';
import 'windows_whpx_backend.dart';

class VmLifecycleManager {
  final PlatformCapabilities capabilities;
  final QemuBinaryResolver binaryResolver;
  final QemuCommandBuilder commandBuilder;

  final Map<String, Process> _runningProcesses = {};
  final Map<String, VmState> _vmStates = {};
  final Map<String, StreamController<VmState>> _stateControllers = {};
  final Map<String, StreamController<String>> _logControllers = {};
  final Map<String, GuestAgentClient> _guestAgents = {};

  VmLifecycleManager(this.capabilities)
      : binaryResolver = QemuBinaryResolver(capabilities),
        commandBuilder = QemuCommandBuilder(capabilities);

  Stream<VmState> stateStream(String vmId) {
    if (!_stateControllers.containsKey(vmId)) {
      _stateControllers[vmId] = BehaviorSubject.seeded(VmState.stopped);
    }
    return _stateControllers[vmId]!.stream;
  }

  Stream<String> logStream(String vmId) {
    if (!_logControllers.containsKey(vmId)) {
      _logControllers[vmId] = BehaviorSubject();
    }
    return _logControllers[vmId]!.stream;
  }

  Future<void> start(VmInstance vm) async {
    final vmId = vm.id;

    if (_vmStates[vmId] == VmState.running || _vmStates[vmId] == VmState.starting) {
      return;
    }

    _setState(vmId, VmState.starting);

    try {
      final binaryPath = await binaryResolver.resolveBinaryPath(null);

      if (binaryPath == null) {
        _setState(vmId, VmState.error);
        return;
      }

      await binaryResolver.makeExecutable(binaryPath);

      final args = commandBuilder.build(vm);
      final logPath = vm.logPath ?? commandBuilder.buildLogPath(vmId);
      final logFile = File(logPath);

      await logFile.parent.create(recursive: true);

      final process = await Process.start(
        binaryPath,
        args,
        workingDirectory: p.dirname(vm.overlayPath),
        environment: _buildEnvironment(),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      _runningProcesses[vmId] = process;
      _setState(vmId, VmState.running);

      _setupProcessListeners(vmId, process);
    } catch (e) {
      _logControllers[vmId]?.add('Failed to start VM: $e\n');
      _setState(vmId, VmState.error);
    }
  }

  void _setupProcessListeners(String vmId, Process process) {
    process.stdout.listen((data) {
      _logControllers[vmId]?.add(data);
    });

    process.stderr.listen((data) {
      _logControllers[vmId]?.add(data);
    });

    process.exitCode.then((code) {
      _runningProcesses.remove(vmId);
      _guestAgents.remove(vmId);
      if (_vmStates[vmId] != VmState.stopping) {
        _setState(vmId, VmState.error);
      }
    });
  }

  Future<GuestAgentClient> getGuestAgent(VmInstance vm) async {
    final vmId = vm.id;
    if (!_guestAgents.containsKey(vmId)) {
      final gaSocketPath = p.join(p.dirname(vm.overlayPath), 'guest-agent.sock');
      _guestAgents[vmId] = GuestAgentClient(gaSocketPath);
    }
    return _guestAgents[vmId]!;
  }

  Future<void> stop(VmInstance vm, {bool force = false}) async {
    final vmId = vm.id;

    if (_vmStates[vmId] == VmState.stopped) {
      return;
    }

    _setState(vmId, VmState.stopping);

    final process = _runningProcesses[vmId];
    if (process != null) {
      try {
        if (!force) {
          process.kill(ProcessSignal.sigterm);

          await process.exitCode.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              process.kill(ProcessSignal.sigkill);
              return 0;
            },
          );
        } else {
          process.kill(ProcessSignal.sigkill);
          await process.exitCode;
        }
      } catch (_) {}
    }

    _runningProcesses.remove(vmId);
    _guestAgents.remove(vmId);
    _setState(vmId, VmState.stopped);
  }

  Future<void> restart(VmInstance vm) async {
    await stop(vm);
    await start(vm);
  }

  void _setState(String vmId, VmState state) {
    _vmStates[vmId] = state;
    if (_stateControllers[vmId] != null && !_stateControllers[vmId]!.isClosed) {
      _stateControllers[vmId]!.add(state);
    }
  }

  Map<String, String> _buildEnvironment() {
    final env = Platform.environment;
    final Map<String, String> result = {...env};
    
    if (capabilities.isChromeOS) {
      result['QEMU_AUDIO_DRV'] = 'none';
      result['GUEST_AGENT_SOCK'] = '/tmp';
    }
    
    if (capabilities.hasHyperV) {
      result['QEMU_AUDIO_DRV'] = 'none';
    }
    
    return result;
  }

  Future<void> cleanupAll() async {
    final futures = <Future>[];
    for (final vmId in _runningProcesses.keys.toList()) {
      futures.add(stop(VmInstance(
        id: vmId,
        config: VmConfig(),
        overlayPath: '',
        dataDiskPath: '',
      )));
    }
    await Future.wait(futures);
  }

  void dispose() {
    for (final controller in _stateControllers.values) {
      controller.close();
    }
    for (final controller in _logControllers.values) {
      controller.close();
    }
    _stateControllers.clear();
    _logControllers.clear();
    _guestAgents.clear();
  }
}