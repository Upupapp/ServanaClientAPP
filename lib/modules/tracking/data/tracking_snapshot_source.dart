/// The contract both tracking transports satisfy.
///
///     TrackingRepository
///       → TrackingCanonicalDataSource      when V1Capability.bookingTracking
///       → TrackingCompatibilityDataSource  otherwise
///       → the same BookingTrackingState either way
///
/// ## Two calls become one, and that is the smaller half
///
/// The legacy path issues `GET /api/:id` and
/// `GET /api/booking/:id/provider-location` in parallel and stitches them. The
/// canonical path is one `GET /api/v1/bookings/:id/tracking` that returns the
/// state, the step history and the position together.
///
/// Collapsing the round trips is the visible difference. The one that matters
/// is that the legacy position route *"answers in EVERY state — a customer
/// could watch their provider on a booking cancelled last week"*, and the
/// canonical route applies the state and time-window rules before deciding
/// whether to read a position at all. The client cannot close that gap on its
/// own: it can decline to draw a pin, but the coordinates have already been
/// sent to the device.
library;

import 'package:client/modules/tracking/domain/booking_tracking_state.dart';

abstract interface class TrackingSnapshotSource {
  /// One tracking frame for [bookingId].
  ///
  /// The seed parameters exist because the legacy transport cannot always
  /// produce a provider name, phone or service coordinate and the caller may
  /// already hold them from the screen that navigated here. The canonical
  /// transport ignores the ones its own payload answers.
  Future<BookingTrackingState> snapshot({
    required String bookingId,
    String? knownWorkerUid,
    String? seedName,
    String? seedPhone,
    double? seedLatitude,
    double? seedLongitude,
    String? seedAddress,
  });
}
