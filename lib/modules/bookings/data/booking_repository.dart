import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/booking/customer_booking.dart';

/// Repository that mediates between [ServanaApiClient] and the bookings domain.
///
/// All methods map the raw API response envelope to typed domain objects so
/// that higher-level code (stores, BLoCs) never touches raw JSON.
///
/// Response envelope reference (from backend sweep):
///   Customer routes  → { success: bool, booking/bookings/tracking: ..., message?: string }
///   Admin routes     → { status: 'success'|'error', data: ..., meta?: {...} }
class BookingRepository {
  final ServanaApiClient _api;

  BookingRepository(this._api);

  // ──────────────────────────── List ──────────────────────────────────────────

  /// Fetch all bookings for [userId].
  ///
  /// Maps the customer envelope `{ success: true, bookings: [...] }` to a
  /// typed list.  Returns an empty list when the backend returns no bookings
  /// rather than throwing.
  Future<List<CustomerBooking>> getBookings(String userId) async {
    final result = await _api.getUserBookings(userId: userId);

    // Envelope: { success: true, bookings: [...] }
    final raw = result['bookings'];
    if (raw == null) return const [];

    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(CustomerBooking.fromApiMap)
        .toList();
  }

  // ──────────────────────────── Detail ────────────────────────────────────────

  /// Fetch a single booking by its numeric ID string.
  ///
  /// Uses GET /api/<id> (the correct mobile/customer path — NOT /api/bookings/<id>
  /// which does not exist).  Maps the envelope `{ success: true, booking: {...} }`
  /// to a [CustomerBooking].
  Future<CustomerBooking> getBookingById(String bookingId) async {
    final result = await _api.getBookingDetail(bookingId);

    // Envelope: { success: true, booking: { ... } }
    final bookingMap = result['booking'];
    if (bookingMap is Map<String, dynamic>) {
      return CustomerBooking.fromApiMap(bookingMap);
    }

    // Some responses return the booking fields at the root level.
    if (result.containsKey('id') || result.containsKey('bookingId')) {
      return CustomerBooking.fromApiMap(result);
    }

    throw ServanaApiException(
      statusCode: 200,
      body: 'getBookingById: unexpected response shape — no "booking" key. '
          'Raw keys: ${result.keys.join(', ')}',
    );
  }

  // ──────────────────────────── Cancel ────────────────────────────────────────

  /// Request cancellation of [bookingId] with a mandatory [reason].
  ///
  // BACKEND_GAP-C15-001: No customer-facing cancel endpoint exists.  This
  // method calls the admin endpoint and will receive HTTP 403 for non-admin
  // tokens.  The [ServanaApiException] is re-thrown unchanged so the caller
  // (store/BLoC) can surface an appropriate user message.
  // Once a POST /api/<id>/cancel customer route exists, update
  // ServanaApiClient.cancelBooking() to point there instead.
  Future<void> cancelBooking(String bookingId, String reason) async {
    await _api.cancelBooking(
      bookingId: int.parse(bookingId),
      reason: reason,
    );
  }

  // ──────────────────────────── Timeline ──────────────────────────────────────

  /// Fetch the customer's timeline for [bookingId].
  ///
  /// GAP-C15-002 is closed: [ServanaApiClient.getBookingTimeline] now calls the
  /// real customer route (GET /api/<id>/timeline) instead of falling back to
  /// tracking.  Each event is `{ code, label, at, actor, sequence }`, already
  /// worded for the customer by the backend — `label` is safe to render as-is
  /// and `actor` is "YOU" | "PROVIDER" | "SERVANA" from the CUSTOMER's seat.
  ///
  /// `tracking` and `data` stay in the fallback chain. An app build outlives a
  /// deploy in both directions, and a released binary pointed at an API that
  /// has not shipped the route yet should degrade to an empty timeline rather
  /// than throw. Nothing calls this method yet — Command 6 built the route and
  /// the web portal consumes it; this keeps the mobile surface honest for the
  /// screen that eventually will.
  Future<List<Map<String, dynamic>>> getTimeline(String bookingId) async {
    final result = await _api.getBookingTimeline(int.parse(bookingId));

    // Timeline envelope: { success: true, timeline: [...] }
    final raw = result['timeline'] ?? result['tracking'] ?? result['data'];
    if (raw == null) return const [];

    final list = raw is List ? raw : <dynamic>[];
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
