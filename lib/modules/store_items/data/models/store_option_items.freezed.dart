// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_option_items.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StoreOptionItem _$StoreOptionItemFromJson(Map<String, dynamic> json) {
  return _StoreOptionItem.fromJson(json);
}

/// @nodoc
mixin _$StoreOptionItem {
  int get merchantOptionItemID => throw _privateConstructorUsedError;
  int get merchantOptionID => throw _privateConstructorUsedError;
  String get merchantServiceID => throw _privateConstructorUsedError;
  String get merchantOptionItemName => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  int get ordinal => throw _privateConstructorUsedError;
  double get baseFair => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StoreOptionItemCopyWith<StoreOptionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreOptionItemCopyWith<$Res> {
  factory $StoreOptionItemCopyWith(
          StoreOptionItem value, $Res Function(StoreOptionItem) then) =
      _$StoreOptionItemCopyWithImpl<$Res, StoreOptionItem>;
  @useResult
  $Res call(
      {int merchantOptionItemID,
      int merchantOptionID,
      String merchantServiceID,
      String merchantOptionItemName,
      double amount,
      int ordinal,
      double baseFair});
}

/// @nodoc
class _$StoreOptionItemCopyWithImpl<$Res, $Val extends StoreOptionItem>
    implements $StoreOptionItemCopyWith<$Res> {
  _$StoreOptionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantOptionItemID = null,
    Object? merchantOptionID = null,
    Object? merchantServiceID = null,
    Object? merchantOptionItemName = null,
    Object? amount = null,
    Object? ordinal = null,
    Object? baseFair = null,
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
      merchantServiceID: null == merchantServiceID
          ? _value.merchantServiceID
          : merchantServiceID // ignore: cast_nullable_to_non_nullable
              as String,
      merchantOptionItemName: null == merchantOptionItemName
          ? _value.merchantOptionItemName
          : merchantOptionItemName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      baseFair: null == baseFair
          ? _value.baseFair
          : baseFair // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreOptionItemImplCopyWith<$Res>
    implements $StoreOptionItemCopyWith<$Res> {
  factory _$$StoreOptionItemImplCopyWith(_$StoreOptionItemImpl value,
          $Res Function(_$StoreOptionItemImpl) then) =
      __$$StoreOptionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int merchantOptionItemID,
      int merchantOptionID,
      String merchantServiceID,
      String merchantOptionItemName,
      double amount,
      int ordinal,
      double baseFair});
}

/// @nodoc
class __$$StoreOptionItemImplCopyWithImpl<$Res>
    extends _$StoreOptionItemCopyWithImpl<$Res, _$StoreOptionItemImpl>
    implements _$$StoreOptionItemImplCopyWith<$Res> {
  __$$StoreOptionItemImplCopyWithImpl(
      _$StoreOptionItemImpl _value, $Res Function(_$StoreOptionItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantOptionItemID = null,
    Object? merchantOptionID = null,
    Object? merchantServiceID = null,
    Object? merchantOptionItemName = null,
    Object? amount = null,
    Object? ordinal = null,
    Object? baseFair = null,
  }) {
    return _then(_$StoreOptionItemImpl(
      merchantOptionItemID: null == merchantOptionItemID
          ? _value.merchantOptionItemID
          : merchantOptionItemID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantOptionID: null == merchantOptionID
          ? _value.merchantOptionID
          : merchantOptionID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantServiceID: null == merchantServiceID
          ? _value.merchantServiceID
          : merchantServiceID // ignore: cast_nullable_to_non_nullable
              as String,
      merchantOptionItemName: null == merchantOptionItemName
          ? _value.merchantOptionItemName
          : merchantOptionItemName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      baseFair: null == baseFair
          ? _value.baseFair
          : baseFair // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreOptionItemImpl implements _StoreOptionItem {
  const _$StoreOptionItemImpl(
      {this.merchantOptionItemID = 0,
      this.merchantOptionID = 0,
      this.merchantServiceID = "0",
      required this.merchantOptionItemName,
      required this.amount,
      this.ordinal = 0,
      required this.baseFair});

  factory _$StoreOptionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreOptionItemImplFromJson(json);

  @override
  @JsonKey()
  final int merchantOptionItemID;
  @override
  @JsonKey()
  final int merchantOptionID;
  @override
  @JsonKey()
  final String merchantServiceID;
  @override
  final String merchantOptionItemName;
  @override
  final double amount;
  @override
  @JsonKey()
  final int ordinal;
  @override
  final double baseFair;

  @override
  String toString() {
    return 'StoreOptionItem(merchantOptionItemID: $merchantOptionItemID, merchantOptionID: $merchantOptionID, merchantServiceID: $merchantServiceID, merchantOptionItemName: $merchantOptionItemName, amount: $amount, ordinal: $ordinal, baseFair: $baseFair)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreOptionItemImpl &&
            (identical(other.merchantOptionItemID, merchantOptionItemID) ||
                other.merchantOptionItemID == merchantOptionItemID) &&
            (identical(other.merchantOptionID, merchantOptionID) ||
                other.merchantOptionID == merchantOptionID) &&
            (identical(other.merchantServiceID, merchantServiceID) ||
                other.merchantServiceID == merchantServiceID) &&
            (identical(other.merchantOptionItemName, merchantOptionItemName) ||
                other.merchantOptionItemName == merchantOptionItemName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.ordinal, ordinal) || other.ordinal == ordinal) &&
            (identical(other.baseFair, baseFair) ||
                other.baseFair == baseFair));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      merchantOptionItemID,
      merchantOptionID,
      merchantServiceID,
      merchantOptionItemName,
      amount,
      ordinal,
      baseFair);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreOptionItemImplCopyWith<_$StoreOptionItemImpl> get copyWith =>
      __$$StoreOptionItemImplCopyWithImpl<_$StoreOptionItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreOptionItemImplToJson(
      this,
    );
  }
}

abstract class _StoreOptionItem implements StoreOptionItem {
  const factory _StoreOptionItem(
      {final int merchantOptionItemID,
      final int merchantOptionID,
      final String merchantServiceID,
      required final String merchantOptionItemName,
      required final double amount,
      final int ordinal,
      required final double baseFair}) = _$StoreOptionItemImpl;

  factory _StoreOptionItem.fromJson(Map<String, dynamic> json) =
      _$StoreOptionItemImpl.fromJson;

  @override
  int get merchantOptionItemID;
  @override
  int get merchantOptionID;
  @override
  String get merchantServiceID;
  @override
  String get merchantOptionItemName;
  @override
  double get amount;
  @override
  int get ordinal;
  @override
  double get baseFair;
  @override
  @JsonKey(ignore: true)
  _$$StoreOptionItemImplCopyWith<_$StoreOptionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
