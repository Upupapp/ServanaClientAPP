// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_order_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JobOrderItem _$JobOrderItemFromJson(Map<String, dynamic> json) {
  return _JobOrderItem.fromJson(json);
}

/// @nodoc
mixin _$JobOrderItem {
  int get jobOrderItemID => throw _privateConstructorUsedError;
  String? get serviceId => throw _privateConstructorUsedError;
  String get serviceName => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  double get transportaion => throw _privateConstructorUsedError;
  double get discount => throw _privateConstructorUsedError;
  List<SelectedOption> get selectedOptions =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $JobOrderItemCopyWith<JobOrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JobOrderItemCopyWith<$Res> {
  factory $JobOrderItemCopyWith(
          JobOrderItem value, $Res Function(JobOrderItem) then) =
      _$JobOrderItemCopyWithImpl<$Res, JobOrderItem>;
  @useResult
  $Res call(
      {int jobOrderItemID,
      String? serviceId,
      String serviceName,
      int quantity,
      String? note,
      double amount,
      double transportaion,
      double discount,
      List<SelectedOption> selectedOptions});
}

/// @nodoc
class _$JobOrderItemCopyWithImpl<$Res, $Val extends JobOrderItem>
    implements $JobOrderItemCopyWith<$Res> {
  _$JobOrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobOrderItemID = null,
    Object? serviceId = freezed,
    Object? serviceName = null,
    Object? quantity = null,
    Object? note = freezed,
    Object? amount = null,
    Object? transportaion = null,
    Object? discount = null,
    Object? selectedOptions = null,
  }) {
    return _then(_value.copyWith(
      jobOrderItemID: null == jobOrderItemID
          ? _value.jobOrderItemID
          : jobOrderItemID // ignore: cast_nullable_to_non_nullable
              as int,
      serviceId: freezed == serviceId
          ? _value.serviceId
          : serviceId // ignore: cast_nullable_to_non_nullable
              as String?,
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      transportaion: null == transportaion
          ? _value.transportaion
          : transportaion // ignore: cast_nullable_to_non_nullable
              as double,
      discount: null == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as double,
      selectedOptions: null == selectedOptions
          ? _value.selectedOptions
          : selectedOptions // ignore: cast_nullable_to_non_nullable
              as List<SelectedOption>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JobOrderItemImplCopyWith<$Res>
    implements $JobOrderItemCopyWith<$Res> {
  factory _$$JobOrderItemImplCopyWith(
          _$JobOrderItemImpl value, $Res Function(_$JobOrderItemImpl) then) =
      __$$JobOrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int jobOrderItemID,
      String? serviceId,
      String serviceName,
      int quantity,
      String? note,
      double amount,
      double transportaion,
      double discount,
      List<SelectedOption> selectedOptions});
}

/// @nodoc
class __$$JobOrderItemImplCopyWithImpl<$Res>
    extends _$JobOrderItemCopyWithImpl<$Res, _$JobOrderItemImpl>
    implements _$$JobOrderItemImplCopyWith<$Res> {
  __$$JobOrderItemImplCopyWithImpl(
      _$JobOrderItemImpl _value, $Res Function(_$JobOrderItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobOrderItemID = null,
    Object? serviceId = freezed,
    Object? serviceName = null,
    Object? quantity = null,
    Object? note = freezed,
    Object? amount = null,
    Object? transportaion = null,
    Object? discount = null,
    Object? selectedOptions = null,
  }) {
    return _then(_$JobOrderItemImpl(
      jobOrderItemID: null == jobOrderItemID
          ? _value.jobOrderItemID
          : jobOrderItemID // ignore: cast_nullable_to_non_nullable
              as int,
      serviceId: freezed == serviceId
          ? _value.serviceId
          : serviceId // ignore: cast_nullable_to_non_nullable
              as String?,
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      transportaion: null == transportaion
          ? _value.transportaion
          : transportaion // ignore: cast_nullable_to_non_nullable
              as double,
      discount: null == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as double,
      selectedOptions: null == selectedOptions
          ? _value._selectedOptions
          : selectedOptions // ignore: cast_nullable_to_non_nullable
              as List<SelectedOption>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JobOrderItemImpl implements _JobOrderItem {
  const _$JobOrderItemImpl(
      {required this.jobOrderItemID,
      this.serviceId,
      required this.serviceName,
      required this.quantity,
      this.note,
      required this.amount,
      this.transportaion = 0,
      required this.discount,
      required final List<SelectedOption> selectedOptions})
      : _selectedOptions = selectedOptions;

  factory _$JobOrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$JobOrderItemImplFromJson(json);

  @override
  final int jobOrderItemID;
  @override
  final String? serviceId;
  @override
  final String serviceName;
  @override
  final int quantity;
  @override
  final String? note;
  @override
  final double amount;
  @override
  @JsonKey()
  final double transportaion;
  @override
  final double discount;
  final List<SelectedOption> _selectedOptions;
  @override
  List<SelectedOption> get selectedOptions {
    if (_selectedOptions is EqualUnmodifiableListView) return _selectedOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedOptions);
  }

  @override
  String toString() {
    return 'JobOrderItem(jobOrderItemID: $jobOrderItemID, serviceId: $serviceId, serviceName: $serviceName, quantity: $quantity, note: $note, amount: $amount, transportaion: $transportaion, discount: $discount, selectedOptions: $selectedOptions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JobOrderItemImpl &&
            (identical(other.jobOrderItemID, jobOrderItemID) ||
                other.jobOrderItemID == jobOrderItemID) &&
            (identical(other.serviceId, serviceId) ||
                other.serviceId == serviceId) &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.transportaion, transportaion) ||
                other.transportaion == transportaion) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            const DeepCollectionEquality()
                .equals(other._selectedOptions, _selectedOptions));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      jobOrderItemID,
      serviceId,
      serviceName,
      quantity,
      note,
      amount,
      transportaion,
      discount,
      const DeepCollectionEquality().hash(_selectedOptions));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JobOrderItemImplCopyWith<_$JobOrderItemImpl> get copyWith =>
      __$$JobOrderItemImplCopyWithImpl<_$JobOrderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JobOrderItemImplToJson(
      this,
    );
  }
}

abstract class _JobOrderItem implements JobOrderItem {
  const factory _JobOrderItem(
          {required final int jobOrderItemID,
          final String? serviceId,
          required final String serviceName,
          required final int quantity,
          final String? note,
          required final double amount,
          final double transportaion,
          required final double discount,
          required final List<SelectedOption> selectedOptions}) =
      _$JobOrderItemImpl;

  factory _JobOrderItem.fromJson(Map<String, dynamic> json) =
      _$JobOrderItemImpl.fromJson;

  @override
  int get jobOrderItemID;
  @override
  String? get serviceId;
  @override
  String get serviceName;
  @override
  int get quantity;
  @override
  String? get note;
  @override
  double get amount;
  @override
  double get transportaion;
  @override
  double get discount;
  @override
  List<SelectedOption> get selectedOptions;
  @override
  @JsonKey(ignore: true)
  _$$JobOrderItemImplCopyWith<_$JobOrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SelectedOption _$SelectedOptionFromJson(Map<String, dynamic> json) {
  return _SelectedOption.fromJson(json);
}

/// @nodoc
mixin _$SelectedOption {
  int get jobOrderOptionItemID => throw _privateConstructorUsedError;
  int get merchantOptionItemID => throw _privateConstructorUsedError;
  int get merchantServiceID => throw _privateConstructorUsedError;
  double get optionAmount => throw _privateConstructorUsedError;
  double get transportaion => throw _privateConstructorUsedError;
  String get merchantOptionItemName => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SelectedOptionCopyWith<SelectedOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelectedOptionCopyWith<$Res> {
  factory $SelectedOptionCopyWith(
          SelectedOption value, $Res Function(SelectedOption) then) =
      _$SelectedOptionCopyWithImpl<$Res, SelectedOption>;
  @useResult
  $Res call(
      {int jobOrderOptionItemID,
      int merchantOptionItemID,
      int merchantServiceID,
      double optionAmount,
      double transportaion,
      String merchantOptionItemName,
      int quantity});
}

/// @nodoc
class _$SelectedOptionCopyWithImpl<$Res, $Val extends SelectedOption>
    implements $SelectedOptionCopyWith<$Res> {
  _$SelectedOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobOrderOptionItemID = null,
    Object? merchantOptionItemID = null,
    Object? merchantServiceID = null,
    Object? optionAmount = null,
    Object? transportaion = null,
    Object? merchantOptionItemName = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      jobOrderOptionItemID: null == jobOrderOptionItemID
          ? _value.jobOrderOptionItemID
          : jobOrderOptionItemID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionItemID: null == merchantOptionItemID
          ? _value.merchantOptionItemID
          : merchantOptionItemID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceID: null == merchantServiceID
          ? _value.merchantServiceID
          : merchantServiceID // ignore: cast_nullable_to_non_nullable
              as int,
      optionAmount: null == optionAmount
          ? _value.optionAmount
          : optionAmount // ignore: cast_nullable_to_non_nullable
              as double,
      transportaion: null == transportaion
          ? _value.transportaion
          : transportaion // ignore: cast_nullable_to_non_nullable
              as double,
      merchantOptionItemName: null == merchantOptionItemName
          ? _value.merchantOptionItemName
          : merchantOptionItemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SelectedOptionImplCopyWith<$Res>
    implements $SelectedOptionCopyWith<$Res> {
  factory _$$SelectedOptionImplCopyWith(_$SelectedOptionImpl value,
          $Res Function(_$SelectedOptionImpl) then) =
      __$$SelectedOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int jobOrderOptionItemID,
      int merchantOptionItemID,
      int merchantServiceID,
      double optionAmount,
      double transportaion,
      String merchantOptionItemName,
      int quantity});
}

/// @nodoc
class __$$SelectedOptionImplCopyWithImpl<$Res>
    extends _$SelectedOptionCopyWithImpl<$Res, _$SelectedOptionImpl>
    implements _$$SelectedOptionImplCopyWith<$Res> {
  __$$SelectedOptionImplCopyWithImpl(
      _$SelectedOptionImpl _value, $Res Function(_$SelectedOptionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? jobOrderOptionItemID = null,
    Object? merchantOptionItemID = null,
    Object? merchantServiceID = null,
    Object? optionAmount = null,
    Object? transportaion = null,
    Object? merchantOptionItemName = null,
    Object? quantity = null,
  }) {
    return _then(_$SelectedOptionImpl(
      jobOrderOptionItemID: null == jobOrderOptionItemID
          ? _value.jobOrderOptionItemID
          : jobOrderOptionItemID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionItemID: null == merchantOptionItemID
          ? _value.merchantOptionItemID
          : merchantOptionItemID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceID: null == merchantServiceID
          ? _value.merchantServiceID
          : merchantServiceID // ignore: cast_nullable_to_non_nullable
              as int,
      optionAmount: null == optionAmount
          ? _value.optionAmount
          : optionAmount // ignore: cast_nullable_to_non_nullable
              as double,
      transportaion: null == transportaion
          ? _value.transportaion
          : transportaion // ignore: cast_nullable_to_non_nullable
              as double,
      merchantOptionItemName: null == merchantOptionItemName
          ? _value.merchantOptionItemName
          : merchantOptionItemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SelectedOptionImpl implements _SelectedOption {
  const _$SelectedOptionImpl(
      {required this.jobOrderOptionItemID,
      this.merchantOptionItemID = 0,
      required this.merchantServiceID,
      this.optionAmount = 0,
      this.transportaion = 0,
      required this.merchantOptionItemName,
      required this.quantity});

  factory _$SelectedOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SelectedOptionImplFromJson(json);

  @override
  final int jobOrderOptionItemID;
  @override
  @JsonKey()
  final int merchantOptionItemID;
  @override
  final int merchantServiceID;
  @override
  @JsonKey()
  final double optionAmount;
  @override
  @JsonKey()
  final double transportaion;
  @override
  final String merchantOptionItemName;
  @override
  final int quantity;

  @override
  String toString() {
    return 'SelectedOption(jobOrderOptionItemID: $jobOrderOptionItemID, merchantOptionItemID: $merchantOptionItemID, merchantServiceID: $merchantServiceID, optionAmount: $optionAmount, transportaion: $transportaion, merchantOptionItemName: $merchantOptionItemName, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectedOptionImpl &&
            (identical(other.jobOrderOptionItemID, jobOrderOptionItemID) ||
                other.jobOrderOptionItemID == jobOrderOptionItemID) &&
            (identical(other.merchantOptionItemID, merchantOptionItemID) ||
                other.merchantOptionItemID == merchantOptionItemID) &&
            (identical(other.merchantServiceID, merchantServiceID) ||
                other.merchantServiceID == merchantServiceID) &&
            (identical(other.optionAmount, optionAmount) ||
                other.optionAmount == optionAmount) &&
            (identical(other.transportaion, transportaion) ||
                other.transportaion == transportaion) &&
            (identical(other.merchantOptionItemName, merchantOptionItemName) ||
                other.merchantOptionItemName == merchantOptionItemName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      jobOrderOptionItemID,
      merchantOptionItemID,
      merchantServiceID,
      optionAmount,
      transportaion,
      merchantOptionItemName,
      quantity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectedOptionImplCopyWith<_$SelectedOptionImpl> get copyWith =>
      __$$SelectedOptionImplCopyWithImpl<_$SelectedOptionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SelectedOptionImplToJson(
      this,
    );
  }
}

abstract class _SelectedOption implements SelectedOption {
  const factory _SelectedOption(
      {required final int jobOrderOptionItemID,
      final int merchantOptionItemID,
      required final int merchantServiceID,
      final double optionAmount,
      final double transportaion,
      required final String merchantOptionItemName,
      required final int quantity}) = _$SelectedOptionImpl;

  factory _SelectedOption.fromJson(Map<String, dynamic> json) =
      _$SelectedOptionImpl.fromJson;

  @override
  int get jobOrderOptionItemID;
  @override
  int get merchantOptionItemID;
  @override
  int get merchantServiceID;
  @override
  double get optionAmount;
  @override
  double get transportaion;
  @override
  String get merchantOptionItemName;
  @override
  int get quantity;
  @override
  @JsonKey(ignore: true)
  _$$SelectedOptionImplCopyWith<_$SelectedOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
