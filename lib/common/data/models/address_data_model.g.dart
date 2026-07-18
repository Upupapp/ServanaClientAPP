// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AddressDataModelImpl _$$AddressDataModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AddressDataModelImpl(
      city: json['city'] as String?,
      province: json['province'] as String?,
      barangay: json['barangay'] as String?,
      country: json['country'] as String?,
      streetAddress: json['streetAddress'] as String?,
      postalCode: json['postalCode'] as String?,
      locationCoordinates: json['locationCoordinates'] == null
          ? null
          : LocationCoordinatesModel.fromJson(
              json['locationCoordinates'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AddressDataModelImplToJson(
        _$AddressDataModelImpl instance) =>
    <String, dynamic>{
      'city': instance.city,
      'province': instance.province,
      'barangay': instance.barangay,
      'country': instance.country,
      'streetAddress': instance.streetAddress,
      'postalCode': instance.postalCode,
      'locationCoordinates': instance.locationCoordinates,
    };
