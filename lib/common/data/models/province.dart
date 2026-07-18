// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'province.freezed.dart';
part 'province.g.dart';

@Freezed(fromJson: true, toJson: true)
class ProvinceModel with _$ProvinceModel {
  const factory ProvinceModel({
    @JsonKey(name: 'province_code') required final String code,
    @JsonKey(name: 'province_name') required final String name,
    @JsonKey(name: 'psgc_code') required final String psgc,
    @JsonKey(name: 'region_code') required final String regionCode,
  }) = _ProvinceModel;

  factory ProvinceModel.fromJson(Map<String, dynamic> json) =>
      _$ProvinceModelFromJson(json);
}
