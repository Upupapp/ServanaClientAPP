import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/modules/homepage/presentation/controllers/home_campaign_controller.dart';
import 'package:client/modules/homepage/data/home_promotion_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeCampaignController', () {
    test('spotlight eligible on first visit', () async {
      final ctrl = HomeCampaignController();
      final result = await ctrl.isSpotlightEligible(
        campaign: HomePromotionRepository.defaultSpotlight,
        hasCriticalBooking: false,
      );
      expect(result, isTrue);
    });

    test('spotlight not eligible when critical booking pending', () async {
      final ctrl = HomeCampaignController();
      final result = await ctrl.isSpotlightEligible(
        campaign: HomePromotionRepository.defaultSpotlight,
        hasCriticalBooking: true,
      );
      expect(result, isFalse);
    });

    test('spotlight not eligible after dismiss in same session', () async {
      final ctrl = HomeCampaignController();
      await ctrl.markDismissed(HomePromotionRepository.defaultSpotlight);
      final result = await ctrl.isSpotlightEligible(
        campaign: HomePromotionRepository.defaultSpotlight,
        hasCriticalBooking: false,
      );
      expect(result, isFalse);
    });

    test('spotlight not eligible after persistent dismiss (new instance)',
        () async {
      final ctrl1 = HomeCampaignController();
      await ctrl1.markDismissed(HomePromotionRepository.defaultSpotlight);
      // Simulate new app session with new controller instance
      final ctrl2 = HomeCampaignController();
      final result = await ctrl2.isSpotlightEligible(
        campaign: HomePromotionRepository.defaultSpotlight,
        hasCriticalBooking: false,
      );
      expect(result, isFalse);
    });

    test('session-level block after markSeen', () async {
      final ctrl = HomeCampaignController();
      await ctrl.markSeen(HomePromotionRepository.defaultSpotlight);
      final result = await ctrl.isSpotlightEligible(
        campaign: HomePromotionRepository.defaultSpotlight,
        hasCriticalBooking: false,
      );
      expect(result, isFalse);
    });

    test('account isolation: different account IDs have separate state',
        () async {
      // Dismiss for user_a — persists to SharedPreferences under user_a's key.
      final ctrl1 = HomeCampaignController();
      await ctrl1.markDismissed(
        HomePromotionRepository.defaultSpotlight,
        accountId: 'user_a',
      );
      // New controller simulates a new session (e.g. user_b logs in on the
      // same device). Only the SharedPreferences key for user_a is set;
      // the user_b key is absent, so user_b should still be eligible.
      final ctrl2 = HomeCampaignController();
      final resultB = await ctrl2.isSpotlightEligible(
        campaign: HomePromotionRepository.defaultSpotlight,
        hasCriticalBooking: false,
        accountId: 'user_b',
      );
      expect(resultB, isTrue);
    });
  });
}
