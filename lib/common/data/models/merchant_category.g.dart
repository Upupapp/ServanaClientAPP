// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MerchantCategoryImpl _$$MerchantCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$MerchantCategoryImpl(
      merchantCategoryID: (json['merchantCategoryID'] as num).toInt(),
      merchantID: json['merchantID'] as String,
      serviceID: (json['serviceID'] as num).toInt(),
      merchantCategoryName: json['merchantCategoryName'] as String,
      ordinal: (json['ordinal'] as num).toInt(),
      createdDate: DateTime.parse(json['createdDate'] as String),
    );

Map<String, dynamic> _$$MerchantCategoryImplToJson(
        _$MerchantCategoryImpl instance) =>
    <String, dynamic>{
      'merchantCategoryID': instance.merchantCategoryID,
      'merchantID': instance.merchantID,
      'serviceID': instance.serviceID,
      'merchantCategoryName': instance.merchantCategoryName,
      'ordinal': instance.ordinal,
      'createdDate': instance.createdDate.toIso8601String(),
    };
