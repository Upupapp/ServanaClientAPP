/// The app must never tell a customer their password is wrong because the
/// backend is down.
///
/// This is not hypothetical. On 2026-08-19 `api.servana.com.ph` was answering
/// 500 on every database-backed route (a broken DB credential), and nginx in
/// front of a restarting Node process answers 502/504. `HttpBackend` turns a
/// body it cannot parse into `'Login failed (502).'` and a JSON body with no
/// message into `'Login failed.'` — neither contains a keyword any list in
/// ErrorMessageMapper matches, so both used to fall through to the default:
/// "The email or password is incorrect."
///
/// A customer who reads that changes a password that was never wrong.
library;

import 'package:client/common/services/error_message_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// The exact strings `HttpBackend.authenticate` produces on a failure.
String transportLoginMessage(int status, {bool jsonBody = false}) =>
    jsonBody ? 'Login failed.' : 'Login failed ($status).';

void main() {
  group('a server failure is never reported as a credential failure', () {
    // 502 and 504 are the ones that bite: neither literal appears in any
    // keyword list, so only the status can classify them.
    for (final status in [500, 502, 503, 504]) {
      test('$status does not blame the credentials', () {
        final msg = ErrorMessageMapper.forLogin(
          transportLoginMessage(status),
          statusCode: status,
        );
        expect(msg, isNot(contains('password')));
        expect(msg, isNot(contains('incorrect')));
        expect(msg, equals(ErrorMessageMapper.forServerError()));
      });

      test('$status with a JSON body carrying no message is still honest', () {
        final msg = ErrorMessageMapper.forLogin(
          transportLoginMessage(status, jsonBody: true),
          statusCode: status,
        );
        expect(msg, isNot(contains('password')));
      });

      test('$status with no body at all is still honest', () {
        expect(
          ErrorMessageMapper.forLogin(null, statusCode: status),
          isNot(contains('password')),
        );
      });
    }

    test('408 reads as a connection problem, which is what it is', () {
      expect(
        ErrorMessageMapper.forLogin(transportLoginMessage(408),
            statusCode: 408),
        equals(ErrorMessageMapper.forNetwork()),
      );
    });

    test('429 asks the customer to wait rather than to re-check a password',
        () {
      final msg = ErrorMessageMapper.forLogin(transportLoginMessage(429),
          statusCode: 429);
      expect(msg, contains('Too many'));
      expect(msg, isNot(contains('password')));
    });
  });

  group('401 still means the credentials, because that is what it means', () {
    test('a 401 with no message keeps the credential copy', () {
      expect(
        ErrorMessageMapper.forLogin(null, statusCode: 401),
        equals('The email or password is incorrect.'),
      );
    });

    test('a 401 that names verification still says verification', () {
      expect(
        ErrorMessageMapper.forLogin('email not verified', statusCode: 401),
        contains('verify'),
      );
    });

    test('a 401 that names a disabled account still says disabled', () {
      expect(
        ErrorMessageMapper.forLogin('account suspended', statusCode: 401),
        contains('disabled'),
      );
    });
  });

  group('registration does not blame the customer for a server fault', () {
    for (final status in [500, 502, 504]) {
      test('$status is not reported as bad details', () {
        final msg = ErrorMessageMapper.forRegistration(
          'Registration failed ($status).',
          statusCode: status,
        );
        expect(msg, isNot(contains('check your details')));
        expect(msg, equals(ErrorMessageMapper.forServerError()));
      });
    }

    test('a duplicate account is still reported as a duplicate', () {
      expect(
        ErrorMessageMapper.forRegistration('email already exists',
            statusCode: 409),
        contains('already exists'),
      );
    });
  });

  group('a request that never reached the server', () {
    // The transport writes the copy itself in this case, and passes a null
    // status precisely because there was no response to take one from.
    test('is reported as offline, not as a bad password', () {
      final msg = ErrorMessageMapper.forLogin(
        'Could not reach server. Please check your connection.',
        statusCode: null,
      );
      expect(msg, equals(ErrorMessageMapper.forNetwork()));
    });
  });
}
