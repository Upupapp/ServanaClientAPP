// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jo_photo_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JOPhotoModel _$JOPhotoModelFromJson(Map<String, dynamic> json) {
  return _JOPhotoModel.fromJson(json);
}

/// @nodoc
mixin _$JOPhotoModel {
  @JsonKey(includeFromJson: false, includeToJson: false)
  XFile? get photoFile => throw _privateConstructorUsedError;
  bool get isFromMerchant => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $JOPhotoModelCopyWith<JOPhotoModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JOPhotoModelCopyWith<$Res> {
  factory $JOPhotoModelCopyWith(
          JOPhotoModel value, $Res Function(JOPhotoModel) then) =
      _$JOPhotoModelCopyWithImpl<$Res, JOPhotoModel>;
  @useResult
  $Res call(
      {@JsonKey(includeFromJson: false, includeToJson: false) XFile? photoFile,
      bool isFromMerchant});
}

/// @nodoc
class _$JOPhotoModelCopyWithImpl<$Res, $Val extends JOPhotoModel>
    implements $JOPhotoModelCopyWith<$Res> {
  _$JOPhotoModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? photoFile = freezed,
    Object? isFromMerchant = null,
  }) {
    return _then(_value.copyWith(
      photoFile: freezed == photoFile
          ? _value.photoFile
          : photoFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      isFromMerchant: null == isFromMerchant
          ? _value.isFromMerchant
          : isFromMerchant // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JOPhotoModelImplCopyWith<$Res>
    implements $JOPhotoModelCopyWith<$Res> {
  factory _$$JOPhotoModelImplCopyWith(
          _$JOPhotoModelImpl value, $Res Function(_$JOPhotoModelImpl) then) =
      __$$JOPhotoModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(includeFromJson: false, includeToJson: false) XFile? photoFile,
      bool isFromMerchant});
}

/// @nodoc
class __$$JOPhotoModelImplCopyWithImpl<$Res>
    extends _$JOPhotoModelCopyWithImpl<$Res, _$JOPhotoModelImpl>
    implements _$$JOPhotoModelImplCopyWith<$Res> {
  __$$JOPhotoModelImplCopyWithImpl(
      _$JOPhotoModelImpl _value, $Res Function(_$JOPhotoModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? photoFile = freezed,
    Object? isFromMerchant = null,
  }) {
    return _then(_$JOPhotoModelImpl(
      photoFile: freezed == photoFile
          ? _value.photoFile
          : photoFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      isFromMerchant: null == isFromMerchant
          ? _value.isFromMerchant
          : isFromMerchant // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JOPhotoModelImpl implements _JOPhotoModel {
  const _$JOPhotoModelImpl(
      {@JsonKey(includeFromJson: false, includeToJson: false) this.photoFile,
      this.isFromMerchant = false});

  factory _$JOPhotoModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$JOPhotoModelImplFromJson(json);

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final XFile? photoFile;
  @override
  @JsonKey()
  final bool isFromMerchant;

  @override
  String toString() {
    return 'JOPhotoModel(photoFile: $photoFile, isFromMerchant: $isFromMerchant)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JOPhotoModelImpl &&
            (identical(other.photoFile, photoFile) ||
                other.photoFile == photoFile) &&
            (identical(other.isFromMerchant, isFromMerchant) ||
                other.isFromMerchant == isFromMerchant));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, photoFile, isFromMerchant);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$JOPhotoModelImplCopyWith<_$JOPhotoModelImpl> get copyWith =>
      __$$JOPhotoModelImplCopyWithImpl<_$JOPhotoModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JOPhotoModelImplToJson(
      this,
    );
  }
}

abstract class _JOPhotoModel implements JOPhotoModel {
  const factory _JOPhotoModel(
      {@JsonKey(includeFromJson: false, includeToJson: false)
      final XFile? photoFile,
      final bool isFromMerchant}) = _$JOPhotoModelImpl;

  factory _JOPhotoModel.fromJson(Map<String, dynamic> json) =
      _$JOPhotoModelImpl.fromJson;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  XFile? get photoFile;
  @override
  bool get isFromMerchant;
  @override
  @JsonKey(ignore: true)
  _$$JOPhotoModelImplCopyWith<_$JOPhotoModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
