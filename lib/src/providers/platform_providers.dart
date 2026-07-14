import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/platform_capabilities.dart';
import '../services/platform_service.dart';

final platformCapabilitiesProvider = FutureProvider<PlatformCapabilities>((ref) async {
  return PlatformService.detect();
});

final vmListProvider = StateProvider<List<String>>((ref) => []);

final activeVmProvider = StateProvider<String?>((ref) => null);