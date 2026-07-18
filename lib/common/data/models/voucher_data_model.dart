// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:client/common/constants/entity_constants.dart';

part 'voucher_data_model.freezed.dart';
part 'voucher_data_model.g.dart';

@Freezed(fromJson: true, toJson: true)
class VoucherDataModel with _$VoucherDataModel {
  const factory VoucherDataModel({
    @JsonKey(name: EntityConstant.VOUCHER_ID) required final int voucherID,
    @JsonKey(name: EntityConstant.MERCHANT_ID) required final int merchantID,
    @JsonKey(name: EntityConstant.VOUCHER_NAME)
    required final String voucherName,
    @JsonKey(name: EntityConstant.VOUCHER_CODE)
    required final String voucherCode,
    @JsonKey(name: EntityConstant.VOUCHER_TYPE) required final int voucherType,
    // @JsonKey(name: EntityConstant.START_DATE) required final DateTime startDate,
    @JsonKey(name: EntityConstant.EXPIRATION_DATE)
    required final DateTime expirationDate,
    @JsonKey(name: EntityConstant.IS_VALID) required final bool isValid,
    @JsonKey(name: EntityConstant.QUANTITY) required final int quantity,
    @JsonKey(name: EntityConstant.QUANTITY_CLAIMED)
    required final int quantityClaimed,
    @JsonKey(name: EntityConstant.DISCOUNT_TYPE)
    required final int discountType,
    @JsonKey(name: EntityConstant.DISCOUNT) required final double discount,
    @JsonKey(name: EntityConstant.MERCHANT_FEE)
    required final double merchantFee,
    @JsonKey(name: EntityConstant.ADMIN_FEE) required final double adminFee,
    @JsonKey(name: EntityConstant.MINIMUM_SPEND)
    required final double minimumSpend,
    @JsonKey(name: EntityConstant.VOUCHER_PURPOSE_TYPE)
    required final int voucherPurposeType,
    // @JsonKey(name: EntityConstant.CAP_AMOUNT) required final double capAmount,
    @JsonKey(name: EntityConstant.CREATED_DATE)
    required final DateTime createdDate,
    @JsonKey(name: EntityConstant.CREATED_BY) required final String createdBy,
  }) = _VoucherDataModel;

  factory VoucherDataModel.fromJson(Map<String, dynamic> json) =>
      _$VoucherDataModelFromJson(json);
}
