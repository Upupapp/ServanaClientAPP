// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CityModelImpl _$$CityModelImplFromJson(Map<String, dynamic> json) =>
    _$CityModelImpl(
      code: json['city_code'] as String,
      name: json['city_name'] as String,
      provinceCode: json['province_code'] as String,
      psgc: json['psgc_code'] as String,
      region: json['region_desc'] as String,
    );

Map<String, dynamic> _$$CityModelImplToJson(_$CityModelImpl instance) =>
    <String, dynamic>{
      'city_code': instance.code,
      'city_name': instance.name,
      'province_code': instance.provinceCode,
      'psgc_code': instance.psgc,
      'region_desc': instance.region,
    };
