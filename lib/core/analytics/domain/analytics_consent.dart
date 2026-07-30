import 'package:shared_preferences/shared_preferences.dart';

enum ConsentCategory {
  essential,
  analytics,
  crashReporting,
  performance,
  personalization,
  marketing,
}

class AnalyticsConsent {
  const AnalyticsConsent({
    required this.grantedCategories,
    required this.policyVersion,
    required this.grantedAt,
  });

  final Set<ConsentCategory> grantedCategories;
  final int policyVersion;
  final DateTime grantedAt;

  static const int currentPolicyVersion = 1;

  // Default grants essential only — analytics/crash require explicit user opt-in
  // (PDPA/GDPR: consent must be affirmative before non-essential tracking).
  static AnalyticsConsent defaultConsent() => AnalyticsConsent(
        grantedCategories: const {ConsentCategory.essential},
        policyVersion: currentPolicyVersion,
        grantedAt: DateTime.now(),
      );

  // Full consent — call this after the user explicitly accepts in the consent
  // dialog (when one is implemented). Until then analytics stays dark.
  static AnalyticsConsent fullConsent() => AnalyticsConsent(
        grantedCategories: const {
          ConsentCategory.essential,
          ConsentCategory.analytics,
          ConsentCategory.crashReporting,
          ConsentCategory.performance,
        },
        policyVersion: currentPolicyVersion,
        grantedAt: DateTime.now(),
      );

  bool allows(ConsentCategory category) =>
      category == ConsentCategory.essential ||
      grantedCategories.contains(category);

  AnalyticsConsent grant(ConsentCategory category) => AnalyticsConsent(
        grantedCategories: {...grantedCategories, category},
        policyVersion: policyVersion,
        grantedAt: grantedAt,
      );

  AnalyticsConsent revoke(ConsentCategory category) => AnalyticsConsent(
        grantedCategories:
            grantedCategories.where((c) => c != category).toSet(),
        policyVersion: policyVersion,
        grantedAt: grantedAt,
      );

  static const _keyPrefix = 'analytics_consent_v1_';

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '${_keyPrefix}categories',
      grantedCategories.map((c) => c.name).toList(),
    );
    await prefs.setInt('${_keyPrefix}policy_version', policyVersion);
    await prefs.setString(
        '${_keyPrefix}granted_at', grantedAt.toIso8601String());
  }

  static Future<AnalyticsConsent> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('${_keyPrefix}categories');
      if (raw == null) return defaultConsent();
      final categories = raw
          .map((name) => ConsentCategory.values.where((c) => c.name == name))
          .expand((it) => it)
          .toSet();
      return AnalyticsConsent(
        grantedCategories: categories,
        policyVersion: prefs.getInt('${_keyPrefix}policy_version') ??
            currentPolicyVersion,
        grantedAt: DateTime.tryParse(
                prefs.getString('${_keyPrefix}granted_at') ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return defaultConsent();
    }
  }
}
