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

  /// `GET /api/booking/:bookingId/provider-location` — where is the provider on
  /// *this* booking.
  ///
  /// TRACK-GAP-006 CLOSED. This replaced `GET /api/workers/location/:uid`, which
  /// was unauthenticated on the backend and took the subject from the URL, so
  /// anyone could follow any provider's live position. The old note here said
  /// the data source "passes through the auth headers … the backend ignores
  /// them for this route" — which was an accurate description of a hole, not a
  /// mitigation.
  ///
  /// The successor asks a question the caller is entitled to ask. Access is
  /// decided server-side by `assertBookingAccess`, and there is no way to phrase
  /// a request for an arbitrary provider's whereabouts: the booking is the
  /// subject, and it is one the customer already owns.
  ///
  /// Returns null when there is no position to show — either no provider is
  /// assigned yet, or one is assigned but has not reported. Both are normal
  /// states rather than errors.
  Future<GeoPositionSnapshot?> getProviderLocation(int bookingId) async {
    try {
      final result = await _api.getBookingProviderLocation(bookingId);
      // `location` is the documented field. `data` is an additive alias the
      // backend added to keep already-installed builds working, since this
      // parser once read only the root or `data`. Reading `location` first is
      // what lets that alias eventually be dropped.
      return GeoPositionSnapshot.fromApiMap(result);
    } on ServanaApiException catch (e) {
      // 404 — booking gone. 403 — not the caller's booking, which is the
      // authorization working, not a failure to render.
      if (e.statusCode == 404 || e.statusCode == 403) return null;
      rethrow;
    }
  }
}
