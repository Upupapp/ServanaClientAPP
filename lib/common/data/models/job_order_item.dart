import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_order_item.freezed.dart';
part 'job_order_item.g.dart';

@freezed
class JobOrderItem with _$JobOrderItem {
  const factory JobOrderItem({
    required int jobOrderItemID,
    String? serviceId,
    required String serviceName,
    required int quantity,
    String? note,
    required double amount,
    @Default(0) double transportaion,
    required double discount,
    required List<SelectedOption> selectedOptions,
  }) = _JobOrderItem;

  factory JobOrderItem.fromJson(Map<String, dynamic> json) =>
      _$JobOrderItemFromJson(json);
}

@freezed
class SelectedOption with _$SelectedOption {
  const factory SelectedOption({
    required int jobOrderOptionItemID,
    @Default(0) int merchantOptionItemID,
    required int merchantServiceID,
    @Default(0) double optionAmount,
    @Default(0) double transportaion,
    required String merchantOptionItemName,
    required int quantity,
  }) = _SelectedOption;

  factory SelectedOption.fromJson(Map<String, dynamic> json) =>
      _$SelectedOptionFromJson(json);
}
