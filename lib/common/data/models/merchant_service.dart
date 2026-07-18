import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_service.freezed.dart';
part 'merchant_service.g.dart';

@freezed
class MerchantServiceModel with _$MerchantServiceModel {
  factory MerchantServiceModel({
    @Default(0) int merchantServiceID,
    @Default(0) int merchantCategoryID,
    @Default(0) int merchantSubcategoryID,
    @Default('') String merchantServiceName,
    @Default("No description") String merchantServiceDescription,
    @Default(0) int amount,
    @Default(0) int ordinal,
    @Default(0) int merchantServiceBillingType,
    @Default('') String recommendation,
    String? inclusion,
    @Default(true) bool isActive,
    String? noteToCustomer,
    @Default(0) int baseFair,
    @Default(0) int freeDistanceTransportationFee,
    @Default(0) int perKilometerFee,
    @Default(0) int effectiveBeyondKilometer,
    @Default('') String merchantServicePictureURL,
    String? merchantServicePictureURLBase64,
    String? merchantCategoryName,
    String? merchantSubcategoryName,
    DateTime? createdDate,
    @Default([]) List<SelectionOption> selectionOptions,
  }) = _MerchantServiceModel;

  factory MerchantServiceModel.fromJson(Map<String, dynamic> json) =>
      _$MerchantServiceModelFromJson(json);
}

@freezed
class SelectionOption with _$SelectionOption {
  factory SelectionOption({
    int? merchantServiceModelOptionID,
    required int merchantOptionID,
    required String merchantOptionName,
    required bool isRequired,
    required int minimumOption,
    required int maximumOption,
    required int ordinal,
    required List<SelectionOptionItem> selectedOptionItems,
  }) = _SelectionOption;

  factory SelectionOption.fromJson(Map<String, dynamic> json) =>
      _$SelectionOptionFromJson(json);
}

@freezed
class SelectionOptionItem with _$SelectionOptionItem {
  factory SelectionOptionItem({
    required int merchantOptionItemID,
    required int merchantOptionID,
    required String merchantOptionItemName,
    required int amount,
    required int ordinal,
    int? merchantServiceModelBillingType,
    required int baseFair,
    required int freeDistanceTransportationFee,
    required int perKilometerFee,
    required int effectiveBeyondKilometer,
    required DateTime createdDate,
  }) = _SelectionOptionItem;

  factory SelectionOptionItem.fromJson(Map<String, dynamic> json) =>
      _$SelectionOptionItemFromJson(json);
}
