import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest_os_image.freezed.dart';
part 'guest_os_image.g.dart';

@freezed
class GuestOSImage with _$GuestOSImage {
  const factory GuestOSImage({
    required String id,
    required String name,
    required String arch,
    required String url,
    required String sha256,
    @Default(0) int size,
    @Default('') String version,
    @Default(false) bool isCached,
  }) = _GuestOSImage;

  factory GuestOSImage.fromJson(Map<String, dynamic> json) =>
      _$GuestOSImageFromJson(json);
}