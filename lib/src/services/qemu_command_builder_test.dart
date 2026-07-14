import 'package:test/test.dart';
import '../models/platform_capabilities.dart';
import '../models/vm_config.dart';
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
          hasHugePages: false,
          hasVirgl: false,
          virtiofsSupported: false,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('uses TCG acceleration with thread=multi', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args, contains('-accel'));
        expect(args, contains('tcg,thread=multi'));
      });

      test('uses virt machine type', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args, contains('-machine'));
        expect(args, contains('virt'));
      });

      test('includes VirtIO disk arguments', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args, contains('-drive'));
        expect(args.any((a) => a.contains('overlay.qcow2')), true);
      });

      test('includes SPICE graphics by default', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args, contains('-spice'));
        expect(args, contains('disable-ticketing=on'));
        expect(args, contains('virtio-gpu-pci'));
      });

      test('includes VNC graphics when configured', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2', graphics: GraphicsBackend.vnc);

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('-vnc')), true);
      });

      test('includes guest agent socket', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

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
          hasHugePages: false,
          hasVirgl: false,
          virtiofsSupported: false,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('uses KVM acceleration', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args, contains('-enable-kvm'));
        expect(args, contains('-cpu'));
        expect(args, contains('host'));
      });

      test('uses q35 machine type with KVM', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args, contains('-machine'));
        expect(args, contains('q35'));
      });
    });

    group('Linux with KVM and HugePages', () {
      setUp(() {
        final caps = const PlatformCapabilities(
          hasKvm: true,
          hasHyperV: false,
          hasVirtFramework: false,
          isChromeOS: false,
          nativeArch: 'x86_64',
          hasTCG: true,
          hasHugePages: true,
          hasVirgl: false,
          virtiofsSupported: false,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('uses hugepages memory backend', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('memory-backend-file')), true);
        expect(args.any((a) => a.contains('mem-path=/dev/hugepages')), true);
        expect(args.any((a) => a.contains('prealloc=on')), true);
      });
    });

    group('Linux with KVM and VirGL', () {
      setUp(() {
        final caps = const PlatformCapabilities(
          hasKvm: true,
          hasHyperV: false,
          hasVirtFramework: false,
          isChromeOS: false,
          nativeArch: 'x86_64',
          hasTCG: true,
          hasHugePages: false,
          hasVirgl: true,
          virtiofsSupported: false,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('enables virgl on virtio-gpu-pci', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('virtio-gpu-pci,virgl=on')), true);
      });
    });

    group('Linux with VirtIO-FS', () {
      setUp(() {
        final caps = const PlatformCapabilities(
          hasKvm: true,
          hasHyperV: false,
          hasVirtFramework: false,
          isChromeOS: false,
          nativeArch: 'x86_64',
          hasTCG: true,
          hasHugePages: false,
          hasVirgl: false,
          virtiofsSupported: true,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('includes virtio-fs-pci when shared folder configured', () {
        final vm = _createTestVm(
          'test-vm',
          '/vms/test-vm/overlay.qcow2',
          config: const VmConfig(
            sharedFolderPath: '/home/user/shared',
            sharedFolderMountPoint: '/mnt/host',
            sharedFolderBackend: SharedFolderBackend.virtiofs,
          ),
        );

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('virtio-fs-pci')), true);
        expect(args.any((a) => a.contains('queue-size=1024')), true);
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
          hasHugePages: false,
          hasVirgl: false,
          virtiofsSupported: false,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('uses WHPX acceleration', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args, contains('-accel'));
        expect(args, contains('whpx'));
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
          hasHugePages: false,
          hasVirgl: false,
          virtiofsSupported: false,
        );
        builder = QemuCommandBuilder(caps);
      });

      test('includes default port forwards SSH and HTTP', () {
        final vm = _createTestVm(
          'test-vm',
          '/vms/test-vm/overlay.qcow2',
        );

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:2222-:22')), true);
        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:8080-:80')), true);
        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:8443-:443')), true);
        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:3389-:3389')), true);
      });

      test('builds port forwards from config', () {
        final vm = _createTestVm(
          'test-vm',
          '/vms/test-vm/overlay.qcow2',
          config: const VmConfig(sshPort: '2222', webPort: '8080'),
        );

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:2222-:22')), true);
        expect(args.any((a) => a.contains('hostfwd=tcp:127.0.0.1:8080-:80')), true);
      });

      test('includes virtio-net device', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2');

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('virtio-net-pci')), true);
      });

      test('includes guest agent virtio-serial-pci with VNC', () {
        final vm = _createTestVm('test-vm', '/vms/test-vm/overlay.qcow2', graphics: GraphicsBackend.vnc);

        final args = builder.build(vm);

        expect(args.any((a) => a.contains('virtio-serial-pci')), true);
        expect(args.any((a) => a.contains('guest-agent.sock')), true);
        expect(args.any((a) => a.contains('org.qemu.guest_agent.0')), true);
      });
    });
  });
}

dynamic _createTestVm(String id, String overlayPath, {VmConfig? config, GraphicsBackend? graphics}) {
  final configObj = config ?? VmConfig(graphics: graphics ?? GraphicsBackend.spice);
  return _VmInstance(
    id: id,
    config: configObj,
    overlayPath: overlayPath,
    dataDiskPath: '$overlayPath-data',
  );
}

class _VmInstance {
  final String id;
  final VmConfig config;
  final String overlayPath;
  final String dataDiskPath;

  _VmInstance({
    required this.id,
    required this.config,
    required this.overlayPath,
    required this.dataDiskPath,
  });
}