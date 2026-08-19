/// Booking reads as the app does them today.
///
/// This is the source every shipped build uses. It changes no endpoint and no
/// envelope handling — it is the previous `BookingRepository` body, moved
/// behind [BookingsDataSource] so the repository has one call path whichever
/// transport answers.
///
/// The envelope tolerance below is inherited, not invented. Each fallback in it
/// exists because a route was observed returning that shape.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/booking/customer_booking.dart';
import 'package:client/modules/bookings/data/bookings_data_source.dart';

class BookingsCompatibilityDataSource implements BookingsDataSource {
  BookingsCompatibilityDataSource(this._api);

  final ServanaApiClient _api;

  /// Envelope: `{ success: true, bookings: [...] }`.
  ///
  /// [userId] is required here: the legacy route reads it as a query parameter.
  @override
  Future<List<CustomerBooking>> list(String userId) async {
    final result = await _api.getUserBookings(userId: userId);

    final raw = result['bookings'];
    // No bookings is an empty list, not a throw — a new customer is not an
    // error state.
    if (raw == null) return const [];

    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(CustomerBooking.fromApiMap)
        .toList();
  }

  /// Uses `GET /api/<id>` — the customer path. `/api/bookings/<id>` does not
  /// exist on this transport.
  @override
  Future<CustomerBooking> byId(String bookingId) async {
    final result = await _api.getBookingDetail(bookingId);

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

  /// `tracking` and `data` stay in the fallback chain on purpose. An app build
  /// outlives a deploy in both directions, and a released binary pointed at an
  /// API that has not shipped the route should degrade to an empty timeline
  /// rather than throw.
  @override
  Future<List<Map<String, dynamic>>> timeline(String bookingId) async {
    final result = await _api.getBookingTimeline(int.parse(bookingId));

    final raw = result['timeline'] ?? result['tracking'] ?? result['data'];
    if (raw == null) return const [];

    final list = raw is List ? raw : <dynamic>[];
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
