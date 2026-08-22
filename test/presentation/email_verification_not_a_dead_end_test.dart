/// An unverified customer who reaches sign-in must be able to finish, and be
/// told the truth about how.
///
/// ## What this pins, and why it is not a copy nit
///
/// Measured against production on 2026-08-21. Signing up succeeds, then signing
/// in with the same email and password is refused. The dialog that appears said:
///
///     We sent a verification link to <email>.
///     Open it from your inbox, then come back to sign in.
///     [ Resend link ]  [ Close ]
///
/// Two things were wrong with that, and only one of them is wording.
///
/// **The app cannot complete a link.** The single call that clears the gate is
/// `IdentityRepository.verifyEmail(email:, otp:)` — a six-digit code, typed into
/// `EmailVerificationScreen`, which announces "Resend code". So the customer was
/// told to look for something that would not finish the job even if it arrived.
///
/// **And the dialog was a dead end.** `EmailVerificationScreen` was reachable
/// from exactly ONE place — `create_account_screen.dart`, immediately after
/// signup. Anyone who signed up, closed the app, and came back to sign in could
/// resend forever and never reach the screen that accepts the code. That is a
/// customer locked out of an account they successfully created, and it is
/// exactly what a Google Play reviewer would have hit.
///
/// The gate itself is real and backend-owned (`identity.dart` reads
/// `emailVerified` from the API). This test does not argue with the gate — it
/// asserts there is a way through it and that the way is described accurately.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Line endings normalised — a CRLF checkout must not change what this sees.
String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail('$path does not exist — this test asserts against a file that has '
        'moved or been deleted.');
  }
  return file.readAsStringSync().replaceAll('\r\n', '\n');
}

/// Drops comment-only lines, leaving code and the string literals inside it.
///
/// Deliberately conservative: it removes a line only when the line is entirely
/// a comment, so a `https://` inside a real string is untouched. Enough to stop
/// prose about a defect being read as the defect.
String _userFacing(String source) => source.split('\n').where((line) {
      final t = line.trimLeft();
      return !t.startsWith('//');
    }).join('\n');

const _authScreen =
    'lib/modules/authentication/presentation/screens/authentication_screen.dart';
const _signupScreen =
    'lib/modules/registration/presentation/screens/create_account_screen.dart';
const _codeScreen =
    'lib/modules/profile/presentation/screens/email_verification_screen.dart';

void main() {
  group('the customer is told what will actually clear the gate', () {
    test('the only completion path in the app is a typed code', () {
      // The premise every assertion below rests on. If a deep link that
      // verifies an email is ever added, this fails first and the copy rules
      // become negotiable again — deliberately, rather than by drift.
      final screen = _read(_codeScreen);

      expect(screen, contains('verifyEmail('),
          reason: 'the code screen no longer verifies anything');
      expect(screen, contains('otp'),
          reason: 'verification is no longer a typed code');
      expect(screen, contains('Resend code'));
    });

    test('no screen promises a verification link', () {
      // Scans what the CUSTOMER can see, with comment-only lines removed.
      //
      // The first version of this test forbade the phrase anywhere in the file
      // and then failed on the comment that explains the very defect being
      // fixed — which is a blunt proxy failing honest code, and the tempting
      // repair is to water down the assertion. Same shape as forbidding the
      // word "catch" in the offline banner and tripping over a try/catch around
      // an analytics call. Comments are not shipped; copy is.
      for (final path in [_authScreen, _signupScreen]) {
        final visible = _userFacing(_read(path));
        expect(
          visible.toLowerCase(),
          isNot(contains('verification link')),
          reason: '$path promises a link the app cannot complete',
        );
        expect(
          visible,
          isNot(contains('Resend link')),
          reason: '$path offers to resend a link; the gate needs a code',
        );
      }
    });

    test('signup and sign-in describe the same mechanism', () {
      // One gate stated in two places. They disagreed for as long as both
      // existed, and the customer-facing cost is a person hunting an inbox for
      // a link while a six-digit code sits unused.
      final auth = _read(_authScreen);
      final signup = _read(_signupScreen);

      expect(auth, contains('verification code'));
      expect(signup, contains('verification code'));
    });
  });

  group('the dialog is a way through, not a wall', () {
    test('sign-in can reach the screen that accepts the code', () {
      // The defect this test exists for. Without a route out, "Close" was the
      // only real option and the account stayed unreachable forever.
      final auth = _read(_authScreen);

      expect(
        auth,
        contains('EmailVerificationScreen.routeName'),
        reason: 'the unverified-email dialog cannot reach the code screen, so '
            'a customer who signs up and returns later is locked out',
      );
      // Routed WITH the email, or the route builder bounces to WelcomeScreen
      // and the dead end simply moves one screen along.
      expect(
        auth,
        contains('SignupEmailVerificationArgs'),
        reason: 'the route requires the email in `extra`; without it the '
            'builder falls back to WelcomeScreen',
      );
    });

    test('the code screen still guards against being opened with no email', () {
      // The fallback that makes the assertion above load-bearing rather than
      // decorative.
      final router = _read('lib/common/presentation/routes/main_router.dart');

      expect(router, contains('SignupEmailVerificationArgs'));
      expect(router, contains('WelcomeScreen()'));
    });
  });
}
