/// Renders whole screens at real device sizes and text scales.
///
/// ## Why this file exists
///
/// The two files whose names suggested this coverage did not provide it.
/// `responsive_test.dart` tests `ServanaBreakpoints`, `otpCellWidth`,
/// `chatBubbleMaxWidth`, `horizontalPadding` and `minTouchTarget` — arithmetic
/// on numbers, no widget. `core/accessibility/accessibility_tokens_test.dart`
/// asserts token constants and `MediaQuery` plumbing, also no widget. The only
/// rendered-overflow test in the repo was for one search card.
///
/// So sixty screens shipped to real customers without any of them ever being
/// built at a phone-sized viewport, and `RewardsScreen` was clipping 411px of
/// its own explanation at the text scale this app declares it supports.
///
/// ## Why an overflow matters more in release than it looks in debug
///
/// In debug an overflow paints the yellow-and-black hatching and throws, which
/// is loud. In a **release** build it does neither: the content is silently
/// clipped. Nobody gets an error report; the customer just sees less text than
/// was written. That is why this runs at 2.0 rather than stopping at the
/// comfortable sizes.
///
/// ## Two traps, both paid for already
///
///  1. **Pass the screen bare.** These widgets bring their own `Scaffold`.
///     Wrapping one in a `SingleChildScrollView` here yields "given an
///     infinite size during layout", which reads as a product bug and is the
///     harness's fault.
///  2. **Set `tester.view.physicalSize`.** Flutter's default test surface is
///     800x600 — a small tablet in landscape, not a phone. A layout that
///     overflows every real handset passes at the default.
///
/// ## Scope, stated rather than implied
///
/// This covers the screens that can be constructed without the dependency
/// locator. Screens that resolve `dpLocator` in `initState` need a registered
/// container and are NOT covered here — see the count asserted at the bottom,
/// which is deliberately a floor rather than a total so that adding a screen
/// to this list never requires editing a number in two places.
library;

import 'package:client/common/presentation/screens/drawer_placeholder_screens.dart';
import 'package:client/modules/settings/presentation/screens/about_screen.dart';
import 'package:client/modules/settings/presentation/screens/security_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real handsets, smallest first. 320x568 is an iPhone SE 1st gen — still the
/// floor Play and the App Store will serve.
const Map<String, Size> _viewports = <String, Size>{
  '320x568': Size(320, 568),
  '360x640': Size(360, 640),
  '390x844': Size(390, 844),
};

/// 1.0 is the default, 1.3 is `AccessibilityTokens.largeTextThreshold`, and
/// 2.0 is `AccessibilityTokens.maxRequiredTextScale` — the ceiling this app
/// promises to support. All three are asserted, because a screen that survives
/// 1.3 and dies at 2.0 is a screen that fails exactly the users who need it.
const List<double> _scales = <double>[1.0, 1.3, 2.0];

/// Every screen here must be constructible with no `dpLocator` registration.
final Map<String, Widget Function()> _screens = <String, Widget Function()>{
  'AboutScreen': () => const AboutScreen(),
  'SecurityScreen': () => const SecurityScreen(),
  'RewardsScreen': () => const RewardsScreen(),
  'FavouritesScreen': () => const FavouritesScreen(),
};

void main() {
  group('screens lay out without overflow at every supported viewport', () {
    for (final screen in _screens.entries) {
      for (final viewport in _viewports.entries) {
        for (final scale in _scales) {
          testWidgets(
            '${screen.key} at ${viewport.key}, text scale $scale',
            (tester) async {
              tester.view.physicalSize = viewport.value;
              tester.view.devicePixelRatio = 1.0;
              addTearDown(tester.view.reset);

              await tester.pumpWidget(
                MediaQuery(
                  data: MediaQueryData(
                    size: viewport.value,
                    textScaler: TextScaler.linear(scale),
                  ),
                  // Bare. The screen supplies its own Scaffold.
                  child: MaterialApp(home: screen.value()),
                ),
              );
              await tester.pump(const Duration(milliseconds: 350));

              expect(
                tester.takeException(),
                isNull,
                reason: '${screen.key} overflowed at ${viewport.key} with text '
                    'scale $scale. In a release build this is silent '
                    'clipping, not an error — the content simply disappears.',
              );
            },
          );
        }
      }
    }
  });

  group('the matrix itself', () {
    test('covers every screen at every viewport and every scale', () {
      // Guards against a screen being added to `_screens` while a viewport or
      // a scale is quietly dropped to make it pass.
      expect(_viewports, hasLength(3));
      expect(_scales, containsAll(<double>[1.0, 1.3, 2.0]));
      expect(
        _screens.length,
        greaterThanOrEqualTo(4),
        reason: 'screens should only ever be added to this matrix',
      );
    });

    test('includes the smallest handset the stores still serve', () {
      // 320dp is where the Rewards clipping was worst — 411px over. Dropping
      // this viewport would make the matrix green and the defect invisible.
      expect(_viewports.values.map((s) => s.width), contains(320.0));
    });
  });
}
