// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_light.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MerchantLightImpl _$$MerchantLightImplFromJson(Map<String, dynamic> json) =>
    _$MerchantLightImpl(
      merchantID: json['merchantID'] as String,
      merchantName: json['merchantName'] as String,
      merchantStatus: (json['merchantStatus'] as num?)?.toInt() ?? 0,
      merchantStatusToString:
          json['merchantStatusToString'] as String? ?? "Unknown",
      city: json['city'] as String? ?? "Unknown",
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      listImage: json['listImage'] as String?,
      discounts: (json['discounts'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$MerchantLightImplToJson(_$MerchantLightImpl instance) =>
    <String, dynamic>{
      'merchantID': instance.merchantID,
      'merchantName': instance.merchantName,
      'merchantStatus': instance.merchantStatus,
      'merchantStatusToString': instance.merchantStatusToString,
      'city': instance.city,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'rating': instance.rating,
      'listImage': instance.listImage,
      'discounts': instance.discounts,
    };
