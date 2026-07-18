// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MerchantServiceModelImpl _$$MerchantServiceModelImplFromJson(
        Map<String, dynamic> json) =>
    _$MerchantServiceModelImpl(
      merchantServiceID: (json['merchantServiceID'] as num?)?.toInt() ?? 0,
      merchantCategoryID: (json['merchantCategoryID'] as num?)?.toInt() ?? 0,
      merchantSubcategoryID:
          (json['merchantSubcategoryID'] as num?)?.toInt() ?? 0,
      merchantServiceName: json['merchantServiceName'] as String? ?? '',
      merchantServiceDescription:
          json['merchantServiceDescription'] as String? ?? "No description",
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
      merchantServiceBillingType:
          (json['merchantServiceBillingType'] as num?)?.toInt() ?? 0,
      recommendation: json['recommendation'] as String? ?? '',
      inclusion: json['inclusion'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      noteToCustomer: json['noteToCustomer'] as String?,
      baseFair: (json['baseFair'] as num?)?.toInt() ?? 0,
      freeDistanceTransportationFee:
          (json['freeDistanceTransportationFee'] as num?)?.toInt() ?? 0,
      perKilometerFee: (json['perKilometerFee'] as num?)?.toInt() ?? 0,
      effectiveBeyondKilometer:
          (json['effectiveBeyondKilometer'] as num?)?.toInt() ?? 0,
      merchantServicePictureURL:
          json['merchantServicePictureURL'] as String? ?? '',
      merchantServicePictureURLBase64:
          json['merchantServicePictureURLBase64'] as String?,
      merchantCategoryName: json['merchantCategoryName'] as String?,
      merchantSubcategoryName: json['merchantSubcategoryName'] as String?,
      createdDate: json['createdDate'] == null
          ? null
          : DateTime.parse(json['createdDate'] as String),
      selectionOptions: (json['selectionOptions'] as List<dynamic>?)
              ?.map((e) => SelectionOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MerchantServiceModelImplToJson(
        _$MerchantServiceModelImpl instance) =>
    <String, dynamic>{
      'merchantServiceID': instance.merchantServiceID,
      'merchantCategoryID': instance.merchantCategoryID,
      'merchantSubcategoryID': instance.merchantSubcategoryID,
      'merchantServiceName': instance.merchantServiceName,
      'merchantServiceDescription': instance.merchantServiceDescription,
      'amount': instance.amount,
      'ordinal': instance.ordinal,
      'merchantServiceBillingType': instance.merchantServiceBillingType,
      'recommendation': instance.recommendation,
      'inclusion': instance.inclusion,
      'isActive': instance.isActive,
      'noteToCustomer': instance.noteToCustomer,
      'baseFair': instance.baseFair,
      'freeDistanceTransportationFee': instance.freeDistanceTransportationFee,
      'perKilometerFee': instance.perKilometerFee,
      'effectiveBeyondKilometer': instance.effectiveBeyondKilometer,
      'merchantServicePictureURL': instance.merchantServicePictureURL,
      'merchantServicePictureURLBase64':
          instance.merchantServicePictureURLBase64,
      'merchantCategoryName': instance.merchantCategoryName,
      'merchantSubcategoryName': instance.merchantSubcategoryName,
      'createdDate': instance.createdDate?.toIso8601String(),
      'selectionOptions': instance.selectionOptions,
    };

_$SelectionOptionImpl _$$SelectionOptionImplFromJson(
        Map<String, dynamic> json) =>
    _$SelectionOptionImpl(
      merchantServiceModelOptionID:
          (json['merchantServiceModelOptionID'] as num?)?.toInt(),
      merchantOptionID: (json['merchantOptionID'] as num).toInt(),
      merchantOptionName: json['merchantOptionName'] as String,
      isRequired: json['isRequired'] as bool,
      minimumOption: (json['minimumOption'] as num).toInt(),
      maximumOption: (json['maximumOption'] as num).toInt(),
      ordinal: (json['ordinal'] as num).toInt(),
      selectedOptionItems: (json['selectedOptionItems'] as List<dynamic>)
          .map((e) => SelectionOptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$SelectionOptionImplToJson(
        _$SelectionOptionImpl instance) =>
    <String, dynamic>{
      'merchantServiceModelOptionID': instance.merchantServiceModelOptionID,
      'merchantOptionID': instance.merchantOptionID,
      'merchantOptionName': instance.merchantOptionName,
      'isRequired': instance.isRequired,
      'minimumOption': instance.minimumOption,
      'maximumOption': instance.maximumOption,
      'ordinal': instance.ordinal,
      'selectedOptionItems': instance.selectedOptionItems,
    };

_$SelectionOptionItemImpl _$$SelectionOptionItemImplFromJson(
        Map<String, dynamic> json) =>
    _$SelectionOptionItemImpl(
      merchantOptionItemID: (json['merchantOptionItemID'] as num).toInt(),
      merchantOptionID: (json['merchantOptionID'] as num).toInt(),
      merchantOptionItemName: json['merchantOptionItemName'] as String,
      amount: (json['amount'] as num).toInt(),
      ordinal: (json['ordinal'] as num).toInt(),
      merchantServiceModelBillingType:
          (json['merchantServiceModelBillingType'] as num?)?.toInt(),
      baseFair: (json['baseFair'] as num).toInt(),
      freeDistanceTransportationFee:
          (json['freeDistanceTransportationFee'] as num).toInt(),
      perKilometerFee: (json['perKilometerFee'] as num).toInt(),
      effectiveBeyondKilometer:
          (json['effectiveBeyondKilometer'] as num).toInt(),
      createdDate: DateTime.parse(json['createdDate'] as String),
    );

Map<String, dynamic> _$$SelectionOptionItemImplToJson(
        _$SelectionOptionItemImpl instance) =>
    <String, dynamic>{
      'merchantOptionItemID': instance.merchantOptionItemID,
      'merchantOptionID': instance.merchantOptionID,
      'merchantOptionItemName': instance.merchantOptionItemName,
      'amount': instance.amount,
      'ordinal': instance.ordinal,
      'merchantServiceModelBillingType':
          instance.merchantServiceModelBillingType,
      'baseFair': instance.baseFair,
      'freeDistanceTransportationFee': instance.freeDistanceTransportationFee,
      'perKilometerFee': instance.perKilometerFee,
      'effectiveBeyondKilometer': instance.effectiveBeyondKilometer,
      'createdDate': instance.createdDate.toIso8601String(),
    };
