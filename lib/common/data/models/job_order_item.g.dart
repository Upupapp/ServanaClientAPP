// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobOrderItemImpl _$$JobOrderItemImplFromJson(Map<String, dynamic> json) =>
    _$JobOrderItemImpl(
      jobOrderItemID: (json['jobOrderItemID'] as num).toInt(),
      serviceId: json['serviceId'] as String?,
      serviceName: json['serviceName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      note: json['note'] as String?,
      amount: (json['amount'] as num).toDouble(),
      transportaion: (json['transportaion'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num).toDouble(),
      selectedOptions: (json['selectedOptions'] as List<dynamic>)
          .map((e) => SelectedOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$JobOrderItemImplToJson(_$JobOrderItemImpl instance) =>
    <String, dynamic>{
      'jobOrderItemID': instance.jobOrderItemID,
      'serviceId': instance.serviceId,
      'serviceName': instance.serviceName,
      'quantity': instance.quantity,
      'note': instance.note,
      'amount': instance.amount,
      'transportaion': instance.transportaion,
      'discount': instance.discount,
      'selectedOptions': instance.selectedOptions,
    };

_$SelectedOptionImpl _$$SelectedOptionImplFromJson(Map<String, dynamic> json) =>
    _$SelectedOptionImpl(
      jobOrderOptionItemID: (json['jobOrderOptionItemID'] as num).toInt(),
      merchantOptionItemID:
          (json['merchantOptionItemID'] as num?)?.toInt() ?? 0,
      merchantServiceID: (json['merchantServiceID'] as num).toInt(),
      optionAmount: (json['optionAmount'] as num?)?.toDouble() ?? 0,
      transportaion: (json['transportaion'] as num?)?.toDouble() ?? 0,
      merchantOptionItemName: json['merchantOptionItemName'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$$SelectedOptionImplToJson(
        _$SelectedOptionImpl instance) =>
    <String, dynamic>{
      'jobOrderOptionItemID': instance.jobOrderOptionItemID,
      'merchantOptionItemID': instance.merchantOptionItemID,
      'merchantServiceID': instance.merchantServiceID,
      'optionAmount': instance.optionAmount,
      'transportaion': instance.transportaion,
      'merchantOptionItemName': instance.merchantOptionItemName,
      'quantity': instance.quantity,
    };
