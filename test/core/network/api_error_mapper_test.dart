import 'dart:async';
import 'dart:io';

import 'package:client/core/network/api_error_mapper.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ApiErrorMapper();

  ApiFailure map(int status, {String body = '', Map<String, String>? headers}) =>
      mapper.fromResponse(
        status: status,
        body: body,
        headers: headers ?? const <String, String>{},
      );

  String v1(String code, {String message = 'nope', String? requestId}) =>
      '{"error":{"code":"$code","message":"$message"'
      '${requestId == null ? '' : ',"requestId":"$requestId"'}}}';

  group('status classification', () {
    test('401 is an auth failure and invalidates the session', () {
      final f = map(401, body: v1('TOKEN_EXPIRED'));
      expect(f, isA<AuthFailure>());
      expect(f.invalidatesSession, isTrue);
      expect(f.isRetryable, isFalse);
    });

    test('403 is forbidden and does not invalidate the session', () {
      final f = map(403, body: v1('BOOKING_ACCESS_DENIED'));
      expect(f, isA<ForbiddenFailure>());
      expect(f.invalidatesSession, isFalse);
    });

    test('404 is not-found', () {
      expect(map(404, body: v1('BOOKING_NOT_FOUND')), isA<NotFoundFailure>());
    });

    test('400, 415 and 422 are validation', () {
      expect(map(400, body: v1('VALIDATION_FAILED')), isA<ValidationFailure>());
      expect(map(415, body: v1('UNSUPPORTED_MEDIA_TYPE')),
          isA<ValidationFailure>());
      expect(map(422, body: v1('REVIEW_NOT_ELIGIBLE')), isA<ValidationFailure>());
    });

    test('409 is a state conflict', () {
      expect(map(409, body: v1('BOOKING_TERMINAL')), isA<StateConflictFailure>());
    });

    test('410 Gone is a state conflict, not a not-found', () {
      // An expired OTP is "the world moved on", which is the state-conflict
      // recovery, not "this never existed".
      expect(map(410, body: v1('OTP_EXPIRED')), isA<StateConflictFailure>());
    });

    test('429 is a rate limit and is retryable', () {
      final f = map(429, body: v1('RATE_LIMITED'));
      expect(f, isA<RateLimitFailure>());
      expect(f.isRetryable, isTrue);
    });

    test('408 and 5xx are retryable', () {
      expect(map(408).isRetryable, isTrue);
      expect(map(500, body: v1('INTERNAL')).isRetryable, isTrue);
      expect(map(503).isRetryable, isTrue);
    });

    test('an unclassifiable status fails closed as unknown and not retryable',
        () {
      final f = map(418);
      expect(f, isA<UnknownFailure>());
      expect(f.isRetryable, isFalse);
    });
  });

  group('code overrides', () {
    test('IDEMPOTENCY_KEY_REUSED is its own case, not a state conflict', () {
      // Both are 409 and the recoveries are opposite: a state conflict means
      // "look again, it may not have happened"; this means "it happened, do
      // not send it again".
      final f = map(409, body: v1('IDEMPOTENCY_KEY_REUSED'));
      expect(f, isA<IdempotencyConflictFailure>());
      expect(f, isNot(isA<StateConflictFailure>()));
    });

    test('IDEMPOTENCY_KEY_INVALID is our bug, not the customer\'s input', () {
      // 400 would otherwise make this a validation failure and send the
      // customer to edit a field they never filled in.
      expect(map(400, body: v1('IDEMPOTENCY_KEY_INVALID')), isA<UnknownFailure>());
    });

    test('OTP cooldowns are rate limits', () {
      expect(map(429, body: v1('BOOKING_OTP_RESEND_COOLDOWN')),
          isA<RateLimitFailure>());
      expect(map(429, body: v1('BOOKING_OTP_ATTEMPTS_EXHAUSTED')),
          isA<RateLimitFailure>());
    });

    test('upstream 502s are retryable', () {
      expect(map(502, body: v1('PAYMENT_PROCESSOR_UNAVAILABLE')).isRetryable,
          isTrue);
    });
  });

  group('envelope parsing', () {
    test('reads code, message and requestId from the v1 envelope', () {
      final f = map(409,
          body: v1('BOOKING_TERMINAL',
              message: 'This booking is already complete.', requestId: 'req_1'));
      expect(f.code, 'BOOKING_TERMINAL');
      expect(f.safeMessage, 'This booking is already complete.');
      expect(f.requestId, 'req_1');
    });

    test('reads the legacy {status:error, error:<string>} envelope', () {
      final f = map(400, body: '{"status":"error","error":"Email is required"}');
      expect(f.safeMessage, 'Email is required');
    });

    test('reads the legacy {success:false, message} envelope', () {
      final f = map(400, body: '{"success":false,"message":"Invalid code"}');
      expect(f.safeMessage, 'Invalid code');
    });

    test('falls back to the client request id when the body carries none', () {
      final f = mapper.fromResponse(
          status: 500, body: '{}', fallbackRequestId: 'req_local');
      expect(f.requestId, 'req_local');
    });

    test('an unparseable body still yields a classified failure', () {
      final f = map(503, body: '<html>502 Bad Gateway</html>');
      expect(f, isA<RetryableFailure>());
      expect(f.code, isNull);
    });

    test('field errors are extracted from details', () {
      final f = map(422,
          body: '{"error":{"code":"VALIDATION_FAILED","message":"Bad",'
              '"details":{"email":"is invalid","phone":["too short"]}}}');
      expect(f, isA<ValidationFailure>());
      expect((f as ValidationFailure).fieldErrors,
          <String, String>{'email': 'is invalid', 'phone': 'too short'});
    });
  });

  group('never leaks internals to the customer', () {
    test('a message that looks like an exception is replaced', () {
      final f = map(500,
          body: '{"error":{"code":"INTERNAL",'
              '"message":"Error: connect ECONNREFUSED 127.0.0.1:5432"}}');
      expect(f.safeMessage, isNot(contains('ECONNREFUSED')));
      expect(f.safeMessage, "Something went wrong on our end. Please try again.");
    });

    test('a SQL fragment is replaced', () {
      final f = map(500,
          body: '{"message":"SELECT * FROM bookings WHERE id = 1 failed"}');
      expect(f.safeMessage, isNot(contains('SELECT')));
    });

    test('an over-long message is replaced', () {
      final f = map(400, body: '{"message":"${'x' * 250}"}');
      expect(f.safeMessage, 'Please check the details and try again.');
    });

    test('the raw body is kept out of toString', () {
      final f = map(500, body: '{"message":"internal detail"}');
      expect(f.toString(), isNot(contains('internal detail')));
      // …but is still available for logs.
      expect(f.debugDetail, contains('internal detail'));
    });
  });

  group('retry-after', () {
    test('is read from the header', () {
      final f = map(429,
          body: v1('RATE_LIMITED'), headers: {'retry-after': '30'});
      expect((f as RateLimitFailure).retryAfter, const Duration(seconds: 30));
    });

    test('is null when absent or unparseable', () {
      expect((map(429, body: v1('RATE_LIMITED')) as RateLimitFailure).retryAfter,
          isNull);
      expect(
          (map(429, body: v1('RATE_LIMITED'), headers: {'retry-after': 'soon'})
                  as RateLimitFailure)
              .retryAfter,
          isNull);
    });
  });

  group('transport failures', () {
    test('a socket error is retryable and marked as transport', () {
      final f = mapper.fromTransport(const SocketException('no route'));
      expect(f, isA<RetryableFailure>());
      expect((f as RetryableFailure).isTransport, isTrue);
      expect(f.safeMessage, contains('No connection'));
    });

    test('a timeout is retryable', () {
      final f = mapper.fromTransport(TimeoutException('slow'));
      expect(f.isRetryable, isTrue);
    });

    test('an already-mapped failure passes through unchanged', () {
      const original = ForbiddenFailure(safeMessage: 'nope');
      expect(identical(mapper.fromTransport(original), original), isTrue);
    });

    test('an unrecognised throw does not leak its text', () {
      final f = mapper.fromTransport(StateError('internal invariant broken'));
      expect(f.safeMessage, isNot(contains('invariant')));
    });
  });
}
