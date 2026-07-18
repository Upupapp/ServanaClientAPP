// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_option_items.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoreOptionItemImpl _$$StoreOptionItemImplFromJson(
        Map<String, dynamic> json) =>
    _$StoreOptionItemImpl(
      merchantOptionItemID:
          (json['merchantOptionItemID'] as num?)?.toInt() ?? 0,
      merchantOptionID: (json['merchantOptionID'] as num?)?.toInt() ?? 0,
      merchantServiceID: json['merchantServiceID'] as String? ?? "0",
      merchantOptionItemName: json['merchantOptionItemName'] as String,
      amount: (json['amount'] as num).toDouble(),
      ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
      baseFair: (json['baseFair'] as num).toDouble(),
    );

Map<String, dynamic> _$$StoreOptionItemImplToJson(
        _$StoreOptionItemImpl instance) =>
    <String, dynamic>{
      'merchantOptionItemID': instance.merchantOptionItemID,
      'merchantOptionID': instance.merchantOptionID,
      'merchantServiceID': instance.merchantServiceID,
      'merchantOptionItemName': instance.merchantOptionItemName,
      'amount': instance.amount,
      'ordinal': instance.ordinal,
      'baseFair': instance.baseFair,
    };
