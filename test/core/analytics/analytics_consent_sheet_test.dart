import 'package:client/core/analytics/presentation/analytics_consent_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  group('AnalyticsConsentSheet', () {
    testWidgets('"Accept & Continue" pops true', (tester) async {
      bool? result;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return TextButton(
          onPressed: () async {
            result = await showAnalyticsConsentSheet(ctx);
          },
          child: const Text('Open'),
        );
      })));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Accept & Continue'), findsOneWidget);
      expect(find.text('Essential Only'), findsOneWidget);

      await tester.tap(find.text('Accept & Continue'));
      await tester.pumpAndSettle();

      expect(result, isTrue,
          reason: '"Accept & Continue" must return true (fullConsent path)');
    });

    testWidgets('"Essential Only" pops false', (tester) async {
      bool? result;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return TextButton(
          onPressed: () async {
            result = await showAnalyticsConsentSheet(ctx);
          },
          child: const Text('Open'),
        );
      })));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Essential Only'));
      await tester.pumpAndSettle();

      expect(result, isFalse,
          reason: '"Essential Only" must return false (defaultConsent path)');
    });

    testWidgets('sheet is non-dismissible via back-gesture', (tester) async {
      bool? result;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return TextButton(
          onPressed: () async {
            result = await showAnalyticsConsentSheet(ctx);
          },
          child: const Text('Open'),
        );
      })));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Simulate Android back button via NavigatorState.maybePop.
      final NavigatorState navigator = tester.state(find.byType(Navigator).first);
      await navigator.maybePop();
      await tester.pumpAndSettle();

      // Sheet should still be visible — back-gesture must not close it.
      expect(find.text('Accept & Continue'), findsOneWidget,
          reason: 'isDismissible:false — sheet must remain after back-gesture');
      expect(result, isNull,
          reason: 'No result until user makes an explicit choice');
    });

    testWidgets('sheet renders all three consent points', (tester) async {
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return TextButton(
          onPressed: () => showAnalyticsConsentSheet(ctx),
          child: const Text('Open'),
        );
      })));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Usage analytics'), findsOneWidget);
      expect(find.text('Crash reporting'), findsOneWidget);
      expect(find.text('Performance monitoring'), findsOneWidget);
    });
  });
}
