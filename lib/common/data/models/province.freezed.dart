// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'province.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProvinceModel _$ProvinceModelFromJson(Map<String, dynamic> json) {
  return _ProvinceModel.fromJson(json);
}

/// @nodoc
mixin _$ProvinceModel {
  @JsonKey(name: 'province_code')
  String get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'province_name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'psgc_code')
  String get psgc => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_code')
  String get regionCode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProvinceModelCopyWith<ProvinceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProvinceModelCopyWith<$Res> {
  factory $ProvinceModelCopyWith(
          ProvinceModel value, $Res Function(ProvinceModel) then) =
      _$ProvinceModelCopyWithImpl<$Res, ProvinceModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'province_code') String code,
      @JsonKey(name: 'province_name') String name,
      @JsonKey(name: 'psgc_code') String psgc,
      @JsonKey(name: 'region_code') String regionCode});
}

/// @nodoc
class _$ProvinceModelCopyWithImpl<$Res, $Val extends ProvinceModel>
    implements $ProvinceModelCopyWith<$Res> {
  _$ProvinceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? psgc = null,
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
      psgc: null == psgc
          ? _value.psgc
          : psgc // ignore: cast_nullable_to_non_nullable
              as String,
      regionCode: null == regionCode
          ? _value.regionCode
          : regionCode // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProvinceModelImplCopyWith<$Res>
    implements $ProvinceModelCopyWith<$Res> {
  factory _$$ProvinceModelImplCopyWith(
          _$ProvinceModelImpl value, $Res Function(_$ProvinceModelImpl) then) =
      __$$ProvinceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'province_code') String code,
      @JsonKey(name: 'province_name') String name,
      @JsonKey(name: 'psgc_code') String psgc,
      @JsonKey(name: 'region_code') String regionCode});
}

/// @nodoc
class __$$ProvinceModelImplCopyWithImpl<$Res>
    extends _$ProvinceModelCopyWithImpl<$Res, _$ProvinceModelImpl>
    implements _$$ProvinceModelImplCopyWith<$Res> {
  __$$ProvinceModelImplCopyWithImpl(
      _$ProvinceModelImpl _value, $Res Function(_$ProvinceModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? name = null,
    Object? psgc = null,
    Object? regionCode = null,
  }) {
    return _then(_$ProvinceModelImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      psgc: null == psgc
          ? _value.psgc
          : psgc // ignore: cast_nullable_to_non_nullable
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
class _$ProvinceModelImpl implements _ProvinceModel {
  const _$ProvinceModelImpl(
      {@JsonKey(name: 'province_code') required this.code,
      @JsonKey(name: 'province_name') required this.name,
      @JsonKey(name: 'psgc_code') required this.psgc,
      @JsonKey(name: 'region_code') required this.regionCode});

  factory _$ProvinceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProvinceModelImplFromJson(json);

  @override
  @JsonKey(name: 'province_code')
  final String code;
  @override
  @JsonKey(name: 'province_name')
  final String name;
  @override
  @JsonKey(name: 'psgc_code')
  final String psgc;
  @override
  @JsonKey(name: 'region_code')
  final String regionCode;

  @override
  String toString() {
    return 'ProvinceModel(code: $code, name: $name, psgc: $psgc, regionCode: $regionCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProvinceModelImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.psgc, psgc) || other.psgc == psgc) &&
            (identical(other.regionCode, regionCode) ||
                other.regionCode == regionCode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, code, name, psgc, regionCode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProvinceModelImplCopyWith<_$ProvinceModelImpl> get copyWith =>
      __$$ProvinceModelImplCopyWithImpl<_$ProvinceModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProvinceModelImplToJson(
      this,
    );
  }
}

abstract class _ProvinceModel implements ProvinceModel {
  const factory _ProvinceModel(
          {@JsonKey(name: 'province_code') required final String code,
          @JsonKey(name: 'province_name') required final String name,
          @JsonKey(name: 'psgc_code') required final String psgc,
          @JsonKey(name: 'region_code') required final String regionCode}) =
      _$ProvinceModelImpl;

  factory _ProvinceModel.fromJson(Map<String, dynamic> json) =
      _$ProvinceModelImpl.fromJson;

  @override
  @JsonKey(name: 'province_code')
  String get code;
  @override
  @JsonKey(name: 'province_name')
  String get name;
  @override
  @JsonKey(name: 'psgc_code')
  String get psgc;
  @override
  @JsonKey(name: 'region_code')
  String get regionCode;
  @override
  @JsonKey(ignore: true)
  _$$ProvinceModelImplCopyWith<_$ProvinceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
