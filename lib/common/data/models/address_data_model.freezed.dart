// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_data_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AddressDataModel _$AddressDataModelFromJson(Map<String, dynamic> json) {
  return _AddressDataModel.fromJson(json);
}

/// @nodoc
mixin _$AddressDataModel {
  String? get city => throw _privateConstructorUsedError;
  String? get province => throw _privateConstructorUsedError;
  String? get barangay => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get streetAddress => throw _privateConstructorUsedError;
  String? get postalCode => throw _privateConstructorUsedError;
  LocationCoordinatesModel? get locationCoordinates =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AddressDataModelCopyWith<AddressDataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddressDataModelCopyWith<$Res> {
  factory $AddressDataModelCopyWith(
          AddressDataModel value, $Res Function(AddressDataModel) then) =
      _$AddressDataModelCopyWithImpl<$Res, AddressDataModel>;
  @useResult
  $Res call(
      {String? city,
      String? province,
      String? barangay,
      String? country,
      String? streetAddress,
      String? postalCode,
      LocationCoordinatesModel? locationCoordinates});

  $LocationCoordinatesModelCopyWith<$Res>? get locationCoordinates;
}

/// @nodoc
class _$AddressDataModelCopyWithImpl<$Res, $Val extends AddressDataModel>
    implements $AddressDataModelCopyWith<$Res> {
  _$AddressDataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = freezed,
    Object? province = freezed,
    Object? barangay = freezed,
    Object? country = freezed,
    Object? streetAddress = freezed,
    Object? postalCode = freezed,
    Object? locationCoordinates = freezed,
  }) {
    return _then(_value.copyWith(
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      province: freezed == province
          ? _value.province
          : province // ignore: cast_nullable_to_non_nullable
              as String?,
      barangay: freezed == barangay
          ? _value.barangay
          : barangay // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      streetAddress: freezed == streetAddress
          ? _value.streetAddress
          : streetAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      postalCode: freezed == postalCode
          ? _value.postalCode
          : postalCode // ignore: cast_nullable_to_non_nullable
              as String?,
      locationCoordinates: freezed == locationCoordinates
          ? _value.locationCoordinates
          : locationCoordinates // ignore: cast_nullable_to_non_nullable
              as LocationCoordinatesModel?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $LocationCoordinatesModelCopyWith<$Res>? get locationCoordinates {
    if (_value.locationCoordinates == null) {
      return null;
    }

    return $LocationCoordinatesModelCopyWith<$Res>(_value.locationCoordinates!,
        (value) {
      return _then(_value.copyWith(locationCoordinates: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AddressDataModelImplCopyWith<$Res>
    implements $AddressDataModelCopyWith<$Res> {
  factory _$$AddressDataModelImplCopyWith(_$AddressDataModelImpl value,
          $Res Function(_$AddressDataModelImpl) then) =
      __$$AddressDataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? city,
      String? province,
      String? barangay,
      String? country,
      String? streetAddress,
      String? postalCode,
      LocationCoordinatesModel? locationCoordinates});

  @override
  $LocationCoordinatesModelCopyWith<$Res>? get locationCoordinates;
}

/// @nodoc
class __$$AddressDataModelImplCopyWithImpl<$Res>
    extends _$AddressDataModelCopyWithImpl<$Res, _$AddressDataModelImpl>
    implements _$$AddressDataModelImplCopyWith<$Res> {
  __$$AddressDataModelImplCopyWithImpl(_$AddressDataModelImpl _value,
      $Res Function(_$AddressDataModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? city = freezed,
    Object? province = freezed,
    Object? barangay = freezed,
    Object? country = freezed,
    Object? streetAddress = freezed,
    Object? postalCode = freezed,
    Object? locationCoordinates = freezed,
  }) {
    return _then(_$AddressDataModelImpl(
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      province: freezed == province
          ? _value.province
          : province // ignore: cast_nullable_to_non_nullable
              as String?,
      barangay: freezed == barangay
          ? _value.barangay
          : barangay // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      streetAddress: freezed == streetAddress
          ? _value.streetAddress
          : streetAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      postalCode: freezed == postalCode
          ? _value.postalCode
          : postalCode // ignore: cast_nullable_to_non_nullable
              as String?,
      locationCoordinates: freezed == locationCoordinates
          ? _value.locationCoordinates
          : locationCoordinates // ignore: cast_nullable_to_non_nullable
              as LocationCoordinatesModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AddressDataModelImpl implements _AddressDataModel {
  const _$AddressDataModelImpl(
      {this.city,
      this.province,
      this.barangay,
      this.country,
      this.streetAddress,
      this.postalCode,
      this.locationCoordinates});

  factory _$AddressDataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddressDataModelImplFromJson(json);

  @override
  final String? city;
  @override
  final String? province;
  @override
  final String? barangay;
  @override
  final String? country;
  @override
  final String? streetAddress;
  @override
  final String? postalCode;
  @override
  final LocationCoordinatesModel? locationCoordinates;

  @override
  String toString() {
    return 'AddressDataModel(city: $city, province: $province, barangay: $barangay, country: $country, streetAddress: $streetAddress, postalCode: $postalCode, locationCoordinates: $locationCoordinates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddressDataModelImpl &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.province, province) ||
                other.province == province) &&
            (identical(other.barangay, barangay) ||
                other.barangay == barangay) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.streetAddress, streetAddress) ||
                other.streetAddress == streetAddress) &&
            (identical(other.postalCode, postalCode) ||
                other.postalCode == postalCode) &&
            (identical(other.locationCoordinates, locationCoordinates) ||
                other.locationCoordinates == locationCoordinates));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, city, province, barangay,
      country, streetAddress, postalCode, locationCoordinates);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AddressDataModelImplCopyWith<_$AddressDataModelImpl> get copyWith =>
      __$$AddressDataModelImplCopyWithImpl<_$AddressDataModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressDataModelImplToJson(
      this,
    );
  }
}

abstract class _AddressDataModel implements AddressDataModel {
  const factory _AddressDataModel(
          {final String? city,
          final String? province,
          final String? barangay,
          final String? country,
          final String? streetAddress,
          final String? postalCode,
          final LocationCoordinatesModel? locationCoordinates}) =
      _$AddressDataModelImpl;

  factory _AddressDataModel.fromJson(Map<String, dynamic> json) =
      _$AddressDataModelImpl.fromJson;

  @override
  String? get city;
  @override
  String? get province;
  @override
  String? get barangay;
  @override
  String? get country;
  @override
  String? get streetAddress;
  @override
  String? get postalCode;
  @override
  LocationCoordinatesModel? get locationCoordinates;
  @override
  @JsonKey(ignore: true)
  _$$AddressDataModelImplCopyWith<_$AddressDataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
