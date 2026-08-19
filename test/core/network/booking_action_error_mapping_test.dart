/// TAB 10 — how a booking action's refusal reaches the customer.
///
/// The backend issues one code per distinguishable refusal *"so a client can
/// tell the caller whether to wait, ask for a new code, pick a different time,
/// or contact support"*. That is only true if the client maps each code to the
/// right recovery, and status alone is not enough to do it: `errors.ts` puts
/// four booking codes on 403 and only two of them are access decisions.
library;

import 'package:client/core/network/api_error_mapper.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

const _mapper = ApiErrorMapper();

ApiFailure map(int status, String code, [String message = 'refused']) =>
    _mapper.fromResponse(
      status: status,
      body: '{"error":{"code":"$code","message":"$message"}}',
    );

void main() {
  group('the two 403s that are not access decisions', () {
    test('a wrong OTP is validation, not forbidden', () {
      // BOOKING_OTP_INVALID is 403 — "The booking verification code the
      // customer received did not match." Classified by status alone it became
      // ForbiddenFailure, whose copy is "You don't have access to this." That
      // tells somebody who mistyped one digit that the booking is not theirs,
      // and offers no way to correct it.
      final failure = map(403, 'BOOKING_OTP_INVALID');
      expect(failure, isA<ValidationFailure>());
      expect(failure, isNot(isA<ForbiddenFailure>()));
    });

    test('a wrong worker code is validation too', () {
      expect(map(403, 'BOOKING_WORKER_CODE_INVALID'), isA<ValidationFailure>());
    });

    test('the 403s that ARE access decisions stay forbidden', () {
      // The distinction has to hold in both directions, or the override is just
      // a blanket downgrade of every 403 on a booking.
      expect(map(403, 'BOOKING_ACCESS_DENIED'), isA<ForbiddenFailure>());
      expect(
          map(403, 'BOOKING_OTP_ACTOR_NOT_PERMITTED'), isA<ForbiddenFailure>());
    });
  });

  group('the 409 family separates by code, not by status', () {
    test('an already-applied request is an idempotency conflict', () {
      // Both are 409 and they want opposite words: one says "this already
      // happened, you are fine", the other says "the world moved".
      expect(map(409, 'IDEMPOTENCY_KEY_REUSED'),
          isA<IdempotencyConflictFailure>());
      expect(map(409, 'BOOKING_STATE_CONFLICT'), isA<StateConflictFailure>());
    });

    test('the terminal and reschedule refusals are state conflicts', () {
      for (final code in <String>[
        'BOOKING_TERMINAL',
        'BOOKING_TRANSITION_INVALID',
        'BOOKING_NOT_RESCHEDULABLE',
        'BOOKING_RESCHEDULE_NOTICE_REQUIRED',
        'BOOKING_RESCHEDULE_PROVIDER_CONFLICT',
        'BOOKING_SCHEDULE_CHANGED',
        'BOOKING_OTP_NOT_APPLICABLE',
        'BOOKING_OTP_NOT_ISSUED',
      ]) {
        expect(map(409, code), isA<StateConflictFailure>(), reason: code);
      }
    });

    test('a malformed key is OUR bug, not the customer’s input', () {
      // 400, but nothing on the screen caused it and nothing the customer edits
      // will fix it. Surfacing it as a validation error would point them at
      // their own typing.
      expect(map(400, 'IDEMPOTENCY_KEY_INVALID'), isA<UnknownFailure>());
    });
  });

  group('the OTP budget refusals are rate limits', () {
    test('cooldown, issue ceiling and attempt budget all mean "wait"', () {
      for (final code in <String>[
        'BOOKING_OTP_RESEND_COOLDOWN',
        'BOOKING_OTP_RESEND_LIMIT',
        'BOOKING_OTP_ATTEMPTS_EXHAUSTED',
      ]) {
        expect(map(429, code), isA<RateLimitFailure>(), reason: code);
      }
    });

    test('Retry-After is carried, so the screen need not invent a cooldown',
        () {
      // This is what lets the OTP screen honour the server's window instead of
      // restarting its own 60-second timer on top of a refusal.
      final failure = _mapper.fromResponse(
        status: 429,
        body: '{"error":{"code":"BOOKING_OTP_RESEND_COOLDOWN",'
            '"message":"Please wait before requesting another code."}}',
        headers: const <String, String>{'retry-after': '42'},
      );
      expect(failure, isA<RateLimitFailure>());
      expect((failure as RateLimitFailure).retryAfter,
          const Duration(seconds: 42));
    });

    test('an expired code is a state conflict, not a rate limit', () {
      // 410. "Request another" rather than "wait" — a different recovery from
      // the cooldown, and the reason the two are not collapsed.
      expect(map(410, 'BOOKING_OTP_EXPIRED'), isA<StateConflictFailure>());
    });
  });

  group('the finance codes need no override — verified, not assumed', () {
    // TAB 11 checked every PAYMENT_ and REFUND_ code against `errors.ts` before
    // touching the mapper, and found the status-driven classification already
    // correct for all of them. That is worth pinning rather than leaving as a
    // silent absence: the TAB 10 OTP codes looked equally fine until their
    // statuses were actually read, and two of them were wrong.

    test('a payment state conflict is a state conflict', () {
      expect(map(409, 'PAYMENT_STATE_CONFLICT'), isA<StateConflictFailure>());
    });

    test('an unavailable processor is retryable, not the customer’s problem',
        () {
      // 502, and already in the override table from an earlier tab. Named here
      // because it is the one finance failure where "try again" is the right
      // advice.
      final failure = map(502, 'PAYMENT_PROCESSOR_UNAVAILABLE');
      expect(failure, isA<RetryableFailure>());
      expect(failure.isRetryable, isTrue);
    });

    test('a provider asking about a customer payment is forbidden', () {
      expect(map(403, 'PAYMENT_ACTOR_NOT_PERMITTED'), isA<ForbiddenFailure>());
    });

    test('no payment record is a not-found', () {
      expect(map(404, 'PAYMENT_NOT_FOUND'), isA<NotFoundFailure>());
    });

    test('the refund refusals that mean "the world moved" are state conflicts',
        () {
      for (final code in <String>[
        'REFUND_PAYMENT_NOT_CAPTURED',
        'REFUND_ALREADY_SETTLED',
        'REFUND_IN_PROGRESS',
        'REFUND_OUTCOME_NOT_REFUNDABLE',
      ]) {
        expect(map(409, code), isA<StateConflictFailure>(), reason: code);
      }
    });

    test('the refund refusals the customer can correct are validation', () {
      // 422. REFUND_EXCEEDS_CAPTURED means "ask for less" and
      // REFUND_TRIGGER_INVALID means "pick another reason" — both are things
      // the person on the screen can act on.
      for (final code in <String>[
        'REFUND_EXCEEDS_CAPTURED',
        'REFUND_TRIGGER_INVALID',
      ]) {
        expect(map(422, code), isA<ValidationFailure>(), reason: code);
      }
    });
  });

  group('what reaches the screen', () {
    test('the backend’s own wording is preferred when it is safe', () {
      // "A booking must be moved at least 24 hours before it starts" is more
      // useful than any generic sentence, and it is the only place the notice
      // window is stated to the customer.
      final failure = map(409, 'BOOKING_RESCHEDULE_NOTICE_REQUIRED',
          'A booking must be moved at least 24 hours before it starts.');
      expect(failure.safeMessage,
          'A booking must be moved at least 24 hours before it starts.');
    });

    test('a leaked internal is replaced, not rendered', () {
      final failure = _mapper.fromResponse(
        status: 409,
        body: '{"error":{"code":"BOOKING_STATE_CONFLICT",'
            '"message":"Error: SequelizeDatabaseError at Object.query"}}',
      );
      expect(failure.safeMessage, 'This has already changed. Pull to refresh.');
    });
  });
}
