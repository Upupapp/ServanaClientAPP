// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_light.freezed.dart';
part 'merchant_light.g.dart';

@freezed
class MerchantLight with _$MerchantLight {
  const factory MerchantLight({
    required String merchantID,
    required String merchantName,
    @Default(0) int merchantStatus,
    @Default("Unknown") String merchantStatusToString,
    @Default("Unknown") String city,
    @Default(0) double longitude,
    @Default(0) double latitude,
    @Default(0) int rating,
    String? listImage,
    required List<int> discounts,
  }) = _MerchantLight;

  factory MerchantLight.fromJson(Map<String, dynamic> json) =>
      _$MerchantLightFromJson(json);
}
