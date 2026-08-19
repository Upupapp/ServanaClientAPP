/// Bookings feature repository.
///
///     BookingRepository
///       → BookingsCanonicalDataSource      when V1Capability.bookingReads
///       → BookingsCompatibilityDataSource  otherwise
///       → the same CustomerBooking either way
///
/// [canonical] and [router] are optional. Omitting either pins the repository
/// to the compatibility source, which is what every build does today because
/// `/api/v1` is not deployed.
///
/// ## Reads are migratable; create is not
///
/// `bookings.listMine`, `bookings.get` and `bookings.timeline` all exist in the
/// canonical contract and are marked `implemented`. Booking CREATION does not
/// exist there at all, which is why it lives in `BookingSubmissionService` on
/// the legacy route instead of here. See
/// `docs/convergence-v1/TAB08_ENDPOINT_GAP.md`.
///
/// Cancellation likewise stays on its existing call: `bookings.cancel` exists
/// canonically, but moving a state-changing action is TAB 10's job, with the
/// idempotency and state-conflict handling that tab specifies. Reading is safe
/// to move on its own; mutating is not.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/booking/customer_booking.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/bookings/data/bookings_data_source.dart';

/// Maps the raw API envelope to typed domain objects so higher-level code —
/// stores, BLoCs, screens — never touches raw JSON.
class BookingRepository {
  BookingRepository(
    this._api, {
    required BookingsDataSource compatibility,
    BookingsDataSource? canonical,
    CanonicalRouter? router,
  })  : _compatibility = compatibility,
        _canonical = canonical,
        _router = router;

  final ServanaApiClient _api;
  final BookingsDataSource _compatibility;
  final BookingsDataSource? _canonical;
  final CanonicalRouter? _router;

  /// The transport answering right now. Falls back to compatibility whenever
  /// the canonical source or router is absent, so a half-wired injector cannot
  /// route at a transport that does not exist.
  BookingsDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<BookingsDataSource>(
      V1Capability.bookingReads,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when reads are served by `/api/v1/bookings`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.bookingReads) ?? false);

  /// Bookings for [userId].
  ///
  /// The canonical transport ignores [userId] and reads identity from the
  /// token; the legacy one requires it as a query parameter. Callers pass it
  /// either way, and it confers no authority on either transport.
  Future<List<CustomerBooking>> getBookings(String userId) =>
      _source.list(userId);

  Future<CustomerBooking> getBookingById(String bookingId) =>
      _source.byId(bookingId);

  /// The customer's timeline for [bookingId].
  Future<List<Map<String, dynamic>>> getTimeline(String bookingId) =>
      _source.timeline(bookingId);

  /// Requests cancellation of [bookingId] with a mandatory [reason].
  ///
  /// Still on the legacy call. `bookings.cancel` exists canonically and carries
  /// real `Idempotency-Key` semantics — `IDEMPOTENCY_KEY_REUSED` — and adopting
  /// them properly is TAB 10's scope, not a read migration's.
  Future<void> cancelBooking(String bookingId, String reason) async {
    await _api.cancelBooking(
      bookingId: int.parse(bookingId),
      reason: reason,
    );
  }
}
