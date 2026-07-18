import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'location_coordinates_model.freezed.dart';
part 'location_coordinates_model.g.dart';

@HiveType(typeId: 7)
@Freezed(fromJson: true, toJson: true)
class LocationCoordinatesModel with _$LocationCoordinatesModel {
  const factory LocationCoordinatesModel({
    @HiveField(71) required final double latitude,
    @HiveField(72) required final double longhitude,
  }) = _LocationCoordinatesModel;

  factory LocationCoordinatesModel.fromJson(Map<String, dynamic> json) =>
      _$LocationCoordinatesModelFromJson(json);
}
