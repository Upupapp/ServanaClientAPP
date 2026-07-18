// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobOrderImpl _$$JobOrderImplFromJson(Map<String, dynamic> json) =>
    _$JobOrderImpl(
      jobOrderID: json['jobOrderID'] as String,
      jobOrderNumber: json['jobOrderNumber'] as String,
      merchantName: json['merchantName'] as String? ?? "Unknown merchant",
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      dateStart: json['dateStart'] == null
          ? null
          : DateTime.parse(json['dateStart'] as String),
      dateEnd: json['dateEnd'] == null
          ? null
          : DateTime.parse(json['dateEnd'] as String),
      jobOrderStatus: json['jobOrderStatus'] == null
          ? JobOrderStatus.none
          : intToJobStatus((json['jobOrderStatus'] as num).toInt()),
      jobOrderStatusToString: json['jobOrderStatusToString'] as String,
      merchantID: json['merchantID'] as String? ?? "null",
      address: json['address'] as String,
      numberOfPersonnel: (json['numberOfPersonnel'] as num).toInt(),
      distanceFromOffice: (json['distanceFromOffice'] as num).toInt(),
      merchantServiceName: json['merchantServiceName'] as String,
      merchantServicePhoto: json['merchantServicePhoto'] as String? ?? '',
      actualDateStart: json['actualDateStart'] == null
          ? null
          : DateTime.parse(json['actualDateStart'] as String),
      actualDateEnd: json['actualDateEnd'] == null
          ? null
          : DateTime.parse(json['actualDateEnd'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      note: json['note'] as String?,
      downPayment: (json['downPayment'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentType: (json['paymentType'] as num).toInt(),
      viewDate: json['viewDate'] == null
          ? null
          : DateTime.parse(json['viewDate'] as String),
      cancelledBy: json['cancelledBy'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
      paymentStatus: json['paymentStatus'] as String?,
      paymentMethodUsed: json['paymentMethodUsed'] as String?,
    );

Map<String, dynamic> _$$JobOrderImplToJson(_$JobOrderImpl instance) =>
    <String, dynamic>{
      'jobOrderID': instance.jobOrderID,
      'jobOrderNumber': instance.jobOrderNumber,
      'merchantName': instance.merchantName,
      'scheduleDate': instance.scheduleDate.toIso8601String(),
      'dateStart': instance.dateStart?.toIso8601String(),
      'dateEnd': instance.dateEnd?.toIso8601String(),
      'jobOrderStatus': _$JobOrderStatusEnumMap[instance.jobOrderStatus]!,
      'jobOrderStatusToString': instance.jobOrderStatusToString,
      'merchantID': instance.merchantID,
      'address': instance.address,
      'numberOfPersonnel': instance.numberOfPersonnel,
      'distanceFromOffice': instance.distanceFromOffice,
      'merchantServiceName': instance.merchantServiceName,
      'merchantServicePhoto': instance.merchantServicePhoto,
      'actualDateStart': instance.actualDateStart?.toIso8601String(),
      'actualDateEnd': instance.actualDateEnd?.toIso8601String(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'note': instance.note,
      'downPayment': instance.downPayment,
      'totalAmount': instance.totalAmount,
      'paymentType': instance.paymentType,
      'viewDate': instance.viewDate?.toIso8601String(),
      'cancelledBy': instance.cancelledBy,
      'createdDate': instance.createdDate.toIso8601String(),
      'paymentStatus': instance.paymentStatus,
      'paymentMethodUsed': instance.paymentMethodUsed,
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
