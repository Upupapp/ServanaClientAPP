import 'package:google_maps_flutter/google_maps_flutter.dart';

/// An immutable GPS snapshot with a backend-authoritative timestamp.
///
/// The backend stores coordinates in GeoJSON order ([longitude, latitude]).
/// [fromApiMap] reverses them so callers always receive standard [LatLng].
///
/// SECURITY: Coordinates are validated against WGS-84 bounds on construction.
/// Out-of-range values are rejected (returns null from [fromApiMap]).
class GeoPositionSnapshot {
  const GeoPositionSnapshot({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  /// Standard Flutter Maps [LatLng] for use with GoogleMap widgets.
  LatLng get latLng => LatLng(latitude, longitude);

  /// Returns true when the location is older than [threshold] relative to [now].
  ///
  /// Default threshold: 3 minutes — chosen to match the provider's expected
  /// location-push interval of every ~30 s, with generous slack for network lag.
  bool isStaleAt(
    DateTime now, {
    Duration threshold = const Duration(minutes: 3),
  }) =>
      now.difference(updatedAt) > threshold;

  /// Parse from the `GET /api/workers/location/:uid` response.
  ///
  /// Expected envelope (unauthenticated mobile route):
  /// ```json
  /// { "uid": "...", "is_online": true,
  ///   "loc": { "type": "Point", "coordinates": [longitude, latitude] },
  ///   "updatedAt": "2026-07-28T10:15:00.000Z" }
  /// ```
  ///
  /// GeoJSON orders coordinates as [longitude, latitude] — this method
  /// reverses them so the result is always latitude-first (standard LatLng).
  static GeoPositionSnapshot? fromApiMap(Map<String, dynamic> map) {
    // Backend may wrap in a "data" envelope.
    final raw = map['loc'] != null
        ? map
        : (map['data'] as Map<String, dynamic>? ?? map);
    final loc = raw['loc'] as Map<String, dynamic>?;
    if (loc == null) return null;

    final coords = loc['coordinates'] as List<dynamic>?;
    if (coords == null || coords.length < 2) return null;

    // GeoJSON: [longitude, latitude]
    final lon = (coords[0] as num?)?.toDouble();
    final lat = (coords[1] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    // Validate WGS-84 bounds.
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;

    // Reject null-island coordinates (0, 0) — sentinel for "not yet located".
    if (lat == 0.0 && lon == 0.0) return null;

    final updatedAtRaw = raw['updatedAt']?.toString();
    final updatedAt =
        updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null;
    if (updatedAt == null) return null;

    return GeoPositionSnapshot(
      latitude: lat,
      longitude: lon,
      updatedAt: updatedAt.toLocal(),
    );
  }
}
