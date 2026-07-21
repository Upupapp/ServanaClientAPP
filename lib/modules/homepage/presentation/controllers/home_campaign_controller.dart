import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/home_promotion.dart';

class HomeCampaignController {
  // In-memory session block — once dismissed in a session, never show again
  final Set<String> _sessionDismissed = {};
  static const String _prefPrefix = 'home_campaign_dismissed_';

  bool _spotlightShownThisSession = false;

  Future<bool> isSpotlightEligible({
    required HomeCampaign campaign,
    required bool hasCriticalBooking,
    String? accountId,
  }) async {
    if (_spotlightShownThisSession) return false;
    if (hasCriticalBooking) return false;
    final key = _dismissedKey(campaign.id, campaign.version, accountId);
    if (_sessionDismissed.contains(key)) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(key) ?? false);
  }

  Future<void> markSeen(HomeCampaign campaign, {String? accountId}) async {
    _spotlightShownThisSession = true;
    final key = _dismissedKey(campaign.id, campaign.version, accountId);
    _sessionDismissed.add(key);
  }

  Future<void> markDismissed(HomeCampaign campaign,
      {String? accountId}) async {
    _spotlightShownThisSession = true;
    final key = _dismissedKey(campaign.id, campaign.version, accountId);
    _sessionDismissed.add(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  Future<void> markCtaCompleted(HomeCampaign campaign,
      {String? accountId}) async {
    await markDismissed(campaign, accountId: accountId);
  }

  void resetSessionState() {
    _spotlightShownThisSession = false;
    _sessionDismissed.clear();
  }

  String _dismissedKey(String id, String version, String? accountId) {
    final scope = accountId != null ? 'acct_${accountId}_' : 'guest_';
    return '$_prefPrefix$scope${id}_v$version';
  }
}
