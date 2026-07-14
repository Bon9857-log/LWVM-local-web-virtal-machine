import 'package:test/test.dart';
import '../models/vm_config.dart';
import '../models/vm_instance.dart';
import 'windows_whpx_backend.dart';

void main() {
  group('WindowsWhpxBackend', () {
    test('buildWhpxOptimizedArgs generates correct QEMU arguments', () {
      final vm = VmInstance(
        id: 'test-vm',
        config: const VmConfig(),
        overlayPath: '/vms/test-vm/overlay.qcow2',
        dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
      );
      
      final args = WindowsWhpxBackend.buildWhpxOptimizedArgs(
        vm: vm,
        qemuPath: '/usr/bin/qemu-system-x86_64',
      );

      expect(args, contains('-machine'));
      expect(args.any((a) => a.contains('q35,accel=whpx')), true);
      expect(args, contains('-cpu'));
      expect(args, contains('host'));
      expect(args.any((a) => a.contains('virtio-net-pci')), true);
      expect(args.any((a) => a.contains('virtio-gpu-pci')), true);
    });

    test('buildWhpxOptimizedArgs includes VirtIO ISO when provided', () {
      final vm = VmInstance(
        id: 'test-vm',
        config: const VmConfig(),
        overlayPath: '/vms/test-vm/overlay.qcow2',
        dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
      );
      
      final args = WindowsWhpxBackend.buildWhpxOptimizedArgs(
        vm: vm,
        qemuPath: '/usr/bin/qemu-system-x86_64',
        virtioIsoPath: '/path/to/virtio-win.iso',
      );

      expect(args.any((a) => a.contains('virtio-win.iso')), true);
      expect(args.any((a) => a.contains('media=cdrom')), true);
    });

    test('getEnhancedSessionConfig returns VMBus features', () {
      final config = WindowsWhpxBackend.getEnhancedSessionConfig();

      expect(config['transportType'], equals('EnhancedSessionTransportType'));
      expect(config['supportsClipboard'], isTrue);
      expect(config['supportsFileTransfer'], isTrue);
      expect(config['supportsDynamicResize'], isTrue);
    });

    test('getWhpxInstallInstructions returns helpful guidance', () {
      final instructions = WindowsWhpxBackend.getWhpxInstallInstructions();

      expect(instructions, contains('Enable-WindowsOptionalFeature'));
      expect(instructions, contains('Microsoft-Windows-Hyper-V-Hypervisor'));
      expect(instructions, contains('WHPX'));
    });
  });
}