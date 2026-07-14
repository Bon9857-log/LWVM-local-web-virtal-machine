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
      _addSpiceArgs(args);
    } else {
      _addVncArgs(args);
    }
    _addGuestAgentArgs(args, vm);
  }

  void _addAccelerationArgs(List<String> args, VmInstance vm) {
    if (capabilities.isChromeOS) {
      args.addAll(['-accel', 'tcg,thread=multi']);
    } else if (capabilities.hasKvm) {
      args.addAll(['-accel', 'kvm', '-cpu', 'host']);
    } else if (capabilities.hasHyperV) {
      args.addAll(['-accel', 'whpx', '-cpu', 'host']);
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

    args.addAll(['-m', '${ram}M']);
    args.addAll(['-smp', '$cpus']);
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

  void _addSpiceArgs(List<String> args) {
    final spicePort = _defaultSpicePort;
    final wsPort = _defaultSpiceWebSocketPort;

    args.addAll([
      '-spice',
      'port=$spicePort,addr=127.0.0.1,disable-ticketing=on,image-compression=off,websocket=$wsPort',
      '-device',
      'virtio-gpu-pci',
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