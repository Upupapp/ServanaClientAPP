import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_category.freezed.dart';
part 'merchant_category.g.dart';

@freezed
class MerchantCategory with _$MerchantCategory {
  const factory MerchantCategory({
    required int merchantCategoryID,
    required String merchantID,
    required int serviceID,
    required String merchantCategoryName,
    required int ordinal,
    required DateTime createdDate,
  }) = _MerchantCategory;

  factory MerchantCategory.fromJson(Map<String, dynamic> json) =>
      _$MerchantCategoryFromJson(json);
}
