/// A device in dark mode must not be handed a theme the app does not have.
///
/// Reported from production against 1.0.0+36: on a phone set to dark mode the
/// Create Account screen rendered its subtitle, its "Already have an account?"
/// line and its terms-and-conditions text as near-black on near-black. The
/// fields and buttons were fine; the words were not there.
///
/// `ColorPalette` holds mutable statics with exactly one set of values —
/// `secondaryText` is #111827 and `accentText` is #6A717F — and `applyBrand()`
/// reassigns them to those same light values at startup. No dark variant exists
/// anywhere. Those two colours are read directly, bypassing `ThemeData`, in
/// hundreds of places, so `buildDarkAppTheme` swapped the surfaces to dark and
/// left every one of them near-black.
///
/// It survived because 39 of the 59 screens hardcode a light scaffold
/// background and are immune. Create Account declares no background at all, so
/// it inherits the theme — and it is the screen a new customer has to get
/// through.
///
/// Settings → Appearance already states the position: it offers System Default
/// and Light, and lists Dark as "being added in a future update". These tests
/// hold the app to what that screen promises.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/common/config/app_config.dart';
import 'package:client/common/constants/color_palette.dart';

String _read(String p) => File(p).readAsStringSync();

String _code(String p) => File(p)
    .readAsLinesSync()
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  group('the app does not ship an unimplemented dark theme', () {
    test('MaterialApp does not install buildDarkAppTheme', () {
      // Comments stripped: the replacement carries an explanation that names
      // buildDarkAppTheme, and matching that prose would fail against the fix.
      final main = _code('lib/main.dart');
      expect(main, isNot(contains('darkTheme: buildDarkAppTheme(')),
          reason: 'dark mode has no palette; installing the dark theme puts '
              'near-black text on dark surfaces');
      expect(main, contains('darkTheme: buildAppTheme('),
          reason: 'a dark device must still receive the light theme');
    });

    test('the palette still has no dark values, which is why', () {
      // If someone adds real dark tokens, this test should fail and be removed
      // along with the clamp above — that is the point at which restoring
      // buildDarkAppTheme becomes correct.
      final palette = _code('lib/common/constants/color_palette.dart');
      expect(palette, contains('static Color secondaryText'));
      expect(palette, isNot(contains('secondaryTextDark')));
      expect(palette, isNot(contains('darkSecondaryText')));
    });

    test('Appearance offers no Dark option, matching the above', () {
      final appearance = _read(
          'lib/modules/settings/presentation/screens/appearance_screen.dart');
      expect(appearance, contains('SettingsUnavailableTile'));
      expect(
          appearance, contains('Dark mode is being added in a future update'));
      expect(appearance, isNot(contains('setThemeMode(ThemeMode.dark)')),
          reason: 'nothing may select a theme mode the app cannot render');
    });
  });

  group('the signup screen is readable on the theme it will actually get', () {
    testWidgets('its body text contrasts against the light scaffold',
        (tester) async {
      // The colours below are the ones the invisible strings used. Rather than
      // pump the whole screen — which needs Firebase, a router and a live API
      // client — this checks the contrast of the exact pairing that failed.
      const scaffold = Color(0xFFF6F6FA); // primaryBackground after applyBrand
      const bodyText = Color(0xFF111827); // secondaryText

      final ratio = _contrast(bodyText, scaffold);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'WCAG AA for body text; measured $ratio:1');
    });

    testWidgets('secondary text clears the floor on the same scaffold', (
      tester,
    ) async {
      // Added 2026-08-11, because it did not. `accentText` was #6B7280, which
      // measures **4.485:1** on #F6F6FA — under the 4.5:1 floor, on the
      // commonest text-on-surface pairing in the app, and it shipped that way.
      // Nothing here covered the pair; the test above only covers the near-black
      // body colour, which is why the miss survived.
      //
      // Caught in the provider app, which was being aligned to this palette and
      // has a contrast test over its token pairs — it refused the value on the
      // way in. Corrected to #6A717F, same hue and saturation, four thousandths
      // of HSL lightness darker.
      //
      // Read from ColorPalette rather than retyped, so the test cannot pass
      // against a value the app no longer uses — and checked BOTH BEFORE AND
      // AFTER `applyBrand()`. The colour is assigned in two places: the field
      // default, and again inside applyBrand, which runs before the first frame.
      // Fixing one and not the other leaves the app shipping the old value while
      // a test reading the other passes, and that is not a hypothetical — it is
      // the shape of this file's original bug.
      const scaffold = Color(0xFFF6F6FA);

      void check(String when) {
        final ratio = _contrast(ColorPalette.accentText, scaffold);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'accentText on primaryBackground measured $ratio:1 $when. This is '
              'helper copy, captions and metadata across the app — it is body '
              'text and the 4.5:1 floor applies. #6B7280 measures 4.485:1; do '
              'not go back.',
        );
      }

      check('as declared');
      ColorPalette.applyBrand(AppConfig.fromEnv().brand);
      check('after applyBrand(), which is what actually ships');
    });

    testWidgets('the same text would fail on a dark surface', (tester) async {
      // The control. Without this the test above passes for a trivial reason
      // and proves nothing about why the clamp is needed.
      const darkSurface = Color(0xFF121212);
      const bodyText = Color(0xFF111827);

      expect(_contrast(bodyText, darkSurface), lessThan(4.5),
          reason: 'this is the pairing production shipped on a dark phone');
    });
  });
}

/// WCAG 2.1 relative-luminance contrast ratio.
///
/// Computed rather than eyeballed: "looks readable" is how a 1.04:1 pairing
/// ships.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

double _luminance(Color c) {
  double channel(int v) {
    final s = v / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(c.red) +
      0.7152 * channel(c.green) +
      0.0722 * channel(c.blue);
}
