/// Two auth journeys that could not complete.
///
/// IN-APP EMAIL VERIFICATION COULD NEVER SUCCEED. The backend looks the OTP row
/// up BY EMAIL and rejects a body without it ("Missing required parameters",
/// auth.service.verifyEmailOtp). The client sent only the code, on both the
/// verify and the resend call, so every attempt failed with a generic error. It
/// cannot be derived server-side: those routes are unauthenticated by
/// necessity, because a customer who has not verified cannot sign in to obtain
/// a token.
///
/// LOGOUT WAS PURELY LOCAL. Nothing called POST /api/auth/logout — the code
/// carried a TODO saying the endpoint did not exist, which stopped being true.
/// The Firebase refresh tokens therefore stayed valid after sign-out, so anyone
/// holding one could keep minting ID tokens, and the device kept receiving that
/// customer's push notifications.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final api = File('lib/common/data/backend/servana_api_client.dart')
      .readAsStringSync();
  final backend =
      File('lib/common/data/backend/http_backend.dart').readAsStringSync();
  final repo = File('lib/modules/profile/data/profile_repository.dart')
      .readAsStringSync();
  final screen = File(
    'lib/modules/profile/presentation/screens/email_verification_screen.dart',
  ).readAsStringSync();

  // Generous window: these methods carry long explanatory comments, and a tight
  // slice makes an assertion fail because it ran out of characters rather than
  // because the code changed — which reads exactly like a regression.
  String fn(String src, String name) {
    final i = src.indexOf(name);
    if (i == -1) return '';
    final end = i + 1600;
    return src.substring(i, end > src.length ? src.length : end);
  }

  group('the OTP calls carry the email the backend needs', () {
    test('verify sends both email and otp', () {
      final f = fn(api, 'Future<Map<String, dynamic>> verifyEmailOtp');
      expect(f, contains("'email': email"));
      expect(f, contains("'otp': otp"));
    });

    test('resend sends the email too', () {
      final f = fn(api, 'Future<Map<String, dynamic>> resendEmailOtp');
      expect(f, contains("'email': email"));
    });

    test('resend posts a body at all', () {
      // It previously sent headers only, so the backend had nothing to look up.
      final f = fn(api, 'Future<Map<String, dynamic>> resendEmailOtp');
      expect(f, contains('body: jsonEncode('));
    });

    test('the repository threads the email through', () {
      expect(repo, contains('resendEmailVerification(String email)'));
      expect(repo, contains('verifyEmailOtp(String email, String otp)'));
    });

    test('the screen sources the email from the profile', () {
      expect(screen, contains("_profileCtrl.profile?.email ?? ''"));
      expect(screen, contains('_repo.verifyEmailOtp(email, otp)'));
      expect(screen, contains('_repo.resendEmailVerification(email)'));
    });

    test('a missing email is reported instead of sent as empty', () {
      // Posting '' would fail the backend's own check and surface as a generic
      // error the customer cannot act on — which is how this looked for months.
      expect(screen, contains('if (email.isEmpty)'));
      expect(screen, contains('could not read your email address'));
    });
  });

  group('logout revokes server-side', () {
    test('the client has a logout method pointing at the endpoint', () {
      final f = fn(api, 'Future<Map<String, dynamic>> logout()');
      expect(f, contains("_uri('/api/auth/logout')"));
    });

    test('the backend logout actually calls it', () {
      final f = fn(backend, 'Future<void> logout()');
      expect(f, contains('api.logout()'));
    });

    test('the stale TODO claiming no endpoint exists is gone', () {
      expect(backend, isNot(contains('when BE adds POST /api/auth/logout')));
      expect(backend, isNot(contains('No backend logout endpoint currently')));
    });

    test('a failed revoke cannot block the logout', () {
      // Offline sign-out must still clear the device. The server call is
      // best-effort; the local teardown is what the customer sees.
      final f = fn(backend, 'Future<void> logout()');
      expect(f, contains('try {'));
      expect(f, contains('catch (_) {}'));
    });
  });
}
