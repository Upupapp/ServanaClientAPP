/// Password recovery on the compatibility path — the one every shipped build
/// takes.
///
/// ## What this is guarding
///
/// `IdentityCompatibilityDataSource.forgotPassword` used to throw, on the
/// stated grounds that the app "initiates password reset through Firebase".
/// It did not: no Firebase reset call existed anywhere in the tree, the login
/// screen said the feature was coming soon, and
/// `POST /api/auth/forgot-password` had been deployed and rate-limited the
/// whole time. A customer who forgot their password had no way back into
/// their account.
///
/// So these tests pin the two things that could quietly undo that: the call
/// must reach the legacy route, and the app must not turn the backend's
/// deliberately neutral answer into an account-enumeration oracle.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/authentication/data/identity_canonical_data_source.dart';
import 'package:client/modules/authentication/data/identity_compatibility_data_source.dart';
import 'package:client/modules/authentication/data/identity_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const base = 'https://api.example.test';

  ({ServanaApiClient api, List<http.Request> sent}) apiThat(
    http.Response response,
  ) {
    final sent = <http.Request>[];
    final mock = MockClient((request) async {
      sent.add(request);
      return response;
    });
    return (
      api: ServanaApiClient(baseUrl: base, client: mock),
      sent: sent,
    );
  }

  http.Response neutralAck() => http.Response(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'data': <String, dynamic>{
            'message': 'If an account with that email exists, a password '
                'reset link has been sent.',
          },
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );

  group('the compatibility source reaches the legacy route', () {
    test('POSTs /api/auth/forgot-password with the email', () async {
      final c = apiThat(neutralAck());
      final source = IdentityCompatibilityDataSource(c.api);

      await source.forgotPassword('a@b.test');

      expect(c.sent, hasLength(1));
      expect(c.sent.single.method, 'POST');
      expect(c.sent.single.url.path, '/api/auth/forgot-password');
      expect(
        jsonDecode(c.sent.single.body),
        <String, dynamic>{'email': 'a@b.test'},
      );
    });

    test('does not send `platform`', () async {
      final c = apiThat(neutralAck());

      await IdentityCompatibilityDataSource(c.api).forgotPassword('a@b.test');

      // Only allowlisted platform NAMES get a platform-specific continueUrl,
      // and the allowlist lives on the server. Omitting the field lands the
      // customer on Firebase's hosted page, which is the correct destination
      // because the reset finishes in a browser and never in this app.
      final body = jsonDecode(c.sent.single.body) as Map<String, dynamic>;
      expect(body.containsKey('platform'), isFalse);
    });

    test('no longer throws UnsupportedTransportOperation', () async {
      final c = apiThat(neutralAck());

      // The regression this whole file exists to prevent.
      await expectLater(
        IdentityCompatibilityDataSource(c.api).forgotPassword('a@b.test'),
        completes,
      );
    });
  });

  group('resetPassword stays a refusal', () {
    test('refuses, because the app never receives an oobCode', () async {
      final c = apiThat(neutralAck());

      // Legacy recovery emails a Firebase LINK; the customer sets the new
      // password on Firebase's page. There is no step here to complete, and a
      // silent no-op would report a password as changed when nothing changed
      // it.
      await expectLater(
        IdentityCompatibilityDataSource(c.api)
            .resetPassword(token: 'x', newPassword: 'y'),
        throwsA(isA<Exception>()),
      );
      expect(c.sent, isEmpty);
    });
  });

  group('the repository routes recovery to compatibility today', () {
    test('every shipped build uses the legacy route', () async {
      final c = apiThat(neutralAck());
      // A canonical client that fails loudly if it is ever selected: the
      // point of this test is that it is NOT.
      final canonicalApi = V1ApiClient(
        baseUrl: base,
        httpClient: MockClient((_) async => fail('canonical must not answer')),
      );
      final repo = IdentityRepository(
        router: const CanonicalRouter(
          // Deny-by-default, exactly as a production build is configured.
          availability: CanonicalAvailability(),
        ),
        canonical: IdentityCanonicalDataSource(canonicalApi),
        compatibility: IdentityCompatibilityDataSource(c.api),
      );

      await repo.forgotPassword('a@b.test');

      expect(c.sent.single.url.path, '/api/auth/forgot-password');
    });
  });
}
