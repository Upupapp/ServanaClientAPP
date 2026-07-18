// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'barangay.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BarangayModel _$BarangayModelFromJson(Map<String, dynamic> json) {
  return _BarangayModel.fromJson(json);
}

/// @nodoc
mixin _$BarangayModel {
  @JsonKey(name: 'brgy_code')
  String get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'brgy_name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'province_code')
  String get provinceCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_code')
  String get cityCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_code')
  String get regionCode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BarangayModelCopyWith<BarangayModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BarangayModelCopyWith<$Res> {
  factory $BarangayModelCopyWith(
          BarangayModel value, $Res Function(BarangayModel) then) =
      _$BarangayModelCopyWithImpl<$Res, BarangayModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'brgy_code') String code,
      @JsonKey(name: 'brgy_name') String name,
      @JsonKey(name: 'province_code') String provinceCode,
      @JsonKey(name: 'city_code') String cityCode,
      @JsonKey(name: 'region_code') String regionCode});
}

/// @nodoc
class _$BarangayModelCopyWithImpl<$Res, $Val extends BarangayModel>
    implements $BarangayModelCopyWith<$Res> {
  _$BarangayModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? provinceCode = null,
    Object? cityCode = null,
    Object? regionCode = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      provinceCode: null == provinceCode
          ? _value.provinceCode
          : provinceCode // ignore: cast_nullable_to_non_nullable
              as String,
      cityCode: null == cityCode
          ? _value.cityCode
          : cityCode // ignore: cast_nullable_to_non_nullable
              as String,
      regionCode: null == regionCode
          ? _value.regionCode
          : regionCode // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BarangayModelImplCopyWith<$Res>
    implements $BarangayModelCopyWith<$Res> {
  factory _$$BarangayModelImplCopyWith(
          _$BarangayModelImpl value, $Res Function(_$BarangayModelImpl) then) =
      __$$BarangayModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'brgy_code') String code,
      @JsonKey(name: 'brgy_name') String name,
      @JsonKey(name: 'province_code') String provinceCode,
      @JsonKey(name: 'city_code') String cityCode,
      @JsonKey(name: 'region_code') String regionCode});
}

/// @nodoc
class __$$BarangayModelImplCopyWithImpl<$Res>
    extends _$BarangayModelCopyWithImpl<$Res, _$BarangayModelImpl>
    implements _$$BarangayModelImplCopyWith<$Res> {
  __$$BarangayModelImplCopyWithImpl(
      _$BarangayModelImpl _value, $Res Function(_$BarangayModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? provinceCode = null,
    Object? cityCode = null,
    Object? regionCode = null,
  }) {
    return _then(_$BarangayModelImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      provinceCode: null == provinceCode
          ? _value.provinceCode
          : provinceCode // ignore: cast_nullable_to_non_nullable
              as String,
      cityCode: null == cityCode
          ? _value.cityCode
          : cityCode // ignore: cast_nullable_to_non_nullable
              as String,
      regionCode: null == regionCode
          ? _value.regionCode
          : regionCode // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BarangayModelImpl implements _BarangayModel {
  const _$BarangayModelImpl(
      {@JsonKey(name: 'brgy_code') required this.code,
      @JsonKey(name: 'brgy_name') required this.name,
      @JsonKey(name: 'province_code') required this.provinceCode,
      @JsonKey(name: 'city_code') required this.cityCode,
      @JsonKey(name: 'region_code') required this.regionCode});

  factory _$BarangayModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BarangayModelImplFromJson(json);

  @override
  @JsonKey(name: 'brgy_code')
  final String code;
  @override
  @JsonKey(name: 'brgy_name')
  final String name;
  @override
  @JsonKey(name: 'province_code')
  final String provinceCode;
  @override
  @JsonKey(name: 'city_code')
  final String cityCode;
  @override
  @JsonKey(name: 'region_code')
  final String regionCode;

  @override
  String toString() {
    return 'BarangayModel(code: $code, name: $name, provinceCode: $provinceCode, cityCode: $cityCode, regionCode: $regionCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BarangayModelImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.provinceCode, provinceCode) ||
                other.provinceCode == provinceCode) &&
            (identical(other.cityCode, cityCode) ||
                other.cityCode == cityCode) &&
            (identical(other.regionCode, regionCode) ||
                other.regionCode == regionCode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, code, name, provinceCode, cityCode, regionCode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BarangayModelImplCopyWith<_$BarangayModelImpl> get copyWith =>
      __$$BarangayModelImplCopyWithImpl<_$BarangayModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BarangayModelImplToJson(
      this,
    );
  }
}

abstract class _BarangayModel implements BarangayModel {
  const factory _BarangayModel(
          {@JsonKey(name: 'brgy_code') required final String code,
          @JsonKey(name: 'brgy_name') required final String name,
          @JsonKey(name: 'province_code') required final String provinceCode,
          @JsonKey(name: 'city_code') required final String cityCode,
          @JsonKey(name: 'region_code') required final String regionCode}) =
      _$BarangayModelImpl;

  factory _BarangayModel.fromJson(Map<String, dynamic> json) =
      _$BarangayModelImpl.fromJson;

  @override
  @JsonKey(name: 'brgy_code')
  String get code;
  @override
  @JsonKey(name: 'brgy_name')
  String get name;
  @override
  @JsonKey(name: 'province_code')
  String get provinceCode;
  @override
  @JsonKey(name: 'city_code')
  String get cityCode;
  @override
  @JsonKey(name: 'region_code')
  String get regionCode;
  @override
  @JsonKey(ignore: true)
  _$$BarangayModelImplCopyWith<_$BarangayModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
