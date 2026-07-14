import 'package:riverpod/riverpod.dart';
import '../models/platform_capabilities.dart';
import '../models/vm_instance.dart';
import '../services/platform_service.dart';
import '../services/qemu_binary_resolver.dart';

final platformCapabilitiesProvider = FutureProvider<PlatformCapabilities>((ref) async {
  return PlatformService.detect();
});

final vmListProvider = StateProvider<List<VmInstance>>((ref) => const []);

final activeVmProvider = StateProvider<VmInstance?>((ref) => null);

final qemuBinaryPathProvider = FutureProvider.autoDispose<String?>((ref) async {
  final capabilities = await ref.watch(platformCapabilitiesProvider.future);
  return QemuBinaryResolver(capabilities).resolveBinaryPath(null);
});