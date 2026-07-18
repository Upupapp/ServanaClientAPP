// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'province.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProvinceModelImpl _$$ProvinceModelImplFromJson(Map<String, dynamic> json) =>
    _$ProvinceModelImpl(
      code: json['province_code'] as String,
      name: json['province_name'] as String,
      psgc: json['psgc_code'] as String,
      regionCode: json['region_code'] as String,
    );

Map<String, dynamic> _$$ProvinceModelImplToJson(_$ProvinceModelImpl instance) =>
    <String, dynamic>{
      'province_code': instance.code,
      'province_name': instance.name,
      'psgc_code': instance.psgc,
      'region_code': instance.regionCode,
    };
