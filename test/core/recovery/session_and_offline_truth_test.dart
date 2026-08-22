/// TAB 12 — a session that ends once, and a banner that only claims what it
/// knows.
///
/// Most of what this TAB asks for was already true. It was not *pinned*, which
/// is a different thing: nothing failed if it stopped being true. These tests
/// are the pin, and each one says whether it defends our behaviour or records
/// the shape of something a test cannot drive.
library;

import 'dart:io';

import 'package:client/common/services/auth_state_service.dart';
import 'package:client/core/recovery/network_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads a source file, failing with its name rather than an errno.
///
/// Line endings normalised: a CRLF checkout must not change what a
/// source-reading test sees.
String _source(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail('$path does not exist — this test asserts against a file that is no '
        'longer in the repository.');
  }
  return file.readAsStringSync().replaceAll('\r\n', '\n');
}

void main() {
  group('a dead session ends exactly once', () {
    test('AuthStateService does not re-notify for an unchanged status', () {
      // This is what makes concurrent 401s safe. Several in-flight requests can
      // fail at once; each calls the sign-out owner; the customer must be
      // signed out ONCE, not once per request.
      final auth = AuthStateService();
      var notifications = 0;
      auth.addListener(() => notifications++);

      auth.update(AuthStatus.expired);
      auth.update(AuthStatus.expired);
      auth.update(AuthStatus.expired);

      expect(auth.status, AuthStatus.expired);
      expect(notifications, 1,
          reason: 'each concurrent 401 would sign the customer out again');
    });

    test('a real transition still notifies', () {
      // Guards against "fixing" the above by never notifying at all.
      final auth = AuthStateService();
      var notifications = 0;
      auth.addListener(() => notifications++);

      auth.update(AuthStatus.authenticated);
      auth.update(AuthStatus.expired);

      expect(notifications, 2);
    });

    test('both transports route 401 through ONE owner', () {
      // The closure was written out twice, identically — once per API client.
      // Two copies of a rule is one edit away from being two rules, and the two
      // would then disagree about whether the session is alive (§10).
      final src = _source('lib/common/injectors/main_injector.dart');

      expect(src, contains('void _endSessionOnUnauthorized()'));
      expect(
        'onUnauthorized: _endSessionOnUnauthorized,'.allMatches(src).length,
        2,
        reason: 'both ServanaApiClient and V1ApiClient must use the owner',
      );
      // And no inline copy has crept back.
      expect(src, isNot(contains('onUnauthorized: () {')));
    });
  });

  group('the offline banner claims only what the device measured', () {
    test('unknown is not offline', () {
      // The state a cold start is in before the first probe returns. Treating
      // it as offline would put "no internet connection" in front of every
      // customer for the first seconds of every launch.
      expect(NetworkState.unknown, isNot(NetworkState.offline));
    });

    test('the monitor probes reachability rather than reading a radio flag',
        () {
      // ⚠ Pins the DESIGN, not a behaviour executed here — opening a socket
      // needs a network. Recorded because the distinction is the whole of TAB
      // 12's banner requirement: during the 19 August outage the device was
      // online and the SERVER was broken, and a banner reading a wifi flag
      // would have blamed the customer's connection.
      final src = _source('lib/core/recovery/connectivity_monitor.dart');

      expect(src, contains('8.8.8.8'));
      expect(src, contains('Socket.connect'));
      // No HTTP failure may promote the app to "offline".
      expect(src, isNot(contains('statusCode')));
    });

    test('the banner is driven by the monitor and nothing else', () {
      final src = _source('lib/core/recovery/offline_banner.dart');

      expect(src, contains('== NetworkState.offline'));

      // Exactly ONE thing assigns the flag, and it is the monitor's state.
      //
      // Asserted on the assignment rather than on the absence of the word
      // "catch": the file does contain a `catch (_) {}`, around the ANALYTICS
      // call, and forbidding the word outright failed on code that has nothing
      // to do with the verdict. A blunt proxy fails honest code and would have
      // been "fixed" by deleting the assertion.
      // TWO occurrences, and both are named: the field's initial value, and
      // the single assignment driven by the monitor's state. A third would be
      // something else deciding the customer is offline.
      expect(src, contains('bool _offline = false;'));
      expect(src, contains('_offline = nowOffline'));
      expect(RegExp(r'_offline = ').allMatches(src).length, 2,
          reason: 'something other than the monitor now sets the flag');

      // And no HTTP failure may promote the app to offline.
      expect(src, isNot(contains('statusCode')));
      expect(src, isNot(contains('ApiException')));
    });
  });

  group('a token refresh happens once, not once per request', () {
    test('the single-flight future is shared and then cleared', () {
      // ⚠ Source-level, and said so. The mechanism is a private static on
      // ServanaApiClient with no seam to drive from a test, so this records the
      // shape rather than exercising it. `??=` is what makes the second caller
      // await the FIRST exchange; `whenComplete` clearing it is what stops one
      // failure poisoning every later refresh.
      final src = _source('lib/common/data/backend/servana_api_client.dart');

      expect(src, contains('_refreshInFlight ??='));
      expect(src, contains('whenComplete(() => _refreshInFlight = null)'));
    });
  });
}
