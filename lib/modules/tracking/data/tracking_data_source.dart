import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/tracking/domain/geo_position_snapshot.dart';

/// Raw API access layer for tracking data.
///
/// Every call maps directly to one backend endpoint. No caching, no retry
/// logic — those concerns belong in [TrackingRepository].
class TrackingDataSource {
  const TrackingDataSource(this._api);

  final ServanaApiClient _api;

  /// `GET /api/:bookingId` — booking detail including `status`, `eta_minutes`,
  /// `eta_at`, `worker_uid`, `assigned_at`, `latitude`, `longitude`, `address`.
  ///
  /// Returns the raw response map. Envelope unwrapping is done in the repository.
  Future<Map<String, dynamic>> getBookingDetail(int bookingId) {
    return _api.getBooking(bookingId);
  }

  /// `GET /api/workers/location/:uid` — latest location of a specific worker.
  ///
  /// Response: `{ uid, is_online, loc: { type: 'Point', coordinates: [lon, lat] }, updatedAt }`
  ///
  /// SECURITY NOTE (TRACK-GAP-006): This endpoint is unauthenticated on the
  /// backend. The data source passes through the auth headers the API client
  /// includes by default; the backend ignores them for this route.
  ///
  /// Returns null instead of throwing when the worker has no location record
  /// (e.g., provider app never pushed a location).
  Future<GeoPositionSnapshot?> getProviderLocation(String workerUid) async {
    try {
      final result = await _api.getWorkerLocation(workerUid);
      // Backend may return the doc at root or under "data".
      final doc = result['data'] is Map<String, dynamic>
          ? result['data'] as Map<String, dynamic>
          : result;
      return GeoPositionSnapshot.fromApiMap(doc);
    } on ServanaApiException catch (e) {
      // 404 means the worker has never pushed a location — not an error.
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
