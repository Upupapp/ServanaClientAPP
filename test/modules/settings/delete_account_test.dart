import 'dart:io';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Account deletion must be reachable, and must stay reachable.
///
/// App Store Review rejected the 2026-08-22 submission under Guideline
/// 5.1.1(v): the app supported account creation and offered no way to initiate
/// deletion. What stood in Settings was a `SettingsUnavailableTile` reading
/// "Account deletion will be available in a future update" — a dead end exactly
/// where the reviewer looked, while `POST /api/account/deletion-request/me` had
/// existed on the backend the whole time.
///
/// These tests pin the three things a re-review will check: the request goes to
/// the right place, the customer cannot trip into it by accident, and the flow
/// never sends them to customer service — which the guideline forbids for
/// anything outside a highly-regulated industry.
void main() {
  /// Source with comments stripped.
  ///
  /// These assertions are about what the screen DOES, and a source scan cannot
  /// tell a live string from prose about it. The first version of the
  /// customer-service test failed on this file's own doc comment, which exists
  /// to explain that the support address must NOT appear here. Scanning raw
  /// text would have invited the worst possible fix — deleting the explanation
  /// to make the gate green.
  String codeOnly(String src) => src.split('\n').where((l) {
        final t = l.trimLeft();
        return !t.startsWith('//');
      }).join('\n');

  final screen = codeOnly(File(
    'lib/modules/settings/presentation/screens/delete_account_screen.dart',
  ).readAsStringSync());
  final settings = codeOnly(File(
    'lib/modules/settings/presentation/screens/privacy_legal_screen.dart',
  ).readAsStringSync());
  final router = File('lib/common/presentation/routes/main_router.dart')
      .readAsStringSync();

  test('the comment stripper actually strips, and keeps the code', () {
    // The floor under every source scan below: if this returned the raw file,
    // or an empty string, the assertions would prove nothing either way.
    expect(screen, isNot(contains('Guideline 5.1.1(v)')),
        reason: 'doc comments were not stripped');
    expect(screen, contains('requestAccountDeletion()'),
        reason: 'the stripper removed code as well as comments');
    expect(screen.length, greaterThan(2000),
        reason: 'the screen source did not load');
  });

  group('the deletion request itself', () {
    test('POSTs to the authenticated self-service endpoint', () async {
      Uri? seen;
      String? method;
      final api = ServanaApiClient(
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          seen = request.url;
          method = request.method;
          return http.Response('{"status":"success"}', 200);
        }),
      );

      await api.requestAccountDeletion();

      expect(method, 'POST');
      expect(seen?.path, '/api/account/deletion-request/me',
          reason: 'the /me variant is the authenticated one; the public '
              'variant takes an identifier and is for the web page');
    });

    test('a second request is not treated as an error', () async {
      // The backend collapses duplicates: idx_adr_open_identifier is UNIQUE on
      // (identifier) WHERE status = 'pending' and the insert is ON CONFLICT DO
      // NOTHING. A retry after a timeout must therefore succeed, not surface a
      // failure to somebody who has already asked once.
      var calls = 0;
      final api = ServanaApiClient(
        baseUrl: 'https://api.example.test',
        client: MockClient((_) async {
          calls++;
          return http.Response('{"status":"success"}', 200);
        }),
      );

      await api.requestAccountDeletion();
      await api.requestAccountDeletion();

      expect(calls, 2);
    });
  });

  group('the flow a reviewer walks', () {
    test('Settings offers a live control, not an unavailable tile', () {
      final i = settings.indexOf("title: 'Delete Account'");
      expect(i, greaterThan(-1), reason: 'the Delete Account entry is gone');

      // The tile type is the whole finding: an "unavailable" tile is what the
      // rejection was about. A fixed window around the title cannot decide
      // this — 'Export My Data' sits immediately above and is still legitimately
      // unavailable, so a window wide enough to reach the constructor also
      // reaches its neighbour's. Instead find the ENCLOSING constructor: the
      // nearest tile opening before the title wins.
      final destructive = settings.lastIndexOf('SettingsDestructiveTile(', i);
      final unavailable = settings.lastIndexOf('SettingsUnavailableTile(', i);
      expect(destructive, greaterThan(-1),
          reason: 'Delete Account must be an actionable destructive tile');
      expect(destructive, greaterThan(unavailable),
          reason: 'the tile enclosing Delete Account is still an unavailable '
              'tile — the dead end App Review rejected is back');
      expect(settings, contains('DeleteAccountScreen.routeName'),
          reason: 'the tile must navigate into the deletion flow');

      // And the neighbour is untouched: Export My Data has no backend and must
      // stay honest rather than be quietly made to look live.
      expect(settings, contains("title: 'Export My Data'"));
    });

    test('the screen is routed, so the tile cannot lead nowhere', () {
      expect(router, contains('DeleteAccountScreen.route'));
      expect(router, contains('DeleteAccountScreen.routeName'));
      expect(router, contains('const DeleteAccountScreen()'));
    });

    test('deletion needs an explicit acknowledgement and a confirmation', () {
      // Guideline 5.1.1(v) permits confirmation steps to prevent accidents.
      // Two gates: a checkbox that enables the button, and a dialog.
      expect(screen, contains('_understood'),
          reason: 'an acknowledgement gate must exist');
      expect(screen,
          contains('(_understood && !_submitting) ? _confirmAndDelete : null'),
          reason: 'the button must be disabled until acknowledged');
      expect(screen, contains('showDialog<bool>'),
          reason: 'a final confirmation must be presented');
    });

    test('the flow never routes the customer to customer service', () {
      // The guideline is explicit: only apps in highly-regulated industries may
      // require a phone call or an email to complete deletion. The privacy
      // address appears elsewhere in Settings and must not appear here.
      expect(screen, isNot(contains('privacy@servana.com.ph')));
      expect(screen.toLowerCase(), isNot(contains('contact us')));
      expect(screen.toLowerCase(), isNot(contains('mailto:')));
    });

    test('a successful deletion signs the customer out', () {
      // Signing out is part of deletion, not a courtesy: the customer-scoped
      // teardown that runs on logout is what clears this account's drafts,
      // cached inbox and tokens from the device.
      expect(screen, contains('AuthLogout()'));
      final i = screen.indexOf('requestAccountDeletion()');
      expect(i, greaterThan(-1));
      expect(screen.substring(i, i + 600), contains('AuthLogout()'),
          reason: 'the sign-out must follow the successful request');
    });

    test('the screen states what is kept as well as what is removed', () {
      // The backend anonymises identity columns and retains the financial
      // trail, because a hard delete would violate a foreign key the moment the
      // account has a booking. Claiming total erasure would be checkable and
      // false.
      expect(screen, contains('What is removed'));
      expect(screen, contains('What is kept'));
      expect(screen.toLowerCase(), contains('payment'));
    });
  });
}
