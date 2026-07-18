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

  Future<String?> retrieveCipherKey({String valKey = "shadow_heat_key"}) async {
    final storage = _storage;

    String? existing;
    try {
      existing = await storage.read(key: valKey);
    } on PlatformException {
      // The secure storage file is corrupted (e.g. BAD_DECRYPT after a
      // backup restore). Drop everything we own there and regenerate.
      await _safeWipe(storage, valKey);
      existing = null;
    }

    if (existing == null) {
      final key = Hive.generateSecureKey();
      try {
        await storage.write(key: valKey, value: base64UrlEncode(key));
      } on PlatformException {
        await _safeWipe(storage, valKey);
        await storage.write(key: valKey, value: base64UrlEncode(key));
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
