import 'package:client/common/services/error_message_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMessageMapper.forLogin', () {
    test('null input returns default', () {
      expect(
        ErrorMessageMapper.forLogin(null),
        equals('The email or password is incorrect.'),
      );
    });

    test('empty string returns default', () {
      expect(
        ErrorMessageMapper.forLogin(''),
        equals('The email or password is incorrect.'),
      );
    });

    test('invalid credentials message', () {
      expect(
        ErrorMessageMapper.forLogin('invalid credentials'),
        equals('The email or password is incorrect.'),
      );
      expect(
        ErrorMessageMapper.forLogin('User not found'),
        equals('The email or password is incorrect.'),
      );
    });

    test('unverified email message', () {
      final msg = ErrorMessageMapper.forLogin('email not verified');
      expect(msg.toLowerCase(), contains('verify'));
    });

    test('rate limit message', () {
      final msg = ErrorMessageMapper.forLogin('too many attempts');
      expect(msg.toLowerCase(), contains('wait'));
    });

    test('network / offline message', () {
      final msg = ErrorMessageMapper.forLogin('network error');
      expect(msg.toLowerCase(), contains('offline'));
    });

    test('server error message', () {
      final msg = ErrorMessageMapper.forLogin('500 internal server error');
      expect(msg, isNotEmpty);
    });

    test('account disabled message', () {
      final msg = ErrorMessageMapper.forLogin('account is suspended');
      expect(msg.toLowerCase(), contains('disabled'));
    });

    test('unrecognised message returns default', () {
      expect(
        ErrorMessageMapper.forLogin('something completely unknown xyzzy'),
        equals('The email or password is incorrect.'),
      );
    });
  });

  group('ErrorMessageMapper.forRegistration', () {
    test('null returns default', () {
      expect(
        ErrorMessageMapper.forRegistration(null),
        contains('Registration failed'),
      );
    });

    test('duplicate email', () {
      final msg = ErrorMessageMapper.forRegistration('email already exists');
      expect(msg.toLowerCase(), contains('already exists'));
    });

    test('network error', () {
      final msg = ErrorMessageMapper.forRegistration('connection refused');
      expect(msg.toLowerCase(), contains('offline'));
    });

    test('weak password', () {
      final msg = ErrorMessageMapper.forRegistration('password too weak');
      expect(msg.toLowerCase(), contains('password'));
    });

    test('invalid email', () {
      final msg = ErrorMessageMapper.forRegistration('email invalid format');
      expect(msg.toLowerCase(), contains('email'));
    });
  });

  group('ErrorMessageMapper static helpers', () {
    test('forSessionExpiry returns non-empty string', () {
      expect(ErrorMessageMapper.forSessionExpiry(), isNotEmpty);
    });

    test('forNetwork returns non-empty string', () {
      expect(ErrorMessageMapper.forNetwork(), isNotEmpty);
    });

    test('forServerError returns non-empty string', () {
      expect(ErrorMessageMapper.forServerError(), isNotEmpty);
    });
  });
}
