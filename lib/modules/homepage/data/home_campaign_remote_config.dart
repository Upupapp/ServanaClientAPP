import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'package:client/modules/homepage/domain/home_promotion.dart';

/// Remote Config overlay for the Home launch campaign (LAUNCHBANNER+ §21/§22).
///
/// Two rules shape this file.
///
/// First, **safe in-app defaults**. Firebase's own guidance is that the app
/// must behave correctly before or without a successful fetch, so every getter
/// falls back to the compiled-in campaign value rather than to a zero value. A
/// failed fetch therefore changes nothing.
///
/// Second, **the kill switch must be able to fail closed but never fail open by
/// accident**. `enabled` defaults to the campaign's own `enabled` flag; the
/// remote value can only be read when Remote Config genuinely returned one, so
/// a network failure cannot silently enable a paused campaign.
///
/// Remote Config values are client-visible. §35 forbids secrets here, and
/// nothing in this file reads or writes anything sensitive.
class HomeCampaignRemoteConfig {
  HomeCampaignRemoteConfig({FirebaseRemoteConfig? remoteConfig})
      : _injected = remoteConfig;

  final FirebaseRemoteConfig? _injected;
  bool _initialised = false;

  // Parameter names, exactly as §21 specifies them.
  static const kEnabled = 'home_launch_banner_enabled';
  static const kCampaignId = 'home_launch_banner_campaign_id';
  static const kVersion = 'home_launch_banner_version';
  static const kStartsAt = 'home_launch_banner_starts_at';
  static const kEndsAt = 'home_launch_banner_ends_at';
  static const kMaxImpressions = 'home_launch_banner_max_impressions';
  static const kRemindDays = 'home_launch_banner_remind_days';
  static const kMinAppVersion = 'home_launch_banner_min_app_version';
  static const kMaxAppVersion = 'home_launch_banner_max_app_version';
  static const kFirstSignInEnabled = 'home_launch_banner_first_signin_enabled';

  FirebaseRemoteConfig? get _rc {
    // Firebase is initialised inside `if (!kIsWeb)` in main.dart, so touching
    // any Firebase singleton on web throws. Guarding here keeps every caller
    // from having to remember that.
    if (kIsWeb) return null;
    if (_injected != null) return _injected;
    try {
      return FirebaseRemoteConfig.instance;
    } catch (_) {
      return null;
    }
  }

  /// Fetches config. Never throws, never blocks Home (§29, §31).
  ///
  /// Returns whether a fetch actually activated, which the caller records for
  /// §30: a campaign whose configuration has never been obtained must not be
  /// shown, because its expiry cannot be known.
  Future<bool> initialise({required HomeCampaign fallback}) async {
    final rc = _rc;
    if (rc == null) return false;
    try {
      await rc.setDefaults(<String, Object>{
        kEnabled: fallback.enabled,
        kCampaignId: fallback.id,
        kVersion: fallback.version,
        kStartsAt: '',
        kEndsAt: '',
        kMaxImpressions: fallback.maxImpressions,
        kRemindDays: fallback.remindLaterCooldown.inDays,
        kMinAppVersion: '',
        kMaxAppVersion: '',
        kFirstSignInEnabled: true,
      });
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        // The campaign is not time-critical; an hour-stale kill switch is an
        // acceptable trade for not hammering the network on every launch.
        minimumFetchInterval: const Duration(hours: 1),
      ));
      final activated = await rc.fetchAndActivate();
      _initialised = true;
      return activated;
    } catch (_) {
      // Offline, quota exhausted, or Firebase unavailable. The compiled-in
      // defaults remain in force.
      return false;
    }
  }

  /// True once a fetch has completed at least once this process.
  bool get hasConfiguration => _initialised;

  /// Applies remote overrides on top of the compiled-in campaign.
  ///
  /// Anything the remote side did not set, or set to an unusable value, leaves
  /// the local value untouched. That asymmetry is deliberate: a typo in the
  /// console should degrade to "as shipped", not to "campaign broken".
  HomeCampaign apply(HomeCampaign campaign) {
    final rc = _rc;
    if (rc == null) return campaign;
    try {
      return campaign.copyWith(
        enabled: rc.getBool(kEnabled),
        startsAt: _date(rc.getString(kStartsAt)),
        endsAt: _date(rc.getString(kEndsAt)),
        maxImpressions:
            _positiveInt(rc.getInt(kMaxImpressions)) ?? campaign.maxImpressions,
        remindLaterCooldown: _positiveInt(rc.getInt(kRemindDays)) != null
            ? Duration(days: rc.getInt(kRemindDays))
            : campaign.remindLaterCooldown,
        minAppVersion: _nonEmpty(rc.getString(kMinAppVersion)),
        maxAppVersion: _nonEmpty(rc.getString(kMaxAppVersion)),
      );
    } catch (_) {
      return campaign;
    }
  }

  /// §5: whether the first-eligible-sign-in trigger is remotely permitted.
  bool get firstSignInEnabled {
    final rc = _rc;
    if (rc == null) return true;
    try {
      return rc.getBool(kFirstSignInEnabled);
    } catch (_) {
      return true;
    }
  }

  static DateTime? _date(String raw) =>
      raw.isEmpty ? null : DateTime.tryParse(raw)?.toUtc();

  static String? _nonEmpty(String raw) => raw.isEmpty ? null : raw;

  /// Zero and negatives mean "unset" for these parameters — a console default
  /// of 0 must not silently cap impressions at zero and disable the campaign.
  static int? _positiveInt(int v) => v > 0 ? v : null;
}
