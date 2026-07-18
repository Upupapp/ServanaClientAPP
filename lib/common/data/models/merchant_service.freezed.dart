// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'merchant_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MerchantServiceModel _$MerchantServiceModelFromJson(Map<String, dynamic> json) {
  return _MerchantServiceModel.fromJson(json);
}

/// @nodoc
mixin _$MerchantServiceModel {
  int get merchantServiceID => throw _privateConstructorUsedError;
  int get merchantCategoryID => throw _privateConstructorUsedError;
  int get merchantSubcategoryID => throw _privateConstructorUsedError;
  String get merchantServiceName => throw _privateConstructorUsedError;
  String get merchantServiceDescription => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  int get ordinal => throw _privateConstructorUsedError;
  int get merchantServiceBillingType => throw _privateConstructorUsedError;
  String get recommendation => throw _privateConstructorUsedError;
  String? get inclusion => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get noteToCustomer => throw _privateConstructorUsedError;
  int get baseFair => throw _privateConstructorUsedError;
  int get freeDistanceTransportationFee => throw _privateConstructorUsedError;
  int get perKilometerFee => throw _privateConstructorUsedError;
  int get effectiveBeyondKilometer => throw _privateConstructorUsedError;
  String get merchantServicePictureURL => throw _privateConstructorUsedError;
  String? get merchantServicePictureURLBase64 =>
      throw _privateConstructorUsedError;
  String? get merchantCategoryName => throw _privateConstructorUsedError;
  String? get merchantSubcategoryName => throw _privateConstructorUsedError;
  DateTime? get createdDate => throw _privateConstructorUsedError;
  List<SelectionOption> get selectionOptions =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MerchantServiceModelCopyWith<MerchantServiceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MerchantServiceModelCopyWith<$Res> {
  factory $MerchantServiceModelCopyWith(MerchantServiceModel value,
          $Res Function(MerchantServiceModel) then) =
      _$MerchantServiceModelCopyWithImpl<$Res, MerchantServiceModel>;
  @useResult
  $Res call(
      {int merchantServiceID,
      int merchantCategoryID,
      int merchantSubcategoryID,
      String merchantServiceName,
      String merchantServiceDescription,
      int amount,
      int ordinal,
      int merchantServiceBillingType,
      String recommendation,
      String? inclusion,
      bool isActive,
      String? noteToCustomer,
      int baseFair,
      int freeDistanceTransportationFee,
      int perKilometerFee,
      int effectiveBeyondKilometer,
      String merchantServicePictureURL,
      String? merchantServicePictureURLBase64,
      String? merchantCategoryName,
      String? merchantSubcategoryName,
      DateTime? createdDate,
      List<SelectionOption> selectionOptions});
}

/// @nodoc
class _$MerchantServiceModelCopyWithImpl<$Res,
        $Val extends MerchantServiceModel>
    implements $MerchantServiceModelCopyWith<$Res> {
  _$MerchantServiceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantServiceID = null,
    Object? merchantCategoryID = null,
    Object? merchantSubcategoryID = null,
    Object? merchantServiceName = null,
    Object? merchantServiceDescription = null,
    Object? amount = null,
    Object? ordinal = null,
    Object? merchantServiceBillingType = null,
    Object? recommendation = null,
    Object? inclusion = freezed,
    Object? isActive = null,
    Object? noteToCustomer = freezed,
    Object? baseFair = null,
    Object? freeDistanceTransportationFee = null,
    Object? perKilometerFee = null,
    Object? effectiveBeyondKilometer = null,
    Object? merchantServicePictureURL = null,
    Object? merchantServicePictureURLBase64 = freezed,
    Object? merchantCategoryName = freezed,
    Object? merchantSubcategoryName = freezed,
    Object? createdDate = freezed,
    Object? selectionOptions = null,
  }) {
    return _then(_value.copyWith(
      merchantServiceID: null == merchantServiceID
          ? _value.merchantServiceID
          : merchantServiceID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantCategoryID: null == merchantCategoryID
          ? _value.merchantCategoryID
          : merchantCategoryID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantSubcategoryID: null == merchantSubcategoryID
          ? _value.merchantSubcategoryID
          : merchantSubcategoryID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceName: null == merchantServiceName
          ? _value.merchantServiceName
          : merchantServiceName // ignore: cast_nullable_to_non_nullable
              as String,
      merchantServiceDescription: null == merchantServiceDescription
          ? _value.merchantServiceDescription
          : merchantServiceDescription // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceBillingType: null == merchantServiceBillingType
          ? _value.merchantServiceBillingType
          : merchantServiceBillingType // ignore: cast_nullable_to_non_nullable
              as int,
      recommendation: null == recommendation
          ? _value.recommendation
          : recommendation // ignore: cast_nullable_to_non_nullable
              as String,
      inclusion: freezed == inclusion
          ? _value.inclusion
          : inclusion // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      noteToCustomer: freezed == noteToCustomer
          ? _value.noteToCustomer
          : noteToCustomer // ignore: cast_nullable_to_non_nullable
              as String?,
      baseFair: null == baseFair
          ? _value.baseFair
          : baseFair // ignore: cast_nullable_to_non_nullable
              as int,
      freeDistanceTransportationFee: null == freeDistanceTransportationFee
          ? _value.freeDistanceTransportationFee
          : freeDistanceTransportationFee // ignore: cast_nullable_to_non_nullable
              as int,
      perKilometerFee: null == perKilometerFee
          ? _value.perKilometerFee
          : perKilometerFee // ignore: cast_nullable_to_non_nullable
              as int,
      effectiveBeyondKilometer: null == effectiveBeyondKilometer
          ? _value.effectiveBeyondKilometer
          : effectiveBeyondKilometer // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServicePictureURL: null == merchantServicePictureURL
          ? _value.merchantServicePictureURL
          : merchantServicePictureURL // ignore: cast_nullable_to_non_nullable
              as String,
      merchantServicePictureURLBase64: freezed ==
              merchantServicePictureURLBase64
          ? _value.merchantServicePictureURLBase64
          : merchantServicePictureURLBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      merchantCategoryName: freezed == merchantCategoryName
          ? _value.merchantCategoryName
          : merchantCategoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      merchantSubcategoryName: freezed == merchantSubcategoryName
          ? _value.merchantSubcategoryName
          : merchantSubcategoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdDate: freezed == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      selectionOptions: null == selectionOptions
          ? _value.selectionOptions
          : selectionOptions // ignore: cast_nullable_to_non_nullable
              as List<SelectionOption>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MerchantServiceModelImplCopyWith<$Res>
    implements $MerchantServiceModelCopyWith<$Res> {
  factory _$$MerchantServiceModelImplCopyWith(_$MerchantServiceModelImpl value,
          $Res Function(_$MerchantServiceModelImpl) then) =
      __$$MerchantServiceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int merchantServiceID,
      int merchantCategoryID,
      int merchantSubcategoryID,
      String merchantServiceName,
      String merchantServiceDescription,
      int amount,
      int ordinal,
      int merchantServiceBillingType,
      String recommendation,
      String? inclusion,
      bool isActive,
      String? noteToCustomer,
      int baseFair,
      int freeDistanceTransportationFee,
      int perKilometerFee,
      int effectiveBeyondKilometer,
      String merchantServicePictureURL,
      String? merchantServicePictureURLBase64,
      String? merchantCategoryName,
      String? merchantSubcategoryName,
      DateTime? createdDate,
      List<SelectionOption> selectionOptions});
}

/// @nodoc
class __$$MerchantServiceModelImplCopyWithImpl<$Res>
    extends _$MerchantServiceModelCopyWithImpl<$Res, _$MerchantServiceModelImpl>
    implements _$$MerchantServiceModelImplCopyWith<$Res> {
  __$$MerchantServiceModelImplCopyWithImpl(_$MerchantServiceModelImpl _value,
      $Res Function(_$MerchantServiceModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantServiceID = null,
    Object? merchantCategoryID = null,
    Object? merchantSubcategoryID = null,
    Object? merchantServiceName = null,
    Object? merchantServiceDescription = null,
    Object? amount = null,
    Object? ordinal = null,
    Object? merchantServiceBillingType = null,
    Object? recommendation = null,
    Object? inclusion = freezed,
    Object? isActive = null,
    Object? noteToCustomer = freezed,
    Object? baseFair = null,
    Object? freeDistanceTransportationFee = null,
    Object? perKilometerFee = null,
    Object? effectiveBeyondKilometer = null,
    Object? merchantServicePictureURL = null,
    Object? merchantServicePictureURLBase64 = freezed,
    Object? merchantCategoryName = freezed,
    Object? merchantSubcategoryName = freezed,
    Object? createdDate = freezed,
    Object? selectionOptions = null,
  }) {
    return _then(_$MerchantServiceModelImpl(
      merchantServiceID: null == merchantServiceID
          ? _value.merchantServiceID
          : merchantServiceID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantCategoryID: null == merchantCategoryID
          ? _value.merchantCategoryID
          : merchantCategoryID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantSubcategoryID: null == merchantSubcategoryID
          ? _value.merchantSubcategoryID
          : merchantSubcategoryID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceName: null == merchantServiceName
          ? _value.merchantServiceName
          : merchantServiceName // ignore: cast_nullable_to_non_nullable
              as String,
      merchantServiceDescription: null == merchantServiceDescription
          ? _value.merchantServiceDescription
          : merchantServiceDescription // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceBillingType: null == merchantServiceBillingType
          ? _value.merchantServiceBillingType
          : merchantServiceBillingType // ignore: cast_nullable_to_non_nullable
              as int,
      recommendation: null == recommendation
          ? _value.recommendation
          : recommendation // ignore: cast_nullable_to_non_nullable
              as String,
      inclusion: freezed == inclusion
          ? _value.inclusion
          : inclusion // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      noteToCustomer: freezed == noteToCustomer
          ? _value.noteToCustomer
          : noteToCustomer // ignore: cast_nullable_to_non_nullable
              as String?,
      baseFair: null == baseFair
          ? _value.baseFair
          : baseFair // ignore: cast_nullable_to_non_nullable
              as int,
      freeDistanceTransportationFee: null == freeDistanceTransportationFee
          ? _value.freeDistanceTransportationFee
          : freeDistanceTransportationFee // ignore: cast_nullable_to_non_nullable
              as int,
      perKilometerFee: null == perKilometerFee
          ? _value.perKilometerFee
          : perKilometerFee // ignore: cast_nullable_to_non_nullable
              as int,
      effectiveBeyondKilometer: null == effectiveBeyondKilometer
          ? _value.effectiveBeyondKilometer
          : effectiveBeyondKilometer // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServicePictureURL: null == merchantServicePictureURL
          ? _value.merchantServicePictureURL
          : merchantServicePictureURL // ignore: cast_nullable_to_non_nullable
              as String,
      merchantServicePictureURLBase64: freezed ==
              merchantServicePictureURLBase64
          ? _value.merchantServicePictureURLBase64
          : merchantServicePictureURLBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      merchantCategoryName: freezed == merchantCategoryName
          ? _value.merchantCategoryName
          : merchantCategoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      merchantSubcategoryName: freezed == merchantSubcategoryName
          ? _value.merchantSubcategoryName
          : merchantSubcategoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdDate: freezed == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      selectionOptions: null == selectionOptions
          ? _value._selectionOptions
          : selectionOptions // ignore: cast_nullable_to_non_nullable
              as List<SelectionOption>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MerchantServiceModelImpl implements _MerchantServiceModel {
  _$MerchantServiceModelImpl(
      {this.merchantServiceID = 0,
      this.merchantCategoryID = 0,
      this.merchantSubcategoryID = 0,
      this.merchantServiceName = '',
      this.merchantServiceDescription = "No description",
      this.amount = 0,
      this.ordinal = 0,
      this.merchantServiceBillingType = 0,
      this.recommendation = '',
      this.inclusion,
      this.isActive = true,
      this.noteToCustomer,
      this.baseFair = 0,
      this.freeDistanceTransportationFee = 0,
      this.perKilometerFee = 0,
      this.effectiveBeyondKilometer = 0,
      this.merchantServicePictureURL = '',
      this.merchantServicePictureURLBase64,
      this.merchantCategoryName,
      this.merchantSubcategoryName,
      this.createdDate,
      final List<SelectionOption> selectionOptions = const []})
      : _selectionOptions = selectionOptions;

  factory _$MerchantServiceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MerchantServiceModelImplFromJson(json);

  @override
  @JsonKey()
  final int merchantServiceID;
  @override
  @JsonKey()
  final int merchantCategoryID;
  @override
  @JsonKey()
  final int merchantSubcategoryID;
  @override
  @JsonKey()
  final String merchantServiceName;
  @override
  @JsonKey()
  final String merchantServiceDescription;
  @override
  @JsonKey()
  final int amount;
  @override
  @JsonKey()
  final int ordinal;
  @override
  @JsonKey()
  final int merchantServiceBillingType;
  @override
  @JsonKey()
  final String recommendation;
  @override
  final String? inclusion;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final String? noteToCustomer;
  @override
  @JsonKey()
  final int baseFair;
  @override
  @JsonKey()
  final int freeDistanceTransportationFee;
  @override
  @JsonKey()
  final int perKilometerFee;
  @override
  @JsonKey()
  final int effectiveBeyondKilometer;
  @override
  @JsonKey()
  final String merchantServicePictureURL;
  @override
  final String? merchantServicePictureURLBase64;
  @override
  final String? merchantCategoryName;
  @override
  final String? merchantSubcategoryName;
  @override
  final DateTime? createdDate;
  final List<SelectionOption> _selectionOptions;
  @override
  @JsonKey()
  List<SelectionOption> get selectionOptions {
    if (_selectionOptions is EqualUnmodifiableListView)
      return _selectionOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectionOptions);
  }

  @override
  String toString() {
    return 'MerchantServiceModel(merchantServiceID: $merchantServiceID, merchantCategoryID: $merchantCategoryID, merchantSubcategoryID: $merchantSubcategoryID, merchantServiceName: $merchantServiceName, merchantServiceDescription: $merchantServiceDescription, amount: $amount, ordinal: $ordinal, merchantServiceBillingType: $merchantServiceBillingType, recommendation: $recommendation, inclusion: $inclusion, isActive: $isActive, noteToCustomer: $noteToCustomer, baseFair: $baseFair, freeDistanceTransportationFee: $freeDistanceTransportationFee, perKilometerFee: $perKilometerFee, effectiveBeyondKilometer: $effectiveBeyondKilometer, merchantServicePictureURL: $merchantServicePictureURL, merchantServicePictureURLBase64: $merchantServicePictureURLBase64, merchantCategoryName: $merchantCategoryName, merchantSubcategoryName: $merchantSubcategoryName, createdDate: $createdDate, selectionOptions: $selectionOptions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MerchantServiceModelImpl &&
            (identical(other.merchantServiceID, merchantServiceID) ||
                other.merchantServiceID == merchantServiceID) &&
            (identical(other.merchantCategoryID, merchantCategoryID) ||
                other.merchantCategoryID == merchantCategoryID) &&
            (identical(other.merchantSubcategoryID, merchantSubcategoryID) ||
                other.merchantSubcategoryID == merchantSubcategoryID) &&
            (identical(other.merchantServiceName, merchantServiceName) ||
                other.merchantServiceName == merchantServiceName) &&
            (identical(other.merchantServiceDescription, merchantServiceDescription) ||
                other.merchantServiceDescription ==
                    merchantServiceDescription) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.ordinal, ordinal) || other.ordinal == ordinal) &&
            (identical(other.merchantServiceBillingType, merchantServiceBillingType) ||
                other.merchantServiceBillingType ==
                    merchantServiceBillingType) &&
            (identical(other.recommendation, recommendation) ||
                other.recommendation == recommendation) &&
            (identical(other.inclusion, inclusion) ||
                other.inclusion == inclusion) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.noteToCustomer, noteToCustomer) ||
                other.noteToCustomer == noteToCustomer) &&
            (identical(other.baseFair, baseFair) ||
                other.baseFair == baseFair) &&
            (identical(other.freeDistanceTransportationFee, freeDistanceTransportationFee) ||
                other.freeDistanceTransportationFee ==
                    freeDistanceTransportationFee) &&
            (identical(other.perKilometerFee, perKilometerFee) ||
                other.perKilometerFee == perKilometerFee) &&
            (identical(
                    other.effectiveBeyondKilometer, effectiveBeyondKilometer) ||
                other.effectiveBeyondKilometer == effectiveBeyondKilometer) &&
            (identical(other.merchantServicePictureURL, merchantServicePictureURL) ||
                other.merchantServicePictureURL == merchantServicePictureURL) &&
            (identical(other.merchantServicePictureURLBase64,
                    merchantServicePictureURLBase64) ||
                other.merchantServicePictureURLBase64 ==
                    merchantServicePictureURLBase64) &&
            (identical(other.merchantCategoryName, merchantCategoryName) ||
                other.merchantCategoryName == merchantCategoryName) &&
            (identical(other.merchantSubcategoryName, merchantSubcategoryName) ||
                other.merchantSubcategoryName == merchantSubcategoryName) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate) &&
            const DeepCollectionEquality()
                .equals(other._selectionOptions, _selectionOptions));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        merchantServiceID,
        merchantCategoryID,
        merchantSubcategoryID,
        merchantServiceName,
        merchantServiceDescription,
        amount,
        ordinal,
        merchantServiceBillingType,
        recommendation,
        inclusion,
        isActive,
        noteToCustomer,
        baseFair,
        freeDistanceTransportationFee,
        perKilometerFee,
        effectiveBeyondKilometer,
        merchantServicePictureURL,
        merchantServicePictureURLBase64,
        merchantCategoryName,
        merchantSubcategoryName,
        createdDate,
        const DeepCollectionEquality().hash(_selectionOptions)
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MerchantServiceModelImplCopyWith<_$MerchantServiceModelImpl>
      get copyWith =>
          __$$MerchantServiceModelImplCopyWithImpl<_$MerchantServiceModelImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MerchantServiceModelImplToJson(
      this,
    );
  }
}

abstract class _MerchantServiceModel implements MerchantServiceModel {
  factory _MerchantServiceModel(
          {final int merchantServiceID,
          final int merchantCategoryID,
          final int merchantSubcategoryID,
          final String merchantServiceName,
          final String merchantServiceDescription,
          final int amount,
          final int ordinal,
          final int merchantServiceBillingType,
          final String recommendation,
          final String? inclusion,
          final bool isActive,
          final String? noteToCustomer,
          final int baseFair,
          final int freeDistanceTransportationFee,
          final int perKilometerFee,
          final int effectiveBeyondKilometer,
          final String merchantServicePictureURL,
          final String? merchantServicePictureURLBase64,
          final String? merchantCategoryName,
          final String? merchantSubcategoryName,
          final DateTime? createdDate,
          final List<SelectionOption> selectionOptions}) =
      _$MerchantServiceModelImpl;

  factory _MerchantServiceModel.fromJson(Map<String, dynamic> json) =
      _$MerchantServiceModelImpl.fromJson;

  @override
  int get merchantServiceID;
  @override
  int get merchantCategoryID;
  @override
  int get merchantSubcategoryID;
  @override
  String get merchantServiceName;
  @override
  String get merchantServiceDescription;
  @override
  int get amount;
  @override
  int get ordinal;
  @override
  int get merchantServiceBillingType;
  @override
  String get recommendation;
  @override
  String? get inclusion;
  @override
  bool get isActive;
  @override
  String? get noteToCustomer;
  @override
  int get baseFair;
  @override
  int get freeDistanceTransportationFee;
  @override
  int get perKilometerFee;
  @override
  int get effectiveBeyondKilometer;
  @override
  String get merchantServicePictureURL;
  @override
  String? get merchantServicePictureURLBase64;
  @override
  String? get merchantCategoryName;
  @override
  String? get merchantSubcategoryName;
  @override
  DateTime? get createdDate;
  @override
  List<SelectionOption> get selectionOptions;
  @override
  @JsonKey(ignore: true)
  _$$MerchantServiceModelImplCopyWith<_$MerchantServiceModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SelectionOption _$SelectionOptionFromJson(Map<String, dynamic> json) {
  return _SelectionOption.fromJson(json);
}

/// @nodoc
mixin _$SelectionOption {
  int? get merchantServiceModelOptionID => throw _privateConstructorUsedError;
  int get merchantOptionID => throw _privateConstructorUsedError;
  String get merchantOptionName => throw _privateConstructorUsedError;
  bool get isRequired => throw _privateConstructorUsedError;
  int get minimumOption => throw _privateConstructorUsedError;
  int get maximumOption => throw _privateConstructorUsedError;
  int get ordinal => throw _privateConstructorUsedError;
  List<SelectionOptionItem> get selectedOptionItems =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SelectionOptionCopyWith<SelectionOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelectionOptionCopyWith<$Res> {
  factory $SelectionOptionCopyWith(
          SelectionOption value, $Res Function(SelectionOption) then) =
      _$SelectionOptionCopyWithImpl<$Res, SelectionOption>;
  @useResult
  $Res call(
      {int? merchantServiceModelOptionID,
      int merchantOptionID,
      String merchantOptionName,
      bool isRequired,
      int minimumOption,
      int maximumOption,
      int ordinal,
      List<SelectionOptionItem> selectedOptionItems});
}

/// @nodoc
class _$SelectionOptionCopyWithImpl<$Res, $Val extends SelectionOption>
    implements $SelectionOptionCopyWith<$Res> {
  _$SelectionOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantServiceModelOptionID = freezed,
    Object? merchantOptionID = null,
    Object? merchantOptionName = null,
    Object? isRequired = null,
    Object? minimumOption = null,
    Object? maximumOption = null,
    Object? ordinal = null,
    Object? selectedOptionItems = null,
  }) {
    return _then(_value.copyWith(
      merchantServiceModelOptionID: freezed == merchantServiceModelOptionID
          ? _value.merchantServiceModelOptionID
          : merchantServiceModelOptionID // ignore: cast_nullable_to_non_nullable
              as int?,
      merchantOptionID: null == merchantOptionID
          ? _value.merchantOptionID
          : merchantOptionID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionName: null == merchantOptionName
          ? _value.merchantOptionName
          : merchantOptionName // ignore: cast_nullable_to_non_nullable
              as String,
      isRequired: null == isRequired
          ? _value.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      minimumOption: null == minimumOption
          ? _value.minimumOption
          : minimumOption // ignore: cast_nullable_to_non_nullable
              as int,
      maximumOption: null == maximumOption
          ? _value.maximumOption
          : maximumOption // ignore: cast_nullable_to_non_nullable
              as int,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      selectedOptionItems: null == selectedOptionItems
          ? _value.selectedOptionItems
          : selectedOptionItems // ignore: cast_nullable_to_non_nullable
              as List<SelectionOptionItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SelectionOptionImplCopyWith<$Res>
    implements $SelectionOptionCopyWith<$Res> {
  factory _$$SelectionOptionImplCopyWith(_$SelectionOptionImpl value,
          $Res Function(_$SelectionOptionImpl) then) =
      __$$SelectionOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? merchantServiceModelOptionID,
      int merchantOptionID,
      String merchantOptionName,
      bool isRequired,
      int minimumOption,
      int maximumOption,
      int ordinal,
      List<SelectionOptionItem> selectedOptionItems});
}

/// @nodoc
class __$$SelectionOptionImplCopyWithImpl<$Res>
    extends _$SelectionOptionCopyWithImpl<$Res, _$SelectionOptionImpl>
    implements _$$SelectionOptionImplCopyWith<$Res> {
  __$$SelectionOptionImplCopyWithImpl(
      _$SelectionOptionImpl _value, $Res Function(_$SelectionOptionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantServiceModelOptionID = freezed,
    Object? merchantOptionID = null,
    Object? merchantOptionName = null,
    Object? isRequired = null,
    Object? minimumOption = null,
    Object? maximumOption = null,
    Object? ordinal = null,
    Object? selectedOptionItems = null,
  }) {
    return _then(_$SelectionOptionImpl(
      merchantServiceModelOptionID: freezed == merchantServiceModelOptionID
          ? _value.merchantServiceModelOptionID
          : merchantServiceModelOptionID // ignore: cast_nullable_to_non_nullable
              as int?,
      merchantOptionID: null == merchantOptionID
          ? _value.merchantOptionID
          : merchantOptionID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionName: null == merchantOptionName
          ? _value.merchantOptionName
          : merchantOptionName // ignore: cast_nullable_to_non_nullable
              as String,
      isRequired: null == isRequired
          ? _value.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      minimumOption: null == minimumOption
          ? _value.minimumOption
          : minimumOption // ignore: cast_nullable_to_non_nullable
              as int,
      maximumOption: null == maximumOption
          ? _value.maximumOption
          : maximumOption // ignore: cast_nullable_to_non_nullable
              as int,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      selectedOptionItems: null == selectedOptionItems
          ? _value._selectedOptionItems
          : selectedOptionItems // ignore: cast_nullable_to_non_nullable
              as List<SelectionOptionItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SelectionOptionImpl implements _SelectionOption {
  _$SelectionOptionImpl(
      {this.merchantServiceModelOptionID,
      required this.merchantOptionID,
      required this.merchantOptionName,
      required this.isRequired,
      required this.minimumOption,
      required this.maximumOption,
      required this.ordinal,
      required final List<SelectionOptionItem> selectedOptionItems})
      : _selectedOptionItems = selectedOptionItems;

  factory _$SelectionOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SelectionOptionImplFromJson(json);

  @override
  final int? merchantServiceModelOptionID;
  @override
  final int merchantOptionID;
  @override
  final String merchantOptionName;
  @override
  final bool isRequired;
  @override
  final int minimumOption;
  @override
  final int maximumOption;
  @override
  final int ordinal;
  final List<SelectionOptionItem> _selectedOptionItems;
  @override
  List<SelectionOptionItem> get selectedOptionItems {
    if (_selectedOptionItems is EqualUnmodifiableListView)
      return _selectedOptionItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedOptionItems);
  }

  @override
  String toString() {
    return 'SelectionOption(merchantServiceModelOptionID: $merchantServiceModelOptionID, merchantOptionID: $merchantOptionID, merchantOptionName: $merchantOptionName, isRequired: $isRequired, minimumOption: $minimumOption, maximumOption: $maximumOption, ordinal: $ordinal, selectedOptionItems: $selectedOptionItems)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectionOptionImpl &&
            (identical(other.merchantServiceModelOptionID,
                    merchantServiceModelOptionID) ||
                other.merchantServiceModelOptionID ==
                    merchantServiceModelOptionID) &&
            (identical(other.merchantOptionID, merchantOptionID) ||
                other.merchantOptionID == merchantOptionID) &&
            (identical(other.merchantOptionName, merchantOptionName) ||
                other.merchantOptionName == merchantOptionName) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired) &&
            (identical(other.minimumOption, minimumOption) ||
                other.minimumOption == minimumOption) &&
            (identical(other.maximumOption, maximumOption) ||
                other.maximumOption == maximumOption) &&
            (identical(other.ordinal, ordinal) || other.ordinal == ordinal) &&
            const DeepCollectionEquality()
                .equals(other._selectedOptionItems, _selectedOptionItems));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      merchantServiceModelOptionID,
      merchantOptionID,
      merchantOptionName,
      isRequired,
      minimumOption,
      maximumOption,
      ordinal,
      const DeepCollectionEquality().hash(_selectedOptionItems));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectionOptionImplCopyWith<_$SelectionOptionImpl> get copyWith =>
      __$$SelectionOptionImplCopyWithImpl<_$SelectionOptionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SelectionOptionImplToJson(
      this,
    );
  }
}

abstract class _SelectionOption implements SelectionOption {
  factory _SelectionOption(
          {final int? merchantServiceModelOptionID,
          required final int merchantOptionID,
          required final String merchantOptionName,
          required final bool isRequired,
          required final int minimumOption,
          required final int maximumOption,
          required final int ordinal,
          required final List<SelectionOptionItem> selectedOptionItems}) =
      _$SelectionOptionImpl;

  factory _SelectionOption.fromJson(Map<String, dynamic> json) =
      _$SelectionOptionImpl.fromJson;

  @override
  int? get merchantServiceModelOptionID;
  @override
  int get merchantOptionID;
  @override
  String get merchantOptionName;
  @override
  bool get isRequired;
  @override
  int get minimumOption;
  @override
  int get maximumOption;
  @override
  int get ordinal;
  @override
  List<SelectionOptionItem> get selectedOptionItems;
  @override
  @JsonKey(ignore: true)
  _$$SelectionOptionImplCopyWith<_$SelectionOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SelectionOptionItem _$SelectionOptionItemFromJson(Map<String, dynamic> json) {
  return _SelectionOptionItem.fromJson(json);
}

/// @nodoc
mixin _$SelectionOptionItem {
  int get merchantOptionItemID => throw _privateConstructorUsedError;
  int get merchantOptionID => throw _privateConstructorUsedError;
  String get merchantOptionItemName => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  int get ordinal => throw _privateConstructorUsedError;
  int? get merchantServiceModelBillingType =>
      throw _privateConstructorUsedError;
  int get baseFair => throw _privateConstructorUsedError;
  int get freeDistanceTransportationFee => throw _privateConstructorUsedError;
  int get perKilometerFee => throw _privateConstructorUsedError;
  int get effectiveBeyondKilometer => throw _privateConstructorUsedError;
  DateTime get createdDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SelectionOptionItemCopyWith<SelectionOptionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelectionOptionItemCopyWith<$Res> {
  factory $SelectionOptionItemCopyWith(
          SelectionOptionItem value, $Res Function(SelectionOptionItem) then) =
      _$SelectionOptionItemCopyWithImpl<$Res, SelectionOptionItem>;
  @useResult
  $Res call(
      {int merchantOptionItemID,
      int merchantOptionID,
      String merchantOptionItemName,
      int amount,
      int ordinal,
      int? merchantServiceModelBillingType,
      int baseFair,
      int freeDistanceTransportationFee,
      int perKilometerFee,
      int effectiveBeyondKilometer,
      DateTime createdDate});
}

/// @nodoc
class _$SelectionOptionItemCopyWithImpl<$Res, $Val extends SelectionOptionItem>
    implements $SelectionOptionItemCopyWith<$Res> {
  _$SelectionOptionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantOptionItemID = null,
    Object? merchantOptionID = null,
    Object? merchantOptionItemName = null,
    Object? amount = null,
    Object? ordinal = null,
    Object? merchantServiceModelBillingType = freezed,
    Object? baseFair = null,
    Object? freeDistanceTransportationFee = null,
    Object? perKilometerFee = null,
    Object? effectiveBeyondKilometer = null,
    Object? createdDate = null,
  }) {
    return _then(_value.copyWith(
      merchantOptionItemID: null == merchantOptionItemID
          ? _value.merchantOptionItemID
          : merchantOptionItemID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionID: null == merchantOptionID
          ? _value.merchantOptionID
          : merchantOptionID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionItemName: null == merchantOptionItemName
          ? _value.merchantOptionItemName
          : merchantOptionItemName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceModelBillingType: freezed ==
              merchantServiceModelBillingType
          ? _value.merchantServiceModelBillingType
          : merchantServiceModelBillingType // ignore: cast_nullable_to_non_nullable
              as int?,
      baseFair: null == baseFair
          ? _value.baseFair
          : baseFair // ignore: cast_nullable_to_non_nullable
              as int,
      freeDistanceTransportationFee: null == freeDistanceTransportationFee
          ? _value.freeDistanceTransportationFee
          : freeDistanceTransportationFee // ignore: cast_nullable_to_non_nullable
              as int,
      perKilometerFee: null == perKilometerFee
          ? _value.perKilometerFee
          : perKilometerFee // ignore: cast_nullable_to_non_nullable
              as int,
      effectiveBeyondKilometer: null == effectiveBeyondKilometer
          ? _value.effectiveBeyondKilometer
          : effectiveBeyondKilometer // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SelectionOptionItemImplCopyWith<$Res>
    implements $SelectionOptionItemCopyWith<$Res> {
  factory _$$SelectionOptionItemImplCopyWith(_$SelectionOptionItemImpl value,
          $Res Function(_$SelectionOptionItemImpl) then) =
      __$$SelectionOptionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int merchantOptionItemID,
      int merchantOptionID,
      String merchantOptionItemName,
      int amount,
      int ordinal,
      int? merchantServiceModelBillingType,
      int baseFair,
      int freeDistanceTransportationFee,
      int perKilometerFee,
      int effectiveBeyondKilometer,
      DateTime createdDate});
}

/// @nodoc
class __$$SelectionOptionItemImplCopyWithImpl<$Res>
    extends _$SelectionOptionItemCopyWithImpl<$Res, _$SelectionOptionItemImpl>
    implements _$$SelectionOptionItemImplCopyWith<$Res> {
  __$$SelectionOptionItemImplCopyWithImpl(_$SelectionOptionItemImpl _value,
      $Res Function(_$SelectionOptionItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantOptionItemID = null,
    Object? merchantOptionID = null,
    Object? merchantOptionItemName = null,
    Object? amount = null,
    Object? ordinal = null,
    Object? merchantServiceModelBillingType = freezed,
    Object? baseFair = null,
    Object? freeDistanceTransportationFee = null,
    Object? perKilometerFee = null,
    Object? effectiveBeyondKilometer = null,
    Object? createdDate = null,
  }) {
    return _then(_$SelectionOptionItemImpl(
      merchantOptionItemID: null == merchantOptionItemID
          ? _value.merchantOptionItemID
          : merchantOptionItemID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionID: null == merchantOptionID
          ? _value.merchantOptionID
          : merchantOptionID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionItemName: null == merchantOptionItemName
          ? _value.merchantOptionItemName
          : merchantOptionItemName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceModelBillingType: freezed ==
              merchantServiceModelBillingType
          ? _value.merchantServiceModelBillingType
          : merchantServiceModelBillingType // ignore: cast_nullable_to_non_nullable
              as int?,
      baseFair: null == baseFair
          ? _value.baseFair
          : baseFair // ignore: cast_nullable_to_non_nullable
              as int,
      freeDistanceTransportationFee: null == freeDistanceTransportationFee
          ? _value.freeDistanceTransportationFee
          : freeDistanceTransportationFee // ignore: cast_nullable_to_non_nullable
              as int,
      perKilometerFee: null == perKilometerFee
          ? _value.perKilometerFee
          : perKilometerFee // ignore: cast_nullable_to_non_nullable
              as int,
      effectiveBeyondKilometer: null == effectiveBeyondKilometer
          ? _value.effectiveBeyondKilometer
          : effectiveBeyondKilometer // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SelectionOptionItemImpl implements _SelectionOptionItem {
  _$SelectionOptionItemImpl(
      {required this.merchantOptionItemID,
      required this.merchantOptionID,
      required this.merchantOptionItemName,
      required this.amount,
      required this.ordinal,
      this.merchantServiceModelBillingType,
      required this.baseFair,
      required this.freeDistanceTransportationFee,
      required this.perKilometerFee,
      required this.effectiveBeyondKilometer,
      required this.createdDate});

  factory _$SelectionOptionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SelectionOptionItemImplFromJson(json);

  @override
  final int merchantOptionItemID;
  @override
  final int merchantOptionID;
  @override
  final String merchantOptionItemName;
  @override
  final int amount;
  @override
  final int ordinal;
  @override
  final int? merchantServiceModelBillingType;
  @override
  final int baseFair;
  @override
  final int freeDistanceTransportationFee;
  @override
  final int perKilometerFee;
  @override
  final int effectiveBeyondKilometer;
  @override
  final DateTime createdDate;

  @override
  String toString() {
    return 'SelectionOptionItem(merchantOptionItemID: $merchantOptionItemID, merchantOptionID: $merchantOptionID, merchantOptionItemName: $merchantOptionItemName, amount: $amount, ordinal: $ordinal, merchantServiceModelBillingType: $merchantServiceModelBillingType, baseFair: $baseFair, freeDistanceTransportationFee: $freeDistanceTransportationFee, perKilometerFee: $perKilometerFee, effectiveBeyondKilometer: $effectiveBeyondKilometer, createdDate: $createdDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectionOptionItemImpl &&
            (identical(other.merchantOptionItemID, merchantOptionItemID) ||
                other.merchantOptionItemID == merchantOptionItemID) &&
            (identical(other.merchantOptionID, merchantOptionID) ||
                other.merchantOptionID == merchantOptionID) &&
            (identical(other.merchantOptionItemName, merchantOptionItemName) ||
                other.merchantOptionItemName == merchantOptionItemName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.ordinal, ordinal) || other.ordinal == ordinal) &&
            (identical(other.merchantServiceModelBillingType,
                    merchantServiceModelBillingType) ||
                other.merchantServiceModelBillingType ==
                    merchantServiceModelBillingType) &&
            (identical(other.baseFair, baseFair) ||
                other.baseFair == baseFair) &&
            (identical(other.freeDistanceTransportationFee,
                    freeDistanceTransportationFee) ||
                other.freeDistanceTransportationFee ==
                    freeDistanceTransportationFee) &&
            (identical(other.perKilometerFee, perKilometerFee) ||
                other.perKilometerFee == perKilometerFee) &&
            (identical(
                    other.effectiveBeyondKilometer, effectiveBeyondKilometer) ||
                other.effectiveBeyondKilometer == effectiveBeyondKilometer) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      merchantOptionItemID,
      merchantOptionID,
      merchantOptionItemName,
      amount,
      ordinal,
      merchantServiceModelBillingType,
      baseFair,
      freeDistanceTransportationFee,
      perKilometerFee,
      effectiveBeyondKilometer,
      createdDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectionOptionItemImplCopyWith<_$SelectionOptionItemImpl> get copyWith =>
      __$$SelectionOptionItemImplCopyWithImpl<_$SelectionOptionItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SelectionOptionItemImplToJson(
      this,
    );
  }
}

abstract class _SelectionOptionItem implements SelectionOptionItem {
  factory _SelectionOptionItem(
      {required final int merchantOptionItemID,
      required final int merchantOptionID,
      required final String merchantOptionItemName,
      required final int amount,
      required final int ordinal,
      final int? merchantServiceModelBillingType,
      required final int baseFair,
      required final int freeDistanceTransportationFee,
      required final int perKilometerFee,
      required final int effectiveBeyondKilometer,
      required final DateTime createdDate}) = _$SelectionOptionItemImpl;

  factory _SelectionOptionItem.fromJson(Map<String, dynamic> json) =
      _$SelectionOptionItemImpl.fromJson;

  @override
  int get merchantOptionItemID;
  @override
  int get merchantOptionID;
  @override
  String get merchantOptionItemName;
  @override
  int get amount;
  @override
  int get ordinal;
  @override
  int? get merchantServiceModelBillingType;
  @override
  int get baseFair;
  @override
  int get freeDistanceTransportationFee;
  @override
  int get perKilometerFee;
  @override
  int get effectiveBeyondKilometer;
  @override
  DateTime get createdDate;
  @override
  @JsonKey(ignore: true)
  _$$SelectionOptionItemImplCopyWith<_$SelectionOptionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
