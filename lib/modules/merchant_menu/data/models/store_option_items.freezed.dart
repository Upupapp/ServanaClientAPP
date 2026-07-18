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
  int get id => throw _privateConstructorUsedError;
  int? get serviceId => throw _privateConstructorUsedError;
  int? get serviceOptionGroupId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  double get transportation => throw _privateConstructorUsedError;
  bool get addedByMerchant => throw _privateConstructorUsedError;

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
      {int id,
      int? serviceId,
      int? serviceOptionGroupId,
      String name,
      double price,
      double transportation,
      bool addedByMerchant});
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
    Object? id = null,
    Object? serviceId = freezed,
    Object? serviceOptionGroupId = freezed,
    Object? name = null,
    Object? price = null,
    Object? transportation = null,
    Object? addedByMerchant = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      serviceId: freezed == serviceId
          ? _value.serviceId
          : serviceId // ignore: cast_nullable_to_non_nullable
              as int?,
      serviceOptionGroupId: freezed == serviceOptionGroupId
          ? _value.serviceOptionGroupId
          : serviceOptionGroupId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      transportation: null == transportation
          ? _value.transportation
          : transportation // ignore: cast_nullable_to_non_nullable
              as double,
      addedByMerchant: null == addedByMerchant
          ? _value.addedByMerchant
          : addedByMerchant // ignore: cast_nullable_to_non_nullable
              as bool,
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
      {int id,
      int? serviceId,
      int? serviceOptionGroupId,
      String name,
      double price,
      double transportation,
      bool addedByMerchant});
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
    Object? id = null,
    Object? serviceId = freezed,
    Object? serviceOptionGroupId = freezed,
    Object? name = null,
    Object? price = null,
    Object? transportation = null,
    Object? addedByMerchant = null,
  }) {
    return _then(_$StoreOptionItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      serviceId: freezed == serviceId
          ? _value.serviceId
          : serviceId // ignore: cast_nullable_to_non_nullable
              as int?,
      serviceOptionGroupId: freezed == serviceOptionGroupId
          ? _value.serviceOptionGroupId
          : serviceOptionGroupId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      transportation: null == transportation
          ? _value.transportation
          : transportation // ignore: cast_nullable_to_non_nullable
              as double,
      addedByMerchant: null == addedByMerchant
          ? _value.addedByMerchant
          : addedByMerchant // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreOptionItemImpl implements _StoreOptionItem {
  const _$StoreOptionItemImpl(
      {required this.id,
      this.serviceId,
      this.serviceOptionGroupId,
      required this.name,
      required this.price,
      required this.transportation,
      this.addedByMerchant = false});

  factory _$StoreOptionItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreOptionItemImplFromJson(json);

  @override
  final int id;
  @override
  final int? serviceId;
  @override
  final int? serviceOptionGroupId;
  @override
  final String name;
  @override
  final double price;
  @override
  final double transportation;
  @override
  @JsonKey()
  final bool addedByMerchant;

  @override
  String toString() {
    return 'StoreOptionItem(id: $id, serviceId: $serviceId, serviceOptionGroupId: $serviceOptionGroupId, name: $name, price: $price, transportation: $transportation, addedByMerchant: $addedByMerchant)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreOptionItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.serviceId, serviceId) ||
                other.serviceId == serviceId) &&
            (identical(other.serviceOptionGroupId, serviceOptionGroupId) ||
                other.serviceOptionGroupId == serviceOptionGroupId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.transportation, transportation) ||
                other.transportation == transportation) &&
            (identical(other.addedByMerchant, addedByMerchant) ||
                other.addedByMerchant == addedByMerchant));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, serviceId,
      serviceOptionGroupId, name, price, transportation, addedByMerchant);

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
      {required final int id,
      final int? serviceId,
      final int? serviceOptionGroupId,
      required final String name,
      required final double price,
      required final double transportation,
      final bool addedByMerchant}) = _$StoreOptionItemImpl;

  factory _StoreOptionItem.fromJson(Map<String, dynamic> json) =
      _$StoreOptionItemImpl.fromJson;

  @override
  int get id;
  @override
  int? get serviceId;
  @override
  int? get serviceOptionGroupId;
  @override
  String get name;
  @override
  double get price;
  @override
  double get transportation;
  @override
  bool get addedByMerchant;
  @override
  @JsonKey(ignore: true)
  _$$StoreOptionItemImplCopyWith<_$StoreOptionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
