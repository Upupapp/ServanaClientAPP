// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoucherDataModelImpl _$$VoucherDataModelImplFromJson(
        Map<String, dynamic> json) =>
    _$VoucherDataModelImpl(
      voucherID: (json['vid'] as num).toInt(),
      merchantID: (json['mid'] as num).toInt(),
      voucherName: json['vn'] as String,
      voucherCode: json['vc'] as String,
      voucherType: (json['vt'] as num).toInt(),
      expirationDate: DateTime.parse(json['ed'] as String),
      isValid: json['iv'] as bool,
      quantity: (json['qu'] as num).toInt(),
      quantityClaimed: (json['qc'] as num).toInt(),
      discountType: (json['dt'] as num).toInt(),
      discount: (json['di'] as num).toDouble(),
      merchantFee: (json['mf'] as num).toDouble(),
      adminFee: (json['af'] as num).toDouble(),
      minimumSpend: (json['msp'] as num).toDouble(),
      voucherPurposeType: (json['vpt'] as num).toInt(),
      createdDate: DateTime.parse(json['cd'] as String),
      createdBy: json['cb'] as String,
    );

Map<String, dynamic> _$$VoucherDataModelImplToJson(
        _$VoucherDataModelImpl instance) =>
    <String, dynamic>{
      'vid': instance.voucherID,
      'mid': instance.merchantID,
      'vn': instance.voucherName,
      'vc': instance.voucherCode,
      'vt': instance.voucherType,
      'ed': instance.expirationDate.toIso8601String(),
      'iv': instance.isValid,
      'qu': instance.quantity,
      'qc': instance.quantityClaimed,
      'dt': instance.discountType,
      'di': instance.discount,
      'mf': instance.merchantFee,
      'af': instance.adminFee,
      'msp': instance.minimumSpend,
      'vpt': instance.voucherPurposeType,
      'cd': instance.createdDate.toIso8601String(),
      'cb': instance.createdBy,
    };
