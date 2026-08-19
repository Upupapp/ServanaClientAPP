/// The one place a session token is persisted.
///
/// ## What was wrong
///
/// `UserSession` — which carries `token` and `refreshToken` — is persisted in
/// the Hive box `session`. Hive is encrypted here (the cipher key lives in
/// `flutter_secure_storage` via `SecureStorageHelper`), so this was never
/// plaintext-on-disk. But the *tokens* sat inside a general-purpose object
/// store alongside display name, email and mobile number, which means every
/// read of the customer's name deserialises their credentials, and any future
/// field added to `UserSession` widens what a single box read exposes.
///
/// This store keeps the bearer and refresh tokens in `flutter_secure_storage`
/// directly — Keychain on iOS, EncryptedSharedPreferences on Android — so the
/// credential has its own home with its own lifetime, and clearing it is one
/// call that cannot be forgotten halfway.
///
/// ## Additive, not a migration
///
/// `SessionService` and the Hive box are NOT removed and NOT changed. Doing so
/// would rewrite the read path for every signed-in customer on the installed
/// base, and TAB 01 recorded that Play still serves `1.0.0+37`. This store is
/// written alongside, is authoritative when present, and falls back to the
/// existing session when it is not — the expand half of expand-migrate-contract.
/// The contract half belongs to a later tab, once telemetry shows the installed
/// base has moved.
///
/// ## Privacy
///
/// Only credentials live here. No email, no phone number, no name — a
/// credential store is not a profile store, and putting identity attributes in
/// it would mean every token read also decrypts personal data.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? _defaultStorage;

  final FlutterSecureStorage _storage;

  // Mirrors SecureStorageHelper's options so both stores behave identically
  // after a backup restore or a keystore invalidation.
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// The keystore is a platform channel to a system service. It normally
  /// answers in milliseconds and it can wedge, and an unbounded await on a
  /// wedged channel never throws — which is how an app ends up sitting on the
  /// splash screen forever. Same bound as `SecureStorageHelper`.
  static const Duration _timeout = Duration(seconds: 4);

  static const String _accessKey = 'servana_access_token';
  static const String _refreshKey = 'servana_refresh_token';
  static const String _subjectKey = 'servana_token_subject';

  /// Persists the credentials for [subject].
  ///
  /// [subject] is the server's uid for the session. It is stored so the app can
  /// detect an account switch and refuse to hand account A's token to a process
  /// that now believes it is account B — the same defence the API client
  /// applies when it compares a Firebase token's subject to the active session.
  Future<void> save({
    required String accessToken,
    String? refreshToken,
    required String subject,
  }) async {
    await _write(_accessKey, accessToken);
    await _write(_subjectKey, subject);
    // A null refresh token clears any previous one rather than leaving a stale
    // credential that outlives the session it belonged to.
    await _write(_refreshKey, refreshToken);
  }

  Future<String?> readAccessToken() => _read(_accessKey);

  Future<String?> readRefreshToken() => _read(_refreshKey);

  Future<String?> readSubject() => _read(_subjectKey);

  /// True when a token is held for someone other than [subject].
  ///
  /// Used at sign-in to decide whether this is an account SWITCH, which
  /// requires clearing customer-scoped caches rather than merely replacing a
  /// token.
  Future<bool> isDifferentSubject(String subject) async {
    final held = await readSubject();
    return held != null && held.isNotEmpty && held != subject;
  }

  /// Removes every credential this store owns.
  ///
  /// Best-effort by design and never throws: a logout the customer asked for
  /// must not be blocked by a storage fault. A failure here is reported to the
  /// caller so it can be logged, and the caller continues clearing.
  Future<bool> clear() async {
    var ok = true;
    for (final key in <String>[_accessKey, _refreshKey, _subjectKey]) {
      try {
        await _storage.delete(key: key).timeout(_timeout);
      } catch (_) {
        ok = false;
      }
    }
    return ok;
  }

  Future<void> _write(String key, String? value) async {
    try {
      if (value == null || value.isEmpty) {
        await _storage.delete(key: key).timeout(_timeout);
        return;
      }
      await _storage.write(key: key, value: value).timeout(_timeout);
    } on TimeoutException {
      rethrow;
    } on PlatformException {
      // Corrupt secure storage (e.g. BAD_DECRYPT after a backup restore).
      // Drop this key and retry once; if that fails the caller sees it.
      try {
        await _storage.delete(key: key).timeout(_timeout);
      } catch (_) {}
      if (value != null && value.isNotEmpty) {
        await _storage.write(key: key, value: value).timeout(_timeout);
      }
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key).timeout(_timeout);
    } catch (_) {
      // An unreadable credential store means "not signed in", never an
      // exception — the same rule SessionService applies to the Hive box.
      return null;
    }
  }
}
