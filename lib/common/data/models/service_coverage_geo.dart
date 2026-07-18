import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_coverage_geo.freezed.dart';
part 'service_coverage_geo.g.dart';

@Freezed(fromJson: true, toJson: true)
class ServiceCoverageGeo with _$ServiceCoverageGeo {
  const factory ServiceCoverageGeo({
    required String type,
    required List<CoverageFeature> features,
  }) = _ServiceCoverageGeo;

  factory ServiceCoverageGeo.fromJson(Map<String, dynamic> json) =>
      _$ServiceCoverageGeoFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class CoverageFeature with _$CoverageFeature {
  const factory CoverageFeature({
    required String type,
    required CoverageGeometry geometry,
    @Default({}) Map<String, dynamic> properties,
  }) = _CoverageFeature;

  factory CoverageFeature.fromJson(Map<String, dynamic> json) =>
      _$CoverageFeatureFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class CoverageGeometry with _$CoverageGeometry {
  const factory CoverageGeometry({
    required String type,

    /// GeoJSON polygon rings: [[[lon, lat], [lon, lat], ...]]
    required List<List<List<double>>> coordinates,
  }) = _CoverageGeometry;

  factory CoverageGeometry.fromJson(Map<String, dynamic> json) =>
      _$CoverageGeometryFromJson(json);
}
