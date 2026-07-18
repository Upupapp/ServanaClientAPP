// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voucher_data_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VoucherDataModel _$VoucherDataModelFromJson(Map<String, dynamic> json) {
  return _VoucherDataModel.fromJson(json);
}

/// @nodoc
mixin _$VoucherDataModel {
  @JsonKey(name: EntityConstant.VOUCHER_ID)
  int get voucherID => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.MERCHANT_ID)
  int get merchantID => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.VOUCHER_NAME)
  String get voucherName => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.VOUCHER_CODE)
  String get voucherCode => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.VOUCHER_TYPE)
  int get voucherType =>
      throw _privateConstructorUsedError; // @JsonKey(name: EntityConstant.START_DATE) required final DateTime startDate,
  @JsonKey(name: EntityConstant.EXPIRATION_DATE)
  DateTime get expirationDate => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.IS_VALID)
  bool get isValid => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.QUANTITY)
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.QUANTITY_CLAIMED)
  int get quantityClaimed => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.DISCOUNT_TYPE)
  int get discountType => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.DISCOUNT)
  double get discount => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.MERCHANT_FEE)
  double get merchantFee => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.ADMIN_FEE)
  double get adminFee => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.MINIMUM_SPEND)
  double get minimumSpend => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.VOUCHER_PURPOSE_TYPE)
  int get voucherPurposeType =>
      throw _privateConstructorUsedError; // @JsonKey(name: EntityConstant.CAP_AMOUNT) required final double capAmount,
  @JsonKey(name: EntityConstant.CREATED_DATE)
  DateTime get createdDate => throw _privateConstructorUsedError;
  @JsonKey(name: EntityConstant.CREATED_BY)
  String get createdBy => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VoucherDataModelCopyWith<VoucherDataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoucherDataModelCopyWith<$Res> {
  factory $VoucherDataModelCopyWith(
          VoucherDataModel value, $Res Function(VoucherDataModel) then) =
      _$VoucherDataModelCopyWithImpl<$Res, VoucherDataModel>;
  @useResult
  $Res call(
      {@JsonKey(name: EntityConstant.VOUCHER_ID) int voucherID,
      @JsonKey(name: EntityConstant.MERCHANT_ID) int merchantID,
      @JsonKey(name: EntityConstant.VOUCHER_NAME) String voucherName,
      @JsonKey(name: EntityConstant.VOUCHER_CODE) String voucherCode,
      @JsonKey(name: EntityConstant.VOUCHER_TYPE) int voucherType,
      @JsonKey(name: EntityConstant.EXPIRATION_DATE) DateTime expirationDate,
      @JsonKey(name: EntityConstant.IS_VALID) bool isValid,
      @JsonKey(name: EntityConstant.QUANTITY) int quantity,
      @JsonKey(name: EntityConstant.QUANTITY_CLAIMED) int quantityClaimed,
      @JsonKey(name: EntityConstant.DISCOUNT_TYPE) int discountType,
      @JsonKey(name: EntityConstant.DISCOUNT) double discount,
      @JsonKey(name: EntityConstant.MERCHANT_FEE) double merchantFee,
      @JsonKey(name: EntityConstant.ADMIN_FEE) double adminFee,
      @JsonKey(name: EntityConstant.MINIMUM_SPEND) double minimumSpend,
      @JsonKey(name: EntityConstant.VOUCHER_PURPOSE_TYPE)
      int voucherPurposeType,
      @JsonKey(name: EntityConstant.CREATED_DATE) DateTime createdDate,
      @JsonKey(name: EntityConstant.CREATED_BY) String createdBy});
}

/// @nodoc
class _$VoucherDataModelCopyWithImpl<$Res, $Val extends VoucherDataModel>
    implements $VoucherDataModelCopyWith<$Res> {
  _$VoucherDataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voucherID = null,
    Object? merchantID = null,
    Object? voucherName = null,
    Object? voucherCode = null,
    Object? voucherType = null,
    Object? expirationDate = null,
    Object? isValid = null,
    Object? quantity = null,
    Object? quantityClaimed = null,
    Object? discountType = null,
    Object? discount = null,
    Object? merchantFee = null,
    Object? adminFee = null,
    Object? minimumSpend = null,
    Object? voucherPurposeType = null,
    Object? createdDate = null,
    Object? createdBy = null,
  }) {
    return _then(_value.copyWith(
      voucherID: null == voucherID
          ? _value.voucherID
          : voucherID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantID: null == merchantID
          ? _value.merchantID
          : merchantID // ignore: cast_nullable_to_non_nullable
              as int,
      voucherName: null == voucherName
          ? _value.voucherName
          : voucherName // ignore: cast_nullable_to_non_nullable
              as String,
      voucherCode: null == voucherCode
          ? _value.voucherCode
          : voucherCode // ignore: cast_nullable_to_non_nullable
              as String,
      voucherType: null == voucherType
          ? _value.voucherType
          : voucherType // ignore: cast_nullable_to_non_nullable
              as int,
      expirationDate: null == expirationDate
          ? _value.expirationDate
          : expirationDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      quantityClaimed: null == quantityClaimed
          ? _value.quantityClaimed
          : quantityClaimed // ignore: cast_nullable_to_non_nullable
              as int,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as int,
      discount: null == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as double,
      merchantFee: null == merchantFee
          ? _value.merchantFee
          : merchantFee // ignore: cast_nullable_to_non_nullable
              as double,
      adminFee: null == adminFee
          ? _value.adminFee
          : adminFee // ignore: cast_nullable_to_non_nullable
              as double,
      minimumSpend: null == minimumSpend
          ? _value.minimumSpend
          : minimumSpend // ignore: cast_nullable_to_non_nullable
              as double,
      voucherPurposeType: null == voucherPurposeType
          ? _value.voucherPurposeType
          : voucherPurposeType // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VoucherDataModelImplCopyWith<$Res>
    implements $VoucherDataModelCopyWith<$Res> {
  factory _$$VoucherDataModelImplCopyWith(_$VoucherDataModelImpl value,
          $Res Function(_$VoucherDataModelImpl) then) =
      __$$VoucherDataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: EntityConstant.VOUCHER_ID) int voucherID,
      @JsonKey(name: EntityConstant.MERCHANT_ID) int merchantID,
      @JsonKey(name: EntityConstant.VOUCHER_NAME) String voucherName,
      @JsonKey(name: EntityConstant.VOUCHER_CODE) String voucherCode,
      @JsonKey(name: EntityConstant.VOUCHER_TYPE) int voucherType,
      @JsonKey(name: EntityConstant.EXPIRATION_DATE) DateTime expirationDate,
      @JsonKey(name: EntityConstant.IS_VALID) bool isValid,
      @JsonKey(name: EntityConstant.QUANTITY) int quantity,
      @JsonKey(name: EntityConstant.QUANTITY_CLAIMED) int quantityClaimed,
      @JsonKey(name: EntityConstant.DISCOUNT_TYPE) int discountType,
      @JsonKey(name: EntityConstant.DISCOUNT) double discount,
      @JsonKey(name: EntityConstant.MERCHANT_FEE) double merchantFee,
      @JsonKey(name: EntityConstant.ADMIN_FEE) double adminFee,
      @JsonKey(name: EntityConstant.MINIMUM_SPEND) double minimumSpend,
      @JsonKey(name: EntityConstant.VOUCHER_PURPOSE_TYPE)
      int voucherPurposeType,
      @JsonKey(name: EntityConstant.CREATED_DATE) DateTime createdDate,
      @JsonKey(name: EntityConstant.CREATED_BY) String createdBy});
}

/// @nodoc
class __$$VoucherDataModelImplCopyWithImpl<$Res>
    extends _$VoucherDataModelCopyWithImpl<$Res, _$VoucherDataModelImpl>
    implements _$$VoucherDataModelImplCopyWith<$Res> {
  __$$VoucherDataModelImplCopyWithImpl(_$VoucherDataModelImpl _value,
      $Res Function(_$VoucherDataModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voucherID = null,
    Object? merchantID = null,
    Object? voucherName = null,
    Object? voucherCode = null,
    Object? voucherType = null,
    Object? expirationDate = null,
    Object? isValid = null,
    Object? quantity = null,
    Object? quantityClaimed = null,
    Object? discountType = null,
    Object? discount = null,
    Object? merchantFee = null,
    Object? adminFee = null,
    Object? minimumSpend = null,
    Object? voucherPurposeType = null,
    Object? createdDate = null,
    Object? createdBy = null,
  }) {
    return _then(_$VoucherDataModelImpl(
      voucherID: null == voucherID
          ? _value.voucherID
          : voucherID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantID: null == merchantID
          ? _value.merchantID
          : merchantID // ignore: cast_nullable_to_non_nullable
              as int,
      voucherName: null == voucherName
          ? _value.voucherName
          : voucherName // ignore: cast_nullable_to_non_nullable
              as String,
      voucherCode: null == voucherCode
          ? _value.voucherCode
          : voucherCode // ignore: cast_nullable_to_non_nullable
              as String,
      voucherType: null == voucherType
          ? _value.voucherType
          : voucherType // ignore: cast_nullable_to_non_nullable
              as int,
      expirationDate: null == expirationDate
          ? _value.expirationDate
          : expirationDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      quantityClaimed: null == quantityClaimed
          ? _value.quantityClaimed
          : quantityClaimed // ignore: cast_nullable_to_non_nullable
              as int,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as int,
      discount: null == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as double,
      merchantFee: null == merchantFee
          ? _value.merchantFee
          : merchantFee // ignore: cast_nullable_to_non_nullable
              as double,
      adminFee: null == adminFee
          ? _value.adminFee
          : adminFee // ignore: cast_nullable_to_non_nullable
              as double,
      minimumSpend: null == minimumSpend
          ? _value.minimumSpend
          : minimumSpend // ignore: cast_nullable_to_non_nullable
              as double,
      voucherPurposeType: null == voucherPurposeType
          ? _value.voucherPurposeType
          : voucherPurposeType // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoucherDataModelImpl implements _VoucherDataModel {
  const _$VoucherDataModelImpl(
      {@JsonKey(name: EntityConstant.VOUCHER_ID) required this.voucherID,
      @JsonKey(name: EntityConstant.MERCHANT_ID) required this.merchantID,
      @JsonKey(name: EntityConstant.VOUCHER_NAME) required this.voucherName,
      @JsonKey(name: EntityConstant.VOUCHER_CODE) required this.voucherCode,
      @JsonKey(name: EntityConstant.VOUCHER_TYPE) required this.voucherType,
      @JsonKey(name: EntityConstant.EXPIRATION_DATE)
      required this.expirationDate,
      @JsonKey(name: EntityConstant.IS_VALID) required this.isValid,
      @JsonKey(name: EntityConstant.QUANTITY) required this.quantity,
      @JsonKey(name: EntityConstant.QUANTITY_CLAIMED)
      required this.quantityClaimed,
      @JsonKey(name: EntityConstant.DISCOUNT_TYPE) required this.discountType,
      @JsonKey(name: EntityConstant.DISCOUNT) required this.discount,
      @JsonKey(name: EntityConstant.MERCHANT_FEE) required this.merchantFee,
      @JsonKey(name: EntityConstant.ADMIN_FEE) required this.adminFee,
      @JsonKey(name: EntityConstant.MINIMUM_SPEND) required this.minimumSpend,
      @JsonKey(name: EntityConstant.VOUCHER_PURPOSE_TYPE)
      required this.voucherPurposeType,
      @JsonKey(name: EntityConstant.CREATED_DATE) required this.createdDate,
      @JsonKey(name: EntityConstant.CREATED_BY) required this.createdBy});

  factory _$VoucherDataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoucherDataModelImplFromJson(json);

  @override
  @JsonKey(name: EntityConstant.VOUCHER_ID)
  final int voucherID;
  @override
  @JsonKey(name: EntityConstant.MERCHANT_ID)
  final int merchantID;
  @override
  @JsonKey(name: EntityConstant.VOUCHER_NAME)
  final String voucherName;
  @override
  @JsonKey(name: EntityConstant.VOUCHER_CODE)
  final String voucherCode;
  @override
  @JsonKey(name: EntityConstant.VOUCHER_TYPE)
  final int voucherType;
// @JsonKey(name: EntityConstant.START_DATE) required final DateTime startDate,
  @override
  @JsonKey(name: EntityConstant.EXPIRATION_DATE)
  final DateTime expirationDate;
  @override
  @JsonKey(name: EntityConstant.IS_VALID)
  final bool isValid;
  @override
  @JsonKey(name: EntityConstant.QUANTITY)
  final int quantity;
  @override
  @JsonKey(name: EntityConstant.QUANTITY_CLAIMED)
  final int quantityClaimed;
  @override
  @JsonKey(name: EntityConstant.DISCOUNT_TYPE)
  final int discountType;
  @override
  @JsonKey(name: EntityConstant.DISCOUNT)
  final double discount;
  @override
  @JsonKey(name: EntityConstant.MERCHANT_FEE)
  final double merchantFee;
  @override
  @JsonKey(name: EntityConstant.ADMIN_FEE)
  final double adminFee;
  @override
  @JsonKey(name: EntityConstant.MINIMUM_SPEND)
  final double minimumSpend;
  @override
  @JsonKey(name: EntityConstant.VOUCHER_PURPOSE_TYPE)
  final int voucherPurposeType;
// @JsonKey(name: EntityConstant.CAP_AMOUNT) required final double capAmount,
  @override
  @JsonKey(name: EntityConstant.CREATED_DATE)
  final DateTime createdDate;
  @override
  @JsonKey(name: EntityConstant.CREATED_BY)
  final String createdBy;

  @override
  String toString() {
    return 'VoucherDataModel(voucherID: $voucherID, merchantID: $merchantID, voucherName: $voucherName, voucherCode: $voucherCode, voucherType: $voucherType, expirationDate: $expirationDate, isValid: $isValid, quantity: $quantity, quantityClaimed: $quantityClaimed, discountType: $discountType, discount: $discount, merchantFee: $merchantFee, adminFee: $adminFee, minimumSpend: $minimumSpend, voucherPurposeType: $voucherPurposeType, createdDate: $createdDate, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoucherDataModelImpl &&
            (identical(other.voucherID, voucherID) ||
                other.voucherID == voucherID) &&
            (identical(other.merchantID, merchantID) ||
                other.merchantID == merchantID) &&
            (identical(other.voucherName, voucherName) ||
                other.voucherName == voucherName) &&
            (identical(other.voucherCode, voucherCode) ||
                other.voucherCode == voucherCode) &&
            (identical(other.voucherType, voucherType) ||
                other.voucherType == voucherType) &&
            (identical(other.expirationDate, expirationDate) ||
                other.expirationDate == expirationDate) &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.quantityClaimed, quantityClaimed) ||
                other.quantityClaimed == quantityClaimed) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.merchantFee, merchantFee) ||
                other.merchantFee == merchantFee) &&
            (identical(other.adminFee, adminFee) ||
                other.adminFee == adminFee) &&
            (identical(other.minimumSpend, minimumSpend) ||
                other.minimumSpend == minimumSpend) &&
            (identical(other.voucherPurposeType, voucherPurposeType) ||
                other.voucherPurposeType == voucherPurposeType) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      voucherID,
      merchantID,
      voucherName,
      voucherCode,
      voucherType,
      expirationDate,
      isValid,
      quantity,
      quantityClaimed,
      discountType,
      discount,
      merchantFee,
      adminFee,
      minimumSpend,
      voucherPurposeType,
      createdDate,
      createdBy);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VoucherDataModelImplCopyWith<_$VoucherDataModelImpl> get copyWith =>
      __$$VoucherDataModelImplCopyWithImpl<_$VoucherDataModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoucherDataModelImplToJson(
      this,
    );
  }
}

abstract class _VoucherDataModel implements VoucherDataModel {
  const factory _VoucherDataModel(
      {@JsonKey(name: EntityConstant.VOUCHER_ID) required final int voucherID,
      @JsonKey(name: EntityConstant.MERCHANT_ID) required final int merchantID,
      @JsonKey(name: EntityConstant.VOUCHER_NAME)
      required final String voucherName,
      @JsonKey(name: EntityConstant.VOUCHER_CODE)
      required final String voucherCode,
      @JsonKey(name: EntityConstant.VOUCHER_TYPE)
      required final int voucherType,
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
      @JsonKey(name: EntityConstant.CREATED_DATE)
      required final DateTime createdDate,
      @JsonKey(name: EntityConstant.CREATED_BY)
      required final String createdBy}) = _$VoucherDataModelImpl;

  factory _VoucherDataModel.fromJson(Map<String, dynamic> json) =
      _$VoucherDataModelImpl.fromJson;

  @override
  @JsonKey(name: EntityConstant.VOUCHER_ID)
  int get voucherID;
  @override
  @JsonKey(name: EntityConstant.MERCHANT_ID)
  int get merchantID;
  @override
  @JsonKey(name: EntityConstant.VOUCHER_NAME)
  String get voucherName;
  @override
  @JsonKey(name: EntityConstant.VOUCHER_CODE)
  String get voucherCode;
  @override
  @JsonKey(name: EntityConstant.VOUCHER_TYPE)
  int get voucherType;
  @override // @JsonKey(name: EntityConstant.START_DATE) required final DateTime startDate,
  @JsonKey(name: EntityConstant.EXPIRATION_DATE)
  DateTime get expirationDate;
  @override
  @JsonKey(name: EntityConstant.IS_VALID)
  bool get isValid;
  @override
  @JsonKey(name: EntityConstant.QUANTITY)
  int get quantity;
  @override
  @JsonKey(name: EntityConstant.QUANTITY_CLAIMED)
  int get quantityClaimed;
  @override
  @JsonKey(name: EntityConstant.DISCOUNT_TYPE)
  int get discountType;
  @override
  @JsonKey(name: EntityConstant.DISCOUNT)
  double get discount;
  @override
  @JsonKey(name: EntityConstant.MERCHANT_FEE)
  double get merchantFee;
  @override
  @JsonKey(name: EntityConstant.ADMIN_FEE)
  double get adminFee;
  @override
  @JsonKey(name: EntityConstant.MINIMUM_SPEND)
  double get minimumSpend;
  @override
  @JsonKey(name: EntityConstant.VOUCHER_PURPOSE_TYPE)
  int get voucherPurposeType;
  @override // @JsonKey(name: EntityConstant.CAP_AMOUNT) required final double capAmount,
  @JsonKey(name: EntityConstant.CREATED_DATE)
  DateTime get createdDate;
  @override
  @JsonKey(name: EntityConstant.CREATED_BY)
  String get createdBy;
  @override
  @JsonKey(ignore: true)
  _$$VoucherDataModelImplCopyWith<_$VoucherDataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
