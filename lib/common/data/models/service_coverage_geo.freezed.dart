// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_coverage_geo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ServiceCoverageGeo _$ServiceCoverageGeoFromJson(Map<String, dynamic> json) {
  return _ServiceCoverageGeo.fromJson(json);
}

/// @nodoc
mixin _$ServiceCoverageGeo {
  String get type => throw _privateConstructorUsedError;
  List<CoverageFeature> get features => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ServiceCoverageGeoCopyWith<ServiceCoverageGeo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceCoverageGeoCopyWith<$Res> {
  factory $ServiceCoverageGeoCopyWith(
          ServiceCoverageGeo value, $Res Function(ServiceCoverageGeo) then) =
      _$ServiceCoverageGeoCopyWithImpl<$Res, ServiceCoverageGeo>;
  @useResult
  $Res call({String type, List<CoverageFeature> features});
}

/// @nodoc
class _$ServiceCoverageGeoCopyWithImpl<$Res, $Val extends ServiceCoverageGeo>
    implements $ServiceCoverageGeoCopyWith<$Res> {
  _$ServiceCoverageGeoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? features = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      features: null == features
          ? _value.features
          : features // ignore: cast_nullable_to_non_nullable
              as List<CoverageFeature>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServiceCoverageGeoImplCopyWith<$Res>
    implements $ServiceCoverageGeoCopyWith<$Res> {
  factory _$$ServiceCoverageGeoImplCopyWith(_$ServiceCoverageGeoImpl value,
          $Res Function(_$ServiceCoverageGeoImpl) then) =
      __$$ServiceCoverageGeoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, List<CoverageFeature> features});
}

/// @nodoc
class __$$ServiceCoverageGeoImplCopyWithImpl<$Res>
    extends _$ServiceCoverageGeoCopyWithImpl<$Res, _$ServiceCoverageGeoImpl>
    implements _$$ServiceCoverageGeoImplCopyWith<$Res> {
  __$$ServiceCoverageGeoImplCopyWithImpl(_$ServiceCoverageGeoImpl _value,
      $Res Function(_$ServiceCoverageGeoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? features = null,
  }) {
    return _then(_$ServiceCoverageGeoImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      features: null == features
          ? _value._features
          : features // ignore: cast_nullable_to_non_nullable
              as List<CoverageFeature>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceCoverageGeoImpl implements _ServiceCoverageGeo {
  const _$ServiceCoverageGeoImpl(
      {required this.type, required final List<CoverageFeature> features})
      : _features = features;

  factory _$ServiceCoverageGeoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceCoverageGeoImplFromJson(json);

  @override
  final String type;
  final List<CoverageFeature> _features;
  @override
  List<CoverageFeature> get features {
    if (_features is EqualUnmodifiableListView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_features);
  }

  @override
  String toString() {
    return 'ServiceCoverageGeo(type: $type, features: $features)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceCoverageGeoImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._features, _features));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, const DeepCollectionEquality().hash(_features));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceCoverageGeoImplCopyWith<_$ServiceCoverageGeoImpl> get copyWith =>
      __$$ServiceCoverageGeoImplCopyWithImpl<_$ServiceCoverageGeoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceCoverageGeoImplToJson(
      this,
    );
  }
}

abstract class _ServiceCoverageGeo implements ServiceCoverageGeo {
  const factory _ServiceCoverageGeo(
          {required final String type,
          required final List<CoverageFeature> features}) =
      _$ServiceCoverageGeoImpl;

  factory _ServiceCoverageGeo.fromJson(Map<String, dynamic> json) =
      _$ServiceCoverageGeoImpl.fromJson;

  @override
  String get type;
  @override
  List<CoverageFeature> get features;
  @override
  @JsonKey(ignore: true)
  _$$ServiceCoverageGeoImplCopyWith<_$ServiceCoverageGeoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CoverageFeature _$CoverageFeatureFromJson(Map<String, dynamic> json) {
  return _CoverageFeature.fromJson(json);
}

/// @nodoc
mixin _$CoverageFeature {
  String get type => throw _privateConstructorUsedError;
  CoverageGeometry get geometry => throw _privateConstructorUsedError;
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CoverageFeatureCopyWith<CoverageFeature> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverageFeatureCopyWith<$Res> {
  factory $CoverageFeatureCopyWith(
          CoverageFeature value, $Res Function(CoverageFeature) then) =
      _$CoverageFeatureCopyWithImpl<$Res, CoverageFeature>;
  @useResult
  $Res call(
      {String type,
      CoverageGeometry geometry,
      Map<String, dynamic> properties});

  $CoverageGeometryCopyWith<$Res> get geometry;
}

/// @nodoc
class _$CoverageFeatureCopyWithImpl<$Res, $Val extends CoverageFeature>
    implements $CoverageFeatureCopyWith<$Res> {
  _$CoverageFeatureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? geometry = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      geometry: null == geometry
          ? _value.geometry
          : geometry // ignore: cast_nullable_to_non_nullable
              as CoverageGeometry,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $CoverageGeometryCopyWith<$Res> get geometry {
    return $CoverageGeometryCopyWith<$Res>(_value.geometry, (value) {
      return _then(_value.copyWith(geometry: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CoverageFeatureImplCopyWith<$Res>
    implements $CoverageFeatureCopyWith<$Res> {
  factory _$$CoverageFeatureImplCopyWith(_$CoverageFeatureImpl value,
          $Res Function(_$CoverageFeatureImpl) then) =
      __$$CoverageFeatureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String type,
      CoverageGeometry geometry,
      Map<String, dynamic> properties});

  @override
  $CoverageGeometryCopyWith<$Res> get geometry;
}

/// @nodoc
class __$$CoverageFeatureImplCopyWithImpl<$Res>
    extends _$CoverageFeatureCopyWithImpl<$Res, _$CoverageFeatureImpl>
    implements _$$CoverageFeatureImplCopyWith<$Res> {
  __$$CoverageFeatureImplCopyWithImpl(
      _$CoverageFeatureImpl _value, $Res Function(_$CoverageFeatureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? geometry = null,
    Object? properties = null,
  }) {
    return _then(_$CoverageFeatureImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      geometry: null == geometry
          ? _value.geometry
          : geometry // ignore: cast_nullable_to_non_nullable
              as CoverageGeometry,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverageFeatureImpl implements _CoverageFeature {
  const _$CoverageFeatureImpl(
      {required this.type,
      required this.geometry,
      final Map<String, dynamic> properties = const {}})
      : _properties = properties;

  factory _$CoverageFeatureImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverageFeatureImplFromJson(json);

  @override
  final String type;
  @override
  final CoverageGeometry geometry;
  final Map<String, dynamic> _properties;
  @override
  @JsonKey()
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'CoverageFeature(type: $type, geometry: $geometry, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverageFeatureImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.geometry, geometry) ||
                other.geometry == geometry) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, type, geometry,
      const DeepCollectionEquality().hash(_properties));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverageFeatureImplCopyWith<_$CoverageFeatureImpl> get copyWith =>
      __$$CoverageFeatureImplCopyWithImpl<_$CoverageFeatureImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverageFeatureImplToJson(
      this,
    );
  }
}

abstract class _CoverageFeature implements CoverageFeature {
  const factory _CoverageFeature(
      {required final String type,
      required final CoverageGeometry geometry,
      final Map<String, dynamic> properties}) = _$CoverageFeatureImpl;

  factory _CoverageFeature.fromJson(Map<String, dynamic> json) =
      _$CoverageFeatureImpl.fromJson;

  @override
  String get type;
  @override
  CoverageGeometry get geometry;
  @override
  Map<String, dynamic> get properties;
  @override
  @JsonKey(ignore: true)
  _$$CoverageFeatureImplCopyWith<_$CoverageFeatureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CoverageGeometry _$CoverageGeometryFromJson(Map<String, dynamic> json) {
  return _CoverageGeometry.fromJson(json);
}

/// @nodoc
mixin _$CoverageGeometry {
  String get type => throw _privateConstructorUsedError;

  /// GeoJSON polygon rings: [[[lon, lat], [lon, lat], ...]]
  List<List<List<double>>> get coordinates =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CoverageGeometryCopyWith<CoverageGeometry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverageGeometryCopyWith<$Res> {
  factory $CoverageGeometryCopyWith(
          CoverageGeometry value, $Res Function(CoverageGeometry) then) =
      _$CoverageGeometryCopyWithImpl<$Res, CoverageGeometry>;
  @useResult
  $Res call({String type, List<List<List<double>>> coordinates});
}

/// @nodoc
class _$CoverageGeometryCopyWithImpl<$Res, $Val extends CoverageGeometry>
    implements $CoverageGeometryCopyWith<$Res> {
  _$CoverageGeometryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? coordinates = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      coordinates: null == coordinates
          ? _value.coordinates
          : coordinates // ignore: cast_nullable_to_non_nullable
              as List<List<List<double>>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CoverageGeometryImplCopyWith<$Res>
    implements $CoverageGeometryCopyWith<$Res> {
  factory _$$CoverageGeometryImplCopyWith(_$CoverageGeometryImpl value,
          $Res Function(_$CoverageGeometryImpl) then) =
      __$$CoverageGeometryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, List<List<List<double>>> coordinates});
}

/// @nodoc
class __$$CoverageGeometryImplCopyWithImpl<$Res>
    extends _$CoverageGeometryCopyWithImpl<$Res, _$CoverageGeometryImpl>
    implements _$$CoverageGeometryImplCopyWith<$Res> {
  __$$CoverageGeometryImplCopyWithImpl(_$CoverageGeometryImpl _value,
      $Res Function(_$CoverageGeometryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? coordinates = null,
  }) {
    return _then(_$CoverageGeometryImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      coordinates: null == coordinates
          ? _value._coordinates
          : coordinates // ignore: cast_nullable_to_non_nullable
              as List<List<List<double>>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverageGeometryImpl implements _CoverageGeometry {
  const _$CoverageGeometryImpl(
      {required this.type, required final List<List<List<double>>> coordinates})
      : _coordinates = coordinates;

  factory _$CoverageGeometryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverageGeometryImplFromJson(json);

  @override
  final String type;

  /// GeoJSON polygon rings: [[[lon, lat], [lon, lat], ...]]
  final List<List<List<double>>> _coordinates;

  /// GeoJSON polygon rings: [[[lon, lat], [lon, lat], ...]]
  @override
  List<List<List<double>>> get coordinates {
    if (_coordinates is EqualUnmodifiableListView) return _coordinates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_coordinates);
  }

  @override
  String toString() {
    return 'CoverageGeometry(type: $type, coordinates: $coordinates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverageGeometryImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality()
                .equals(other._coordinates, _coordinates));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, const DeepCollectionEquality().hash(_coordinates));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverageGeometryImplCopyWith<_$CoverageGeometryImpl> get copyWith =>
      __$$CoverageGeometryImplCopyWithImpl<_$CoverageGeometryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverageGeometryImplToJson(
      this,
    );
  }
}

abstract class _CoverageGeometry implements CoverageGeometry {
  const factory _CoverageGeometry(
          {required final String type,
          required final List<List<List<double>>> coordinates}) =
      _$CoverageGeometryImpl;

  factory _CoverageGeometry.fromJson(Map<String, dynamic> json) =
      _$CoverageGeometryImpl.fromJson;

  @override
  String get type;
  @override

  /// GeoJSON polygon rings: [[[lon, lat], [lon, lat], ...]]
  List<List<List<double>>> get coordinates;
  @override
  @JsonKey(ignore: true)
  _$$CoverageGeometryImplCopyWith<_$CoverageGeometryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
