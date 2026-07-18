import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_service_light.freezed.dart';
part 'merchant_service_light.g.dart';

@freezed
class MerchantServiceLight with _$MerchantServiceLight {
  const factory MerchantServiceLight({
    String? merchantCategoryName,
    int? merchantCategoryID,
    int? categoryOrdinal,
    required int merchantServiceID,
    required String merchantServiceName,
    required String merchantServiceDescription,
    @Default('') String merchantServicePictureURL,
    required int serviceOrdinal,
    required int amount,
    required String recommendation,
    required bool isActive,
  }) = _MerchantServiceLight;

  factory MerchantServiceLight.fromJson(Map<String, dynamic> json) =>
      _$MerchantServiceLightFromJson(json);
}
