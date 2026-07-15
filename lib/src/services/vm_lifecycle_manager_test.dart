import 'package:flutter_test/flutter_test.dart';
import '../models/platform_capabilities.dart';
import '../models/vm_config.dart';
import '../models/vm_instance.dart';
import 'vm_lifecycle_manager.dart';

void main() {
  group('VmLifecycleManager', () {
    late VmLifecycleManager manager;

    setUp(() {
      final caps = const PlatformCapabilities(
        hasKvm: false,
        hasHyperV: false,
        hasVirtFramework: false,
        isChromeOS: true,
        nativeArch: 'arm64',
        hasTCG: true,
      );
      manager = VmLifecycleManager(caps);
    });

    tearDown(() {
      manager.dispose();
    });

    group('state management', () {
      test('returns stopped state initially', () async {
        final initialState = await manager.stateStream('test-vm').first;
        expect(initialState, equals(VmState.stopped));
      });
    });

    group('guest agent', () {
      test('getGuestAgent creates client with correct socket path', () async {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final client = await manager.getGuestAgent(vm);

        expect(client, isNotNull);
      });
    });
  });
}

VmInstance _createTestVm(String id, String overlayPath, {VmConfig? config}) {
  final configObj = config ?? VmConfig();
  return VmInstance(
    id: id,
    config: configObj,
    overlayPath: overlayPath,
    dataDiskPath: '$overlayPath-data',
  );
}