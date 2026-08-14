import 'package:client/core/session/secure_session_store.dart';
import 'package:client/core/session/session_token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory FlutterSecureStorage that can be told to fail.
class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage();

  final Map<String, String> values = <String, String>{};

  /// When true, every write throws — the corrupt-keystore case.
  bool failWrites = false;

  /// When true, writes silently succeed and store nothing — the case a naive
  /// implementation would pass and then lose the credential.
  bool swallowWrites = false;

  int writeCount = 0;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    writeCount++;
    if (failWrites) throw Exception('keystore unavailable');
    if (swallowWrites) return;
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      values[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

/// A legacy record we can inspect for the strip.
class _FakeLegacy implements LegacyTokenAccess {
  _FakeLegacy(this.tokens);

  SessionTokens? tokens;
  int stripCount = 0;
  bool failStrip = false;

  @override
  Future<SessionTokens?> readLegacyTokens() async => tokens;

  @override
  Future<void> stripLegacyTokens() async {
    stripCount++;
    if (failStrip) throw Exception('hive write failed');
    tokens = null;
  }
}

void main() {
  late _FakeSecureStorage storage;
  late SecureSessionStore secure;

  setUp(() {
    storage = _FakeSecureStorage();
    secure = SecureSessionStore(storage: storage);
  });

  const legacyTokens = SessionTokens(
    accessToken: 'legacy-access',
    refreshToken: 'legacy-refresh',
    subject: 'cust_1',
  );

  group('migration success', () {
    test('copies the legacy token to secure storage and strips the original',
        () async {
      final legacy = _FakeLegacy(legacyTokens);
      final store = SessionTokenStore(secure: secure, legacy: legacy);

      final tokens = await store.read();

      // The caller still gets working credentials.
      expect(tokens.accessToken, 'legacy-access');
      expect(tokens.refreshToken, 'legacy-refresh');
      expect(tokens.subject, 'cust_1');

      // Secure storage now holds them.
      expect(await secure.readAccessToken(), 'legacy-access');
      expect(await secure.readRefreshToken(), 'legacy-refresh');
      expect(await secure.readSubject(), 'cust_1');

      // The legacy copy is gone.
      expect(legacy.stripCount, 1);
      expect(legacy.tokens, isNull);
      expect(store.didFallBackToLegacy, isTrue);
    });

    test('migrates once, then reads from secure storage', () async {
      final legacy = _FakeLegacy(legacyTokens);
      final store = SessionTokenStore(secure: secure, legacy: legacy);

      await store.read();
      store.invalidateCache();
      final second = await store.read();

      expect(second.accessToken, 'legacy-access');
      expect(legacy.stripCount, 1, reason: 'the strip must not repeat');
    });

    test('a device with no legacy token and no secure token reads empty',
        () async {
      final store =
          SessionTokenStore(secure: secure, legacy: _FakeLegacy(null));
      final tokens = await store.read();
      expect(tokens.isEmpty, isTrue);
      expect(store.didFallBackToLegacy, isFalse);
    });
  });

  group('secure-write failure preserves legacy material', () {
    test('a throwing write leaves the legacy token untouched', () async {
      // Strip-first-then-discover-the-write-failed would sign the customer out
      // and lose a refresh token that cannot be regenerated on this device.
      storage.failWrites = true;
      final legacy = _FakeLegacy(legacyTokens);
      final store = SessionTokenStore(secure: secure, legacy: legacy);

      final tokens = await store.read();

      expect(tokens.accessToken, 'legacy-access',
          reason: 'the customer must stay signed in');
      expect(legacy.stripCount, 0, reason: 'nothing may be stripped');
      expect(legacy.tokens, isNotNull);
    });

    test('a silently-dropped write is caught by the read-back check', () async {
      // This is the case a naive "write then strip" implementation passes and
      // then loses the credential on. The write reports success; nothing is
      // stored.
      storage.swallowWrites = true;
      final legacy = _FakeLegacy(legacyTokens);
      final store = SessionTokenStore(secure: secure, legacy: legacy);

      final tokens = await store.read();

      expect(tokens.accessToken, 'legacy-access');
      expect(legacy.stripCount, 0,
          reason: 'the read-back mismatch must abort the strip');
      expect(legacy.tokens, isNotNull);
    });

    test('a failure exposes no token material', () async {
      storage.failWrites = true;
      final legacy = _FakeLegacy(legacyTokens);
      final store = SessionTokenStore(secure: secure, legacy: legacy);
      final tokens = await store.read();
      // toString is the thing most likely to reach a log.
      expect(tokens.toString(), isNot(contains('legacy-access')));
      expect(tokens.toString(), isNot(contains('legacy-refresh')));
    });

    test('a strip failure still leaves the secure copy authoritative', () async {
      final legacy = _FakeLegacy(legacyTokens)..failStrip = true;
      final store = SessionTokenStore(secure: secure, legacy: legacy);

      final tokens = await store.read();

      expect(tokens.accessToken, 'legacy-access');
      expect(await secure.readAccessToken(), 'legacy-access',
          reason: 'the secure copy was verified before the strip was attempted');
    });
  });

  group('steady state writes are secure-only', () {
    test('write persists to secure storage and strips any legacy copy',
        () async {
      final legacy = _FakeLegacy(legacyTokens);
      final store = SessionTokenStore(secure: secure, legacy: legacy);

      final ok = await store.write(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        subject: 'cust_2',
      );

      expect(ok, isTrue);
      expect(await secure.readAccessToken(), 'new-access');
      expect(legacy.stripCount, greaterThan(0),
          reason: 'a sign-in must not resurrect a Hive token');
    });

    test('write reports failure rather than pretending to have saved', () async {
      storage.failWrites = true;
      final store =
          SessionTokenStore(secure: secure, legacy: _FakeLegacy(null));
      final ok = await store.write(
          accessToken: 'a', refreshToken: 'b', subject: 'c');
      expect(ok, isFalse);
    });

    test('a null refresh token clears any previous one', () async {
      final store =
          SessionTokenStore(secure: secure, legacy: _FakeLegacy(null));
      await store.write(
          accessToken: 'a', refreshToken: 'old', subject: 'c');
      await store.write(accessToken: 'a2', refreshToken: null, subject: 'c');
      store.invalidateCache();
      expect(await secure.readRefreshToken(), isNull,
          reason: 'a stale refresh token must not outlive its session');
    });
  });

  group('secure reads', () {
    test('prefers secure storage over the legacy record', () async {
      await secure.save(
          accessToken: 'secure-access', refreshToken: 'r', subject: 's');
      final legacy = _FakeLegacy(legacyTokens);
      final store = SessionTokenStore(secure: secure, legacy: legacy);

      final tokens = await store.read();

      expect(tokens.accessToken, 'secure-access');
      expect(legacy.stripCount, 0,
          reason: 'no migration is needed when secure storage already answers');
    });

    test('caches so the platform channel is not hit per request', () async {
      await secure.save(accessToken: 'a', refreshToken: 'r', subject: 's');
      final store =
          SessionTokenStore(secure: secure, legacy: _FakeLegacy(null));
      await store.read();
      final before = storage.writeCount;
      await store.read();
      await store.read();
      expect(storage.writeCount, before);
    });
  });

  group('clear removes BOTH locations', () {
    test('logout wipes secure storage and any legacy token fields', () async {
      final legacy = _FakeLegacy(legacyTokens);
      final store = SessionTokenStore(secure: secure, legacy: legacy);
      await store.read(); // migrate first
      legacy.tokens = legacyTokens; // simulate a stale copy reappearing

      await store.clear();

      expect(await secure.readAccessToken(), isNull);
      expect(await secure.readRefreshToken(), isNull);
      expect(await secure.readSubject(), isNull);
      expect(legacy.tokens, isNull);
      expect((await store.read()).isEmpty, isTrue);
    });

    test('clear survives a legacy strip failure', () async {
      final legacy = _FakeLegacy(legacyTokens)..failStrip = true;
      final store = SessionTokenStore(secure: secure, legacy: legacy);
      await store.clear();
      expect(await secure.readAccessToken(), isNull,
          reason: 'the secure wipe must not be blocked by the legacy one');
    });
  });

  group('account switch detection', () {
    test('a different subject is a switch', () async {
      await secure.save(accessToken: 'a', refreshToken: null, subject: 'cust_1');
      final store =
          SessionTokenStore(secure: secure, legacy: _FakeLegacy(null));
      expect(await store.isDifferentSubjectFrom('cust_2'), isTrue);
      expect(await store.isDifferentSubjectFrom('cust_1'), isFalse);
    });

    test('a first sign-in is not a switch', () async {
      final store =
          SessionTokenStore(secure: secure, legacy: _FakeLegacy(null));
      expect(await store.isDifferentSubjectFrom('cust_1'), isFalse);
    });
  });
}
