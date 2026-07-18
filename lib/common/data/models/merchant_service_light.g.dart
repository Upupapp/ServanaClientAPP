// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_service_light.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MerchantServiceLightImpl _$$MerchantServiceLightImplFromJson(
        Map<String, dynamic> json) =>
    _$MerchantServiceLightImpl(
      merchantCategoryName: json['merchantCategoryName'] as String?,
      merchantCategoryID: (json['merchantCategoryID'] as num?)?.toInt(),
      categoryOrdinal: (json['categoryOrdinal'] as num?)?.toInt(),
      merchantServiceID: (json['merchantServiceID'] as num).toInt(),
      merchantServiceName: json['merchantServiceName'] as String,
      merchantServiceDescription: json['merchantServiceDescription'] as String,
      merchantServicePictureURL:
          json['merchantServicePictureURL'] as String? ?? '',
      serviceOrdinal: (json['serviceOrdinal'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
      recommendation: json['recommendation'] as String,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$$MerchantServiceLightImplToJson(
        _$MerchantServiceLightImpl instance) =>
    <String, dynamic>{
      'merchantCategoryName': instance.merchantCategoryName,
      'merchantCategoryID': instance.merchantCategoryID,
      'categoryOrdinal': instance.categoryOrdinal,
      'merchantServiceID': instance.merchantServiceID,
      'merchantServiceName': instance.merchantServiceName,
      'merchantServiceDescription': instance.merchantServiceDescription,
      'merchantServicePictureURL': instance.merchantServicePictureURL,
      'serviceOrdinal': instance.serviceOrdinal,
      'amount': instance.amount,
      'recommendation': instance.recommendation,
      'isActive': instance.isActive,
    };
