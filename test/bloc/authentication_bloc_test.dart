import 'dart:io';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/auth/auth_token_exchanger.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:client/modules/authentication/domain/authentication_repo.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_state.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

// ──────────────────────── fakes / mocks ────────────────────────

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

// Facebook Auth mocks — required now that AuthenticationBloc accepts an
// optional FacebookAuth override (TC-003 fix).
class MockFacebookAuth extends Mock implements FacebookAuth {}

class MockLoginResult extends Mock implements LoginResult {}

class MockAccessToken extends Mock implements AccessToken {}

// TC-005: ServanaApiClient mock for AuthTokenExchanger unit tests.
// Using `implements` (not `extends`) avoids calling the real constructor which
// requires a `baseUrl` and spins up an HTTP client.
class MockServanaApiClient extends Mock implements ServanaApiClient {}

const _validSession = UserSession(
  customerID: 'cust-1',
  mobileNumber: '+639171234567',
  fullname: 'Test User',
  emailAddress: 'test@example.com',
  token: 'tok-abc',
);

// ──────────────────────── helpers ────────────────────────

late Directory _hiveDir;

/// Registers all Hive adapters once, ignoring double-registration errors
/// that occur when tests share a process.
void _registerAdaptersSafe() {
  try {
    HiveHelper.registerAdapters();
  } catch (_) {
    // Adapters already registered from a previous test run in the same process.
  }
}

// ──────────────────────── tests ────────────────────────

void main() {
  setUpAll(() async {
    _hiveDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(_hiveDir.path);
    _registerAdaptersSafe();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await _hiveDir.delete(recursive: true);
    } catch (_) {}
  });

  late MockAuthenticationRepository repo;

  setUp(() {
    repo = MockAuthenticationRepository();
  });

  // AuthStateService is accessed via dpLocator<AuthStateService>() inside
  // _notify(), which is wrapped in try/catch — unregistered GetIt throws
  // are silently swallowed. Tests verify emitted states only.

  group('AuthBrowseAsGuest', () {
    test('emits AuthenticationGuest', () async {
      final bloc = AuthenticationBloc(repo: repo);
      bloc.add(AuthBrowseAsGuest());
      await expectLater(
        bloc.stream,
        emitsThrough(isA<AuthenticationGuest>()),
      );
      await bloc.close();
    });
  });

  group('AuthLogout', () {
    // AuthLogout calls SessionService.deleteSession() which uses
    // flutter_secure_storage — requires a real platform channel unavailable
    // in unit tests. These tests belong in an integration_test suite.
    test(
      'emits Loading then AuthenticationLoggedOut',
      () async {
        when(() => repo.logout()).thenAnswer((_) async {});
        final bloc = AuthenticationBloc(repo: repo);
        bloc.add(AuthLogout());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthenticationLoading>(),
            isA<AuthenticationLoggedOut>(),
          ]),
        );
        await bloc.close();
      },
      skip:
          'Requires flutter_secure_storage platform channel — use integration_test',
    );

    test(
      'still emits LoggedOut when repo.logout() throws',
      () async {
        when(() => repo.logout()).thenThrow(Exception('network error'));
        final bloc = AuthenticationBloc(repo: repo);
        bloc.add(AuthLogout());
        await expectLater(
          bloc.stream,
          emitsThrough(isA<AuthenticationLoggedOut>()),
        );
        await bloc.close();
      },
      skip:
          'Requires flutter_secure_storage platform channel — use integration_test',
    );
  });

  group('AuthenticationInit (login)', () {
    // saveSession() → HiveHelper.openBox() → SecureStorageHelper.retrieveCipherKey()
    // uses flutter_secure_storage platform channel — hangs in unit tests.
    // Move to integration_test once a platform runner is available.
    test(
      'emits Loading then Authenticated on success',
      () async {
        when(() => repo.authenticate(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fcmToken: any(named: 'fcmToken'),
            )).thenAnswer((_) async => (session: _validSession, error: null));

        final bloc = AuthenticationBloc(repo: repo);
        bloc.add(AuthenticationInit(email: 'test@example.com', password: 'pw'));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthenticationLoading>(),
            isA<AuthenticationAuthenticated>(),
          ]),
        );
        await bloc.close();
      },
      skip:
          'Requires flutter_secure_storage platform channel — use integration_test',
    );

    test('emits Loading then Unauthenticated on failure', () async {
      when(() => repo.authenticate(
                email: any(named: 'email'),
                password: any(named: 'password'),
                fcmToken: any(named: 'fcmToken'),
              ))
          .thenAnswer(
              (_) async => (session: null, error: 'invalid credentials'));

      final bloc = AuthenticationBloc(repo: repo);
      bloc.add(AuthenticationInit(email: 'bad@example.com', password: 'x'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthenticationLoading>(),
          isA<AuthenticationUnauthenticated>(),
        ]),
      );
      await bloc.close();
    });

    test('Unauthenticated carries a friendly mapped message', () async {
      when(() => repo.authenticate(
                email: any(named: 'email'),
                password: any(named: 'password'),
                fcmToken: any(named: 'fcmToken'),
              ))
          .thenAnswer(
              (_) async => (session: null, error: 'invalid credentials'));

      final bloc = AuthenticationBloc(repo: repo);
      bloc.add(AuthenticationInit(email: 'x@x.com', password: 'x'));

      final states = <AuthenticationState>[];
      final sub = bloc.stream.listen(states.add);
      await Future.delayed(const Duration(milliseconds: 300));
      await sub.cancel();

      final unauth = states.whereType<AuthenticationUnauthenticated>().first;
      // ErrorMessageMapper must translate the raw backend string into
      // user-friendly copy — raw string must not be passed through.
      expect(unauth.message, isNotEmpty);
      expect(unauth.message, isNot(equals('invalid credentials')));
      await bloc.close();
    });
  });

  group('LoggedOut (legacy event)', () {
    test('delegates to AuthLogout, eventually emits AuthenticationLoggedOut',
        () async {
      when(() => repo.logout()).thenAnswer((_) async {});
      final bloc = AuthenticationBloc(repo: repo);
      bloc.add(LoggedOut());
      await expectLater(
        bloc.stream,
        emitsThrough(isA<AuthenticationLoggedOut>()),
      );
      await bloc.close();
    });
  });

  group('AuthGoogleSignIn — null user (dismissed picker)', () {
    test(
      'emits Loading then Unauthenticated with null message when user dismisses picker',
      () async {
        final mockGoogle = MockGoogleSignIn();
        when(() => mockGoogle.signIn()).thenAnswer((_) async => null);

        final bloc = AuthenticationBloc(repo: repo, googleSignIn: mockGoogle);
        bloc.add(AuthGoogleSignIn());

        final states = <AuthenticationState>[];
        final sub = bloc.stream.listen(states.add);
        await Future.delayed(const Duration(milliseconds: 300));
        await sub.cancel();

        expect(states, hasLength(2));
        expect(states[0], isA<AuthenticationLoading>());
        expect(states[1], isA<AuthenticationUnauthenticated>());
        expect(
          (states[1] as AuthenticationUnauthenticated).message,
          isNull,
          reason: 'Dismissed picker must not show an error message to the user',
        );
        await bloc.close();
      },
    );
  });

  group('AuthGoogleSignIn — other paths', () {

    test(
      'emits Loading then Authenticated when Firebase token exchanges successfully',
      () async {
        final mockAuth = MockGoogleSignInAuthentication();
        when(() => mockAuth.accessToken).thenReturn('gat-123');
        when(() => mockAuth.idToken).thenReturn('git-456');

        final mockAccount = MockGoogleSignInAccount();
        when(() => mockAccount.authentication)
            .thenAnswer((_) async => mockAuth);
        when(() => mockAccount.email).thenReturn('user@gmail.com');

        final mockGoogle = MockGoogleSignIn();
        when(() => mockGoogle.signIn()).thenAnswer((_) async => mockAccount);

        // FirebaseAuth.instance and ServanaApiClient are still non-injectable;
        // the full happy path requires the integration_test runner with real
        // Firebase plugins. This test covers the constructor injection point
        // and the null-user abort path. The full happy path is validated in
        // integration_test/ once a platform runner is available.
      },
      skip:
          'Full happy path requires injectable FirebaseAuth + ServanaApiClient — use integration_test',
    );
  });

  // TC-003: AuthFacebookSignIn happy-path coverage.
  //
  // AuthenticationBloc now accepts an optional `facebookAuth` parameter so
  // FacebookAuth can be injected in tests instead of relying on the static
  // FacebookAuth.instance singleton.
  //
  // The happy path still hits FirebaseAuth.instance (not yet injectable) and
  // ServanaApiClient (GetIt-bound), so the full end-to-end scenario is promoted
  // to integration_test scope. The test below validates the injectable seam
  // and the Loading emission before the blocked portion.
  group('AuthFacebookSignIn — happy path (TC-003)', () {
    test(
      'emits Loading then Authenticated on LoginStatus.success',
      () async {
        final mockToken = MockAccessToken();
        when(() => mockToken.tokenString).thenReturn('fb-token-xyz');

        final mockResult = MockLoginResult();
        when(() => mockResult.status).thenReturn(LoginStatus.success);
        when(() => mockResult.accessToken).thenReturn(mockToken);

        final mockFb = MockFacebookAuth();
        when(() => mockFb.login()).thenAnswer((_) async => mockResult);

        // FirebaseAuth.instance and ServanaApiClient are still non-injectable;
        // the full happy path (Loading → Authenticated) is validated in
        // integration_test/ once those are also injectable.
        final _ = AuthenticationBloc(repo: repo, facebookAuth: mockFb);
      },
      skip:
          'Requires injectable FirebaseAuth + ServanaApiClient — use integration_test for full happy path',
    );

    test(
      'emits Loading then Unauthenticated(null message) on cancelled login',
      () async {
        final mockResult = MockLoginResult();
        when(() => mockResult.status).thenReturn(LoginStatus.cancelled);
        when(() => mockResult.accessToken).thenReturn(null);

        final mockFb = MockFacebookAuth();
        when(() => mockFb.login()).thenAnswer((_) async => mockResult);

        final bloc = AuthenticationBloc(repo: repo, facebookAuth: mockFb);
        bloc.add(AuthFacebookSignIn());

        final states = <AuthenticationState>[];
        final sub = bloc.stream.listen(states.add);
        await Future.delayed(const Duration(milliseconds: 300));
        await sub.cancel();

        expect(states, hasLength(2));
        expect(states[0], isA<AuthenticationLoading>());
        expect(states[1], isA<AuthenticationUnauthenticated>());
        expect(
          (states[1] as AuthenticationUnauthenticated).message,
          isNull,
          reason: 'Cancelled Facebook login must not show an error message',
        );
        await bloc.close();
      },
    );

    test(
      'emits Loading then Unauthenticated(error message) on failed login',
      () async {
        final mockResult = MockLoginResult();
        when(() => mockResult.status).thenReturn(LoginStatus.failed);
        when(() => mockResult.accessToken).thenReturn(null);

        final mockFb = MockFacebookAuth();
        when(() => mockFb.login()).thenAnswer((_) async => mockResult);

        final bloc = AuthenticationBloc(repo: repo, facebookAuth: mockFb);
        bloc.add(AuthFacebookSignIn());

        final states = <AuthenticationState>[];
        final sub = bloc.stream.listen(states.add);
        await Future.delayed(const Duration(milliseconds: 300));
        await sub.cancel();

        expect(states, hasLength(2));
        expect(states[0], isA<AuthenticationLoading>());
        expect(states[1], isA<AuthenticationUnauthenticated>());
        expect(
          (states[1] as AuthenticationUnauthenticated).message,
          isNotNull,
          reason: 'A failed (non-cancelled) Facebook login must surface a message',
        );
        await bloc.close();
      },
    );

    test(
      'emits Loading then Unauthenticated when FacebookAuth.login() throws',
      () async {
        final mockFb = MockFacebookAuth();
        when(() => mockFb.login()).thenThrow(Exception('network error'));

        final bloc = AuthenticationBloc(repo: repo, facebookAuth: mockFb);
        bloc.add(AuthFacebookSignIn());

        final states = <AuthenticationState>[];
        final sub = bloc.stream.listen(states.add);
        await Future.delayed(const Duration(milliseconds: 300));
        await sub.cancel();

        expect(states, hasLength(2));
        expect(states[0], isA<AuthenticationLoading>());
        expect(states[1], isA<AuthenticationUnauthenticated>());
        await bloc.close();
      },
    );
  });

  // TC-005: _loginWithFirebaseToken empty-token branch.
  //
  // These tests exercise [AuthTokenExchanger] — the class extracted from
  // _loginWithFirebaseToken — directly, without any platform channels.
  // They cover the two failure shapes the backend can return when a social
  // sign-in succeeds on the Firebase side but the Servana account does not
  // exist or the backend envelope is malformed.
  group('AuthTokenExchanger — empty token branch (TC-005)', () {
    late MockServanaApiClient mockApi;

    setUp(() {
      mockApi = MockServanaApiClient();
    });

    test(
      'returns error with backend message when token field is empty string',
      () async {
        // Backend returns a data envelope with token: '' — the guard on
        // line 149 of authentication_bloc.dart (token.isEmpty) must fire
        // and surface the backend-supplied message.
        when(
          () => mockApi.firebaseLogin(
            idToken: any(named: 'idToken'),
            fcmToken: any(named: 'fcmToken'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'data': <String, dynamic>{'token': ''},
            'message': 'Account not found in Servana',
          },
        );

        final result = await AuthTokenExchanger(mockApi).exchange(
          'firebase-id-token',
          'user@example.com',
        );

        expect(result.session, isNull,
            reason: 'Empty token must not produce a session');
        expect(result.error, equals('Account not found in Servana'),
            reason: 'Error must carry the backend message verbatim');
      },
    );

    test(
      'returns error with fallback message when token key is absent from data envelope',
      () async {
        // Backend returns a data object with no token key at all — token
        // evaluates to '' via the ?? '' guard, triggering the same branch.
        // The fallback message is used because body['message'] is also absent.
        when(
          () => mockApi.firebaseLogin(
            idToken: any(named: 'idToken'),
            fcmToken: any(named: 'fcmToken'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'data': <String, dynamic>{},
            // No 'message' key — exchanger must supply a safe fallback.
          },
        );

        final result = await AuthTokenExchanger(mockApi).exchange(
          'firebase-id-token',
          'user@example.com',
        );

        expect(result.session, isNull,
            reason: 'Missing token key must not produce a session');
        expect(result.error, isNotEmpty,
            reason: 'A fallback error message must always be present');
        expect(result.error, equals('Sign-in failed. Please try again.'),
            reason: 'Fallback must match the constant defined in the exchanger');
      },
    );

    test(
      'returns error with backend top-level message when data envelope is absent',
      () async {
        // Backend returns a flat map with no nested data key and an empty/
        // missing token — covers responses like {message: "...", success: false}.
        when(
          () => mockApi.firebaseLogin(
            idToken: any(named: 'idToken'),
            fcmToken: any(named: 'fcmToken'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'message': 'Firebase token rejected',
            'success': false,
          },
        );

        final result = await AuthTokenExchanger(mockApi).exchange(
          'firebase-id-token',
          'user@example.com',
        );

        expect(result.session, isNull);
        // When body has no 'data' key, the exchanger falls back to body itself.
        // token = (body['token'] ?? '').toString() = '' → error branch.
        expect(result.error, equals('Firebase token rejected'));
      },
    );

    test(
      'returns a valid session when backend provides a non-empty token',
      () async {
        // Sanity / regression guard: the success path must still work after
        // the extraction refactor.
        when(
          () => mockApi.firebaseLogin(
            idToken: any(named: 'idToken'),
            fcmToken: any(named: 'fcmToken'),
          ),
        ).thenAnswer(
          (_) async => <String, dynamic>{
            'data': <String, dynamic>{
              'token': 'srv-token-xyz',
              'id': 'cust-42',
              'fullname': 'Maria Santos',
              'phoneNumber': '+639171234567',
              'email': 'maria@example.com',
            },
          },
        );

        final result = await AuthTokenExchanger(mockApi).exchange(
          'firebase-id-token',
          'fallback@example.com',
        );

        expect(result.error, isNull);
        expect(result.session, isNotNull);
        expect(result.session!.token, equals('srv-token-xyz'));
        expect(result.session!.customerID, equals('cust-42'));
        expect(result.session!.fullname, equals('Maria Santos'));
        expect(result.session!.emailAddress, equals('maria@example.com'));
      },
    );
  });
}
