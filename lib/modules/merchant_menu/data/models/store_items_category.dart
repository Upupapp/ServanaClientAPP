import 'package:client/common/data/models/merchant_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_items_category.freezed.dart';

@freezed
class StoreItemCategory with _$StoreItemCategory {
  const factory StoreItemCategory({
    required final int id,
    required final int ordinal,
    required final String name,
    required final List<MerchantServiceModel> services,
  }) = _StoreItemCategory;
}
