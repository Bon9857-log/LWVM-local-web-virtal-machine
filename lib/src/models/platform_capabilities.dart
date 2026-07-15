class PlatformCapabilities {
  final bool hasKvm;
  final bool hasHyperV;
  final bool hasVirtFramework;
  final bool isChromeOS;
  final String nativeArch;
  final bool hasTCG;
  final bool hasHugePages;
  final bool hasVirgl;
  final bool virtiofsSupported;

  const PlatformCapabilities({
    required this.hasKvm,
    required this.hasHyperV,
    required this.hasVirtFramework,
    required this.isChromeOS,
    required this.nativeArch,
    this.hasTCG = false,
    this.hasHugePages = false,
    this.hasVirgl = false,
    this.virtiofsSupported = false,
  });

  factory PlatformCapabilities.fromJson(Map<String, dynamic> json) {
    return PlatformCapabilities(
      hasKvm: json['hasKvm'] as bool? ?? false,
      hasHyperV: json['hasHyperV'] as bool? ?? false,
      hasVirtFramework: json['hasVirtFramework'] as bool? ?? false,
      isChromeOS: json['isChromeOS'] as bool? ?? false,
      nativeArch: json['nativeArch'] as String? ?? 'unknown',
      hasTCG: json['hasTCG'] as bool? ?? false,
      hasHugePages: json['hasHugePages'] as bool? ?? false,
      hasVirgl: json['hasVirgl'] as bool? ?? false,
      virtiofsSupported: json['virtiofsSupported'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasKvm': hasKvm,
      'hasHyperV': hasHyperV,
      'hasVirtFramework': hasVirtFramework,
      'isChromeOS': isChromeOS,
      'nativeArch': nativeArch,
      'hasTCG': hasTCG,
      'hasHugePages': hasHugePages,
      'hasVirgl': hasVirgl,
      'virtiofsSupported': virtiofsSupported,
    };
  }
}