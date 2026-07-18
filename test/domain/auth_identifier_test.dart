import 'package:client/common/domain/auth/auth_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthIdentifier.isMobileInput', () {
    test('recognises 09XX format', () {
      expect(AuthIdentifier.isMobileInput('09171234567'), isTrue);
      expect(AuthIdentifier.isMobileInput('09291234567'), isTrue);
    });

    test('recognises +63 prefix', () {
      expect(AuthIdentifier.isMobileInput('+639171234567'), isTrue);
    });

    test('recognises 63 prefix without +', () {
      expect(AuthIdentifier.isMobileInput('639171234567'), isTrue);
    });

    test('accepts spaces and dashes in mobile', () {
      expect(AuthIdentifier.isMobileInput('0917 123 4567'), isTrue);
      expect(AuthIdentifier.isMobileInput('0917-123-4567'), isTrue);
    });

    test('rejects invalid mobile prefix 08XX', () {
      expect(AuthIdentifier.isMobileInput('08171234567'), isFalse);
    });

    test('rejects short numbers', () {
      expect(AuthIdentifier.isMobileInput('0917123'), isFalse);
    });

    test('rejects email', () {
      expect(AuthIdentifier.isMobileInput('user@example.com'), isFalse);
    });

    test('rejects empty string', () {
      expect(AuthIdentifier.isMobileInput(''), isFalse);
    });

    test('rejects random text', () {
      expect(AuthIdentifier.isMobileInput('notanumber'), isFalse);
    });
  });

  group('AuthIdentifier.isEmailInput', () {
    test('recognises valid email', () {
      expect(AuthIdentifier.isEmailInput('user@example.com'), isTrue);
      expect(AuthIdentifier.isEmailInput('USER@EXAMPLE.COM'), isTrue);
    });

    test('rejects email without @', () {
      expect(AuthIdentifier.isEmailInput('userexample.com'), isFalse);
    });

    test('rejects email without domain', () {
      expect(AuthIdentifier.isEmailInput('user@'), isFalse);
    });

    test('rejects mobile number', () {
      expect(AuthIdentifier.isEmailInput('09171234567'), isFalse);
    });

    test('rejects empty string', () {
      expect(AuthIdentifier.isEmailInput(''), isFalse);
    });
  });

  group('AuthIdentifier.parse', () {
    test('returns EmailIdentifier for valid email', () {
      final id = AuthIdentifier.parse('user@example.com');
      expect(id, isA<EmailIdentifier>());
    });

    test('returns MobileIdentifier for PH mobile', () {
      final id = AuthIdentifier.parse('09171234567');
      expect(id, isA<MobileIdentifier>());
    });

    test('returns null for empty string', () {
      expect(AuthIdentifier.parse(''), isNull);
    });

    test('returns null for ambiguous input', () {
      expect(AuthIdentifier.parse('hello'), isNull);
    });

    test('trims whitespace before parsing', () {
      final id = AuthIdentifier.parse('  user@example.com  ');
      expect(id, isA<EmailIdentifier>());
    });
  });

  group('EmailIdentifier.normalized', () {
    test('lowercases email', () {
      const id = EmailIdentifier('USER@EXAMPLE.COM');
      expect(id.normalized, equals('user@example.com'));
    });

    test('trims whitespace', () {
      const id = EmailIdentifier('  user@example.com  ');
      expect(id.normalized, equals('user@example.com'));
    });
  });

  group('EmailIdentifier.redacted', () {
    test('redacts middle of local part', () {
      const id = EmailIdentifier('paul@gmail.com');
      expect(id.redacted, equals('p***@gmail.com'));
    });

    test('handles very short local part', () {
      const id = EmailIdentifier('a@b.com');
      expect(id.redacted, contains('@'));
    });
  });

  group('MobileIdentifier.normalized', () {
    test('normalises 09XX to +639XX', () {
      const id = MobileIdentifier('09171234567');
      expect(id.normalized, equals('+639171234567'));
    });

    test('normalises 639XX to +639XX', () {
      const id = MobileIdentifier('639171234567');
      expect(id.normalized, equals('+639171234567'));
    });

    test('leaves +639XX unchanged', () {
      const id = MobileIdentifier('+639171234567');
      expect(id.normalized, equals('+639171234567'));
    });
  });

  group('MobileIdentifier.redacted', () {
    test('masks last 4 digits', () {
      const id = MobileIdentifier('+639171234567');
      final r = id.redacted;
      expect(r.endsWith('••••'), isTrue);
      expect(r.startsWith('+63'), isTrue);
    });
  });
}
