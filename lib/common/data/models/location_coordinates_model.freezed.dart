// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_coordinates_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LocationCoordinatesModel _$LocationCoordinatesModelFromJson(
    Map<String, dynamic> json) {
  return _LocationCoordinatesModel.fromJson(json);
}

/// @nodoc
mixin _$LocationCoordinatesModel {
  @HiveField(71)
  double get latitude => throw _privateConstructorUsedError;
  @HiveField(72)
  double get longhitude => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LocationCoordinatesModelCopyWith<LocationCoordinatesModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationCoordinatesModelCopyWith<$Res> {
  factory $LocationCoordinatesModelCopyWith(LocationCoordinatesModel value,
          $Res Function(LocationCoordinatesModel) then) =
      _$LocationCoordinatesModelCopyWithImpl<$Res, LocationCoordinatesModel>;
  @useResult
  $Res call({@HiveField(71) double latitude, @HiveField(72) double longhitude});
}

/// @nodoc
class _$LocationCoordinatesModelCopyWithImpl<$Res,
        $Val extends LocationCoordinatesModel>
    implements $LocationCoordinatesModelCopyWith<$Res> {
  _$LocationCoordinatesModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longhitude = null,
  }) {
    return _then(_value.copyWith(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longhitude: null == longhitude
          ? _value.longhitude
          : longhitude // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LocationCoordinatesModelImplCopyWith<$Res>
    implements $LocationCoordinatesModelCopyWith<$Res> {
  factory _$$LocationCoordinatesModelImplCopyWith(
          _$LocationCoordinatesModelImpl value,
          $Res Function(_$LocationCoordinatesModelImpl) then) =
      __$$LocationCoordinatesModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@HiveField(71) double latitude, @HiveField(72) double longhitude});
}

/// @nodoc
class __$$LocationCoordinatesModelImplCopyWithImpl<$Res>
    extends _$LocationCoordinatesModelCopyWithImpl<$Res,
        _$LocationCoordinatesModelImpl>
    implements _$$LocationCoordinatesModelImplCopyWith<$Res> {
  __$$LocationCoordinatesModelImplCopyWithImpl(
      _$LocationCoordinatesModelImpl _value,
      $Res Function(_$LocationCoordinatesModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longhitude = null,
  }) {
    return _then(_$LocationCoordinatesModelImpl(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longhitude: null == longhitude
          ? _value.longhitude
          : longhitude // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocationCoordinatesModelImpl implements _LocationCoordinatesModel {
  const _$LocationCoordinatesModelImpl(
      {@HiveField(71) required this.latitude,
      @HiveField(72) required this.longhitude});

  factory _$LocationCoordinatesModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocationCoordinatesModelImplFromJson(json);

  @override
  @HiveField(71)
  final double latitude;
  @override
  @HiveField(72)
  final double longhitude;

  @override
  String toString() {
    return 'LocationCoordinatesModel(latitude: $latitude, longhitude: $longhitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationCoordinatesModelImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longhitude, longhitude) ||
                other.longhitude == longhitude));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, latitude, longhitude);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationCoordinatesModelImplCopyWith<_$LocationCoordinatesModelImpl>
      get copyWith => __$$LocationCoordinatesModelImplCopyWithImpl<
          _$LocationCoordinatesModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocationCoordinatesModelImplToJson(
      this,
    );
  }
}

abstract class _LocationCoordinatesModel implements LocationCoordinatesModel {
  const factory _LocationCoordinatesModel(
          {@HiveField(71) required final double latitude,
          @HiveField(72) required final double longhitude}) =
      _$LocationCoordinatesModelImpl;

  factory _LocationCoordinatesModel.fromJson(Map<String, dynamic> json) =
      _$LocationCoordinatesModelImpl.fromJson;

  @override
  @HiveField(71)
  double get latitude;
  @override
  @HiveField(72)
  double get longhitude;
  @override
  @JsonKey(ignore: true)
  _$$LocationCoordinatesModelImplCopyWith<_$LocationCoordinatesModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
