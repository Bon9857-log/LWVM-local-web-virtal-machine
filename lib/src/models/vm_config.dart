enum GuestOS { alpine, ubuntu, zorin }
enum GraphicsBackend { spice, vnc }
enum SharedFolderBackend { webdav, virtiofs }

class VmConfig {
  final int cpus;
  final int ram;
  final int diskSize;
  final GuestOS guestOS;
  final GraphicsBackend graphics;
  final SharedFolderBackend sharedFolderBackend;
  final String? sshPort;
  final String? webPort;
  final String? httpsPort;
  final String? rdpPort;
  final Map<int, int>? customPortForwards;
  final String? sharedFolderPath;
  final String? sharedFolderMountPoint;

  const VmConfig({
    this.cpus = 2,
    this.ram = 2048,
    this.diskSize = 20,
    this.guestOS = GuestOS.alpine,
    this.graphics = GraphicsBackend.spice,
    this.sharedFolderBackend = SharedFolderBackend.webdav,
    this.sshPort,
    this.webPort,
    this.httpsPort,
    this.rdpPort,
    this.customPortForwards,
    this.sharedFolderPath,
    this.sharedFolderMountPoint,
  });

  factory VmConfig.fromJson(Map<String, dynamic> json) {
    return VmConfig(
      cpus: json['cpus'] as int? ?? 2,
      ram: json['ram'] as int? ?? 2048,
      diskSize: json['diskSize'] as int? ?? 20,
      guestOS: _guestOSFromJson(json['guestOS'] as String? ?? 'alpine'),
      graphics: _graphicsBackendFromJson(json['graphics'] as String? ?? 'spice'),
      sharedFolderBackend: _sharedFolderBackendFromJson(json['sharedFolderBackend'] as String? ?? 'webdav'),
      sshPort: json['sshPort'] as String?,
      webPort: json['webPort'] as String?,
      httpsPort: json['httpsPort'] as String?,
      rdpPort: json['rdpPort'] as String?,
      customPortForwards: (json['customPortForwards'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
      sharedFolderPath: json['sharedFolderPath'] as String?,
      sharedFolderMountPoint: json['sharedFolderMountPoint'] as String?,
    );
  }

  Map<int, int> getAllPortForwards() {
    final forwards = <int, int>{
      if (sshPort != null) 22: int.parse(sshPort!),
      if (webPort != null) 80: int.parse(webPort!),
      if (httpsPort != null) 443: int.parse(httpsPort!),
      if (rdpPort != null) 3389: int.parse(rdpPort!),
    };
    if (customPortForwards != null) {
      forwards.addAll(customPortForwards!);
    }
    return forwards;
  }

  Map<int, int> getDefaultPortForwards() {
    return const <int, int>{
      22: 2222,
      80: 8080,
      443: 8443,
      3389: 3389,
    };
  }
}

GuestOS _guestOSFromJson(String value) {
  switch (value) {
    case 'alpine': return GuestOS.alpine;
    case 'ubuntu': return GuestOS.ubuntu;
    case 'zorin': return GuestOS.zorin;
    default: return GuestOS.alpine;
  }
}

GraphicsBackend _graphicsBackendFromJson(String value) {
  switch (value) {
    case 'spice': return GraphicsBackend.spice;
    case 'vnc': return GraphicsBackend.vnc;
    default: return GraphicsBackend.spice;
  }
}

SharedFolderBackend _sharedFolderBackendFromJson(String value) {
  switch (value) {
    case 'webdav': return SharedFolderBackend.webdav;
    case 'virtiofs': return SharedFolderBackend.virtiofs;
    default: return SharedFolderBackend.webdav;
  }
}