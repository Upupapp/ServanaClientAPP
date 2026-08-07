import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/registration/domain/use_cases/validate_registration_step1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validator = ValidateRegistrationFormUseCase();

  ({bool isValid, String? error}) validate(String? name) =>
      validator.isNameValid(RegistrationFormModel(ownerName: name));

  group('customer signup name validation', () {
    test('rejects an empty name', () {
      expect(validate('').isValid, isFalse);
    });

    test('rejects whitespace only', () {
      expect(validate('   ').isValid, isFalse);
    });

    test('rejects a first name without a last name', () {
      final result = validate('Maria');
      expect(result.isValid, isFalse);
      expect(result.error, contains('first and last name'));
    });

    test('accepts a first and last name', () {
      expect(validate('Maria Santos').isValid, isTrue);
    });

    test('accepts a multi-part surname', () {
      expect(validate('Maria de la Cruz').isValid, isTrue);
    });

    test('accepts punctuation within names', () {
      expect(validate("Anne-Marie O'Connor").isValid, isTrue);
    });

    test('accepts Unicode names', () {
      expect(validate('José Rizal').isValid, isTrue);
      expect(validate('李 小龙').isValid, isTrue);
    });

    test('still enforces the existing 60-character contract', () {
      final first = List.filled(30, 'A').join();
      final last = List.filled(30, 'B').join();
      expect(validate('$first $last').isValid, isFalse);
    });
  });

  group('customer signup password matches the backend boundary', () {
    ({bool isValid, String? error}) validate(String password) =>
        validator.isPasswordValid(
          RegistrationFormModel(ownerPassword: password),
        );

    test('rejects a six-character password', () {
      expect(validate('123456').isValid, isFalse);
    });

    test('accepts a seven-character password', () {
      expect(validate('1234567').isValid, isTrue);
    });
  });
}
