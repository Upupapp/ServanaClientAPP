/// Produces one [BookingTrackingState] per frame, from whichever transport the
/// router selects.
///
///     TrackingRepository
///       → TrackingCanonicalDataSource      when V1Capability.bookingTracking
///       → TrackingCompatibilityDataSource  otherwise
///
/// [canonical] and [router] are optional. Omitting either pins the repository
/// to the compatibility source, which is what every build does today because
/// `/api/v1` is not deployed.
///
/// ## What used to be here
///
/// The two-call stitch. It has not been deleted or rewritten — it moved into
/// [TrackingCompatibilityDataSource] unchanged, because it is what every
/// shipped build still runs and TRACK-GAP-002 is still true of the legacy API.
/// What changed is that it is now one of two answers to the same question
/// instead of the only one.
library;

import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/tracking/data/tracking_snapshot_source.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';

class TrackingRepository {
  const TrackingRepository({
    required TrackingSnapshotSource compatibility,
    TrackingSnapshotSource? canonical,
    CanonicalRouter? router,
  })  : _compatibility = compatibility,
        _canonical = canonical,
        _router = router;

  final TrackingSnapshotSource _compatibility;
  final TrackingSnapshotSource? _canonical;
  final CanonicalRouter? _router;

  TrackingSnapshotSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<TrackingSnapshotSource>(
      V1Capability.bookingTracking,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when tracking is served by `/api/v1`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.bookingTracking) ?? false);

  /// Fetch a fresh [BookingTrackingState] for [bookingId].
  ///
  /// [knownWorkerUid] is passed from the prior state or from `TrackingArgs`
  /// so the legacy transport can fire its location call in parallel with the
  /// booking fetch. [seedName] / [seedPhone] cover the responses that carry no
  /// worker profile — which, on the canonical transport, is all of them.
  Future<BookingTrackingState> fetchSnapshot({
    required String bookingId,
    String? knownWorkerUid,
    String? seedName,
    String? seedPhone,
    double? seedLatitude,
    double? seedLongitude,
    String? seedAddress,
  }) =>
      _source.snapshot(
        bookingId: bookingId,
        knownWorkerUid: knownWorkerUid,
        seedName: seedName,
        seedPhone: seedPhone,
        seedLatitude: seedLatitude,
        seedLongitude: seedLongitude,
        seedAddress: seedAddress,
      );
}
