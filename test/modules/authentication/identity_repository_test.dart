import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/authentication/data/identity_canonical_data_source.dart';
import 'package:client/modules/authentication/data/identity_data_source.dart';
import 'package:client/modules/authentication/data/identity_repository.dart';
import 'package:client/modules/authentication/domain/identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Records calls and answers with whatever the test scripted.
class _FakeSource implements IdentityDataSource {
  _FakeSource({this.identity, this.throwOnCall});

  final Identity? identity;
  final Object? throwOnCall;
  final List<String> calls = <String>[];

  T _maybeThrow<T>(String name, T value) {
    calls.add(name);
    final error = throwOnCall;
    if (error != null) throw error;
    return value;
  }

  @override
  Future<Identity> fetchIdentity() async => _maybeThrow(
      'fetchIdentity', identity ?? const Identity(uid: 'legacy-uid'));

  @override
  Future<void> resendEmailVerification(String email) async =>
      _maybeThrow('resendEmailVerification', null);

  @override
  Future<void> verifyEmail({required String email, required String otp}) async =>
      _maybeThrow('verifyEmail', null);

  @override
  Future<void> verifyMobile({
    required String mobileNumber,
    required String otp,
  }) async =>
      _maybeThrow('verifyMobile', null);

  @override
  Future<void> forgotPassword(String email) async =>
      _maybeThrow('forgotPassword', null);

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async =>
      _maybeThrow('resetPassword', null);

  @override
  Future<void> logout() async => _maybeThrow('logout', null);
}

void main() {
  V1ApiClient canonicalReturning(Object body, {int status = 200}) => V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((_) async => http.Response(
              jsonEncode(body),
              status,
              headers: {'content-type': 'application/json'},
            )),
      );

  const enabledRouter = CanonicalRouter(
    availability: CanonicalAvailability(
      enabled: true,
      capabilities: <V1Capability>{V1Capability.identity},
    ),
  );

  group('routing', () {
    test('uses compatibility when nothing is wired', () async {
      final legacy = _FakeSource();
      final repo = IdentityRepository(compatibility: legacy);
      await repo.fetchIdentity();
      expect(legacy.calls, <String>['fetchIdentity']);
      expect(repo.isCanonical, isFalse);
    });

    test('stays on compatibility while the gate is closed', () async {
      // The state of every shipped build: /api/v1 is not deployed.
      final legacy = _FakeSource();
      final repo = IdentityRepository(
        compatibility: legacy,
        canonical: _FakeSource(identity: const Identity(uid: 'v1-uid')),
        router: const CanonicalRouter(availability: CanonicalAvailability()),
      );
      final identity = await repo.fetchIdentity();
      expect(identity.uid, 'legacy-uid');
      expect(repo.isCanonical, isFalse);
    });

    test('uses canonical once the capability is enabled', () async {
      final legacy = _FakeSource();
      final canonical = _FakeSource(identity: const Identity(uid: 'v1-uid'));
      final repo = IdentityRepository(
        compatibility: legacy,
        canonical: canonical,
        router: enabledRouter,
      );
      final identity = await repo.fetchIdentity();
      expect(identity.uid, 'v1-uid');
      expect(legacy.calls, isEmpty);
      expect(repo.isCanonical, isTrue);
    });

    test('a canonical source without a router cannot take traffic', () async {
      final legacy = _FakeSource();
      final repo = IdentityRepository(
        compatibility: legacy,
        canonical: _FakeSource(identity: const Identity(uid: 'v1-uid')),
      );
      await repo.fetchIdentity();
      expect(legacy.calls, <String>['fetchIdentity']);
    });
  });

  group('failure normalisation', () {
    test('a legacy ServanaApiException becomes a typed ApiFailure', () async {
      // Nothing above the repository should ever see a status code.
      final repo = IdentityRepository(
        compatibility: _FakeSource(
          throwOnCall: const ServanaApiException(
            statusCode: 409,
            body: '{"error":{"code":"OTP_EXPIRED","message":"gone"}}',
          ),
        ),
      );
      await expectLater(
        repo.verifyEmail(email: 'a@b.c', otp: '123456'),
        throwsA(isA<StateConflictFailure>()
            .having((f) => f.code, 'code', 'OTP_EXPIRED')),
      );
    });

    test('a canonical ApiFailure passes through unchanged', () async {
      final repo = IdentityRepository(
        compatibility: _FakeSource(
          throwOnCall: const ForbiddenFailure(safeMessage: 'no'),
        ),
      );
      await expectLater(
          repo.fetchIdentity(), throwsA(isA<ForbiddenFailure>()));
    });

    test('an unsupported operation is deterministic and NOT retryable',
        () async {
      // "This build has no route for that" must never be retried forever.
      final repo = IdentityRepository(
        compatibility: _FakeSource(
          throwOnCall: const UnsupportedTransportOperation('verifyMobile', 'x'),
        ),
      );
      try {
        await repo.verifyMobile(mobileNumber: '+63', otp: '1');
        fail('should have thrown');
      } on ApiFailure catch (failure) {
        expect(failure.isRetryable, isFalse);
        expect(failure.code, 'TRANSPORT_UNSUPPORTED');
        expect(failure.safeMessage, isNot(contains('verifyMobile')));
      }
    });

    test('a transport error becomes retryable', () async {
      final repo = IdentityRepository(
        compatibility: _FakeSource(throwOnCall: Exception('socket')),
      );
      await expectLater(
          repo.fetchIdentity(), throwsA(isA<RetryableFailure>()));
    });
  });

  group('logout never throws', () {
    test('returns null on success', () async {
      final repo = IdentityRepository(compatibility: _FakeSource());
      expect(await repo.logout(), isNull);
    });

    test('returns the failure instead of throwing', () async {
      // A server that refuses must not trap the customer in a signed-in app.
      final repo = IdentityRepository(
        compatibility: _FakeSource(
          throwOnCall: const ServanaApiException(statusCode: 500, body: '{}'),
        ),
      );
      final failure = await repo.logout();
      expect(failure, isA<RetryableFailure>());
    });
  });

  group('canonical transport', () {
    test('GET /api/v1/me carries no identifier in the URL', () async {
      // Least privilege: the subject is the token, so this cannot be asked
      // about another account.
      final urls = <Uri>[];
      final client = V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          urls.add(request.url);
          return http.Response(jsonEncode({'data': {'uid': 'u1'}}), 200);
        }),
      );
      await IdentityCanonicalDataSource(client).fetchIdentity();
      expect(urls.single.toString(), 'https://api.example.test/api/v1/me');
      expect(urls.single.queryParameters, isEmpty);
    });

    test('the OTP travels in the body, never the query string', () async {
      // A query string is written to the access log on every request, and an
      // OTP in a plaintext log is a live credential.
      final requests = <http.Request>[];
      final client = V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(jsonEncode({'data': {}}), 200);
        }),
      );
      await IdentityCanonicalDataSource(client)
          .verifyEmail(email: 'a@b.c', otp: '654321');
      expect(requests.single.url.query, isEmpty);
      expect(requests.single.body, contains('654321'));
    });

    test('maps the canonical /me payload to Identity', () async {
      final source = IdentityCanonicalDataSource(canonicalReturning({
        'data': {
          'uid': 'u1',
          'email': 'a@b.c',
          'emailVerified': true,
          'mobileNumber': '+639171234567',
          'mobileVerified': false,
        }
      }));
      final identity = await source.fetchIdentity();
      expect(identity.uid, 'u1');
      expect(identity.emailVerification, ChannelVerification.verified);
      expect(identity.mobileVerification, ChannelVerification.unverified);
      expect(identity.hasVerifiedChannel, isTrue);
      expect(identity.pendingChannels, <String>['mobile']);
    });
  });
}
