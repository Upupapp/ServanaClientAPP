import 'package:client/common/data/models/location_coordinates_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_data_model.freezed.dart';
part 'address_data_model.g.dart';

@Freezed(fromJson: true, toJson: true)
class AddressDataModel with _$AddressDataModel {
  const factory AddressDataModel({
    final String? city,
    final String? province,
    final String? barangay,
    final String? country,
    final String? streetAddress,
    final String? postalCode,
    final LocationCoordinatesModel? locationCoordinates,
  }) = _AddressDataModel;

  factory AddressDataModel.fromJson(Map<String, dynamic> json) =>
      _$AddressDataModelFromJson(json);
}
