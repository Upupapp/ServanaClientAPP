import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class SecureStorageHelper {
  // Android-specific options that:
  //  - back the storage with EncryptedSharedPreferences (AES-GCM via Tink), and
  //  - automatically wipe the file if the underlying keystore key is no longer
  //    able to decrypt it (happens after restore-from-backup, OS upgrades, or
  //    keystore invalidation). Without this, `read` throws a PlatformException
  //    wrapping `javax.crypto.BadPaddingException: ... BAD_DECRYPT`.
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  FlutterSecureStorage get _storage => const FlutterSecureStorage(
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

  /// How long any single secure-storage call may take before we give up.
  ///
  /// The Android keystore is a platform channel to a system service. It
  /// normally answers in milliseconds, but it can wedge — and an unbounded
  /// `await` on a wedged channel never throws, so no `catch` can save it. The
  /// app then sits on the splash screen forever, showing no error and offering
  /// no way out. Observed directly on a clean emulator: the session check never
  /// completed, so not one network request was ever issued.
  static const Duration _storageTimeout = Duration(seconds: 4);

  Future<String?> retrieveCipherKey({String valKey = "shadow_heat_key"}) async {
    final storage = _storage;

    String? existing;
    try {
      existing = await storage.read(key: valKey).timeout(_storageTimeout);
    } on TimeoutException {
      // Deliberately NOT treated as "no key yet".
      //
      // Returning null here would fall into the regenerate branch below, write
      // a fresh key, and orphan the existing Hive box — signing the customer
      // out and discarding their local data because the keystore was briefly
      // slow. Failing is recoverable; that is not.
      rethrow;
    } on PlatformException {
      // The secure storage file is corrupted (e.g. BAD_DECRYPT after a
      // backup restore). Drop everything we own there and regenerate.
      await _safeWipe(storage, valKey);
      existing = null;
    }

    if (existing == null) {
      final key = Hive.generateSecureKey();
      try {
        await storage
            .write(key: valKey, value: base64UrlEncode(key))
            .timeout(_storageTimeout);
      } on PlatformException {
        await _safeWipe(storage, valKey);
        await storage
            .write(key: valKey, value: base64UrlEncode(key))
            .timeout(_storageTimeout);
      }
      return base64UrlEncode(key);
    }

    return existing;
  }

  Future<void> _safeWipe(FlutterSecureStorage storage, String valKey) async {
    try {
      await storage.delete(key: valKey);
    } catch (_) {
      // Last resort: nuke everything this app owns in secure storage so the
      // next read/write starts from a clean slate.
      try {
        await storage.deleteAll();
      } catch (_) {}
    }
  }
}
