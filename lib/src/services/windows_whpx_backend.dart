import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/vm_config.dart';
import '../models/vm_instance.dart';

class WindowsWhpxBackend {
  static const String _virtioIsoPath = 'assets/virtio/virtio-win.iso';

  static List<String> buildWhpxOptimizedArgs({
    required VmInstance vm,
    required String qemuPath,
    String? virtioIsoPath,
  }) {
    final args = <String>[
      '-machine', 'q35,accel=whpx',
      '-cpu', 'host',
      '-m', '${vm.config.ram}M',
      '-smp', '${vm.config.cpus}',
      '-drive', 'file=${vm.overlayPath},if=virtio,format=qcow2,id=drive0',
      '-netdev', 'user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:8080-:80',
      '-device', 'virtio-net-pci,netdev=net0',
      '-device', 'virtio-gpu-pci',
      '-device', 'virtio-serial-pci',
      '-chardev', 'socket,id=ga0,path=${p.join(p.dirname(vm.overlayPath), 'guest-agent.sock')},server=on,wait=off',
      '-device', 'virtserialport,chardev=ga0,name=org.qemu.guest_agent.0',
      '-nographic',
      '-serial', 'mon:stdio',
    ];

    if (virtioIsoPath != null) {
      args.addAll([
        '-drive', 'file=$virtioIsoPath,media=cdrom,index=1',
      ]);
    }

    return args;
  }

  static Future<bool> checkWhpxAvailability() async {
    if (!Platform.isWindows) return false;
    
    try {
      final result = await Process.run('powershell', [
        '-Command',
        'Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Hyper-V-Hypervisor -ErrorAction SilentlyContinue | Select-Object -ExpandProperty State',
      ]);
      return result.exitCode == 0 && result.stdout.toString().trim() == 'Enabled';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkEnhancedSessionMode() async {
    if (!Platform.isWindows) return false;
    
    try {
      final result = await Process.run('powershell', [
        '-Command',
        'Get-VMHost | Select-Object -ExpandProperty EnableEnhancedSessionMode',
      ]);
      return result.exitCode == 0 && result.stdout.toString().trim() == 'True';
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> getEnhancedSessionConfig() {
    return {
      'transportType': 'EnhancedSessionTransportType',
      'supportsClipboard': true,
      'supportsFileTransfer': true,
      'supportsDynamicResize': true,
    };
  }

  static String getWhpxInstallInstructions() {
    return '''
To enable WHPX on Windows 10/11 Pro/Enterprise:
1. Open PowerShell as Administrator
2. Run: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Hyper-V-Hypervisor -All
3. Reboot when prompted
4. Verify with: Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Hyper-V-Hypervisor

For optimal performance, also enable:
- Hyper-V Services
- Virtual Machine Platform
- Windows Hypervisor Platform
''';
  }
}