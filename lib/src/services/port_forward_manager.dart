import '../models/vm_config.dart';

class PortForwardManager {
  static const int defaultSshPort = 2222;
  static const int defaultWebPort = 8080;
  static const int defaultHttpsPort = 8443;
  static const int defaultRdpPort = 3389;

  static final Map<int, int> defaultForwards = {
    22: defaultSshPort,
    80: defaultWebPort,
    443: defaultHttpsPort,
    3389: defaultRdpPort,
  };

  List<String> buildNetdevArgs(VmConfig config) {
    final forwards = <int, int>{};

    if (config.sshPort != null) {
      forwards[22] = int.parse(config.sshPort!);
    }
    if (config.webPort != null) {
      forwards[80] = int.parse(config.webPort!);
    }
    if (config.httpsPort != null) {
      forwards[443] = int.parse(config.httpsPort!);
    }
    if (config.rdpPort != null) {
      forwards[3389] = int.parse(config.rdpPort!);
    }
    if (config.customPortForwards != null) {
      forwards.addAll(config.customPortForwards!);
    }

    if (forwards.isEmpty) {
      return ['-netdev', 'user,id=net0', '-device', 'virtio-net-pci,netdev=net0'];
    }

    final forwardRules = forwards.entries
        .map((e) => 'hostfwd=tcp:127.0.0.1:${e.value}-:${e.key}')
        .join(',');

    return [
      '-netdev',
      'user,id=net0,$forwardRules',
      '-device',
      'virtio-net-pci,netdev=net0',
    ];
  }

  Map<int, int> getAllForwards(VmConfig config) {
    final result = <int, int>{};

    if (config.sshPort != null) {
      result[22] = int.parse(config.sshPort!);
    }
    if (config.webPort != null) {
      result[80] = int.parse(config.webPort!);
    }
    if (config.httpsPort != null) {
      result[443] = int.parse(config.httpsPort!);
    }
    if (config.rdpPort != null) {
      result[3389] = int.parse(config.rdpPort!);
    }
    if (config.customPortForwards != null) {
      result.addAll(config.customPortForwards!);
    }

    return result;
  }
}