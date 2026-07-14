import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest_os_image.freezed.dart';
part 'guest_os_image.g.dart';

enum CpuArch { x86_64, aarch64 }

@freezed
class GuestOSImage with _$GuestOSImage {
  const factory GuestOSImage({
    required String id,
    required String name,
    required CpuArch arch,
    required String url,
    required String sha256,
    @Default(0) int size,
    String? version,
  }) = _GuestOSImage;

  factory GuestOSImage.fromJson(Map<String, dynamic> json) =>
      _$GuestOSImageFromJson(json);
}