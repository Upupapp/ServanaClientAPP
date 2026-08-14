/// A Firebase token must never be sent for a session it does not belong to.
///
/// Nothing in this app signed out of Firebase, so `FirebaseAuth.currentUser`
/// survived a logout. That was latent until the API client began PREFERRING the
/// Firebase token over the stored one:
///
///   customer A signs in with Google  -> Firebase user = A, session = A
///   A logs out                       -> session cleared, Firebase user STILL A
///   customer B signs in with email   -> session = B, Firebase user still A
///   next request                     -> Firebase token for A sent as B
///
/// The backend would then verify A's token and return A's bookings, addresses
/// and phone number to B. Two independent defences: logout now ends the Firebase
/// session, and the client refuses a token whose subject does not match the
/// active session.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// An unsigned JWT carrying the given subject. Only the payload is read.
String jwtFor(String uid, {String claim = 'user_id'}) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${seg({'alg': 'none'})}.${seg({claim: uid})}.sig';
}

void main() {
  final client = File('lib/common/data/backend/servana_api_client.dart')
      .readAsStringSync();
  final bloc = File(
    'lib/modules/authentication/presentation/bloc/authentication_bloc.dart',
  ).readAsStringSync();

  group('logout ends the Firebase session', () {
    test('signOut is called on logout', () {
      expect(bloc, contains('FirebaseAuth.instance.signOut()'));
    });

    test('a signOut failure cannot block the logout the user asked for', () {
      // The guarantee is unchanged; the mechanism moved. signOut is now a
      // CleanupStep, and SessionCleanupService.run isolates every step —
      // recording a failure and continuing rather than propagating. That is a
      // stronger promise than the old inline try/catch, because it also
      // guarantees the steps AFTER signOut still run.
      //
      // Behaviour is asserted directly in
      // test/core/session/session_cleanup_service_test.dart; this only checks
      // the wiring, since a source scan cannot execute the bloc.
      final i = bloc.indexOf('FirebaseAuth.instance.signOut()');
      final around = bloc.substring(i - 400, i + 120);
      expect(around, contains('CleanupStep('),
          reason: 'signOut must run as an isolated cleanup step');
      expect(bloc, contains('_cleanup.run(customerScopedCleanupSteps('),
          reason: 'the steps must be executed through the isolating runner');
    });

    test('logout clears the credential wherever it now lives', () {
      // The cross-user invariant this file exists for moved when tokens moved:
      // credentials are in secure storage now, so a logout that only deleted
      // the Hive record would leave customer A's bearer token on the device
      // for customer B's session to pick up.
      //
      // SessionTokenStore.clear wipes BOTH locations, which also covers a
      // device caught mid-migration holding one copy in each.
      expect(bloc, contains("CleanupStep('sessionTokens'"),
          reason: 'logout must clear the token store');
      final store = File('lib/core/session/session_token_store.dart')
          .readAsStringSync();
      final clear = store.substring(store.indexOf('Future<void> clear()'));
      expect(clear, contains('_secure.clear()'));
      expect(clear, contains('stripLegacyTokens()'));
    });

    test('an account switch clears the previous customer state', () {
      // Signing in as somebody else on a device that never signed out is the
      // same leak as a missed logout, and it does not go through _onLogout.
      expect(bloc, contains('isDifferentSubjectFrom('));
      final i = bloc.indexOf('isDifferentSubjectFrom(');
      expect(bloc.substring(i, i + 400),
          contains('customerScopedCleanupSteps('),
          reason: 'a detected switch must run the same teardown as a logout');
    });
  });

  group('the API client binds the token to the active session', () {
    test('the Firebase token is checked against the session before use', () {
      expect(client, contains('_matchesSession(fresh, session)'));
    });

    test('the session is loaded BEFORE the provider is consulted', () {
      // Order matters: checking afterwards would mean the comparison has
      // nothing to compare against on the first call.
      final resolve = client.substring(
        client.indexOf('Future<String?> _resolveToken()'),
        client.indexOf('/// True when [jwt] belongs'),
      );
      expect(
        resolve.indexOf('SessionService.getSession()'),
        lessThan(resolve.indexOf('await provider()')),
      );
    });
  });

  group('subject matching', () {
    // Mirrors _matchesSession, which is private. The behaviour is what matters:
    // a mismatch must be refused, and an unreadable token must not lock the
    // user out.
    bool matches(String jwt, String? expected) {
      if (expected == null || expected.isEmpty) return true;
      try {
        final parts = jwt.split('.');
        if (parts.length < 2) return true;
        var p = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        p += '=' * ((4 - p.length % 4) % 4);
        final c = jsonDecode(utf8.decode(base64.decode(p)));
        final sub = (c is Map ? (c['user_id'] ?? c['sub']) : null)?.toString();
        if (sub == null || sub.isEmpty) return true;
        return sub == expected;
      } catch (_) {
        return true;
      }
    }

    test('a token for another customer is refused', () {
      expect(matches(jwtFor('customer-A'), 'customer-B'), isFalse);
    });

    test('a token for the active customer is accepted', () {
      expect(matches(jwtFor('customer-B'), 'customer-B'), isTrue);
    });

    test('the sub claim is honoured as well as user_id', () {
      expect(
          matches(jwtFor('customer-A', claim: 'sub'), 'customer-B'), isFalse);
      expect(matches(jwtFor('customer-B', claim: 'sub'), 'customer-B'), isTrue);
    });

    test('an unparseable token does not lock the customer out', () {
      // Refusing to authenticate on a token we merely failed to decode would
      // break more sessions than it protects.
      expect(matches('not-a-jwt', 'customer-B'), isTrue);
    });

    test('a session with no customerID imposes no constraint', () {
      expect(matches(jwtFor('customer-A'), null), isTrue);
      expect(matches(jwtFor('customer-A'), ''), isTrue);
    });
  });
}
