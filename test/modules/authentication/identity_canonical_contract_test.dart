/// What `IdentityCanonicalDataSource` actually puts on the wire.
///
/// ## Why this file exists
///
/// `identity_repository_test.dart` covers the repository with a fake that
/// implements `IdentityDataSource`. That fake satisfies the CLIENT's own
/// interface, so it agrees with the client's field names by construction — it
/// cannot disagree with the backend, because the backend is not in it. Five
/// request bodies were wrong for the whole of the convergence work and 1901
/// tests had nothing to say about it.
///
/// So these tests assert one layer lower: the JSON handed to `V1ApiClient`.
/// The expected key sets are transcribed from `servana_api`'s
/// `src/api/v1/openapi.ts`, named in each test so a reader can check them
/// against the source rather than trusting this file.
///
/// ## What a failure here means
///
/// A red test is a claim that the app would be rejected by, or silently
/// misunderstood by, the deployed v1 handler. It is not a style check: two of
/// these bodies were unsatisfiable before this suite existed.
library;

import 'dart:convert';

import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/authentication/data/identity_canonical_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const base = 'https://api.example.test';

  /// A source whose every call is answered 200, recording what was sent.
  ({IdentityCanonicalDataSource source, List<http.Request> sent}) sourceThat() {
    final sent = <http.Request>[];
    final mock = MockClient((request) async {
      sent.add(request);
      return http.Response(
        jsonEncode(<String, dynamic>{'data': <String, dynamic>{}}),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    return (
      source: IdentityCanonicalDataSource(
        V1ApiClient(baseUrl: base, httpClient: mock),
      ),
      sent: sent,
    );
  }

  Map<String, dynamic> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, dynamic>;

  group('request bodies match the v1 contract', () {
    test('verifyEmail sends VerifyEmailRequest {identifier, code}', () async {
      final c = sourceThat();
      await c.source.verifyEmail(email: 'a@b.test', otp: '123456');

      final body = bodyOf(c.sent.single);
      // openapi.ts VerifyEmailRequest: required [identifier, code],
      // additionalProperties: false.
      expect(body.keys.toSet(), <String>{'identifier', 'code'});
      expect(body['identifier'], 'a@b.test');
      expect(body['code'], '123456');
    });

    test('verifyEmail puts the code in the body, never the query string',
        () async {
      final c = sourceThat();
      await c.source.verifyEmail(email: 'a@b.test', otp: '123456');

      // An OTP in a query string is written to the access log on every
      // request, where it sits as a live credential in something that gets
      // rotated, backed up and read by anyone with host access.
      expect(c.sent.single.url.query, isEmpty);
      expect(c.sent.single.url.toString(), isNot(contains('123456')));
    });

    test('resendEmailVerification sends a channel that is in the enum',
        () async {
      final c = sourceThat();
      await c.source.resendEmailVerification('a@b.test');

      final body = bodyOf(c.sent.single);
      // openapi.ts ResendVerificationRequest: required [identifier];
      // channel enum ['otp', 'link'].
      expect(body['identifier'], 'a@b.test');
      expect(body['channel'], anyOf('otp', 'link'));
      expect(
        body.containsKey('email'),
        isFalse,
        reason: 'the contract field is `identifier`',
      );
    });

    test('forgotPassword sends ForgotPasswordRequest {identifier}', () async {
      final c = sourceThat();
      await c.source.forgotPassword('a@b.test');

      final body = bodyOf(c.sent.single);
      // openapi.ts ForgotPasswordRequest: required [identifier]; `platform` is
      // optional and deliberately not sent — the server's default is correct
      // for this client and its allowlist lives on the server.
      expect(body['identifier'], 'a@b.test');
      expect(body.containsKey('platform'), isFalse);
    });

    test('resetPassword sends ResetPasswordRequest {oobCode, newPassword}',
        () async {
      final c = sourceThat();
      await c.source.resetPassword(token: 'oob-123', newPassword: 'hunter2!');

      final body = bodyOf(c.sent.single);
      // openapi.ts ResetPasswordRequest: required [oobCode, newPassword],
      // additionalProperties: false. The handler has NO alias fallback for
      // either — `{token, password}` earns a VALIDATION_FAILED.
      expect(body.keys.toSet(), <String>{'oobCode', 'newPassword'});
      expect(body['oobCode'], 'oob-123');
      expect(body['newPassword'], 'hunter2!');
    });
  });

  group('verifyMobile carries the proof v1 actually wants', () {
    test('sends VerifyMobileRequest {idToken}', () async {
      final c = sourceThat();
      await c.source.verifyMobile(idToken: 'firebase-id-token');

      final body = bodyOf(c.sent.single);
      // openapi.ts VerifyMobileRequest: required [idToken],
      // additionalProperties: false. The handler reads body.idToken with NO
      // fallback, so `{mobileNumber, otp}` — what this used to send — was a
      // guaranteed VALIDATION_FAILED.
      expect(body.keys.toSet(), <String>{'idToken'});
      expect(body['idToken'], 'firebase-id-token');
    });

    test('never sends a number or an OTP the app collected itself', () async {
      // The proof is Firebase's. This backend has no SMS sender and does not
      // pretend to verify a number, so a code this app gathered proves
      // nothing and must not be presented as though it did.
      final c = sourceThat();
      await c.source.verifyMobile(idToken: 'firebase-id-token');

      final body = bodyOf(c.sent.single);
      expect(body.containsKey('mobileNumber'), isFalse);
      expect(body.containsKey('otp'), isFalse);
    });
  });

  group('paths', () {
    test('every identity write targets the /api/v1 namespace', () async {
      final c = sourceThat();
      await c.source.verifyEmail(email: 'a@b.test', otp: '1');
      await c.source.resendEmailVerification('a@b.test');
      await c.source.forgotPassword('a@b.test');
      await c.source.resetPassword(token: 'x', newPassword: 'y');
      await c.source.verifyMobile(idToken: 't');
      await c.source.logout();

      expect(c.sent, hasLength(6));
      for (final request in c.sent) {
        expect(request.url.path, startsWith('/api/v1/'));
        expect(request.method, 'POST');
      }
    });
  });
}
