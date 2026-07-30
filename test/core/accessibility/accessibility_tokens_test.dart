import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/accessibility/accessibility_tokens.dart';

// Helper: pump a widget inside MediaQuery with custom data
Future<void> pumpWithMedia(
  WidgetTester tester,
  MediaQueryData data,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(data: data, child: Scaffold(body: child)),
    ),
  );
}

void main() {
  group('AccessibilityTokens', () {
    group('constants', () {
      test('minTouchTarget is 44', () {
        expect(AccessibilityTokens.minTouchTarget, equals(44.0));
      });

      test('maxRequiredTextScale is 2.0', () {
        expect(AccessibilityTokens.maxRequiredTextScale, equals(2.0));
      });

      test('largeTextThreshold is 1.3', () {
        expect(AccessibilityTokens.largeTextThreshold, equals(1.3));
      });
    });

    group('reducedMotion', () {
      testWidgets('returns true when disableAnimations is true', (tester) async {
        late bool result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(disableAnimations: true),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.reducedMotion(ctx);
            return const SizedBox();
          }),
        );
        expect(result, isTrue);
      });

      testWidgets('returns false when disableAnimations is false', (tester) async {
        late bool result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(disableAnimations: false),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.reducedMotion(ctx);
            return const SizedBox();
          }),
        );
        expect(result, isFalse);
      });
    });

    group('boldText', () {
      testWidgets('returns true when boldText is true', (tester) async {
        late bool result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(boldText: true),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.boldText(ctx);
            return const SizedBox();
          }),
        );
        expect(result, isTrue);
      });
    });

    group('screenReaderActive', () {
      testWidgets('returns true when accessibleNavigation is true', (tester) async {
        late bool result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(accessibleNavigation: true),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.screenReaderActive(ctx);
            return const SizedBox();
          }),
        );
        expect(result, isTrue);
      });

      testWidgets('returns false when accessibleNavigation is false', (tester) async {
        late bool result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(accessibleNavigation: false),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.screenReaderActive(ctx);
            return const SizedBox();
          }),
        );
        expect(result, isFalse);
      });
    });

    group('isLargeText', () {
      testWidgets('returns true at 1.3 scale', (tester) async {
        late bool result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.isLargeText(ctx);
            return const SizedBox();
          }),
        );
        expect(result, isTrue);
      });

      testWidgets('returns true at 2.0 scale', (tester) async {
        late bool result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.isLargeText(ctx);
            return const SizedBox();
          }),
        );
        expect(result, isTrue);
      });

      testWidgets('returns false at 1.0 scale', (tester) async {
        late bool result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(textScaler: TextScaler.linear(1.0)),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.isLargeText(ctx);
            return const SizedBox();
          }),
        );
        expect(result, isFalse);
      });
    });

    group('safeTouchTarget', () {
      testWidgets('always returns minTouchTarget', (tester) async {
        late double result;
        await pumpWithMedia(
          tester,
          const MediaQueryData(),
          Builder(builder: (ctx) {
            result = AccessibilityTokens.safeTouchTarget(ctx);
            return const SizedBox();
          }),
        );
        expect(result, equals(AccessibilityTokens.minTouchTarget));
      });
    });
  });
}
