import 'package:riverpod/riverpod.dart';
import '../models/platform_capabilities.dart';
import '../models/vm_instance.dart';
import '../services/platform_service.dart';
import '../services/qemu_binary_resolver.dart';
import '../services/vm_lifecycle_manager.dart';
import '../services/vm_storage_manager.dart';
import '../services/vm_provisioning_service.dart';

final platformCapabilitiesProvider = FutureProvider<PlatformCapabilities>((ref) async {
  return PlatformService.detect();
});

final vmListProvider = StateProvider<List<VmInstance>>((ref) => const []);

final activeVmProvider = StateProvider<VmInstance?>((ref) => null);

final qemuBinaryPathProvider = FutureProvider.autoDispose<String?>((ref) async {
  final capabilities = await ref.watch(platformCapabilitiesProvider.future);
  return QemuBinaryResolver(capabilities).resolveBinaryPath(null);
});

final vmLifecycleManagerProvider = Provider.autoDispose<VmLifecycleManager>((ref) {
  final capsAsync = ref.watch(platformCapabilitiesProvider);
  return capsAsync.when(
    data: (caps) => VmLifecycleManager(caps),
    loading: () => throw StateError('Capabilities loading'),
    error: (e, _) => throw StateError('Capabilities error: $e'),
  );
});

final vmProvisioningServiceProvider = Provider<VmProvisioningService>((ref) {
  return VmProvisioningService();
});
