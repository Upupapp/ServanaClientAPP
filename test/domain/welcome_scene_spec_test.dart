import 'package:client/modules/landing/domain/welcome_scene_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WelcomeSceneSpec.scenes', () {
    test('has exactly three scenes', () {
      expect(WelcomeSceneSpec.scenes, hasLength(3));
    });

    test('each scene has a non-empty id', () {
      for (final s in WelcomeSceneSpec.scenes) {
        expect(s.id, isNotEmpty,
            reason: 'scene id must be non-empty for analytics');
      }
    });

    test('all scene ids are unique', () {
      final ids = WelcomeSceneSpec.scenes.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('each scene has non-empty headline and subtext', () {
      for (final s in WelcomeSceneSpec.scenes) {
        expect(s.headline, isNotEmpty);
        expect(s.subtext, isNotEmpty);
      }
    });

    test('background assets point at existing page_N_bg.png paths', () {
      final assets = WelcomeSceneSpec.scenes.map((s) => s.backgroundAsset);
      expect(
          assets,
          containsAll([
            'assets/images/welcome/page_1_bg.webp',
            'assets/images/welcome/page_2_bg.webp',
            'assets/images/welcome/page_3_bg.webp',
          ]));
    });

    test('each scene has exactly three gradient stops', () {
      for (final s in WelcomeSceneSpec.scenes) {
        expect(s.gradientStops, hasLength(3),
            reason: 'gradient requires exactly 3 stops for 3-color overlay');
      }
    });

    test('gradient stops are in ascending order within [0, 1]', () {
      for (final s in WelcomeSceneSpec.scenes) {
        final stops = s.gradientStops;
        expect(stops[0], greaterThanOrEqualTo(0.0));
        expect(stops[1], greaterThan(stops[0]));
        expect(stops[2], greaterThan(stops[1]));
        expect(stops[2], lessThanOrEqualTo(1.0));
      }
    });

    test('each scene has a non-empty semantic description', () {
      for (final s in WelcomeSceneSpec.scenes) {
        expect(s.semanticDescription, isNotEmpty,
            reason: 'screen-reader must have a description for every scene');
      }
    });
  });

  group('WelcomeSceneVisual', () {
    test('enum has exactly three values', () {
      expect(WelcomeSceneVisual.values, hasLength(3));
    });

    test('values are serviceCategories, serviceCards, bookingJourney', () {
      expect(
          WelcomeSceneVisual.values,
          containsAll([
            WelcomeSceneVisual.serviceCategories,
            WelcomeSceneVisual.serviceCards,
            WelcomeSceneVisual.bookingJourney,
          ]));
    });
  });
}
