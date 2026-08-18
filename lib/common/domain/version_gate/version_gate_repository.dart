import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:client/common/domain/version_gate/version_gate.dart';

/// Delivers [VersionGateConfig] from Remote Config, and remembers the last one.
///
/// Remote Config is the transport because it is already a dependency and
/// already proven in this codebase by the Home campaign registry — introducing
/// a second remote-configuration mechanism for one integer would be the
/// expensive way to do this.
///
/// ## Fail open, but only once
///
/// If Remote Config has NEVER been fetched successfully and nothing is cached,
/// [load] returns null and the gate allows the app through. A gate that blocks
/// the application when the network is unavailable is worse than the problem it
/// solves.
///
/// If a config was fetched before, it is cached and enforced offline. Fail-open
/// applies to never-fetched, not to previously-fetched: a published minimum was
/// a real decision, and a customer going offline must not become a way to
/// escape it. That asymmetry is the whole design.
///
/// ## Nothing sensitive
///
/// Remote Config values are client-visible. This reads four integers, a
/// sentence and two store URLs, and writes the same to unencrypted local
/// preferences. Nothing here is a secret, and nothing here may become one.
class VersionGateRepository {
  VersionGateRepository({
    FirebaseRemoteConfig? remoteConfig,
    SharedPreferences? preferences,
  })  : _injected = remoteConfig,
        _injectedPrefs = preferences;

  final FirebaseRemoteConfig? _injected;
  final SharedPreferences? _injectedPrefs;

  /// Remote Config parameter names.
  static const kSchemaVersion = 'version_gate_schema_version';
  static const kMinimumBuild = 'version_gate_minimum_supported_build';
  static const kRecommendedBuild = 'version_gate_recommended_build';
  static const kMessage = 'version_gate_message';
  static const kAndroidStoreUrl = 'version_gate_android_store_url';
  static const kIosStoreUrl = 'version_gate_ios_store_url';

  /// Where the last known good config is remembered.
  static const _cacheKey = 'version_gate.cached_config.v1';

  FirebaseRemoteConfig? get _rc {
    // Firebase is initialised inside `if (!kIsWeb)` in main.dart, so touching
    // any Firebase singleton on web throws.
    if (kIsWeb) return null;
    if (_injected != null) return _injected;
    try {
      return FirebaseRemoteConfig.instance;
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences?> get _prefs async {
    if (_injectedPrefs != null) return _injectedPrefs;
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// Fetches, caches and returns the config. Never throws.
  ///
  /// Returns the cached config when the fetch fails, and null only when there
  /// has never been one.
  Future<VersionGateConfig?> load() async {
    final fetched = await _fetch();
    if (fetched != null) {
      await _cache(fetched);
      return fetched;
    }
    return _cached();
  }

  Future<VersionGateConfig?> _fetch() async {
    final rc = _rc;
    if (rc == null) return null;
    try {
      // Defaults that assert nothing. `minimum_supported_build: 0` cannot
      // block any build, so a Remote Config project with these parameters
      // unset behaves exactly as if the gate were absent.
      await rc.setDefaults(<String, Object>{
        kSchemaVersion: VersionGateConfig.supportedSchemaVersion,
        kMinimumBuild: 0,
        kRecommendedBuild: 0,
        kMessage: '',
        kAndroidStoreUrl: '',
        kIosStoreUrl: '',
      });
      await rc.fetchAndActivate();

      // A parameter the console has never defined comes back as the default,
      // and a minimum of 0 blocks nothing — so an unconfigured project is
      // indistinguishable from no gate, which is the intended behaviour.
      final minimum = rc.getInt(kMinimumBuild);
      if (minimum <= 0) return null;

      return VersionGateConfig.fromMap(<String, Object?>{
        'schema_version': rc.getInt(kSchemaVersion),
        'minimum_supported_build': minimum,
        'recommended_build': rc.getInt(kRecommendedBuild),
        'message': rc.getString(kMessage),
        'android_store_url': rc.getString(kAndroidStoreUrl),
        'ios_store_url': rc.getString(kIosStoreUrl),
      });
    } catch (_) {
      // Any failure is a fetch failure, and a fetch failure is not evidence
      // about which builds are supported.
      return null;
    }
  }

  Future<void> _cache(VersionGateConfig config) async {
    final prefs = await _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_cacheKey, jsonEncode(config.toMap()));
    } catch (_) {
      // A cache that cannot be written costs an offline enforcement, not a
      // crash.
    }
  }

  Future<VersionGateConfig?> _cached() async {
    final prefs = await _prefs;
    if (prefs == null) return null;
    try {
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return VersionGateConfig.fromMap(
        decoded.map((k, v) => MapEntry(k.toString(), v as Object?)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Test seam: forget the cached config.
  @visibleForTesting
  Future<void> clearCache() async {
    final prefs = await _prefs;
    await prefs?.remove(_cacheKey);
  }
}
