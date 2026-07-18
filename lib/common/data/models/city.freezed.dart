// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'city.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CityModel _$CityModelFromJson(Map<String, dynamic> json) {
  return _CityModel.fromJson(json);
}

/// @nodoc
mixin _$CityModel {
  @JsonKey(name: 'city_code')
  String get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'province_code')
  String get provinceCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'psgc_code')
  String get psgc => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_desc')
  String get region => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CityModelCopyWith<CityModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CityModelCopyWith<$Res> {
  factory $CityModelCopyWith(CityModel value, $Res Function(CityModel) then) =
      _$CityModelCopyWithImpl<$Res, CityModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'city_code') String code,
      @JsonKey(name: 'city_name') String name,
      @JsonKey(name: 'province_code') String provinceCode,
      @JsonKey(name: 'psgc_code') String psgc,
      @JsonKey(name: 'region_desc') String region});
}

/// @nodoc
class _$CityModelCopyWithImpl<$Res, $Val extends CityModel>
    implements $CityModelCopyWith<$Res> {
  _$CityModelCopyWithImpl(this._value, this._then);

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
    Object? psgc = null,
    Object? region = null,
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
      psgc: null == psgc
          ? _value.psgc
          : psgc // ignore: cast_nullable_to_non_nullable
              as String,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CityModelImplCopyWith<$Res>
    implements $CityModelCopyWith<$Res> {
  factory _$$CityModelImplCopyWith(
          _$CityModelImpl value, $Res Function(_$CityModelImpl) then) =
      __$$CityModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'city_code') String code,
      @JsonKey(name: 'city_name') String name,
      @JsonKey(name: 'province_code') String provinceCode,
      @JsonKey(name: 'psgc_code') String psgc,
      @JsonKey(name: 'region_desc') String region});
}

/// @nodoc
class __$$CityModelImplCopyWithImpl<$Res>
    extends _$CityModelCopyWithImpl<$Res, _$CityModelImpl>
    implements _$$CityModelImplCopyWith<$Res> {
  __$$CityModelImplCopyWithImpl(
      _$CityModelImpl _value, $Res Function(_$CityModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? provinceCode = null,
    Object? psgc = null,
    Object? region = null,
  }) {
    return _then(_$CityModelImpl(
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
      psgc: null == psgc
          ? _value.psgc
          : psgc // ignore: cast_nullable_to_non_nullable
              as String,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CityModelImpl implements _CityModel {
  const _$CityModelImpl(
      {@JsonKey(name: 'city_code') required this.code,
      @JsonKey(name: 'city_name') required this.name,
      @JsonKey(name: 'province_code') required this.provinceCode,
      @JsonKey(name: 'psgc_code') required this.psgc,
      @JsonKey(name: 'region_desc') required this.region});

  factory _$CityModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CityModelImplFromJson(json);

  @override
  @JsonKey(name: 'city_code')
  final String code;
  @override
  @JsonKey(name: 'city_name')
  final String name;
  @override
  @JsonKey(name: 'province_code')
  final String provinceCode;
  @override
  @JsonKey(name: 'psgc_code')
  final String psgc;
  @override
  @JsonKey(name: 'region_desc')
  final String region;

  @override
  String toString() {
    return 'CityModel(code: $code, name: $name, provinceCode: $provinceCode, psgc: $psgc, region: $region)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CityModelImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.provinceCode, provinceCode) ||
                other.provinceCode == provinceCode) &&
            (identical(other.psgc, psgc) || other.psgc == psgc) &&
            (identical(other.region, region) || other.region == region));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, code, name, provinceCode, psgc, region);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CityModelImplCopyWith<_$CityModelImpl> get copyWith =>
      __$$CityModelImplCopyWithImpl<_$CityModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CityModelImplToJson(
      this,
    );
  }
}

abstract class _CityModel implements CityModel {
  const factory _CityModel(
          {@JsonKey(name: 'city_code') required final String code,
          @JsonKey(name: 'city_name') required final String name,
          @JsonKey(name: 'province_code') required final String provinceCode,
          @JsonKey(name: 'psgc_code') required final String psgc,
          @JsonKey(name: 'region_desc') required final String region}) =
      _$CityModelImpl;

  factory _CityModel.fromJson(Map<String, dynamic> json) =
      _$CityModelImpl.fromJson;

  @override
  @JsonKey(name: 'city_code')
  String get code;
  @override
  @JsonKey(name: 'city_name')
  String get name;
  @override
  @JsonKey(name: 'province_code')
  String get provinceCode;
  @override
  @JsonKey(name: 'psgc_code')
  String get psgc;
  @override
  @JsonKey(name: 'region_desc')
  String get region;
  @override
  @JsonKey(ignore: true)
  _$$CityModelImplCopyWith<_$CityModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
