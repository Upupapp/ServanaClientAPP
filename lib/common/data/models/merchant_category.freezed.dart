// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'merchant_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MerchantCategory _$MerchantCategoryFromJson(Map<String, dynamic> json) {
  return _MerchantCategory.fromJson(json);
}

/// @nodoc
mixin _$MerchantCategory {
  int get merchantCategoryID => throw _privateConstructorUsedError;
  String get merchantID => throw _privateConstructorUsedError;
  int get serviceID => throw _privateConstructorUsedError;
  String get merchantCategoryName => throw _privateConstructorUsedError;
  int get ordinal => throw _privateConstructorUsedError;
  DateTime get createdDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MerchantCategoryCopyWith<MerchantCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MerchantCategoryCopyWith<$Res> {
  factory $MerchantCategoryCopyWith(
          MerchantCategory value, $Res Function(MerchantCategory) then) =
      _$MerchantCategoryCopyWithImpl<$Res, MerchantCategory>;
  @useResult
  $Res call(
      {int merchantCategoryID,
      String merchantID,
      int serviceID,
      String merchantCategoryName,
      int ordinal,
      DateTime createdDate});
}

/// @nodoc
class _$MerchantCategoryCopyWithImpl<$Res, $Val extends MerchantCategory>
    implements $MerchantCategoryCopyWith<$Res> {
  _$MerchantCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantCategoryID = null,
    Object? merchantID = null,
    Object? serviceID = null,
    Object? merchantCategoryName = null,
    Object? ordinal = null,
    Object? createdDate = null,
  }) {
    return _then(_value.copyWith(
      merchantCategoryID: null == merchantCategoryID
          ? _value.merchantCategoryID
          : merchantCategoryID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantID: null == merchantID
          ? _value.merchantID
          : merchantID // ignore: cast_nullable_to_non_nullable
              as String,
      serviceID: null == serviceID
          ? _value.serviceID
          : serviceID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantCategoryName: null == merchantCategoryName
          ? _value.merchantCategoryName
          : merchantCategoryName // ignore: cast_nullable_to_non_nullable
              as String,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _value.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MerchantCategoryImplCopyWith<$Res>
    implements $MerchantCategoryCopyWith<$Res> {
  factory _$$MerchantCategoryImplCopyWith(_$MerchantCategoryImpl value,
          $Res Function(_$MerchantCategoryImpl) then) =
      __$$MerchantCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int merchantCategoryID,
      String merchantID,
      int serviceID,
      String merchantCategoryName,
      int ordinal,
      DateTime createdDate});
}

/// @nodoc
class __$$MerchantCategoryImplCopyWithImpl<$Res>
    extends _$MerchantCategoryCopyWithImpl<$Res, _$MerchantCategoryImpl>
    implements _$$MerchantCategoryImplCopyWith<$Res> {
  __$$MerchantCategoryImplCopyWithImpl(_$MerchantCategoryImpl _value,
      $Res Function(_$MerchantCategoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantCategoryID = null,
    Object? merchantID = null,
    Object? serviceID = null,
    Object? merchantCategoryName = null,
    Object? ordinal = null,
    Object? createdDate = null,
  }) {
    return _then(_$MerchantCategoryImpl(
      merchantCategoryID: null == merchantCategoryID
          ? _value.merchantCategoryID
          : merchantCategoryID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantID: null == merchantID
          ? _value.merchantID
          : merchantID // ignore: cast_nullable_to_non_nullable
              as String,
      serviceID: null == serviceID
          ? _value.serviceID
          : serviceID // ignore: cast_nullable_to_non_nullable
              as int,
      merchantCategoryName: null == merchantCategoryName
          ? _value.merchantCategoryName
          : merchantCategoryName // ignore: cast_nullable_to_non_nullable
              as String,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
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
class _$MerchantCategoryImpl implements _MerchantCategory {
  const _$MerchantCategoryImpl(
      {required this.merchantCategoryID,
      required this.merchantID,
      required this.serviceID,
      required this.merchantCategoryName,
      required this.ordinal,
      required this.createdDate});

  factory _$MerchantCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MerchantCategoryImplFromJson(json);

  @override
  final int merchantCategoryID;
  @override
  final String merchantID;
  @override
  final int serviceID;
  @override
  final String merchantCategoryName;
  @override
  final int ordinal;
  @override
  final DateTime createdDate;

  @override
  String toString() {
    return 'MerchantCategory(merchantCategoryID: $merchantCategoryID, merchantID: $merchantID, serviceID: $serviceID, merchantCategoryName: $merchantCategoryName, ordinal: $ordinal, createdDate: $createdDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MerchantCategoryImpl &&
            (identical(other.merchantCategoryID, merchantCategoryID) ||
                other.merchantCategoryID == merchantCategoryID) &&
            (identical(other.merchantID, merchantID) ||
                other.merchantID == merchantID) &&
            (identical(other.serviceID, serviceID) ||
                other.serviceID == serviceID) &&
            (identical(other.merchantCategoryName, merchantCategoryName) ||
                other.merchantCategoryName == merchantCategoryName) &&
            (identical(other.ordinal, ordinal) || other.ordinal == ordinal) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, merchantCategoryID, merchantID,
      serviceID, merchantCategoryName, ordinal, createdDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MerchantCategoryImplCopyWith<_$MerchantCategoryImpl> get copyWith =>
      __$$MerchantCategoryImplCopyWithImpl<_$MerchantCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MerchantCategoryImplToJson(
      this,
    );
  }
}

abstract class _MerchantCategory implements MerchantCategory {
  const factory _MerchantCategory(
      {required final int merchantCategoryID,
      required final String merchantID,
      required final int serviceID,
      required final String merchantCategoryName,
      required final int ordinal,
      required final DateTime createdDate}) = _$MerchantCategoryImpl;

  factory _MerchantCategory.fromJson(Map<String, dynamic> json) =
      _$MerchantCategoryImpl.fromJson;

  @override
  int get merchantCategoryID;
  @override
  String get merchantID;
  @override
  int get serviceID;
  @override
  String get merchantCategoryName;
  @override
  int get ordinal;
  @override
  DateTime get createdDate;
  @override
  @JsonKey(ignore: true)
  _$$MerchantCategoryImplCopyWith<_$MerchantCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
