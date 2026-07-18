// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';

part 'job_order_model.freezed.dart';
part 'job_order_model.g.dart';

JobOrderStatus intToJobStatus(int val) {
  return JobOrderStatus.values.firstWhere((element) => element.value == val);
}

@freezed
class JobOrder with _$JobOrder {
  const factory JobOrder({
    required String jobOrderID,
    required String jobOrderNumber,
    @Default("Unknown merchant") String merchantName,
    required DateTime scheduleDate,
    DateTime? dateStart,
    DateTime? dateEnd,
    @Default(JobOrderStatus.none)
    @JsonKey(fromJson: intToJobStatus)
    JobOrderStatus jobOrderStatus,
    required String jobOrderStatusToString,
    @Default("null") String merchantID,
    required String address,
    required int numberOfPersonnel,
    required int distanceFromOffice,
    required String merchantServiceName,
    @Default('')
    String merchantServicePhoto,
    DateTime? actualDateStart,
    DateTime? actualDateEnd,
    required double latitude,
    required double longitude,
    String? note,
    required double downPayment,
    required double totalAmount,
    required int paymentType,
    DateTime? viewDate,
    String? cancelledBy,
    required DateTime createdDate,
    String? paymentStatus,
    String? paymentMethodUsed,
  }) = _JobOrder;

  factory JobOrder.fromJson(Map<String, dynamic> json) =>
      _$JobOrderFromJson(json);
}
