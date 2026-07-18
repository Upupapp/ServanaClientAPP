// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_coverage_geo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceCoverageGeoImpl _$$ServiceCoverageGeoImplFromJson(
        Map<String, dynamic> json) =>
    _$ServiceCoverageGeoImpl(
      type: json['type'] as String,
      features: (json['features'] as List<dynamic>)
          .map((e) => CoverageFeature.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ServiceCoverageGeoImplToJson(
        _$ServiceCoverageGeoImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'features': instance.features,
    };

_$CoverageFeatureImpl _$$CoverageFeatureImplFromJson(
        Map<String, dynamic> json) =>
    _$CoverageFeatureImpl(
      type: json['type'] as String,
      geometry:
          CoverageGeometry.fromJson(json['geometry'] as Map<String, dynamic>),
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$CoverageFeatureImplToJson(
        _$CoverageFeatureImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'geometry': instance.geometry,
      'properties': instance.properties,
    };

_$CoverageGeometryImpl _$$CoverageGeometryImplFromJson(
        Map<String, dynamic> json) =>
    _$CoverageGeometryImpl(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as List<dynamic>)
              .map((e) => (e as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList())
              .toList())
          .toList(),
    );

Map<String, dynamic> _$$CoverageGeometryImplToJson(
        _$CoverageGeometryImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
    };
