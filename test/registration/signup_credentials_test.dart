/// Account creation must not write a password to disk, and must not lose the
/// customer's phone number.
///
/// Found by a SWEEP/STITCH/LEAK pass over the mobile client's signup flow.
///
/// ── The password ───────────────────────────────────────────────────────────
/// `RegistrationFormModel` is a Hive type. `ownerPassword` and
/// `ownerConfirmPassword` carried `@HiveField(04)` and `@HiveField(05)`, so the
/// generated adapter contained `..write(obj.ownerPassword)` and the generated
/// `toJson` emitted it.
///
/// `RegistrationBloc` calls `saveRegistrationToLocalUseCase` with the entire
/// form the moment signup succeeds — password included. The only reason a
/// plaintext password was not already sitting in a Hive box is that
/// `RegistrationRepository.saveRegistrationToLocal` is a `//todo: implement`
/// stub that returns without writing.
///
/// That is timing, not a safeguard. The call site is live and the serialiser
/// is generated and ready; implementing that TODO would look like finishing a
/// draft-saving feature and would ship a credential to disk with it.
///
/// ── The phone number ───────────────────────────────────────────────────────
/// Two implementations post to `/api/auth/signup`. The live one
/// (`HttpBackend.registerCustomer`) sends `phoneNumber`; the orphaned one on
/// `ServanaApiClient` does not. The Create Account screen collects "Mobile
/// Number (optional)", so adopting the orphan would silently stop persisting
/// it.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String p) => File(p).readAsStringSync();

String _code(String p) => File(p).readAsLinesSync().where((l) {
      final t = l.trimLeft();
      return !t.startsWith('//') && !t.startsWith('///');
    }).join('\n');

void main() {
  group('no password is ever serialised', () {
    test('the generated Hive adapter cannot write it', () {
      // The .g.dart file is generated, so this asserts against the real
      // serialiser rather than against the annotation that produces it.
      final generated = _read(
          'lib/modules/registration/data/models/registration_form_model.g.dart');

      expect(generated, isNot(contains('ownerPassword')),
          reason:
              'the adapter or toJson would put a plaintext password on disk');
      expect(generated, isNot(contains('ownerConfirmPassword')));
    });

    test('the model declares them outside Hive and outside JSON', () {
      final model = _code(
          'lib/modules/registration/data/models/registration_form_model.dart');

      // Comments stripped: the explanation above the fields names the old
      // annotations, and a raw substring check would match that prose.
      expect(model, isNot(contains('@HiveField(04)')));
      expect(model, isNot(contains('@HiveField(05)')));
      expect(model, contains('includeFromJson: false, includeToJson: false'));

      // The fields themselves must still exist — the form needs them in memory.
      expect(model, contains('final String? ownerPassword'));
      expect(model, contains('final String? ownerConfirmPassword'));
    });

    test('the fields that SHOULD persist still do', () {
      // Guards over-correction: this fix must not disable draft saving for
      // everything else.
      final generated = _read(
          'lib/modules/registration/data/models/registration_form_model.g.dart');
      for (final f in ['ownerName', 'ownerEmail', 'ownerPhoneNo']) {
        expect(generated, contains(f), reason: '$f should still be persisted');
      }
    });

    test('the save call site is still live, which is why this matters', () {
      // If this ever stops being called the fix is still correct, but the
      // urgency changes — so the premise is pinned rather than assumed.
      final bloc = _code(
          'lib/modules/registration/presentation/bloc/registration_bloc.dart');
      expect(bloc, contains('saveRegistrationToLocalUseCase.call('));
    });
  });

  group('the phone number survives signup', () {
    test('the live path sends phoneNumber', () {
      final http = _code('lib/common/data/backend/http_backend.dart');
      expect(http, contains("'phoneNumber': registration.ownerPhoneNo"));
    });

    test('the live path is the one registration actually uses', () {
      final repo = _code(
          'lib/modules/registration/domain/repositories/registration_repository.dart');
      expect(repo, contains('backend.registerCustomer(registration)'));
    });

    test('the drifted duplicate is marked so it cannot be adopted quietly', () {
      final api = _read('lib/common/data/backend/servana_api_client.dart');
      final idx = api.indexOf('Future<Map<String, dynamic>> signup(');
      expect(idx, greaterThan(-1));

      // The @Deprecated must sit immediately above the declaration, not
      // somewhere else in the file.
      final preceding = api.substring(0, idx);
      expect(preceding.trimRight(), endsWith(')'),
          reason: 'expected the @Deprecated annotation to close right above '
              'the signup declaration');
      expect(preceding, contains('@Deprecated('));
    });

    test('the UI still collects it', () {
      // If the field is ever removed, these assertions should be revisited
      // rather than left asserting a value nothing produces.
      final screen = _read(
          'lib/modules/registration/presentation/screens/create_account_screen.dart');
      expect(screen, contains('Mobile Number (optional)'));
      expect(screen, contains('ownerPhoneNo:'));
    });
  });

  group('mobile signup sends exactly one verification message', () {
    test('success does not call the legacy verification-link resend', () {
      final bloc = _code(
          'lib/modules/registration/presentation/bloc/registration_bloc.dart');
      final submitStart = bloc.indexOf('Future<void> onSubmitRegistrationForm');
      final resendStart =
          bloc.indexOf('Future<void> onResendVerificationEmail');
      final submitFlow = bloc.substring(submitStart, resendStart);

      expect(submitFlow, isNot(contains('resendVerificationEmail(')),
          reason: 'mobile signup already sends an OTP; a second link email is '
              'redundant and selects the wrong verification channel');
    });
  });
}
