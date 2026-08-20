/// A booking failure must name a cause the app actually knows.
///
/// Every case below is a body or status `POST /api/bookings` really produces,
/// read out of `bookingService.createBooking` and `bookingCreateValidation.ts`
/// on the commit production runs (`f8d9b78`, verified equal to
/// `Upupapp/servana_api` main on 2026-08-20) — not invented to agree with the
/// mapper.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/booking/booking_submission_result.dart';
import 'package:flutter_test/flutter_test.dart';

ServanaApiException _api(int status, Object body) => ServanaApiException(
      statusCode: status,
      body: body is String ? body : body.toString(),
    );

void main() {
  group('the status decides, not the sentence', () {
    test('a 500 is never reported as a connectivity problem', () {
      final result = BookingErrorMapper.fromException(
        _api(500, '{"success":false,"message":"Internal server error"}'),
      );

      expect(result.category, BookingErrorCategory.serverFailure);
      expect(result.message.toLowerCase(), isNot(contains('connection')));
      expect(result.message.toLowerCase(), isNot(contains('internet')));
    });

    test('a 502 from nginx in front of a restarting API is a server failure',
        () {
      // The exact condition of the 19 August outage, and the shape that has no
      // JSON body at all because nginx wrote the page.
      final result = BookingErrorMapper.fromException(
        _api(502, '<html><head><title>502 Bad Gateway</title></head></html>'),
      );

      expect(result.category, BookingErrorCategory.serverFailure);
      expect(result.message.toLowerCase(), isNot(contains('connection')));
    });

    test('504 too — the status that matched no keyword list before', () {
      expect(
        BookingErrorMapper.fromException(_api(504, 'Gateway Time-out')).category,
        BookingErrorCategory.serverFailure,
      );
    });

    test('a 401 sends the customer to sign in', () {
      expect(
        BookingErrorMapper.fromException(
          _api(401, '{"status":"failed","code":"UNAUTHENTICATED"}'),
        ).category,
        BookingErrorCategory.authenticationRequired,
      );
    });

    test('the client\'s own 408 timeout IS a connectivity answer', () {
      final result = BookingErrorMapper.fromException(_api(408, 'timeout'));
      expect(result.category, BookingErrorCategory.networkUnavailable);
    });
  });

  group('the body\'s code is read before its prose', () {
    test('SLOT_FULL is a slot problem, not a duplicate', () {
      final result = BookingErrorMapper.fromException(
        _api(
          409,
          '{"success":false,"code":"SLOT_FULL","message":'
              '"That branch slot just filled up. Choose another time."}',
        ),
      );
      expect(result.category, BookingErrorCategory.slotUnavailable);
    });

    test('IDEMPOTENCY_KEY_REUSED points at My Bookings', () {
      final result = BookingErrorMapper.fromException(
        _api(409, '{"success":false,"code":"IDEMPOTENCY_KEY_REUSED"}'),
      );
      expect(result.category, BookingErrorCategory.duplicateSubmission);
      expect(result.message, contains('My Bookings'));
    });
  });

  group('the 400s a real booking hits', () {
    test('"Service not available in your area." is a coverage refusal', () {
      // The regression this file exists for. That sentence contains neither
      // "address" nor "coverage", so the keyword mapper matched nothing and
      // told the customer "Something went wrong. Please try again." — advice to
      // repeat the one action that cannot succeed.
      final result = BookingErrorMapper.fromException(
        _api(
          400,
          '{"success":false,"message":"Service not available in your area."}',
        ),
      );

      expect(result.category, BookingErrorCategory.addressOutsideCoverage);
      expect(result.message.toLowerCase(), contains('service area'));
    });

    test('"Invalid address." asks for a different address', () {
      expect(
        BookingErrorMapper.fromException(
          _api(400, '{"success":false,"message":"Invalid address."}'),
        ).category,
        BookingErrorCategory.addressOutsideCoverage,
      );
    });

    test('"Address missing locationId." does not leak the field name', () {
      final result = BookingErrorMapper.fromException(
        _api(400, '{"success":false,"message":"Address missing locationId."}'),
      );
      expect(result.message, isNot(contains('locationId')));
      expect(result.message, isNot(contains('location_id')));
    });

    test('"Invalid service option." names the service', () {
      expect(
        BookingErrorMapper.fromException(
          _api(400, '{"success":false,"message":"Invalid service option."}'),
        ).category,
        BookingErrorCategory.serviceUnavailable,
      );
    });

    test('"A valid branch is required." never reaches the customer verbatim',
        () {
      // The validator's own words. A customer on a branchless service has no
      // branch control to look for, so echoing this would send them hunting.
      final result = BookingErrorMapper.fromException(
        _api(400, '{"success":false,"message":"A valid branch is required."}'),
      );
      expect(result.message, isNot(contains('valid branch')));
    });
  });

  group('nothing raw ever reaches the screen', () {
    test('a SocketException does not render its host name', () {
      final result = BookingErrorMapper.fromException(
        Exception(
          "SocketException: Failed host lookup: 'api.servana.com.ph' "
          '(OS Error: No address associated with hostname, errno = 7)',
        ),
      );

      expect(result.category, BookingErrorCategory.networkUnavailable);
      expect(result.message, isNot(contains('api.servana.com.ph')));
      expect(result.message, isNot(contains('errno')));
    });

    test('an unrecognised exception is safe and actionable', () {
      final result =
          BookingErrorMapper.fromException(StateError('Bad state: No element'));
      expect(result.message, isNot(contains('Bad state')));
      expect(result.message, isNotEmpty);
    });

    test('no mapped message is ever empty or a stack trace', () {
      final samples = <Object>[
        _api(400, '{"message":"Service not available in your area."}'),
        _api(409, '{"code":"SLOT_FULL"}'),
        _api(500, 'boom'),
        _api(401, ''),
        _api(408, ''),
        _api(418, 'teapot'),
        Exception('SocketException'),
        StateError('anything'),
      ];

      for (final sample in samples) {
        final message = BookingErrorMapper.fromException(sample).message;
        expect(message.trim(), isNotEmpty, reason: '$sample');
        expect(message, isNot(contains('#0')), reason: '$sample');
        expect(message, isNot(contains('Exception:')), reason: '$sample');
        expect(message, isNot(contains('ServanaApiException')),
            reason: '$sample');
      }
    });
  });
}
