import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/platform_capabilities.dart';
import '../models/vm_config.dart';
import '../models/vm_instance.dart';

class QemuCommandBuilder {
  static const int _defaultChromeOSRamLimitMb = 2048;
  static const int _defaultChromeOSVncPort = 5900;
  static const int _defaultSpicePort = 5900;
  static const int _defaultSpiceWebSocketPort = 5700;

  final PlatformCapabilities capabilities;

  QemuCommandBuilder(this.capabilities);

  List<String> build(VmInstance vm) {
    final args = <String>[];

    _addAccelerationArgs(args, vm);
    _addMachineArgs(args);
    _addMemoryCpuArgs(args, vm);
    _addDiskArgs(args, vm);
    _addAllNetworkArgs(args, vm);
    _addGraphicsAndGuestAgent(args, vm);
    _addOtherArgs(args);

    return args;
  }

  void _addGraphicsAndGuestAgent(List<String> args, VmInstance vm) {
    if (vm.config.graphics == GraphicsBackend.spice) {
      _addSpiceArgs(args, vm);
    } else {
      _addVncArgs(args);
    }
    _addGuestAgentArgs(args, vm);
    _addSharedFolderArgs(args, vm);
  }

  void _addAccelerationArgs(List<String> args, VmInstance vm) {
    if (capabilities.isChromeOS) {
      args.addAll(['-accel', 'tcg,thread=multi']);
    } else if (capabilities.hasKvm) {
      args.addAll(['-enable-kvm', '-cpu', 'host']);
    } else if (capabilities.hasHyperV) {
      args.addAll(['-accel', 'whpx']);
    } else {
      args.addAll(['-accel', 'tcg']);
    }
  }

  void _addMachineArgs(List<String> args) {
    if (capabilities.isChromeOS) {
      args.addAll(['-machine', 'virt']);
    } else if (capabilities.hasKvm || capabilities.hasHyperV) {
      args.addAll(['-machine', 'q35']);
    }
  }

  void _addMemoryCpuArgs(List<String> args, VmInstance vm) {
    int ram = vm.config.ram;
    int cpus = vm.config.cpus;

    if (capabilities.isChromeOS) {
      ram = ram.clamp(512, ram > _defaultChromeOSRamLimitMb ? ram : _defaultChromeOSRamLimitMb);
    }

    if (capabilities.hasKvm && capabilities.hasHugePages) {
      _addHugePageMemoryArgs(args, ram);
    } else {
      args.addAll(['-m', '${ram}M']);
    }
    args.addAll(['-smp', '$cpus']);
  }

  void _addHugePageMemoryArgs(List<String> args, int ram) {
    final sizeGb = (ram * 1024 * 1024) ~/ (1024 * 1024 * 1024) + 1;
    args.addAll([
      '-object',
      'memory-backend-file,id=mem,size=${sizeGb}G,mem-path=/dev/hugepages,share=on,prealloc=on',
      '-numa',
      'node,memdev=mem',
    ]);
  }

  void _addDiskArgs(List<String> args, VmInstance vm) {
    args.addAll([
      '-drive',
      'file=${vm.overlayPath},if=virtio,format=qcow2,id=drive0',
    ]);

    if (vm.dataDiskPath.isNotEmpty) {
      args.addAll([
        '-drive',
        'file=${vm.dataDiskPath},if=virtio,format=qcow2,id=drive1',
      ]);
    }
  }

  void _addAllNetworkArgs(List<String> args, VmInstance vm) {
    final customForwards = <int, int>{};

    if (vm.config.sshPort != null) {
      customForwards[22] = int.parse(vm.config.sshPort!);
    }
    if (vm.config.webPort != null) {
      customForwards[80] = int.parse(vm.config.webPort!);
    }
    if (vm.config.httpsPort != null) {
      customForwards[443] = int.parse(vm.config.httpsPort!);
    }
    if (vm.config.rdpPort != null) {
      customForwards[3389] = int.parse(vm.config.rdpPort!);
    }
    if (vm.config.customPortForwards != null) {
      customForwards.addAll(vm.config.customPortForwards!);
    }

    final forwards = {...vm.config.getDefaultPortForwards(), ...customForwards};

    final forwardRules = forwards.entries.map((e) => 'hostfwd=tcp:127.0.0.1:${e.value}-:${e.key}').join(',');

    args.addAll([
      '-netdev',
      'user,id=net0,$forwardRules',
      '-device',
      'virtio-net-pci,netdev=net0',
    ]);
  }

  void _addSpiceArgs(List<String> args, VmInstance vm) {
    final spicePort = _defaultSpicePort;
    final wsPort = _defaultSpiceWebSocketPort;

    final gpuDevice = (capabilities.hasVirgl)
        ? 'virtio-gpu-pci,virgl=on'
        : 'virtio-gpu-pci';

    args.addAll([
      '-spice',
      'port=$spicePort,addr=127.0.0.1,disable-ticketing=on,image-compression=off,websocket=$wsPort',
      '-device',
      gpuDevice,
      '-device',
      'virtio-serial-pci',
      '-chardev',
      'spicevmc,id=spicevdagent,name=vdagent',
      '-device',
      'virtserialport,chardev=spicevdagent,name=com.redhat.spice.0',
    ]);
  }

  void _addVncArgs(List<String> args) {
    final vncPort = _defaultChromeOSVncPort;
    final wsPort = _defaultSpiceWebSocketPort;
    args.addAll(['-vnc', '127.0.0.1:$vncPort,websocket=$wsPort']);
  }

  void _addGuestAgentArgs(List<String> args, VmInstance vm) {
    final gaSocketPath = p.join(p.dirname(vm.overlayPath), 'guest-agent.sock');

    if (vm.config.graphics != GraphicsBackend.spice) {
      args.addAll(['-device', 'virtio-serial-pci']);
    }

    args.addAll([
      '-chardev',
      'socket,id=ga0,path=$gaSocketPath,server=on,wait=off',
      '-device',
      'virtserialport,chardev=ga0,name=org.qemu.guest_agent.0',
    ]);
  }

  void _addSharedFolderArgs(List<String> args, VmInstance vm) {
    if (!capabilities.hasKvm || !capabilities.virtiofsSupported) return;

    final sharedPath = vm.config.sharedFolderPath;

    if (sharedPath == null || sharedPath.isEmpty) return;

    if (vm.config.sharedFolderBackend == SharedFolderBackend.virtiofs) {
      args.addAll([
        '-fsdev',
        'local,id=fsdev0,path=$sharedPath,security_model=mapped-xattr,readonly=off',
        '-device',
        'virtio-fs-pci,fsdev=fsdev0,mount_tag=host_shared,queue-size=1024',
      ]);
    }
  }

  void _addOtherArgs(List<String> args) {
    args.addAll(['-nographic']);
    args.addAll(['-serial', 'mon:stdio']);
  }

  String buildLogPath(String vmId) {
    return p.join(_vmDirectory(vmId), 'logs', 'qemu.log');
  }

  static String _vmDirectory(String vmId) {
    return p.join(_homeDirectory(), '.lwvm', 'vms', vmId);
  }

  static String _homeDirectory() {
    final envHome = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    return envHome.isEmpty ? '.' : envHome;
  }
}