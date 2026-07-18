// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';

part 'jo_details.freezed.dart';
part 'jo_details.g.dart';

JobOrderStatus intToJobStatus(int val) {
  return JobOrderStatus.values.firstWhere((element) => element.value == val);
}

@freezed
class JobOrderDetails with _$JobOrderDetails {
  const factory JobOrderDetails({
    required String jobOrderID,
    required String customerID,
    required String merchantID,
    String? voucherCode,
    required String jobOrderNumber,
    @JsonKey(fromJson: intToJobStatus) required JobOrderStatus jobOrderStatus,
    required DateTime scheduleDate,
    required DateTime? dateStart,
    required DateTime? dateEnd,
    required DateTime? actualDateStart,
    required DateTime? actualDateEnd,
    required String address,
    @Default(0) double latitude,
    @Default(0) double longitude,
    @Default("") String note,
    @Default(0) double distanceFromOffice,
    @Default(0) int numberOfPersonnel,
    double? totalItemAmount,
    double? totalItemDiscount,
    double? subDiscountAmount,
    double? subDiscountPercent,
    double? downPayment,
    @Default(0) double transportationFee,
    @Default(0) double totalAmount,
    DateTime? viewDate,
    String? cancelledBy,
    @Default(0) double earnedCredit,
    @Default(0) int paymentType,
    required DateTime createdDate,
  }) = _JobOrderDetails;

  factory JobOrderDetails.fromJson(Map<String, dynamic> json) =>
      _$JobOrderDetailsFromJson(json);
}
