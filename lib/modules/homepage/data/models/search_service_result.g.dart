// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_service_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchServiceResultImpl _$$SearchServiceResultImplFromJson(
        Map<String, dynamic> json) =>
    _$SearchServiceResultImpl(
      merchantID: json['merchantID'] as String,
      merchantName: json['merchantName'] as String,
      merchantStatus: (json['merchantStatus'] as num).toInt(),
      merchantStatusToString: json['merchantStatusToString'] as String,
      city: json['city'] as String,
      barangay: json['barangay'] as String,
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      rating: (json['rating'] as num).toInt(),
      listImage: json['listImage'] as String,
      merchantServiceID: (json['merchantServiceID'] as num).toInt(),
      merchantServiceName: json['merchantServiceName'] as String,
      amount: (json['amount'] as num).toDouble(),
      merchantServicePictureURL: json['merchantServicePictureURL'] as String,
      discounts: (json['discounts'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$$SearchServiceResultImplToJson(
        _$SearchServiceResultImpl instance) =>
    <String, dynamic>{
      'merchantID': instance.merchantID,
      'merchantName': instance.merchantName,
      'merchantStatus': instance.merchantStatus,
      'merchantStatusToString': instance.merchantStatusToString,
      'city': instance.city,
      'barangay': instance.barangay,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'rating': instance.rating,
      'listImage': instance.listImage,
      'merchantServiceID': instance.merchantServiceID,
      'merchantServiceName': instance.merchantServiceName,
      'amount': instance.amount,
      'merchantServicePictureURL': instance.merchantServicePictureURL,
      'discounts': instance.discounts,
    };
