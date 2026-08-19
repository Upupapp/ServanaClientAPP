/// Tracking over `GET /api/v1/bookings/:bookingId/tracking`.
///
/// ## Not reachable in any shipped build
///
/// Selected only when
/// `CanonicalAvailability.isAvailable(V1Capability.bookingTracking)`, which
/// requires `--dart-define=CANONICAL_V1_ENABLED=true` AND `bookingTracking` in
/// `CANONICAL_V1_CAPABILITIES`. No production build passes either.
///
/// ## A withheld position is a success
///
/// This source never treats an absent position as a failure, because the
/// backend never sends one as an error: *"the caller is entitled to the
/// booking and simply not to a live location for it yet."* The verdict travels
/// as data — `visibility.reason` — and is preserved all the way to the screen
/// rather than being flattened into a null the way the legacy stitcher did.
///
/// ## What is still seeded
///
/// The provider's NAME and PHONE. The tracking payload carries the position and
/// the assignment flag but no worker profile, so those keep coming from the
/// caller's seed exactly as they do today. Inventing a second profile lookup
/// here would put a duplicate owner on data the booking detail already holds.
library;

import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/tracking/data/tracking_snapshot_source.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:client/modules/tracking/domain/geo_position_snapshot.dart';
import 'package:client/modules/tracking/domain/tracking_visibility.dart';

class TrackingCanonicalDataSource implements TrackingSnapshotSource {
  const TrackingCanonicalDataSource(this._api);

  final V1ApiClient _api;

  @override
  Future<BookingTrackingState> snapshot({
    required String bookingId,
    String? knownWorkerUid,
    String? seedName,
    String? seedPhone,
    double? seedLatitude,
    double? seedLongitude,
    String? seedAddress,
  }) async {
    final envelope = await _api.get(V1Endpoints.bookingTracking(bookingId));
    final data = envelope.asMap;

    final visibility = _visibility(data);
    final provider = _map(data['assignedProvider']);

    // Only read a position when the verdict permits one. The backend already
    // nulls it otherwise, so this is belt-and-braces — but the alternative is a
    // client that would draw a pin the moment a server regression started
    // leaking coordinates alongside a WITHHELD verdict, which is precisely the
    // failure §64 exists to prevent.
    final locationRaw = visibility.isVisible
        ? _map(provider['location'])
        : const <String, dynamic>{};
    final location = locationRaw.isEmpty
        ? null
        : GeoPositionSnapshot.fromApiMap(locationRaw);

    return BookingTrackingState(
      bookingId: bookingId,
      // `state` is the canonical state from the shared derivation — the same
      // vocabulary every surface agrees on — rather than the raw column the
      // legacy detail route returns.
      bookingStatus: BookingStatusMapper.fromString(
          '${data['state'] ?? ''}'.toUpperCase()),
      providerLocation: location,
      // No ETA on this payload. Null is the honest value; the legacy stitcher
      // derives one from booking columns and this route does not carry them.
      eta: null,
      providerUid: knownWorkerUid,
      providerName: seedName,
      providerPhone: seedPhone,
      serviceAddress: seedAddress ?? '',
      serviceLatitude: seedLatitude ?? _fallbackLatitude,
      serviceLongitude: seedLongitude ?? _fallbackLongitude,
      visibility: visibility,
    );
  }

  /// Manila. The same fallback the legacy repository uses, kept identical so a
  /// flip between transports cannot move the map.
  static const double _fallbackLatitude = 14.5995;
  static const double _fallbackLongitude = 120.9842;

  TrackingVisibility _visibility(Map<String, dynamic> data) {
    final raw = _map(data['visibility']);
    if (raw.isEmpty) {
      // A tracking payload with no verdict is a contract break. Withhold — the
      // one direction that cannot expose a position the policy meant to hide.
      return const TrackingVisibility(isVisible: false);
    }
    return TrackingVisibility.fromApiMap(raw);
  }

  /// An absent or wrongly-shaped node reads as empty rather than null, so the
  /// callers above stay branch-free. A malformed tracking payload must degrade
  /// to "nothing to show", never to a crash on a screen a customer is watching.
  static Map<String, dynamic> _map(Object? raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
}
