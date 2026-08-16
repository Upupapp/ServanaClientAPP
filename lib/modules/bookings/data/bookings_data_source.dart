/// The contract both booking-read transports satisfy.
///
///     BookingRepository
///       → BookingsCanonicalDataSource      when V1Capability.bookingReads
///       → BookingsCompatibilityDataSource  otherwise
///       → the same CustomerBooking either way
///
/// ## Reads only
///
/// Booking CREATION is deliberately absent. There is no
/// `POST /api/v1/bookings` — see `docs/convergence-v1/TAB08_ENDPOINT_GAP.md` —
/// so create lives in `BookingSubmissionService` on the legacy route and does
/// not pretend to be part of a canonical boundary it has no endpoint in.
///
/// The three reads DO exist canonically, which is what makes this boundary
/// worth building rather than aspirational.
library;

import 'package:client/common/domain/booking/customer_booking.dart';

abstract interface class BookingsDataSource {
  /// The caller's own bookings.
  ///
  /// [userId] is accepted because the LEGACY route requires it as a query
  /// parameter. The canonical route takes identity from the token and ignores
  /// it entirely — its contract says so outright: *"Identity comes from the
  /// token, never from a parameter."* The parameter therefore describes the
  /// transport that still needs it, not the caller's authority.
  Future<List<CustomerBooking>> list(String userId);

  Future<CustomerBooking> byId(String bookingId);

  /// Operational history, already worded for the customer by the backend.
  ///
  /// Rows are returned unmapped: each event is `{code, label, at, actor,
  /// sequence}`, `label` is safe to render as-is, and `actor` is
  /// `YOU | PROVIDER | SERVANA` from the CUSTOMER's seat.
  Future<List<Map<String, dynamic>>> timeline(String bookingId);
}
