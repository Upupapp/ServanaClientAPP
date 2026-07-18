// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'barangay.freezed.dart';
part 'barangay.g.dart';

@Freezed(fromJson: true, toJson: true)
class BarangayModel with _$BarangayModel {
  const factory BarangayModel({
    @JsonKey(name: 'brgy_code') required final String code,
    @JsonKey(name: 'brgy_name') required final String name,
    @JsonKey(name: 'province_code') required final String provinceCode,
    @JsonKey(name: 'city_code') required final String cityCode,
    @JsonKey(name: 'region_code') required final String regionCode,
  }) = _BarangayModel;

  factory BarangayModel.fromJson(Map<String, dynamic> json) =>
      _$BarangayModelFromJson(json);
}
