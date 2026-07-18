// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_items_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$StoreItemCategory {
  int get id => throw _privateConstructorUsedError;
  int get ordinal => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<MerchantServiceModel> get services => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $StoreItemCategoryCopyWith<StoreItemCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreItemCategoryCopyWith<$Res> {
  factory $StoreItemCategoryCopyWith(
          StoreItemCategory value, $Res Function(StoreItemCategory) then) =
      _$StoreItemCategoryCopyWithImpl<$Res, StoreItemCategory>;
  @useResult
  $Res call(
      {int id, int ordinal, String name, List<MerchantServiceModel> services});
}

/// @nodoc
class _$StoreItemCategoryCopyWithImpl<$Res, $Val extends StoreItemCategory>
    implements $StoreItemCategoryCopyWith<$Res> {
  _$StoreItemCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ordinal = null,
    Object? name = null,
    Object? services = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      services: null == services
          ? _value.services
          : services // ignore: cast_nullable_to_non_nullable
              as List<MerchantServiceModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreItemCategoryImplCopyWith<$Res>
    implements $StoreItemCategoryCopyWith<$Res> {
  factory _$$StoreItemCategoryImplCopyWith(_$StoreItemCategoryImpl value,
          $Res Function(_$StoreItemCategoryImpl) then) =
      __$$StoreItemCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id, int ordinal, String name, List<MerchantServiceModel> services});
}

/// @nodoc
class __$$StoreItemCategoryImplCopyWithImpl<$Res>
    extends _$StoreItemCategoryCopyWithImpl<$Res, _$StoreItemCategoryImpl>
    implements _$$StoreItemCategoryImplCopyWith<$Res> {
  __$$StoreItemCategoryImplCopyWithImpl(_$StoreItemCategoryImpl _value,
      $Res Function(_$StoreItemCategoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ordinal = null,
    Object? name = null,
    Object? services = null,
  }) {
    return _then(_$StoreItemCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      ordinal: null == ordinal
          ? _value.ordinal
          : ordinal // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      services: null == services
          ? _value._services
          : services // ignore: cast_nullable_to_non_nullable
              as List<MerchantServiceModel>,
    ));
  }
}

/// @nodoc

class _$StoreItemCategoryImpl implements _StoreItemCategory {
  const _$StoreItemCategoryImpl(
      {required this.id,
      required this.ordinal,
      required this.name,
      required final List<MerchantServiceModel> services})
      : _services = services;

  @override
  final int id;
  @override
  final int ordinal;
  @override
  final String name;
  final List<MerchantServiceModel> _services;
  @override
  List<MerchantServiceModel> get services {
    if (_services is EqualUnmodifiableListView) return _services;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_services);
  }

  @override
  String toString() {
    return 'StoreItemCategory(id: $id, ordinal: $ordinal, name: $name, services: $services)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreItemCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ordinal, ordinal) || other.ordinal == ordinal) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._services, _services));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, ordinal, name,
      const DeepCollectionEquality().hash(_services));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreItemCategoryImplCopyWith<_$StoreItemCategoryImpl> get copyWith =>
      __$$StoreItemCategoryImplCopyWithImpl<_$StoreItemCategoryImpl>(
          this, _$identity);
}

abstract class _StoreItemCategory implements StoreItemCategory {
  const factory _StoreItemCategory(
          {required final int id,
          required final int ordinal,
          required final String name,
          required final List<MerchantServiceModel> services}) =
      _$StoreItemCategoryImpl;

  @override
  int get id;
  @override
  int get ordinal;
  @override
  String get name;
  @override
  List<MerchantServiceModel> get services;
  @override
  @JsonKey(ignore: true)
  _$$StoreItemCategoryImplCopyWith<_$StoreItemCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
