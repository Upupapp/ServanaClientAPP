import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_address_model.freezed.dart';
part 'user_address_model.g.dart';

@Freezed(fromJson: true, toJson: true)
class UserAddressModel with _$UserAddressModel {
  const factory UserAddressModel({
    required String userId,
    @Default('') String locationId,
    required String addressOne,
    String? addressTwo,
    @Default('') String zipCode,
    @Default('') String postTown,
    @Default('Philippines') String country,
    required double lat,
    required double lon,
    @Default('') String label,
    @Default(false) bool isPrimary,
  }) = _UserAddressModel;

  factory UserAddressModel.fromJson(Map<String, dynamic> json) =>
      _$UserAddressModelFromJson(json);
}
