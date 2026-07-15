class GuestOSImage {
  final String id;
  final String name;
  final String arch;
  final String url;
  final String sha256;
  final int size;
  final String version;
  final bool isCached;

  const GuestOSImage({
    required this.id,
    required this.name,
    required this.arch,
    required this.url,
    required this.sha256,
    this.size = 0,
    this.version = '',
    this.isCached = false,
  });

  factory GuestOSImage.fromJson(Map<String, dynamic> json) {
    return GuestOSImage(
      id: json['id'] as String,
      name: json['name'] as String,
      arch: json['arch'] as String,
      url: json['url'] as String,
      sha256: json['sha256'] as String,
      size: json['size'] as int? ?? 0,
      version: json['version'] as String? ?? '',
      isCached: json['isCached'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arch': arch,
      'url': url,
      'sha256': sha256,
      'size': size,
      'version': version,
      'isCached': isCached,
    };
  }
}