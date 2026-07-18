// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_service_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MerchantServiceOptionModelImpl _$$MerchantServiceOptionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$MerchantServiceOptionModelImpl(
      merchantOptionID: (json['merchantOptionID'] as num).toInt(),
      merchantID: json['merchantID'] as String,
      merchantServiceID: (json['merchantServiceID'] as num).toInt(),
      merchantOptionName: json['merchantOptionName'] as String,
      isRequired: json['isRequired'] as bool,
      minimumOption: (json['minimumOption'] as num).toInt(),
      maximumOption: (json['maximumOption'] as num).toInt(),
      ordinal: (json['ordinal'] as num).toInt(),
      createdDate: DateTime.parse(json['createdDate'] as String),
      optionItems: (json['optionItems'] as List<dynamic>)
          .map((e) => StoreOptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MerchantServiceOptionModelImplToJson(
        _$MerchantServiceOptionModelImpl instance) =>
    <String, dynamic>{
      'merchantOptionID': instance.merchantOptionID,
      'merchantID': instance.merchantID,
      'merchantServiceID': instance.merchantServiceID,
      'merchantOptionName': instance.merchantOptionName,
      'isRequired': instance.isRequired,
      'minimumOption': instance.minimumOption,
      'maximumOption': instance.maximumOption,
      'ordinal': instance.ordinal,
      'createdDate': instance.createdDate.toIso8601String(),
      'optionItems': instance.optionItems,
    };
