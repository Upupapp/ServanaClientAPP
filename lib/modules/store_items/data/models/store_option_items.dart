import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_option_items.freezed.dart';
part 'store_option_items.g.dart';

@freezed
class StoreOptionItem with _$StoreOptionItem {
  const factory StoreOptionItem({
    @Default(0) int merchantOptionItemID,
    @Default(0) int merchantOptionID,
    @Default("0") String merchantServiceID,
    required String merchantOptionItemName,
    required double amount,
    @Default(0) int ordinal,
    required double baseFair,
  }) = _StoreOptionItem;

  factory StoreOptionItem.fromJson(Map<String, dynamic> json) =>
      _$StoreOptionItemFromJson(json);
}
