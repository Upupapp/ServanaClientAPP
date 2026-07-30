import 'package:client/core/analytics/domain/analytics_consent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsConsent.defaultConsent()', () {
    test('grants ONLY essential — never analytics', () {
      final consent = AnalyticsConsent.defaultConsent();
      expect(consent.grantedCategories, {ConsentCategory.essential});
      expect(consent.grantedCategories.contains(ConsentCategory.analytics),
          false,
          reason: 'analytics consent must never be on by default (PDPA/GDPR)');
    });

    test('allows essential events', () {
      final consent = AnalyticsConsent.defaultConsent();
      expect(consent.allows(ConsentCategory.essential), true);
    });

    test('blocks analytics events', () {
      final consent = AnalyticsConsent.defaultConsent();
      expect(consent.allows(ConsentCategory.analytics), false,
          reason: 'analytics events must be dark until user grants consent');
    });

    test('blocks crashReporting, performance, personalization, marketing', () {
      final consent = AnalyticsConsent.defaultConsent();
      expect(consent.allows(ConsentCategory.crashReporting), false);
      expect(consent.allows(ConsentCategory.performance), false);
      expect(consent.allows(ConsentCategory.personalization), false);
      expect(consent.allows(ConsentCategory.marketing), false);
    });
  });

  group('AnalyticsConsent.fullConsent()', () {
    test('grants essential + analytics + crashReporting + performance', () {
      final consent = AnalyticsConsent.fullConsent();
      expect(consent.grantedCategories, containsAll([
        ConsentCategory.essential,
        ConsentCategory.analytics,
        ConsentCategory.crashReporting,
        ConsentCategory.performance,
      ]));
    });

    test('allows analytics events', () {
      final consent = AnalyticsConsent.fullConsent();
      expect(consent.allows(ConsentCategory.analytics), true);
    });

    test('does NOT grant personalization or marketing', () {
      final consent = AnalyticsConsent.fullConsent();
      expect(consent.grantedCategories.contains(ConsentCategory.personalization),
          false);
      expect(consent.grantedCategories.contains(ConsentCategory.marketing),
          false);
    });

    test('policyVersion matches currentPolicyVersion', () {
      final consent = AnalyticsConsent.fullConsent();
      expect(consent.policyVersion, AnalyticsConsent.currentPolicyVersion);
    });
  });

  group('AnalyticsConsent.allows()', () {
    test('essential category always passes regardless of grant set', () {
      // Even with an empty grantedCategories set, essential must still pass.
      // This is the contract: essential is never gated.
      final consent = AnalyticsConsent(
        grantedCategories: const {},
        policyVersion: AnalyticsConsent.currentPolicyVersion,
        grantedAt: DateTime.now(),
      );
      expect(consent.allows(ConsentCategory.essential), true);
    });

    test('non-essential category blocked when not in grantedCategories', () {
      final consent = AnalyticsConsent(
        grantedCategories: const {ConsentCategory.essential},
        policyVersion: AnalyticsConsent.currentPolicyVersion,
        grantedAt: DateTime.now(),
      );
      expect(consent.allows(ConsentCategory.analytics), false);
      expect(consent.allows(ConsentCategory.crashReporting), false);
    });

    test('non-essential category passes when explicitly granted', () {
      final consent = AnalyticsConsent(
        grantedCategories: const {
          ConsentCategory.essential,
          ConsentCategory.analytics,
        },
        policyVersion: AnalyticsConsent.currentPolicyVersion,
        grantedAt: DateTime.now(),
      );
      expect(consent.allows(ConsentCategory.analytics), true);
    });
  });
}
