// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jo_employee_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JOEmployeeModel _$JOEmployeeModelFromJson(Map<String, dynamic> json) {
  return _JOEmployeeModel.fromJson(json);
}

/// @nodoc
mixin _$JOEmployeeModel {
  String get name => throw _privateConstructorUsedError;
  String get contactNo => throw _privateConstructorUsedError;
  String? get photoURL => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $JOEmployeeModelCopyWith<JOEmployeeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JOEmployeeModelCopyWith<$Res> {
  factory $JOEmployeeModelCopyWith(
          JOEmployeeModel value, $Res Function(JOEmployeeModel) then) =
      _$JOEmployeeModelCopyWithImpl<$Res, JOEmployeeModel>;
  @useResult
  $Res call({String name, String contactNo, String? photoURL});
}

/// @nodoc
class _$JOEmployeeModelCopyWithImpl<$Res, $Val extends JOEmployeeModel>
    implements $JOEmployeeModelCopyWith<$Res> {
  _$JOEmployeeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? contactNo = null,
    Object? photoURL = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      contactNo: null == contactNo
          ? _value.contactNo
          : contactNo // ignore: cast_nullable_to_non_nullable
              as String,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JOEmployeeModelImplCopyWith<$Res>
    implements $JOEmployeeModelCopyWith<$Res> {
  factory _$$JOEmployeeModelImplCopyWith(_$JOEmployeeModelImpl value,
          $Res Function(_$JOEmployeeModelImpl) then) =
      __$$JOEmployeeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String contactNo, String? photoURL});
}

/// @nodoc
class __$$JOEmployeeModelImplCopyWithImpl<$Res>
    extends _$JOEmployeeModelCopyWithImpl<$Res, _$JOEmployeeModelImpl>
    implements _$$JOEmployeeModelImplCopyWith<$Res> {
  __$$JOEmployeeModelImplCopyWithImpl(
      _$JOEmployeeModelImpl _value, $Res Function(_$JOEmployeeModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? contactNo = null,
    Object? photoURL = freezed,
  }) {
    return _then(_$JOEmployeeModelImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      contactNo: null == contactNo
          ? _value.contactNo
          : contactNo // ignore: cast_nullable_to_non_nullable
              as String,
      photoURL: freezed == photoURL
          ? _value.photoURL
          : photoURL // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JOEmployeeModelImpl implements _JOEmployeeModel {
  const _$JOEmployeeModelImpl(
      {required this.name, required this.contactNo, this.photoURL});

  factory _$JOEmployeeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$JOEmployeeModelImplFromJson(json);

  @override
  final String name;
  @override
  final String contactNo;
  @override
  final String? photoURL;

  @override
  String toString() {
    return 'JOEmployeeModel(name: $name, contactNo: $contactNo, photoURL: $photoURL)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JOEmployeeModelImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.contactNo, contactNo) ||
                other.contactNo == contactNo) &&
            (identical(other.photoURL, photoURL) ||
                other.photoURL == photoURL));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, contactNo, photoURL);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JOEmployeeModelImplCopyWith<_$JOEmployeeModelImpl> get copyWith =>
      __$$JOEmployeeModelImplCopyWithImpl<_$JOEmployeeModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JOEmployeeModelImplToJson(
      this,
    );
  }
}

abstract class _JOEmployeeModel implements JOEmployeeModel {
  const factory _JOEmployeeModel(
      {required final String name,
      required final String contactNo,
      final String? photoURL}) = _$JOEmployeeModelImpl;

  factory _JOEmployeeModel.fromJson(Map<String, dynamic> json) =
      _$JOEmployeeModelImpl.fromJson;

  @override
  String get name;
  @override
  String get contactNo;
  @override
  String? get photoURL;
  @override
  @JsonKey(ignore: true)
  _$$JOEmployeeModelImplCopyWith<_$JOEmployeeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
