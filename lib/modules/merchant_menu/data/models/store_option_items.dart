import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_option_items.freezed.dart';
part 'store_option_items.g.dart';

@freezed
class StoreOptionItem with _$StoreOptionItem {
  const factory StoreOptionItem({
    required final int id,
    final int? serviceId,
    final int? serviceOptionGroupId,
    required final String name,
    required final double price,
    required final double transportation,
    @Default(false) final bool addedByMerchant,
  }) = _StoreOptionItem;

  factory StoreOptionItem.fromJson(Map<String, dynamic> json) =>
      _$StoreOptionItemFromJson(json);
}
