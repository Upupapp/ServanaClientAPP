import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/services/category_experience_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // CategoryRegistry
  // ─────────────────────────────────────────────────────────────────────────

  group('CategoryRegistry', () {
    test('forId returns the correct config for every enum value', () {
      for (final id in ServiceCategoryId.values) {
        final config = CategoryRegistry.forId(id);
        expect(config.id, equals(id));
      }
    });

    test('every config has non-empty headline and subtext', () {
      for (final id in ServiceCategoryId.values) {
        final c = CategoryRegistry.forId(id);
        expect(c.revealHeadline, isNotEmpty,
            reason: '${id.name} headline must not be empty');
        expect(c.revealSubtext, isNotEmpty,
            reason: '${id.name} subtext must not be empty');
      }
    });

    test('first-view duration >= repeat-view duration for all configs', () {
      for (final id in ServiceCategoryId.values) {
        final c = CategoryRegistry.forId(id);
        expect(c.firstViewRevealDuration >= c.repeatViewRevealDuration, isTrue,
            reason: '${id.name}: firstView must be >= repeat');
      }
    });

    test('all primary and accent colors are fully opaque', () {
      for (final id in ServiceCategoryId.values) {
        final c = CategoryRegistry.forId(id);
        expect(c.primaryColor.alpha, equals(255),
            reason: '${id.name} primaryColor must be fully opaque');
        expect(c.accentColor.alpha, equals(255),
            reason: '${id.name} accentColor must be fully opaque');
      }
    });

    test('Beauty flagship first-view duration is at least 800 ms', () {
      expect(
        CategoryRegistry.beautyWellness.firstViewRevealDuration.inMilliseconds,
        greaterThanOrEqualTo(800),
      );
    });

    test('Aircon title is "Aircon Services" (not "Aircon Repair")', () {
      expect(CategoryRegistry.aircon.title, equals('Aircon Services'));
    });

    test('generic repeat-view duration is zero for instant dismiss', () {
      expect(
        CategoryRegistry.generic.repeatViewRevealDuration,
        equals(Duration.zero),
      );
    });

    test('Beauty and Hair share the same brand primaryColor', () {
      expect(
        CategoryRegistry.beautyWellness.primaryColor,
        equals(CategoryRegistry.hairAndNails.primaryColor),
      );
    });

    test('Massage and Aircon have distinct primaryColors from each other', () {
      expect(
        CategoryRegistry.massage.primaryColor,
        isNot(equals(CategoryRegistry.aircon.primaryColor)),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CategoryExperienceHistory
  // ─────────────────────────────────────────────────────────────────────────

  group('CategoryExperienceHistory', () {
    setUp(() => CategoryExperienceHistory.resetForTesting());

    test('hasSeenFirstView returns false for every category on fresh state',
        () {
      for (final id in ServiceCategoryId.values) {
        expect(
          CategoryExperienceHistory.hasSeenFirstView(id),
          isFalse,
          reason: '${id.name} must not be pre-marked',
        );
      }
    });

    test('markFirstViewSeen → hasSeenFirstView returns true', () {
      CategoryExperienceHistory.markFirstViewSeen(
          ServiceCategoryId.beautyWellness);
      expect(
        CategoryExperienceHistory.hasSeenFirstView(
            ServiceCategoryId.beautyWellness),
        isTrue,
      );
    });

    test('marking one category does not affect others', () {
      CategoryExperienceHistory.markFirstViewSeen(ServiceCategoryId.aircon);
      expect(
        CategoryExperienceHistory.hasSeenFirstView(ServiceCategoryId.massage),
        isFalse,
      );
      expect(
        CategoryExperienceHistory.hasSeenFirstView(
            ServiceCategoryId.hairAndNails),
        isFalse,
      );
    });

    test('markFirstViewSeen is idempotent', () {
      CategoryExperienceHistory.markFirstViewSeen(
          ServiceCategoryId.hairAndNails);
      expect(
        () => CategoryExperienceHistory.markFirstViewSeen(
            ServiceCategoryId.hairAndNails),
        returnsNormally,
      );
      expect(
        CategoryExperienceHistory.hasSeenFirstView(
            ServiceCategoryId.hairAndNails),
        isTrue,
      );
    });

    test('resetForTesting clears all entries', () {
      for (final id in ServiceCategoryId.values) {
        CategoryExperienceHistory.markFirstViewSeen(id);
      }
      CategoryExperienceHistory.resetForTesting();
      for (final id in ServiceCategoryId.values) {
        expect(CategoryExperienceHistory.hasSeenFirstView(id), isFalse);
      }
    });

    test('first-view flag pattern: first entry = true, second = false', () {
      const id = ServiceCategoryId.massage;

      // Simulate initState() call.
      final isFirstView = !CategoryExperienceHistory.hasSeenFirstView(id);
      CategoryExperienceHistory.markFirstViewSeen(id);

      expect(isFirstView, isTrue);

      // Re-enter same category.
      final isFirstViewAgain = !CategoryExperienceHistory.hasSeenFirstView(id);
      expect(isFirstViewAgain, isFalse);
    });

    test('all five categories can be independently tracked', () {
      const ids = ServiceCategoryId.values;
      for (int i = 0; i < ids.length; i++) {
        CategoryExperienceHistory.markFirstViewSeen(ids[i]);
        for (int j = 0; j <= i; j++) {
          expect(CategoryExperienceHistory.hasSeenFirstView(ids[j]), isTrue,
              reason: '${ids[j].name} should be seen after being marked');
        }
        for (int j = i + 1; j < ids.length; j++) {
          expect(CategoryExperienceHistory.hasSeenFirstView(ids[j]), isFalse,
              reason: '${ids[j].name} should not be seen yet');
        }
      }
    });
  });
}
