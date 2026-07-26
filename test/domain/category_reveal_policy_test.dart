import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/modules/categories/domain/category_reveal_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => CategoryRevealPolicy.reset());
  tearDown(() => CategoryRevealPolicy.reset());

  group('CategoryRevealPolicy.decide', () {
    test('returns fullReveal on first visit with motion enabled', () {
      final decision = CategoryRevealPolicy.decide(
        categoryId: ServiceCategoryId.beautyWellness,
        reducedMotion: false,
      );
      expect(decision, RevealDecision.fullReveal);
    });

    test('returns reducedReveal on first visit with reduced motion', () {
      final decision = CategoryRevealPolicy.decide(
        categoryId: ServiceCategoryId.aircon,
        reducedMotion: true,
      );
      expect(decision, RevealDecision.reducedReveal);
    });

    test('returns skipReveal after markSeen is called', () {
      CategoryRevealPolicy.markSeen(ServiceCategoryId.massage);
      final decision = CategoryRevealPolicy.decide(
        categoryId: ServiceCategoryId.massage,
        reducedMotion: false,
      );
      expect(decision, RevealDecision.skipReveal);
    });

    test('categories are tracked independently', () {
      CategoryRevealPolicy.markSeen(ServiceCategoryId.beautyWellness);
      expect(
        CategoryRevealPolicy.decide(
          categoryId: ServiceCategoryId.hairAndNails,
          reducedMotion: false,
        ),
        RevealDecision.fullReveal,
      );
    });

    test('reset clears all seen categories', () {
      CategoryRevealPolicy.markSeen(ServiceCategoryId.beautyWellness);
      CategoryRevealPolicy.markSeen(ServiceCategoryId.aircon);
      CategoryRevealPolicy.reset();
      expect(
        CategoryRevealPolicy.decide(
          categoryId: ServiceCategoryId.beautyWellness,
          reducedMotion: false,
        ),
        RevealDecision.fullReveal,
      );
    });

    test('hasSeen returns false before markSeen', () {
      expect(CategoryRevealPolicy.hasSeen(ServiceCategoryId.aircon), isFalse);
    });

    test('hasSeen returns true after markSeen', () {
      CategoryRevealPolicy.markSeen(ServiceCategoryId.aircon);
      expect(CategoryRevealPolicy.hasSeen(ServiceCategoryId.aircon), isTrue);
    });
  });
}
