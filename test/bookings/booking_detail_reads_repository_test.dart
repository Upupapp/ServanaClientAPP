/// The booking detail read goes through `BookingRepository`.
///
/// ## What this is protecting
///
/// `BookingRepository` was built as the seam that chooses between the
/// canonical `/api/v1/bookings/:id` transport and the legacy one and returns
/// the same `CustomerBooking` from either. It was registered in the injector
/// and never resolved: the detail screen called `ServanaApiClient.getBooking`
/// directly and re-derived every field from the raw map. So
/// `V1Capability.bookingReads` was inert whatever it was set to — the object
/// that reads the flag had no callers, and the flag could be flipped in a
/// build with no effect at all.
///
/// The screen itself needs a `BuildContext`, a router and a live locator to
/// render, so what is asserted here is the layer underneath it: that the
/// repository is the thing that answers a detail read, that it honours the
/// capability, and that both transports produce one model. A screen wired to
/// the repository inherits all three; the previous arrangement could inherit
/// none of them.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/bookings/data/booking_repository.dart';
import 'package:client/modules/bookings/data/bookings_canonical_data_source.dart';
import 'package:client/modules/bookings/data/bookings_compatibility_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const base = 'https://api.example.test';

  /// The booking as the LEGACY route serves it: nested under `booking`, with
  /// the amount under finalPrice and the provider already working.
  const legacyBody = <String, dynamic>{
    'success': true,
    'booking': <String, dynamic>{
      'bookingId': 42,
      'bookingCode': 'SVN-000042',
      'status': 'CONFIRMED',
      'workerStatus': 'IN_PROGRESS',
      'serviceOptionName': "Emperor's Drip",
      'serviceName': 'Massage & Wellness',
      'branchName': 'Servana Makati',
      'finalPrice': 1850,
      'scheduledAt': '2026-08-20T09:00:00.000Z',
      'createdAt': '2026-08-18T09:00:00.000Z',
    },
  };

  ({List<Uri> hits, BookingRepository repo}) repositoryWith({
    required Set<V1Capability> capabilities,
  }) {
    final hits = <Uri>[];
    http.Response answer(http.BaseRequest request) {
      hits.add(request.url);
      // The canonical route returns the same booking under `data`, because it
      // is the output of the same formatBooking the legacy route uses.
      final isCanonical = request.url.path.contains('/api/v1/');
      return http.Response(
        jsonEncode(
          isCanonical
              ? <String, dynamic>{'data': legacyBody['booking']}
              : legacyBody,
        ),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    }

    final legacy = MockClient((r) async => answer(r));
    final canonical = MockClient((r) async => answer(r));

    return (
      hits: hits,
      repo: BookingRepository(
        ServanaApiClient(baseUrl: base, client: legacy),
        compatibility: BookingsCompatibilityDataSource(
          ServanaApiClient(baseUrl: base, client: legacy),
        ),
        canonical: BookingsCanonicalDataSource(
          V1ApiClient(baseUrl: base, httpClient: canonical),
        ),
        router: CanonicalRouter(
          availability: CanonicalAvailability(
            enabled: capabilities.isNotEmpty,
            capabilities: capabilities,
          ),
        ),
      ),
    );
  }

  group('the detail read is served by the repository', () {
    test('every shipped build takes the legacy route', () async {
      // Deny-by-default: no capability set, exactly as production is built.
      final c = repositoryWith(capabilities: const <V1Capability>{});

      await c.repo.getBookingById('42');

      expect(c.hits.single.path, '/api/42');
    });

    test('the bookingReads capability moves it to /api/v1', () async {
      final c = repositoryWith(
        capabilities: const <V1Capability>{V1Capability.bookingReads},
      );

      await c.repo.getBookingById('42');

      // This is the assertion the old arrangement could never satisfy: with
      // the screen calling ServanaApiClient directly, setting the capability
      // changed nothing.
      expect(c.hits.single.path, '/api/v1/bookings/42');
    });
  });

  group('both transports produce one model', () {
    test('the same booking reads identically either way', () async {
      final legacy = await repositoryWith(
        capabilities: const <V1Capability>{},
      ).repo.getBookingById('42');

      final canonical = await repositoryWith(
        capabilities: const <V1Capability>{V1Capability.bookingReads},
      ).repo.getBookingById('42');

      // If a screen could tell which transport answered, the migration would
      // reach the presentation layer and the seam would have bought nothing.
      expect(canonical.serviceName, legacy.serviceName);
      expect(canonical.serviceCategory, legacy.serviceCategory);
      expect(canonical.totalAmount, legacy.totalAmount);
      expect(canonical.effectiveWireStatus, legacy.effectiveWireStatus);
    });
  });

  group('the model the screen renders is the one it used to derive', () {
    test('carries the field values the screen parsed by hand', () async {
      final booking = await repositoryWith(
        capabilities: const <V1Capability>{},
      ).repo.getBookingById('42');

      // Each of these was derived inline in _refreshBooking and would have
      // been silently lost by a naive swap to the repository.
      expect(booking.totalAmount, 1850.0, reason: 'finalPrice fallback');
      expect(booking.serviceName, "Emperor's Drip", reason: 'the option name');
      expect(booking.serviceCategory, 'Servana Makati', reason: 'the branch');
      expect(
        booking.effectiveWireStatus,
        'IN_PROGRESS',
        reason: 'the provider outranks a CONFIRMED row',
      );
      expect(booking.latitude, isNull, reason: 'unknown, never (0,0)');
      expect(booking.hasResolvedSchedule, isTrue);
    });

    test('an unparseable schedule is flagged, not fabricated', () async {
      final hits = <Uri>[];
      final repo = BookingRepository(
        ServanaApiClient(baseUrl: base),
        compatibility: BookingsCompatibilityDataSource(
          ServanaApiClient(
            baseUrl: base,
            client: MockClient((r) async {
              hits.add(r.url);
              return http.Response(
                jsonEncode(<String, dynamic>{
                  'booking': <String, dynamic>{'bookingId': 7, 'status': 'NEW'},
                }),
                200,
                headers: <String, String>{'content-type': 'application/json'},
              );
            }),
          ),
        ),
      );

      final booking = await repo.getBookingById('7');

      // scheduledAt falls back to `now` so a screen always has something to
      // render. A reschedule that sent that fabricated instant as
      // `expectedSchedule` would be refused BOOKING_SCHEDULE_CHANGED every
      // time, so the screen must be able to tell the difference.
      expect(booking.hasResolvedSchedule, isFalse);
    });
  });
}
