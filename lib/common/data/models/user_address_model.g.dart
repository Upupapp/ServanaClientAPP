// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_address_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserAddressModelImpl _$$UserAddressModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserAddressModelImpl(
      userId: json['userId'] as String,
      locationId: json['locationId'] as String? ?? '',
      addressOne: json['addressOne'] as String,
      addressTwo: json['addressTwo'] as String?,
      zipCode: json['zipCode'] as String? ?? '',
      postTown: json['postTown'] as String? ?? '',
      country: json['country'] as String? ?? 'Philippines',
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      label: json['label'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserAddressModelImplToJson(
        _$UserAddressModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'locationId': instance.locationId,
      'addressOne': instance.addressOne,
      'addressTwo': instance.addressTwo,
      'zipCode': instance.zipCode,
      'postTown': instance.postTown,
      'country': instance.country,
      'lat': instance.lat,
      'lon': instance.lon,
      'label': instance.label,
      'isPrimary': instance.isPrimary,
    };
