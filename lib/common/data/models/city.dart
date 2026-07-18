// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'city.freezed.dart';
part 'city.g.dart';

@Freezed(fromJson: true, toJson: true)
class CityModel with _$CityModel {
  const factory CityModel({
    @JsonKey(name: 'city_code') required final String code,
    @JsonKey(name: 'city_name') required final String name,
    @JsonKey(name: 'province_code') required final String provinceCode,
    @JsonKey(name: 'psgc_code') required final String psgc,
    @JsonKey(name: 'region_desc') required final String region,
  }) = _CityModel;

  factory CityModel.fromJson(Map<String, dynamic> json) =>
      _$CityModelFromJson(json);
}
