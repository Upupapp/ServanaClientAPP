import 'package:flutter_test/flutter_test.dart';
import 'package:client/modules/homepage/data/home_promotion_repository.dart';
import 'package:client/modules/homepage/domain/home_promotion.dart';

void main() {
  group('HomePromotionRepository', () {
    final repo = HomePromotionRepository();

    test('bannerA returned for all audiences', () {
      expect(repo.getBannerA(isAuthenticated: false), isNotNull);
      expect(repo.getBannerA(isAuthenticated: true), isNotNull);
    });

    test('bannerB returned for all audiences', () {
      expect(repo.getBannerB(isAuthenticated: false), isNotNull);
      expect(repo.getBannerB(isAuthenticated: true), isNotNull);
    });

    test('bannerC guest-only for unauthenticated', () {
      final promo = repo.getBannerC(isAuthenticated: false);
      expect(promo, isNotNull);
      expect(promo!.audience, equals(HomePromotionAudience.guestOnly));
    });

    test('bannerC authenticated for authenticated', () {
      final promo = repo.getBannerC(isAuthenticated: true);
      expect(promo, isNotNull);
      expect(promo!.audience, equals(HomePromotionAudience.authenticatedOnly));
    });

    test('all promotions have non-empty title and ctaLabel', () {
      for (final promo in [
        repo.getBannerA(isAuthenticated: false)!,
        repo.getBannerB(isAuthenticated: false)!,
        repo.getBannerC(isAuthenticated: false)!,
        repo.getBannerC(isAuthenticated: true)!,
      ]) {
        expect(promo.title, isNotEmpty);
        expect(promo.ctaLabel, isNotEmpty);
        expect(promo.analyticsId, isNotEmpty);
      }
    });

    test('no promotion contains fake discounts', () {
      final allPromos = [
        repo.getBannerA(isAuthenticated: false)!,
        repo.getBannerB(isAuthenticated: false)!,
        repo.getBannerC(isAuthenticated: false)!,
        repo.getBannerC(isAuthenticated: true)!,
      ];
      for (final p in allPromos) {
        expect(p.title.toLowerCase(), isNot(contains('cashback')));
        expect(p.subtitle?.toLowerCase() ?? '', isNot(contains('cashback')));
        expect(p.title, isNot(contains('dining')));
      }
    });

    test('default spotlight is non-null and has correct ID', () {
      expect(
        HomePromotionRepository.defaultSpotlight.id,
        equals('benefit_spotlight_v1'),
      );
      expect(
        HomePromotionRepository.defaultSpotlight.ctaLabel,
        isNotEmpty,
      );
    });
  });
}
