import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:client/common/domain/helpers/update_repo.dart';
import 'package:client/common/domain/version_gate/version_gate.dart';
import 'package:client/common/domain/version_gate/version_gate_repository.dart';

/// Decides, at launch and on resume, whether this build may keep running.
///
/// Separated from the widget that draws the blocking screen so the policy can
/// be tested without a Flutter binding, and so the frequency cap on the soft
/// prompt lives beside the decision rather than inside a `build` method.
///
/// ## The consumer `update_repo.dart` never had
///
/// `UpdateHelper` wrapped Play Core's in-app update flow and had **zero
/// callers** anywhere in `lib/`, so nothing enforced a minimum version. It is
/// now called from exactly one place — the hard block on Android — rather than
/// deleted, because Play's immediate-update flow is a materially better
/// experience than bouncing the customer to a store listing, and it is already
/// a dependency.
///
/// It only ever covered half the fleet: `in_app_update` is Play Core and
/// Android-only. iOS has no equivalent and needs the application-level gate
/// this class provides, which is the reason the gate is not simply "call
/// InAppUpdate at startup".
class VersionGateCoordinator {
  VersionGateCoordinator({
    VersionGateRepository? repository,
    SharedPreferences? preferences,
    Future<int> Function()? readBuildNumber,
    Future<void> Function()? androidImmediateUpdate,
  })  : _repo = repository ?? VersionGateRepository(),
        _injectedPrefs = preferences,
        _readBuildNumber = readBuildNumber ?? _defaultBuildNumber,
        _androidImmediateUpdate =
            androidImmediateUpdate ?? UpdateHelper.checkForUpdate;

  final VersionGateRepository _repo;
  final SharedPreferences? _injectedPrefs;
  final Future<int> Function() _readBuildNumber;
  final Future<void> Function() _androidImmediateUpdate;

  /// How long a dismissed soft prompt stays dismissed. A nag on every resume
  /// is how customers learn to dismiss without reading, which costs the hard
  /// block its credibility too.
  static const softPromptCooldown = Duration(days: 3);
  static const _lastPromptKey = 'version_gate.last_soft_prompt_epoch_ms';

  VersionGateConfig? _config;
  VersionGateConfig? get config => _config;

  int _buildNumber = 0;
  int get buildNumber => _buildNumber;

  /// Evaluates the gate. Never throws.
  ///
  /// Call at launch BEFORE the first authenticated request, and again on
  /// resume — a build can become unsupported while it sits in the background.
  Future<VersionGateDecision> evaluate({DateTime? now}) async {
    try {
      _buildNumber = await _readBuildNumber();
      _config = await _repo.load();
      final decision = VersionGate.evaluate(
        currentBuild: _buildNumber,
        config: _config,
      );
      if (decision != VersionGateDecision.recommendUpdate) return decision;

      // Frequency cap applies only to the dismissible half. A hard block is
      // never suppressed.
      return await _softPromptDue(now ?? DateTime.now())
          ? VersionGateDecision.recommendUpdate
          : VersionGateDecision.allowed;
    } catch (_) {
      // The gate may block the app; it may never break it.
      return VersionGateDecision.allowed;
    }
  }

  Future<bool> _softPromptDue(DateTime now) async {
    final prefs = _injectedPrefs ?? await _safePrefs();
    if (prefs == null) return true;
    final last = prefs.getInt(_lastPromptKey);
    if (last == null) return true;
    final since = now.difference(DateTime.fromMillisecondsSinceEpoch(last));
    return since >= softPromptCooldown;
  }

  /// Records that the customer dismissed the soft prompt.
  Future<void> recordSoftPromptShown({DateTime? now}) async {
    final prefs = _injectedPrefs ?? await _safePrefs();
    await prefs?.setInt(
      _lastPromptKey,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  /// The store URL for this platform, or empty when none is configured.
  String storeUrl() {
    final c = _config;
    if (c == null) return '';
    if (kIsWeb) return '';
    return Platform.isIOS ? c.iosStoreUrl : c.androidStoreUrl;
  }

  /// Attempts Play's immediate in-app update. Android only; returns false when
  /// it is unavailable so the caller falls back to the store link.
  Future<bool> tryAndroidImmediateUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      await _androidImmediateUpdate();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> _defaultBuildNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber) ?? 0;
    } catch (_) {
      // 0 is read by VersionGate as "unknown", which allows the app through.
      return 0;
    }
  }

  Future<SharedPreferences?> _safePrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
