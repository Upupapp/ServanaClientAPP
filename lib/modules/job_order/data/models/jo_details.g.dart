// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jo_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobOrderDetailsImpl _$$JobOrderDetailsImplFromJson(
        Map<String, dynamic> json) =>
    _$JobOrderDetailsImpl(
      jobOrderID: json['jobOrderID'] as String,
      customerID: json['customerID'] as String,
      merchantID: json['merchantID'] as String,
      voucherCode: json['voucherCode'] as String?,
      jobOrderNumber: json['jobOrderNumber'] as String,
      jobOrderStatus: intToJobStatus((json['jobOrderStatus'] as num).toInt()),
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      dateStart: json['dateStart'] == null
          ? null
          : DateTime.parse(json['dateStart'] as String),
      dateEnd: json['dateEnd'] == null
          ? null
          : DateTime.parse(json['dateEnd'] as String),
      actualDateStart: json['actualDateStart'] == null
          ? null
          : DateTime.parse(json['actualDateStart'] as String),
      actualDateEnd: json['actualDateEnd'] == null
          ? null
          : DateTime.parse(json['actualDateEnd'] as String),
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String? ?? "",
      distanceFromOffice: (json['distanceFromOffice'] as num?)?.toDouble() ?? 0,
      numberOfPersonnel: (json['numberOfPersonnel'] as num?)?.toInt() ?? 0,
      totalItemAmount: (json['totalItemAmount'] as num?)?.toDouble(),
      totalItemDiscount: (json['totalItemDiscount'] as num?)?.toDouble(),
      subDiscountAmount: (json['subDiscountAmount'] as num?)?.toDouble(),
      subDiscountPercent: (json['subDiscountPercent'] as num?)?.toDouble(),
      downPayment: (json['downPayment'] as num?)?.toDouble(),
      transportationFee: (json['transportationFee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      viewDate: json['viewDate'] == null
          ? null
          : DateTime.parse(json['viewDate'] as String),
      cancelledBy: json['cancelledBy'] as String?,
      earnedCredit: (json['earnedCredit'] as num?)?.toDouble() ?? 0,
      paymentType: (json['paymentType'] as num?)?.toInt() ?? 0,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );

Map<String, dynamic> _$$JobOrderDetailsImplToJson(
        _$JobOrderDetailsImpl instance) =>
    <String, dynamic>{
      'jobOrderID': instance.jobOrderID,
      'customerID': instance.customerID,
      'merchantID': instance.merchantID,
      'voucherCode': instance.voucherCode,
      'jobOrderNumber': instance.jobOrderNumber,
      'jobOrderStatus': _$JobOrderStatusEnumMap[instance.jobOrderStatus]!,
      'scheduleDate': instance.scheduleDate.toIso8601String(),
      'dateStart': instance.dateStart?.toIso8601String(),
      'dateEnd': instance.dateEnd?.toIso8601String(),
      'actualDateStart': instance.actualDateStart?.toIso8601String(),
      'actualDateEnd': instance.actualDateEnd?.toIso8601String(),
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'note': instance.note,
      'distanceFromOffice': instance.distanceFromOffice,
      'numberOfPersonnel': instance.numberOfPersonnel,
      'totalItemAmount': instance.totalItemAmount,
      'totalItemDiscount': instance.totalItemDiscount,
      'subDiscountAmount': instance.subDiscountAmount,
      'subDiscountPercent': instance.subDiscountPercent,
      'downPayment': instance.downPayment,
      'transportationFee': instance.transportationFee,
      'totalAmount': instance.totalAmount,
      'viewDate': instance.viewDate?.toIso8601String(),
      'cancelledBy': instance.cancelledBy,
      'earnedCredit': instance.earnedCredit,
      'paymentType': instance.paymentType,
      'createdDate': instance.createdDate.toIso8601String(),
    };

const _$JobOrderStatusEnumMap = {
  JobOrderStatus.none: 'none',
  JobOrderStatus.forReview: 'forReview',
  JobOrderStatus.accepted: 'accepted',
  JobOrderStatus.inTransit: 'inTransit',
  JobOrderStatus.inProgress: 'inProgress',
  JobOrderStatus.completed: 'completed',
  JobOrderStatus.cancelled: 'cancelled',
};
