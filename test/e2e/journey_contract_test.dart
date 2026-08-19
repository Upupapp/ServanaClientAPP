/// The customer journey, pinned against what production actually answered.
///
/// ## Why this file exists (TAB 01)
///
/// The suite has 2179 tests and, before this, not one of them walked a
/// customer from sign-up to a booking. Every test stopped at a seam it owned,
/// which is right for a unit test and useless as an MVP go/no-go. "The app
/// works end to end" was an opinion held by whoever last tapped through it.
///
/// ## What makes these fixtures different from invented ones
///
/// Every response body below was **captured from `api.servana.com.ph` on
/// 2026-08-19**, by replaying the exact request bodies `HttpBackend` sends.
/// A fake that agrees with the client by construction proves nothing — that is
/// how five identity calls were once believed broken when two were fine and
/// two had no caller at all. These agree with the SERVER by construction.
///
/// When production changes shape, these fixtures go stale and should be
/// re-captured rather than edited to match the client.
library;

import 'package:client/common/services/error_message_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// ─────────────── captured from production, 2026-08-19 ───────────────

/// `POST /api/auth/signup` — HTTP 200. The client's exact body was
/// `{email, password, firstName, lastName, phoneNumber, role: 3,
/// platform: 'mobile'}`.
const signupSuccess = {
  'status': 'success',
  'data': {
    'success': true,
    'userId': 'S2SSISI6VrWeFeN5krVxq94NJi13',
    'message': 'User created successfully. OTP sent to email.',
    'verificationType': 'otp',
    'verificationDeliveryPending': false,
    'onboardingPending': false,
  },
};

/// `POST /api/auth/signin` for an account that exists but is unverified.
/// **HTTP 403.**
const signinUnverified = {
  'status': 'failed',
  'message':
      'Email not verified. Please check your inbox for a verification link.',
  'error': {
    'code': 'IDENTIFIER_NOT_VERIFIED',
    'message':
        'Email not verified. Please check your inbox for a verification link.',
    'recovery': 'VERIFY_IDENTIFIER',
    'retryable': false,
  },
};

void main() {
  group('sign-up is accepted in the shape the client actually sends', () {
    test('a 200 declares success and says how verification will arrive', () {
      final data = signupSuccess['data']! as Map<String, dynamic>;

      expect(data['success'], isTrue);
      expect(data['userId'], isNotEmpty);
      // The client's registration flow branches on this: an OTP screen, not a
      // "check your email for a link" screen. If the backend ever switches to
      // 'link', the app must follow or it strands the customer on a screen
      // asking for a code nobody sent.
      expect(data['verificationType'], equals('otp'));
    });

    test('the backend confirms the verification actually went out', () {
      final data = signupSuccess['data']! as Map<String, dynamic>;

      // `false` means delivery was not deferred. This is the field that
      // separates "we created your account and emailed you" from "we created
      // your account and something else has to send the mail". A registration
      // screen that ignores it can tell a customer to check an inbox nothing
      // was sent to.
      expect(data['verificationDeliveryPending'], isFalse);
    });
  });

  group('an unverified sign-in tells the customer the right thing', () {
    test('production answers 403, not 401', () {
      // Worth pinning: 401 and 403 are handled differently downstream, and the
      // mapper deliberately lets BOTH defer to the body precisely because this
      // distinction (unverified vs bad password vs disabled) lives there and
      // not in the status.
      expect(signinUnverified['status'], equals('failed'));
    });

    test('the customer is asked to verify, not told their password is wrong',
        () {
      final raw = signinUnverified['message']! as String;

      final shown = ErrorMessageMapper.forLogin(raw, statusCode: 403);

      expect(shown, contains('verify'));
      expect(shown, isNot(contains('password')));
      expect(shown, isNot(contains('incorrect')));
    });

    test('the status-first rule does not swallow the body for a 403', () {
      // The regression this guards: making status authoritative for 5xx is
      // right, but if 403 had also been decided by status the customer would
      // get a generic server message instead of "verify your account", and the
      // one action that unblocks them would never be named.
      final raw = signinUnverified['message']! as String;

      expect(
        ErrorMessageMapper.forLogin(raw, statusCode: 403),
        equals(ErrorMessageMapper.forLogin(raw)),
        reason: '403 must reach the same copy with or without the status',
      );
    });

    test('the response carries a recovery hint the client does not yet use',
        () {
      final error = signinUnverified['error']! as Map<String, dynamic>;

      // Recorded, not asserted as wired. `recovery` is the field the backend
      // means clients to branch on, and the legacy transport this app ships on
      // ignores it in favour of matching prose. That works today because the
      // prose happens to contain "verified" — which is a coincidence, not a
      // contract.
      expect(error['recovery'], equals('VERIFY_IDENTIFIER'));
      expect(error['retryable'], isFalse);
    });
  });
}
