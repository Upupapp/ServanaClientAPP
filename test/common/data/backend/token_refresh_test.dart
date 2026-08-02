/// The bearer token must be resolved per request, not cached at sign-in.
///
/// The backend verifies the Authorization header with
/// `admin.auth().verifyIdToken()` (servana_api/src/middleware/verifyAuth.ts:36),
/// so the credential is a **Firebase ID token and expires after one hour**. The
/// backend even has a dedicated branch for it:
///
///     auth/id-token-expired -> 401 TOKEN_EXPIRED
///                              "Session expired. Please log in again."
///
/// ServanaApiClient used to read `SessionService.getSession()?.token` — written
/// once at sign-in and never renewed. So an hour into any session every
/// authenticated call began returning 401, and `onUnauthorized` responded by
/// clearing the session and bouncing the customer to the login screen, mid
/// journey.
///
/// This was survivable while only rarely used endpoints required auth. It became
/// load-bearing when the customer's own booking flow was authenticated: booking
/// create, booking detail, tracking, OTP confirm, address list, cancellation and
/// both payment submissions all sit behind `verifyAuth` now.
///
/// The fix is to ask `FirebaseAuth.currentUser.getIdToken()` per request, which
/// renews only when the token is expired or nearly so. These tests pin the
/// seam — that a provider is consulted, and that it wins over the stored token —
/// without requiring Firebase in the test process.
library;

import 'dart:convert';
import 'dart:io';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    registerFallbackValue(Uri());
    registerFallbackValue(<String, String>{});
    registerFallbackValue(http.Request('GET', Uri()));

    hiveDir = Directory.systemTemp.createTempSync('servana_token_refresh_test');
    Hive.init(hiveDir.path);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null,
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
    try {
      hiveDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  late MockHttpClient mockHttp;

  setUp(() {
    mockHttp = MockHttpClient();
    // ServanaApiClient wraps whatever client it is given in _TimeoutClient,
    // which calls send() — stubbing get() would never be reached.
    when(() => mockHttp.send(any())).thenAnswer(
      (_) async => http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'ok': true}))),
        200,
      ),
    );
  });

  /// Headers on the most recent request that reached the transport.
  Map<String, String>? capturedHeaders() {
    final sent = verify(() => mockHttp.send(captureAny())).captured;
    if (sent.isEmpty) return null;
    return (sent.last as http.BaseRequest).headers;
  }

  test('the token provider is consulted on every request', () async {
    var calls = 0;
    final client = ServanaApiClient(
      baseUrl: 'https://api.test.example',
      client: mockHttp,
      tokenProvider: () async {
        calls++;
        return 'token-$calls';
      },
    );

    await client.listWorkersByRole(2);
    await client.listWorkersByRole(2);

    // Two requests, two resolutions. Resolving once and caching is precisely
    // the bug: the cached value is what goes stale after an hour.
    expect(calls, 2);
  });

  test('the resolved token is what gets sent', () async {
    final client = ServanaApiClient(
      baseUrl: 'https://api.test.example',
      client: mockHttp,
      tokenProvider: () async => 'fresh-token',
    );

    await client.listWorkersByRole(2);

    expect(capturedHeaders()?['Authorization'], 'Bearer fresh-token');
  });

  test('a later request sends the NEWER token, not the first one', () async {
    var n = 0;
    final client = ServanaApiClient(
      baseUrl: 'https://api.test.example',
      client: mockHttp,
      tokenProvider: () async => 'token-${++n}',
    );

    await client.listWorkersByRole(2);
    await client.listWorkersByRole(2);

    // This is the whole point: after a refresh the app must use the new
    // credential. Sending 'token-1' twice would reproduce the outage.
    expect(capturedHeaders()?['Authorization'], 'Bearer token-2');
  });

  test('a provider that throws does not break the request', () async {
    final client = ServanaApiClient(
      baseUrl: 'https://api.test.example',
      client: mockHttp,
      tokenProvider: () async => throw StateError('no network'),
    );

    // Falls through to the stored session (absent here), so the call proceeds
    // unauthenticated and the server decides. A refresh failure turning into a
    // thrown exception would take out every screen at once.
    await client.listWorkersByRole(2);
    expect(capturedHeaders()?.containsKey('Authorization'), isFalse);
  });

  test('a provider returning null falls back rather than sending "Bearer null"',
      () async {
    final client = ServanaApiClient(
      baseUrl: 'https://api.test.example',
      client: mockHttp,
      tokenProvider: () async => null,
    );

    await client.listWorkersByRole(2);
    expect(capturedHeaders()?.containsKey('Authorization'), isFalse);
  });

  test('with no provider the client still works, for tests and direct callers',
      () async {
    final client = ServanaApiClient(
      baseUrl: 'https://api.test.example',
      client: mockHttp,
    );

    await client.listWorkersByRole(2);
    expect(capturedHeaders()?['Content-Type'], 'application/json');
  });

  group('the app actually wires a refreshing provider', () {
    // The seam above is useless if production never plugs anything into it —
    // that would be a passing test suite over a still-broken app.
    final injector =
        File('lib/common/injectors/main_injector.dart').readAsStringSync();

    test('ServanaApiClient is registered with a tokenProvider', () {
      final reg = injector.substring(injector.indexOf('ServanaApiClient('));
      expect(reg.contains('tokenProvider:'), isTrue);
    });

    test('the provider asks Firebase rather than reading the stored session',
        () {
      final reg = injector.substring(
        injector.indexOf('tokenProvider:'),
        injector.indexOf('tokenProvider:') + 400,
      );
      expect(reg, contains('getIdToken'));
      expect(reg, contains('FirebaseAuth.instance.currentUser'));
      // SessionService.getSession() here would restore the original bug while
      // looking like a fix.
      expect(reg.contains('SessionService.getSession'), isFalse);
    });
  });

  group('email/password sessions can refresh too', () {
    // The first version of this fix only covered SOCIAL sign-in. Email/password
    // sign-in is performed by the BACKEND calling Firebase server-side, so
    // FirebaseAuth.currentUser is null on the device and the injected provider
    // always yields null. Those sessions fell back to the stored ID token and
    // died after an hour — the exact bug the provider was added to fix, still
    // live for everyone who did not use Google or Facebook.

    test('the persisted model accepts a session with no refresh token', () {
      // Every currently signed-in user has one of these. A non-nullable field
      // would have made the Hive adapter emit `fields[59] as String`, which
      // throws "Null is not a subtype of String" on cold start after release —
      // compiles fine, passes every new-session test, breaks only real devices.
      const s = UserSession(
        customerID: 'c1',
        mobileNumber: '0917',
        fullname: 'Juan',
        token: 'tok',
      );
      expect(s.refreshToken, isNull);
    });

    test('the generated Hive adapter reads field 59 as nullable', () {
      final gen =
          File('lib/common/data/models/user_session.g.dart').readAsStringSync();
      expect(gen, contains('refreshToken: fields[59] as String?'));
      expect(gen, isNot(contains('refreshToken: fields[59] as String,')));
    });

    test('a refresh token round-trips through copyWith', () {
      const s = UserSession(
        customerID: 'c1',
        mobileNumber: '0917',
        fullname: 'Juan',
        token: 'old',
      );
      final updated = s.copyWith(token: 'new', refreshToken: 'r2');
      expect(updated.token, 'new');
      expect(updated.refreshToken, 'r2');
    });

    test('the client exchanges at the documented endpoint, unauthenticated',
        () {
      // The exchange must NOT go through _headers(): that calls _resolveToken,
      // which is what asked for the refresh — it would recurse.
      final src = File('lib/common/data/backend/servana_api_client.dart')
          .readAsStringSync();
      final fn = src.substring(src.indexOf('_exchangeRefreshToken'));
      expect(fn, contains("_uri('/api/auth/refresh')"));
      expect(fn, contains("'Content-Type': 'application/json'"));
      expect(
          fn.substring(0, fn.indexOf('Future<Map<String, String>> _headers')),
          isNot(contains('await _headers()')));
    });

    test('a 401 ends the session but a 502 does not', () {
      final src = File('lib/common/data/backend/servana_api_client.dart')
          .readAsStringSync();
      final fn = src.substring(
        src.indexOf('_exchangeRefreshToken'),
        src.indexOf('Future<Map<String, String>> _headers'),
      );
      // 401 = the refresh token is genuinely dead. Anything else is transient,
      // and treating it as fatal would sign out every user during a blip.
      expect(fn, contains('if (res.statusCode == 401) onUnauthorized?.call()'));
      expect(
          fn,
          isNot(contains(
              'onUnauthorized?.call();\n      return null;\n    }\n    }')));
    });

    test('refreshes are single-flight', () {
      final src = File('lib/common/data/backend/servana_api_client.dart')
          .readAsStringSync();
      expect(src, contains('_refreshInFlight ??='));
      expect(src, contains('whenComplete(() => _refreshInFlight = null)'));
    });

    test('a token with an unreadable exp is not refreshed every request', () {
      final src = File('lib/common/data/backend/servana_api_client.dart')
          .readAsStringSync();
      final fn = src.substring(src.indexOf('static bool _isExpiringSoon'));
      expect(fn.substring(0, 700), contains('return false'));
    });
  });
}
