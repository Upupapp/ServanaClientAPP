import 'package:client/modules/landing/domain/welcome_motion_mode.dart';
import 'package:client/modules/landing/presentation/controllers/welcome_experience_controller.dart';
import 'package:flutter_test/flutter_test.dart';

WelcomeExperienceController _make(
        [WelcomeMotionMode mode = WelcomeMotionMode.full]) =>
    WelcomeExperienceController(motionMode: mode);

void main() {
  group('WelcomeExperienceController — initial state', () {
    late WelcomeExperienceController ctrl;

    setUp(() => ctrl = _make());
    tearDown(() => ctrl.dispose());

    test('pageProgress starts at 0.0', () {
      expect(ctrl.pageProgress, 0.0);
    });

    test('currentPage starts at 0', () {
      expect(ctrl.currentPage, 0);
    });

    test('navigationLocked starts false', () {
      expect(ctrl.navigationLocked, isFalse);
    });

    test('motionMode is preserved from constructor', () {
      expect(ctrl.motionMode, WelcomeMotionMode.full);
    });

    test('staticMode controller preserves mode', () {
      final c = _make(WelcomeMotionMode.staticMode);
      expect(c.motionMode, WelcomeMotionMode.staticMode);
      c.dispose();
    });
  });

  group('WelcomeExperienceController — navigation lock', () {
    late WelcomeExperienceController ctrl;
    setUp(() => ctrl = _make());
    tearDown(() => ctrl.dispose());

    test('lock() sets navigationLocked to true', () {
      ctrl.lock();
      expect(ctrl.navigationLocked, isTrue);
    });

    test('unlock() sets navigationLocked to false after lock()', () {
      ctrl.lock();
      ctrl.unlock();
      expect(ctrl.navigationLocked, isFalse);
    });

    test('lock() notifies listeners', () {
      var notified = false;
      ctrl.addListener(() => notified = true);
      ctrl.lock();
      expect(notified, isTrue);
    });

    test('lock() when already locked does not double-notify', () {
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.lock();
      ctrl.lock(); // second call should be a no-op
      expect(count, 1);
    });

    test('unlock() when already unlocked does not notify', () {
      var count = 0;
      ctrl.addListener(() => count++);
      ctrl.unlock(); // no-op: already unlocked
      expect(count, 0);
    });
  });

  group('WelcomeExperienceController — parallax helpers', () {
    late WelcomeExperienceController ctrl;
    setUp(() => ctrl = _make());
    tearDown(() => ctrl.dispose());

    test('parallaxOffset is 0 when pageProgress equals pageIndex', () {
      // pageProgress starts at 0 and pageIndex=0 → no offset
      expect(ctrl.parallaxOffset(0, 0.3, 400), 0.0);
    });

    test('travelProgress returns 0.0 at start of segment', () {
      expect(ctrl.travelProgress(0, 1), 0.0);
    });

    test('travelProgress clamps below 0', () {
      // pageProgress=0, segment (1,2) → progress is negative → clamp to 0
      expect(ctrl.travelProgress(1, 2), 0.0);
    });
  });

  group('WelcomeExperienceController — page change', () {
    late WelcomeExperienceController ctrl;
    setUp(() => ctrl = _make());
    tearDown(() => ctrl.dispose());

    test('onPageChanged updates currentPage', () {
      ctrl.onPageChanged(1);
      expect(ctrl.currentPage, 1);
    });

    test('onPageChanged notifies listeners', () {
      var notified = false;
      ctrl.addListener(() => notified = true);
      ctrl.onPageChanged(2);
      expect(notified, isTrue);
    });
  });

  group('WelcomeMotionMode helpers', () {
    test('full mode has parallax and traveling elements', () {
      expect(WelcomeMotionMode.full.hasParallax, isTrue);
      expect(WelcomeMotionMode.full.hasTravelingElements, isTrue);
      expect(WelcomeMotionMode.full.isStatic, isFalse);
    });

    test('staticMode is static and has no parallax', () {
      expect(WelcomeMotionMode.staticMode.isStatic, isTrue);
      expect(WelcomeMotionMode.staticMode.hasParallax, isFalse);
      expect(WelcomeMotionMode.staticMode.hasTravelingElements, isFalse);
      expect(WelcomeMotionMode.staticMode.hasLogoFragments, isFalse);
    });

    test('standard mode has parallax but no ambient loops', () {
      expect(WelcomeMotionMode.standard.hasParallax, isTrue);
      expect(WelcomeMotionMode.standard.hasAmbientLoops, isFalse);
      expect(WelcomeMotionMode.standard.isStatic, isFalse);
    });

    test('reduced mode has no parallax and no traveling elements', () {
      expect(WelcomeMotionMode.reduced.hasParallax, isFalse);
      expect(WelcomeMotionMode.reduced.hasTravelingElements, isFalse);
    });
  });
}
