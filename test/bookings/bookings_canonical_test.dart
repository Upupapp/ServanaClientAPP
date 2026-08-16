/// TAB 09 — canonical booking reads.
///
/// Unlike TAB 08, this tab could migrate for real: `bookings.listMine`,
/// `bookings.get` and `bookings.timeline` all exist in the canonical contract
/// and are marked `implemented`. Creation still does not exist, which is why
/// this boundary is reads-only and says so in its name.
///
/// The property worth the most here is the identity one: the canonical list
/// route takes the customer FROM THE TOKEN — *"Identity comes from the token,
/// never from a parameter"* — where the legacy route takes `?userId=`.
library;

import 'dart:convert';

import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/bookings/data/bookings_canonical_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A booking in the shape `bookingService.formatBooking` produces — the same
/// formatter behind BOTH transports, which is why the DTOs did not change.
Map<String, dynamic> bookingJson({
  int id = 4242,
  String status = 'CONFIRMED',
  String paymentStatus = 'PAID',
}) =>
    <String, dynamic>{
      'id': id,
      'bookingId': id,
      'status': status,
      'paymentStatus': paymentStatus,
      'schedule': '2026-09-01T02:30:00.000Z',
      'serviceName': 'Aircon Cleaning',
    };

void main() {
  V1ApiClient client(List<Uri> into, Object body) => V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          into.add(request.url);
          return http.Response(
            jsonEncode({'data': body}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

  group('canonical routes', () {
    test('the list route sends NO userId — identity is the token', () async {
      final urls = <Uri>[];
      final source = BookingsCanonicalDataSource(client(urls, {
        'bookings': [bookingJson()],
      }));

      // The caller still passes one, because the legacy transport needs it.
      await source.list('cust-should-be-ignored');

      expect(urls.single.path, '/api/v1/bookings');
      // The whole point: the app can no longer tell the server whose bookings
      // to return.
      expect(urls.single.queryParameters, isEmpty);
      expect(urls.single.toString(), isNot(contains('cust-should-be-ignored')));
    });

    test('detail and timeline address the booking by id', () async {
      final urls = <Uri>[];
      final source = BookingsCanonicalDataSource(
        client(urls, {'booking': bookingJson(), 'timeline': <dynamic>[]}),
      );

      await source.byId('4242');
      await source.timeline('4242');

      expect(urls[0].path, '/api/v1/bookings/4242');
      expect(urls[1].path, '/api/v1/bookings/4242/timeline');
    });
  });

  group('the DTO survives the move', () {
    test('a canonical booking parses into the same CustomerBooking', () async {
      final source = BookingsCanonicalDataSource(client(<Uri>[], {
        'bookings': [bookingJson(id: 7, status: 'IN_PROGRESS')],
      }));

      final bookings = await source.list('anything');

      expect(bookings, hasLength(1));
      expect(bookings.single.status, BookingStatus.inProgress);
    });

    test('booking state and payment state stay separate values', () async {
      // The acceptance gate: one enum must not carry both. A booking can be
      // CONFIRMED and unpaid, or COMPLETED and refunded.
      final source = BookingsCanonicalDataSource(client(<Uri>[], {
        'bookings': [bookingJson(status: 'CONFIRMED', paymentStatus: 'PENDING')],
      }));

      final booking = (await source.list('anything')).single;

      expect(booking.status, BookingStatus.confirmed);
      expect(booking.paymentStatus, 'PENDING');
      expect(booking.isPaid, isFalse,
          reason: 'a confirmed booking is not thereby a paid one');
    });

    test('an unknown state is never read as confirmed', () async {
      final source = BookingsCanonicalDataSource(client(<Uri>[], {
        'bookings': [bookingJson(status: 'SOMETHING_NEW')],
      }));

      final booking = (await source.list('anything')).single;

      // Failing toward "confirmed" would tell a customer their booking is on
      // when the app has no idea what the server said.
      expect(booking.status, BookingStatus.unknown);
      expect(booking.status, isNot(BookingStatus.confirmed));
    });

    test('an ISO timestamp is read as UTC, not as local time', () async {
      final source = BookingsCanonicalDataSource(client(<Uri>[], {
        'bookings': [bookingJson()],
      }));

      final booking = (await source.list('anything')).single;

      // A Z-suffixed instant reinterpreted in the device zone is how a booking
      // renders hours away from when it was made. The instant must survive
      // parsing; how it is DISPLAYED is the screen's business.
      expect(booking.scheduledAt.toUtc().hour, 2);
      expect(booking.scheduledAt.toUtc().minute, 30);
      expect(booking.scheduledAt.isUtc || booking.scheduledAt.toUtc().year == 2026,
          isTrue);
    });

    test('an empty list is empty, not an error', () async {
      final source =
          BookingsCanonicalDataSource(client(<Uri>[], {'bookings': <dynamic>[]}));
      expect(await source.list('anything'), isEmpty);
    });
  });

  group('capability gating', () {
    test('bookings reads are off in every build today', () {
      const availability = CanonicalAvailability();
      expect(availability.isAvailable(V1Capability.bookingReads), isFalse);
    });

    test('enabling bookings enables nothing else', () {
      const on = CanonicalRouter(
        availability: CanonicalAvailability(
          enabled: true,
          capabilities: {V1Capability.bookingReads},
        ),
      );

      expect(on.isCanonical(V1Capability.bookingReads), isTrue);
      expect(on.isCanonical(V1Capability.catalog), isFalse);
      expect(on.isCanonical(V1Capability.search), isFalse);
    });

    test('the capability is named for reads, because create has no endpoint',
        () {
      // A capability called `bookings` would claim the DOMAIN migrated when its
      // most important write cannot. `bookingReads` claims only the reads.
      // See TAB08_ENDPOINT_GAP.md.
      final names = V1Capability.values.map((c) => c.name);
      expect(names, contains('bookingReads'));
      expect(names, isNot(contains('bookings')));
      expect(names, isNot(contains('booking')));
    });
  });
}
