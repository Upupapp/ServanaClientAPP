// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barangay.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BarangayModelImpl _$$BarangayModelImplFromJson(Map<String, dynamic> json) =>
    _$BarangayModelImpl(
      code: json['brgy_code'] as String,
      name: json['brgy_name'] as String,
      provinceCode: json['province_code'] as String,
      cityCode: json['city_code'] as String,
      regionCode: json['region_code'] as String,
    );

Map<String, dynamic> _$$BarangayModelImplToJson(_$BarangayModelImpl instance) =>
    <String, dynamic>{
      'brgy_code': instance.code,
      'brgy_name': instance.name,
      'province_code': instance.provinceCode,
      'city_code': instance.cityCode,
      'region_code': instance.regionCode,
    };
