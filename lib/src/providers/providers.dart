import 'package:riverpod/riverpod.dart';
import '../models/platform_capabilities.dart';
import '../models/vm_instance.dart';
import '../services/platform_service.dart';
import '../services/qemu_binary_resolver.dart';
import '../services/vm_lifecycle_manager.dart';
import '../services/provisioning_service.dart';
import '../services/offline_mode.dart';

final offlineModeProvider = StateProvider<bool>((ref) => false);

final offlineModeServiceProvider = Provider.autoDispose<OfflineModeService>((ref) {
  return OfflineModeService();
});

final platformCapabilitiesProvider = FutureProvider<PlatformCapabilities>((ref) async {
  return PlatformService.detect();
});

final vmLifecycleManagerProvider = Provider.autoDispose<VmLifecycleManager>((ref) {
  final capabilities = ref.watch(platformCapabilitiesProvider).value;
  return VmLifecycleManager(capabilities ?? const PlatformCapabilities(
    hasKvm: false,
    hasHyperV: false,
    hasVirtFramework: false,
    isChromeOS: false,
    nativeArch: 'unknown',
  ));
});

final provisioningServiceProvider = Provider.autoDispose<ProvisioningService>((ref) {
  final capabilities = ref.watch(platformCapabilitiesProvider).value;
  return ProvisioningService(capabilities ?? const PlatformCapabilities(
    hasKvm: false,
    hasHyperV: false,
    hasVirtFramework: false,
    isChromeOS: false,
    nativeArch: 'unknown',
  ));
});

final vmListProvider = StateProvider<List<VmInstance>>((ref) => const []);

final activeVmProvider = StateProvider<VmInstance?>((ref) => null);

final qemuBinaryPathProvider = FutureProvider.autoDispose<String?>((ref) async {
  final capabilities = await ref.watch(platformCapabilitiesProvider.future);
  return QemuBinaryResolver(capabilities).resolveBinaryPath(null);
});