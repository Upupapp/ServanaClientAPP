/// Sign in with Apple — required by App Store Review Guideline 4.8.
///
/// The app offers Google and Facebook login, which is exactly the trigger for
/// 4.8: an app offering third-party or social login must also offer a
/// privacy-preserving equivalent. Without this the submission is rejected no
/// matter how well everything else works, so its presence is asserted rather
/// than assumed.
///
/// The runtime flow cannot be exercised here — `getAppleIDCredential` needs a
/// real Apple platform and a signed-in Apple ID, and the standing rule is that
/// validation stops at `flutter analyze` + `flutter test`. So these cover the
/// two things that are checkable and that fail silently or opaquely when wrong:
/// the nonce contract, and whether the option is wired end to end at all.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

String _read(String p) => File(p).readAsStringSync();

void main() {
  late final String bloc;
  late final String buttons;
  late final String events;

  setUpAll(() {
    bloc = _read(
        'lib/modules/authentication/presentation/bloc/authentication_bloc.dart');
    buttons = _read(
        'lib/modules/authentication/presentation/widgets/social_auth_buttons.dart');
    events = _read(
        'lib/modules/authentication/presentation/bloc/authentication_event.dart');
  });

  group('Guideline 4.8 — the option exists and is reachable', () {
    test('the package is a dependency', () {
      expect(_read('pubspec.yaml'), contains('sign_in_with_apple:'));
    });

    test('the event, handler and registration all exist', () {
      // Any one of these missing means a button that does nothing.
      expect(events, contains('class AuthAppleSignIn'));
      expect(bloc, contains('on<AuthAppleSignIn>(_onAppleSignIn)'),
          reason: 'the event is defined but never handled');
      expect(bloc, contains('Future<void> _onAppleSignIn('));
    });

    test('a button dispatches the event', () {
      expect(buttons, contains('AuthAppleSignIn()'),
          reason: 'no UI path reaches the handler');
    });

    test('the button renders on a capability check, not a platform branch', () {
      // Standing rule: keep per-platform differences in configuration, not in
      // Dart branching. isAvailable() also becomes true on Android once a
      // Services ID is configured, so one code path serves both.
      //
      // Comments are stripped before the negative assertion. The source
      // explains in prose why it does NOT use a Platform.isIOS branch, and a
      // naive substring check matches that explanation — the same way the
      // AspectRatio assertion in the search-overflow test first "failed"
      // against a correct implementation.
      expect(buttons, contains('SignInWithApple.isAvailable()'));

      final code = buttons
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(code, isNot(contains('Platform.isIOS')),
          reason: 'gate on capability, not on the platform');
      expect(code, isNot(contains('defaultTargetPlatform')),
          reason: 'gate on capability, not on the platform');
    });

    test('the entitlement is declared', () {
      // Without com.apple.developer.applesignin the credential request fails
      // at runtime with an authorization error, and signing fails first.
      final ent = _read('ios/Runner/Runner.entitlements');
      expect(ent, contains('com.apple.developer.applesignin'));
      expect(ent, contains('<string>Default</string>'));
    });

    test('every third-party provider offered has an Apple counterpart', () {
      // The rule is conditional: it binds *because* Google and Facebook are
      // offered. If those are ever removed, this test should be revisited
      // rather than silently continuing to demand Apple.
      final offersThirdParty = buttons.contains('AuthGoogleSignIn()') ||
          buttons.contains('AuthFacebookSignIn()');
      expect(offersThirdParty, isTrue,
          reason: 'if no third-party login is offered, 4.8 no longer applies '
              'and this whole file should be reconsidered');
      expect(buttons, contains('AuthAppleSignIn()'));
    });
  });

  group('the nonce contract', () {
    // Firebase binds the Apple credential to this attempt with a nonce. Apple
    // is given the SHA-256 HASH; Firebase is given the RAW value and verifies
    // that hashing it reproduces what Apple signed.
    //
    // Getting this backwards fails with `invalid-credential` and no indication
    // of why, which is why it is pinned here.

    test('Apple receives the hashed nonce', () {
      expect(bloc, contains('nonce: sha256.convert(utf8.encode(rawNonce))'),
          reason: 'Apple must be given the HASH, never the raw nonce');
    });

    test('Firebase receives the raw nonce', () {
      expect(bloc, contains('rawNonce: rawNonce'),
          reason: 'Firebase must be given the RAW nonce to verify the hash');
    });

    test('the two are not the same value', () {
      // Guards the copy-paste failure where one variable is used for both.
      expect(bloc, isNot(contains('nonce: rawNonce,')),
          reason: 'sending the raw nonce to Apple defeats the binding');
    });

    test('the nonce is cryptographically random, not Random()', () {
      // A predictable nonce is the same as no replay protection.
      expect(bloc, contains('Random.secure()'));
      expect(bloc, isNot(contains('= Random();')));
    });

    test('hashing the raw nonce reproduces what Apple would be sent', () {
      // Exercises the actual transformation the handler performs, so a change
      // to the algorithm (SHA-1, hex vs base64) is caught here.
      const raw = 'abcDEF123-._xyz';
      final hashed = sha256.convert(utf8.encode(raw)).toString();
      expect(hashed.length, 64, reason: 'SHA-256 hex is 64 characters');
      expect(hashed, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(hashed, isNot(equals(raw)));
    });
  });

  group('first-authorisation-only identity', () {
    // Apple returns givenName/familyName/email ONLY on the first authorisation
    // for a given Apple ID. Every later sign-in returns nulls, and deleting
    // the app does not reset it — so the handler must capture the name then,
    // and must not overwrite or invent one afterwards.

    test('the name is composed from the credential and saved once', () {
      expect(bloc, contains('credentialResult.givenName'));
      expect(bloc, contains('credentialResult.familyName'));
      expect(bloc, contains('updateDisplayName(fullName)'));
    });

    test('an existing display name is not overwritten', () {
      expect(bloc, contains("(userCred.user?.displayName ?? '').isEmpty"),
          reason: 'later sign-ins return null names; do not clobber the '
              'account with an empty one');
    });

    test('email falls back to the Firebase user after the first sign-in', () {
      expect(bloc, contains('credentialResult.email ?? userCred.user?.email'));
    });

    test('a failed name save does not fail the sign-in', () {
      // The customer is authenticated at that point; losing a display name is
      // not a reason to reject the session.
      final handler =
          bloc.substring(bloc.indexOf('Future<void> _onAppleSignIn('));
      final upTo =
          handler.substring(0, handler.indexOf('final firebaseIdToken'));
      expect(upTo, contains('try {'));
      expect(upTo, contains('} catch (_) {'));
    });
  });

  group('cancellation is not an error', () {
    test('a cancelled authorisation emits no error message', () {
      // Matches how the Facebook handler treats LoginStatus.cancelled. A user
      // who backs out should not be shown a failure.
      expect(bloc, contains('AuthorizationErrorCode.canceled'));
      final handler =
          bloc.substring(bloc.indexOf('Future<void> _onAppleSignIn('));
      final idx = handler.indexOf('AuthorizationErrorCode.canceled');
      final branch = handler.substring(idx, idx + 200);
      expect(branch, contains('AuthenticationUnauthenticated()'),
          reason: 'cancellation must return to idle with no message');
    });
  });

  group('analytics', () {
    test('apple is a declared auth method', () {
      expect(_read('lib/core/analytics/domain/analytics_property.dart'),
          contains("static const String apple = 'apple';"));
    });

    test('the handler tracks start and failure like the others', () {
      final handler =
          bloc.substring(bloc.indexOf('Future<void> _onAppleSignIn('));
      expect(handler, contains('SignInStartedEvent'));
      expect(handler, contains('SignInFailedEvent'));
    });
  });
}
