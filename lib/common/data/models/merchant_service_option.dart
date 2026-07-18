// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';

part 'merchant_service_option.freezed.dart';
part 'merchant_service_option.g.dart';

@freezed
class MerchantServiceOptionModel with _$MerchantServiceOptionModel {
  const factory MerchantServiceOptionModel({
    required int merchantOptionID,
    required String merchantID,
    required int merchantServiceID,
    required String merchantOptionName,
    required bool isRequired,
    required int minimumOption,
    required int maximumOption,
    required int ordinal,
    required DateTime createdDate,
    required List<StoreOptionItem> optionItems,
  }) = _MerchantServiceOptionModel;

  factory MerchantServiceOptionModel.fromJson(Map<String, dynamic> json) =>
      _$MerchantServiceOptionModelFromJson(json);
}
