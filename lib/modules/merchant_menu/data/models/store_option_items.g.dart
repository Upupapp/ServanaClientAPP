// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_option_items.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoreOptionItemImpl _$$StoreOptionItemImplFromJson(
        Map<String, dynamic> json) =>
    _$StoreOptionItemImpl(
      id: (json['id'] as num).toInt(),
      serviceId: (json['serviceId'] as num?)?.toInt(),
      serviceOptionGroupId: (json['serviceOptionGroupId'] as num?)?.toInt(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      transportation: (json['transportation'] as num).toDouble(),
      addedByMerchant: json['addedByMerchant'] as bool? ?? false,
    );

Map<String, dynamic> _$$StoreOptionItemImplToJson(
        _$StoreOptionItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceId': instance.serviceId,
      'serviceOptionGroupId': instance.serviceOptionGroupId,
      'name': instance.name,
      'price': instance.price,
      'transportation': instance.transportation,
      'addedByMerchant': instance.addedByMerchant,
    };
