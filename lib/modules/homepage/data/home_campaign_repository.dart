import 'package:shared_preferences/shared_preferences.dart';

import 'package:client/modules/homepage/domain/home_campaign_state.dart';

/// Account-scoped persistence for campaign frequency state (LAUNCHBANNER+ §23).
///
/// The key namespace is deliberately three-part — account, campaign, version:
///
///     home_campaign_state/acct_<customerId>/<campaignId>/v<version>
///
/// A single global key such as `hasSeenLaunchBanner` would make Customer A's
/// dismissal silently suppress the campaign for Customer B on a shared device.
/// §41 classes that as Critical, and it is invisible in testing unless someone
/// deliberately signs in as two people.
///
/// Follows the `SupportDraftRepository` precedent already in this codebase: a
/// shared prefix, a key builder, and an enumerate-and-clear counterpart — that
/// last part is what the older `HomeCampaignController` was missing.
class HomeCampaignRepository {
  HomeCampaignRepository({SharedPreferences? prefs}) : _injected = prefs;

  /// Injected only by tests. Production resolves the singleton lazily so
  /// construction never awaits.
  final SharedPreferences? _injected;

  static const String kPrefix = 'home_campaign_state/';

  Future<SharedPreferences> get _prefs async =>
      _injected ?? await SharedPreferences.getInstance();

  /// Builds the storage key.
  ///
  /// A null [accountId] yields a `guest` scope. Guests cannot be shown this
  /// campaign — it is authenticated-only (§5) — but the scope exists so a guest
  /// write can never collide with a real account's namespace.
  static String keyFor({
    required String campaignId,
    required String campaignVersion,
    String? accountId,
  }) {
    final scope = (accountId != null && accountId.isNotEmpty)
        ? 'acct_$accountId'
        : 'guest';
    return '$kPrefix$scope/$campaignId/v$campaignVersion';
  }

  /// Reads state, or null when this customer has no history for the campaign.
  ///
  /// Corrupt JSON decodes to null rather than throwing — §29 requires campaign
  /// failures never to block Home, and "no history" is the safe reading.
  Future<HomeCampaignState?> read({
    required String campaignId,
    required String campaignVersion,
    String? accountId,
  }) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(keyFor(
        campaignId: campaignId,
        campaignVersion: campaignVersion,
        accountId: accountId,
      ));
      return HomeCampaignState.decode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Persists state. Returns false on failure instead of throwing.
  ///
  /// A failed write must not surface to the customer, but the caller does need
  /// to know: silently losing an impression write is how a campaign starts
  /// looping, which §41 classes as Critical.
  Future<bool> write(
    HomeCampaignState state, {
    String? accountId,
  }) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(
        keyFor(
          campaignId: state.campaignId,
          campaignVersion: state.campaignVersion,
          accountId: accountId,
        ),
        state.encode(),
      );
    } catch (_) {
      return false;
    }
  }

  /// Removes every campaign key for one account.
  ///
  /// Not called on logout — §23 requires history to SURVIVE logout, or a
  /// customer could reset a permanent dismissal by signing out and back in.
  /// This exists for account deletion and for tests.
  Future<void> clearAccount(String accountId) async {
    try {
      final prefs = await _prefs;
      final scope = '${kPrefix}acct_$accountId/';
      final keys = prefs.getKeys().where((k) => k.startsWith(scope)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {
      // Best-effort.
    }
  }
}
