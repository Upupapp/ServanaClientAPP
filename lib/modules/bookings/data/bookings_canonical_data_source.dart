/// Booking reads over the canonical `/api/v1/bookings` namespace.
///
/// ## Not reachable in any shipped build
///
/// Selected only when `CanonicalAvailability.isAvailable(V1Capability.bookingReads)`
/// — which requires `--dart-define=CANONICAL_V1_ENABLED=true` AND `bookings` in
/// `CANONICAL_V1_CAPABILITIES`. No production build passes either.
///
/// ## Why the DTOs did not have to change
///
/// The canonical `Booking` schema is documented as *"a booking as produced by
/// `bookingService.formatBooking`"* — the same formatter behind the legacy
/// route. So `CustomerBooking.fromApiMap` parses both, and this migration is a
/// change of URL and envelope rather than of meaning. That is worth stating,
/// because it is the reason this source is small: had the shapes differed, the
/// difference would belong here and not in the screens.
///
/// ## What genuinely improves
///
/// `GET /api/v1/bookings` takes the customer **from the token**. Its contract
/// says so: *"Identity comes from the token, never from a parameter."* The
/// legacy route takes `?userId=`, so today the app tells the server whose
/// bookings to return. Under this source it stops being able to.
library;

import 'package:client/common/domain/booking/customer_booking.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/bookings/data/bookings_data_source.dart';

class BookingsCanonicalDataSource implements BookingsDataSource {
  BookingsCanonicalDataSource(this._api);

  final V1ApiClient _api;

  /// [userId] is ignored, deliberately and completely. Passing it would be
  /// asking the server to trust a client-supplied identity on a route built to
  /// refuse exactly that.
  @override
  Future<List<CustomerBooking>> list(String userId) async {
    final envelope = await _api.get(V1Endpoints.bookings());
    return envelope
        .listAt('bookings')
        .map(CustomerBooking.fromApiMap)
        .toList(growable: false);
  }

  @override
  Future<CustomerBooking> byId(String bookingId) async {
    final envelope = await _api.get(V1Endpoints.booking(bookingId));
    final data = envelope.asMap;
    // `Booking` is returned at the root of `data`, not wrapped again.
    final booking = data['booking'];
    return CustomerBooking.fromApiMap(
      booking is Map<String, dynamic> ? booking : data,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> timeline(String bookingId) async {
    final envelope = await _api.get(V1Endpoints.bookingTimeline(bookingId));
    return envelope.listAt('timeline');
  }
}
