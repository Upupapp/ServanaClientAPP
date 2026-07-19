import 'package:client/common/presentation/responsive/servana_responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServanaBreakpoints', () {
    test('compact < standard < largePh < tablet', () {
      expect(ServanaBreakpoints.compact, lessThan(ServanaBreakpoints.standard));
      expect(ServanaBreakpoints.standard, lessThan(ServanaBreakpoints.largePh));
      expect(ServanaBreakpoints.largePh, lessThan(ServanaBreakpoints.tablet));
    });
  });

  group('ServanaResponsive.otpCellWidth', () {
    test('returns a value within [minCell, maxCell] on a 320dp screen', () {
      const screen = 320.0;
      const hPad = 48.0;
      const gap = 8.0;
      const len = 6;
      const minCell = 40.0;
      const maxCell = 56.0;
      final w = ServanaResponsive.otpCellWidth(
        availableWidth: screen - hPad,
        otpLength: len,
        gapBetween: gap,
        minCell: minCell,
        maxCell: maxCell,
      );
      // Cell must be within the clamped range regardless of viewport.
      expect(w, greaterThanOrEqualTo(minCell));
      expect(w, lessThanOrEqualTo(maxCell));
    });

    test('clamps to maxCell on wide screens', () {
      final w = ServanaResponsive.otpCellWidth(
        availableWidth: 900.0,
        otpLength: 6,
        gapBetween: 8.0,
        maxCell: 56.0,
      );
      expect(w, equals(56.0));
    });

    test('clamps to minCell on very narrow screens', () {
      final w = ServanaResponsive.otpCellWidth(
        availableWidth: 200.0,
        otpLength: 6,
        gapBetween: 8.0,
        minCell: 40.0,
      );
      expect(w, equals(40.0));
    });
  });

  group('ServanaResponsive.chatBubbleMaxWidth', () {
    testWidgets('is 78% of width on a standard phone', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 390, height: 844, builder: (context) {
          final max = ServanaResponsive.chatBubbleMaxWidth(context);
          // 390 * 0.78 = 304.2, clamped to [240, 320] → 304.2
          expect(max, closeTo(390 * 0.78, 1.0));
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('does not exceed 320 on a wide tablet', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 1024, height: 768, builder: (context) {
          final max = ServanaResponsive.chatBubbleMaxWidth(context);
          expect(max, equals(320.0));
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('does not go below 240 on the narrowest phone', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 280, height: 568, builder: (context) {
          final max = ServanaResponsive.chatBubbleMaxWidth(context);
          expect(max, equals(240.0));
          return const SizedBox.shrink();
        }),
      );
    });
  });

  group('ServanaResponsive breakpoint helpers', () {
    testWidgets('isCompact is true below 360dp', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 320, height: 568, builder: (context) {
          expect(ServanaResponsive.isCompact(context), isTrue);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('isCompact is false at 360dp', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 360, height: 640, builder: (context) {
          expect(ServanaResponsive.isCompact(context), isFalse);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('isTablet is true at 600dp', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 600, height: 960, builder: (context) {
          expect(ServanaResponsive.isTablet(context), isTrue);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('isTablet is false on a standard phone', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 390, height: 844, builder: (context) {
          expect(ServanaResponsive.isTablet(context), isFalse);
          return const SizedBox.shrink();
        }),
      );
    });
  });

  group('ServanaResponsive.horizontalPadding', () {
    testWidgets('compact phone gets 12dp', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 320, height: 568, builder: (context) {
          expect(ServanaResponsive.horizontalPadding(context), 12.0);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('standard phone gets 16dp', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 390, height: 844, builder: (context) {
          expect(ServanaResponsive.horizontalPadding(context), 16.0);
          return const SizedBox.shrink();
        }),
      );
    });

    testWidgets('large tablet gets 48dp', (tester) async {
      await tester.pumpWidget(
        _sizedApp(width: 1024, height: 768, builder: (context) {
          expect(ServanaResponsive.horizontalPadding(context), 48.0);
          return const SizedBox.shrink();
        }),
      );
    });
  });

  group('ServanaResponsive.minTouchTarget', () {
    test('is at least 44dp', () {
      expect(ServanaResponsive.minTouchTarget, greaterThanOrEqualTo(44.0));
    });
  });
}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _sizedApp({
  required double width,
  required double height,
  required Widget Function(BuildContext) builder,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: Builder(builder: builder),
    ),
  );
}
