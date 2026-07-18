import 'dart:io';

import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:client/modules/authentication/domain/authentication_repo.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

// ──────────────────────── fakes / mocks ────────────────────────

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

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
      skip: 'Requires flutter_secure_storage platform channel — use integration_test',
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
      skip: 'Requires flutter_secure_storage platform channel — use integration_test',
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
      skip: 'Requires flutter_secure_storage platform channel — use integration_test',
    );

    test('emits Loading then Unauthenticated on failure', () async {
      when(() => repo.authenticate(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fcmToken: any(named: 'fcmToken'),
          )).thenAnswer(
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
          )).thenAnswer(
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
}
