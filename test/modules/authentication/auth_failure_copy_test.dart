import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/authentication/domain/auth_failure_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AuthFailureCopy copyFor(String code, {ApiFailure? failure}) =>
      AuthFailureCopy.of(failure ?? StateConflictFailure(safeMessage: 'x', code: code));

  group('the six codes the Master Command names', () {
    test('INVALID_CREDENTIALS asks them to retype', () {
      final copy = copyFor('INVALID_CREDENTIALS');
      expect(copy.message, 'The email or password is incorrect.');
      expect(copy.recovery, AuthRecovery.retryInput);
    });

    test('ACCOUNT_UNVERIFIED sends them to verification', () {
      final copy = copyFor('ACCOUNT_UNVERIFIED');
      expect(copy.recovery, AuthRecovery.verifyAccount);
    });

    test('OTP_INVALID and OTP_EXPIRED are DIFFERENT recoveries', () {
      // The old screen matched on e.toString().contains('400') and could not
      // tell these apart. They need different buttons: retype vs resend.
      final invalid = copyFor('OTP_INVALID');
      final expired = copyFor('OTP_EXPIRED');
      expect(invalid.recovery, AuthRecovery.retryInput);
      expect(expired.recovery, AuthRecovery.resendCode);
      expect(invalid.message, isNot(equals(expired.message)));
    });

    test('RATE_LIMITED tells them to wait and carries the server budget', () {
      final copy = AuthFailureCopy.of(const RateLimitFailure(
        safeMessage: 'x',
        code: 'RATE_LIMITED',
        retryAfter: Duration(seconds: 45),
      ));
      expect(copy.recovery, AuthRecovery.wait);
      expect(copy.retryAfter, const Duration(seconds: 45));
    });

    test('RESET_TOKEN_INVALID restarts the flow', () {
      final copy = copyFor('RESET_TOKEN_INVALID');
      expect(copy.recovery, AuthRecovery.restartFlow);
    });
  });

  group('OTP cooldown codes are rate limits with a countdown', () {
    for (final code in const <String>[
      'BOOKING_OTP_RESEND_COOLDOWN',
      'BOOKING_OTP_RESEND_LIMIT',
      'BOOKING_OTP_ATTEMPTS_EXHAUSTED',
    ]) {
      test(code, () {
        final copy = AuthFailureCopy.of(
            RateLimitFailure(safeMessage: 'x', code: code, retryAfter: null));
        expect(copy.recovery, AuthRecovery.wait);
      });
    }
  });

  group('falls back to the failure class when there is no code', () {
    test('AuthFailure asks them to sign in again', () {
      final copy = AuthFailureCopy.of(const AuthFailure(safeMessage: 'x'));
      expect(copy.recovery, AuthRecovery.reauthenticate);
    });

    test('a transport failure reads as offline', () {
      final copy = AuthFailureCopy.of(
          const RetryableFailure(safeMessage: 'x', isTransport: true));
      expect(copy.message, contains('offline'));
      expect(copy.recovery, AuthRecovery.retryRequest);
    });

    test('a server-side retryable does NOT blame the connection', () {
      final copy = AuthFailureCopy.of(
          const RetryableFailure(safeMessage: 'x', isTransport: false));
      expect(copy.message, isNot(contains('offline')));
      expect(copy.recovery, AuthRecovery.retryRequest);
    });

    test('validation asks them to check the details', () {
      final copy = AuthFailureCopy.of(const ValidationFailure(safeMessage: 'x'));
      expect(copy.recovery, AuthRecovery.retryInput);
    });

    test('every failure class yields copy and a recovery', () {
      // Exhaustiveness: a new sealed case must not fall through to nothing.
      final failures = <ApiFailure>[
        const AuthFailure(safeMessage: 'x'),
        const ForbiddenFailure(safeMessage: 'x'),
        const NotFoundFailure(safeMessage: 'x'),
        const ValidationFailure(safeMessage: 'x'),
        const StateConflictFailure(safeMessage: 'x'),
        const IdempotencyConflictFailure(safeMessage: 'x'),
        const RateLimitFailure(safeMessage: 'x'),
        const RetryableFailure(safeMessage: 'x'),
        const UnknownFailure(safeMessage: 'x'),
      ];
      for (final failure in failures) {
        final copy = AuthFailureCopy.of(failure);
        expect(copy.message, isNotEmpty, reason: '${failure.runtimeType}');
      }
    });
  });

  group('never leaks internals', () {
    test('copy is our own, not the backend prose', () {
      final copy = AuthFailureCopy.of(const StateConflictFailure(
        safeMessage: 'SequelizeDatabaseError: relation does not exist',
        code: 'OTP_EXPIRED',
      ));
      expect(copy.message, isNot(contains('Sequelize')));
      expect(copy.message, 'That code has expired. Request a new one.');
    });
  });
}
