import 'package:test/test.dart';
import '../models/platform_capabilities.dart';
import '../models/vm_config.dart';
import '../models/vm_instance.dart';
import 'qemu_command_builder.dart';

void main() {
  group('QemuCommandBuilder', () {
    late QemuCommandBuilder builder;

    group('ChromeOS ARM64', () {
      setUp(() {
        final caps = const PlatformCapabilities(
          hasKvm: false,
          hasHyperV: false,
          hasVirtFramework: false,
          isChromeOS: true,
          nativeArch: 'arm64',
          hasTCG: true,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('uses TCG acceleration with thread=multi', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-accel'));
        expect(args, contains('tcg,thread=multi'));
      });

      test('uses virt machine type', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-machine'));
        expect(args, contains('virt'));
      });

      test('includes VirtIO disk arguments', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-drive'));
        expect(args.any((a) => a.contains('overlay.qcow2')), true);
      });

      test('includes SPICE graphics by default', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-spice'));
        expect(args, contains('disable-ticketing=on'));
        expect(args, contains('virtio-gpu-pci'));
      });

      test('includes VNC graphics when configured', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(graphics: GraphicsBackend.vnc),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('-vnc')), true);
      });

      test('includes guest agent socket', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-chardev'));
        expect(args.any((a) => a.contains('guest-agent.sock')), true);
      });

      test('builds log path correctly', () {
        final logPath = builder.buildLogPath('test-vm');
        expect(logPath, contains('.lwvm/vms/test-vm/logs/qemu.log'));
      });
    });

    group('Linux with KVM', () {
      setUp(() {
        final caps = const PlatformCapabilities(
          hasKvm: true,
          hasHyperV: false,
          hasVirtFramework: false,
          isChromeOS: false,
          nativeArch: 'x86_64',
          hasTCG: true,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('uses KVM acceleration', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-accel'));
        expect(args, contains('kvm'));
        expect(args, contains('-cpu'));
        expect(args, contains('host'));
      });

      test('uses q35 machine type with KVM', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-machine'));
        expect(args, contains('q35'));
      });
    });

    group('Windows with Hyper-V', () {
      setUp(() {
        final caps = const PlatformCapabilities(
          hasKvm: false,
          hasHyperV: true,
          hasVirtFramework: false,
          isChromeOS: false,
          nativeArch: 'x86_64',
          hasTCG: true,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('uses WHPX acceleration with host CPU', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-accel'));
        expect(args, contains('whpx'));
        expect(args, contains('-cpu'));
        expect(args, contains('host'));
      });

      test('uses q35 machine type with WHPX', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args, contains('-machine'));
        expect(args, contains('q35'));
      });
    });

    group('Network', () {
      setUp(() {
        final caps = const PlatformCapabilities(
          hasKvm: false,
          hasHyperV: false,
          hasVirtFramework: false,
          isChromeOS: true,
          nativeArch: 'arm64',
          hasTCG: true,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('includes default port forwards SSH and HTTP', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:2222-:22')), true);
        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:8080-:80')), true);
        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:8443-:443')), true);
        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:3389-:3389')), true);
      });

      test('builds port forwards from config', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(sshPort: '2222', webPort: '8080'),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:2222-:22')), true);
        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:8080-:80')), true);
      });

      test('includes virtio-net device', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('virtio-net-pci')), true);
      });

      test('includes guest agent virtio-serial-pci with VNC', () {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(graphics: GraphicsBackend.vnc),
          overlayPath: '/vms/test-vm/overlay.qcow2',
          dataDiskPath: '/vms/test-vm/overlay.qcow2-data',
        );

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('virtio-serial-pci')), true);
        expect(args.any((a) => a.contains('guest-agent.sock')), true);
        expect(args.any((a) => a.contains('org.qemu.guest_agent.0')), true);
      });
    });
  });
}