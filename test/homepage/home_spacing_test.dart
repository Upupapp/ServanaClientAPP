/// HOMESPACING+ §26 — spacing, alignment and large-text safety on Home.
///
/// Home pulls four MobX stores, GoRouter and a live catalog, so pumping the
/// real screen in a widget test would exercise the mocks rather than the
/// layout. These assert the two things that actually regressed and can be
/// checked directly: the gutter helper every section now shares, and the
/// absence of the hardcoded values that produced the misalignment.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/common/constants/app_spacing.dart';

Widget _sized(Size size, Widget child) => MediaQuery(
      data: MediaQueryData(size: size),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

void main() {
  group('responsive gutter (§3)', () {
    Future<double> gutterAt(WidgetTester tester, double width) async {
      late double value;
      await tester.pumpWidget(_sized(
        Size(width, 800),
        Builder(builder: (context) {
          value = homeGutter(context);
          return const SizedBox();
        }),
      ));
      return value;
    }

    testWidgets('compact phones below 360 get 16', (tester) async {
      expect(await gutterAt(tester, 320), AppSpacing.lg);
      expect(await gutterAt(tester, 359), AppSpacing.lg);
    });

    testWidgets('standard phones get 20', (tester) async {
      expect(await gutterAt(tester, 360), AppSpacing.xl);
      expect(await gutterAt(tester, 390), AppSpacing.xl);
      expect(await gutterAt(tester, 430), AppSpacing.xl);
    });

    testWidgets('tablets get 24', (tester) async {
      expect(await gutterAt(tester, 600), AppSpacing.section);
      expect(await gutterAt(tester, 800), AppSpacing.section);
    });

    testWidgets('never returns an off-scale value', (tester) async {
      // §4 names 13/17/19/21/27 as the kind of value that must not reappear.
      // A list, not a Set: doubles have no primitive equality, so a const Set
      // of them will not compile.
      const scale = <double>[
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.section,
      ];
      for (final w in [
        320.0,
        360.0,
        375.0,
        390.0,
        412.0,
        430.0,
        600.0,
        800.0
      ]) {
        expect(scale.contains(await gutterAt(tester, w)), isTrue,
            reason: 'width $w produced an off-scale gutter');
      }
    });
  });

  group('wide-screen content width (§19)', () {
    testWidgets('phones get plain symmetric padding', (tester) async {
      late EdgeInsets pad;
      await tester.pumpWidget(_sized(
        const Size(390, 844),
        Builder(builder: (context) {
          pad = homeHorizontalPadding(context);
          return const SizedBox();
        }),
      ));
      expect(pad.left, AppSpacing.xl);
      expect(pad.left, pad.right);
    });

    testWidgets('very wide screens centre the column instead of stretching it',
        (tester) async {
      // §19: a banner stretched across 1200pt is a shallow rectangle nobody
      // designed. Past the max width, extra space becomes margin.
      late EdgeInsets pad;
      await tester.pumpWidget(_sized(
        const Size(1400, 1000),
        Builder(builder: (context) {
          pad = homeHorizontalPadding(context);
          return const SizedBox();
        }),
      ));
      final contentWidth = 1400 - pad.left - pad.right;
      expect(contentWidth, closeTo(kHomeMaxContentWidth, 0.5));
      expect(pad.left, pad.right, reason: 'content must stay centred');
    });
  });

  group('the hardcoded values that caused the misalignment are gone', () {
    // Source-level, because these are the exact literals that produced the
    // 16-vs-20 split the audit found. A future edit reintroducing one would
    // pass every rendering test and silently break the vertical guide again.
    /// Reads a source file with `//` comments stripped.
    ///
    /// These assertions are about code. The comments explaining *why* a value
    /// was removed necessarily quote that value, and matching against them
    /// would fail the moment someone documented the fix properly.
    String read(String p) => File(p).readAsLinesSync().map((l) {
          final i = l.indexOf('//');
          return i == -1 ? l : l.substring(0, i);
        }).join('\n');

    final home =
        read('lib/modules/homepage/presentation/screens/home_screen.dart');

    test('the header no longer computes its own height (§6)', () {
      // `const contentH = 76.0 + 80.0` was a sum of assumed child sizes and was
      // wrong by 5pt at default text size, which the emulator reported as
      // "BOTTOM OVERFLOWED BY 5.0 PIXELS".
      expect(home, isNot(contains('76.0 + 80.0')));
      expect(home, isNot(contains('final totalH = topPad + contentH')));
    });

    test(
        'the search no longer adds its own trailing gap on top of the next '
        'section (§8)', () {
      // 28 below the search plus 20 above "Services" gave a 48pt trench that
      // neither file could see alone.
      final headerSection = home.substring(
        home.indexOf('Widget _buildHeaderSection()'),
        home.indexOf('Widget _buildActiveBookingSection()'),
      );
      expect(headerSection, isNot(contains('SizedBox(height: 28)')));
    });

    test('section gutters come from the helper, not from literals', () {
      for (final literal in const [
        'EdgeInsets.symmetric(horizontal: 16)',
        'EdgeInsets.fromLTRB(16, 16, 16, 0)',
        'EdgeInsets.fromLTRB(16, 20, 16, 0)',
        'EdgeInsets.only(left: 20, bottom: 12)',
      ]) {
        expect(home, isNot(contains(literal)), reason: literal);
      }
      expect(home, contains('homeGutter(context)'));
    });

    test('the benefit section no longer stacks three vertical paddings (§16)',
        () {
      final benefit = read(
          'lib/modules/homepage/presentation/widgets/home_benefit_section.dart');
      expect(benefit,
          isNot(contains('EdgeInsets.symmetric(horizontal: 20, vertical: 8)')));
      expect(benefit, contains('homeGutter(context)'));
    });

    test('the bottom spacer does not re-add the navigation height (§18)', () {
      // The Scaffold already reserves it; adding it again is the double-count
      // §18 warns about.
      expect(home, isNot(contains('SizedBox(height: 40)')));
    });

    test('the stray promo accent line is gone', () {
      final banner = read(
          'lib/modules/homepage/presentation/widgets/home_promotion_banner.dart');
      // A 48x2 Container pinned bottom-left — exactly where the CTA pill sits,
      // so it read as an underline hanging off the button. Asserted on the
      // dimensions rather than on the comment that named it, since `read`
      // strips comments.
      expect(banner, isNot(contains('width: 48')));
    });
  });
}
