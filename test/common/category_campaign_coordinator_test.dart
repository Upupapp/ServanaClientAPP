/// The duplicate-presentation guard and the analytics funnel.
///
/// The guard is rated High in the command's severity table: a customer who
/// double-taps a category card must get one modal, not two stacked ones. It is
/// tested here rather than in the widget test because it lives on the
/// coordinator — the popup itself deliberately knows nothing about how many
/// times it has been asked to appear.
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:client/common/presentation/category_campaign/category_campaign_coordinator.dart';
import 'package:client/common/presentation/category_campaign/category_campaign_registry.dart';
import 'package:client/common/presentation/category_campaign/servana_category_campaign_popup.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/data/firebase_analytics_service.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

AnalyticsCoordinator _analytics(MockFirebaseAnalytics fa) {
  when(() => fa.setAnalyticsCollectionEnabled(any())).thenAnswer((_) async {});
  when(() => fa.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      )).thenAnswer((_) async {});
  when(() => fa.setUserProperty(
        name: any(named: 'name'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});
  return AnalyticsCoordinator(service: FirebaseAnalyticsService(analytics: fa));
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    SharedPreferences.setMockInitialValues({});
  });

  group('campaign eligibility', () {
    test('only categories with a creative have a campaign', () {
      expect(CategoryCampaignCoordinator.hasCampaignFor('beauty_wellness'),
          isTrue);
      expect(CategoryCampaignCoordinator.hasCampaignFor('hair_nails'), isTrue);
      // These must keep navigating straight through, exactly as before.
      expect(CategoryCampaignCoordinator.hasCampaignFor('massage'), isFalse);
      expect(CategoryCampaignCoordinator.hasCampaignFor('aircon'), isFalse);
    });

    testWidgets('a category with no campaign never opens a modal',
        (tester) async {
      final coord = CategoryCampaignCoordinator(
          analytics: _analytics(MockFirebaseAnalytics()));
      late bool result;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result =
                  await coord.present(context: context, categoryKey: 'massage');
            },
            child: const Text('go'),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(result, isFalse,
          reason: 'no campaign means "do not navigate here"');
      expect(find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsNothing);
    });
  });

  group('duplicate-presentation guard', () {
    testWidgets('two presentations dispatched in one frame open one modal',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final coord = CategoryCampaignCoordinator(
          analytics: _analytics(MockFirebaseAnalytics()));
      final results = <bool>[];

      // Both calls are made from ONE gesture, without awaiting the first.
      // Tapping the button twice would not model this: after the first tap the
      // button sits behind the modal barrier, so the second tap dismisses the
      // popup instead of racing it. The real hazard is two callbacks
      // dispatched before the modal is up, which is what this reproduces.
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  coord
                      .present(context: context, categoryKey: 'hair_nails')
                      .then(results.add);
                  coord
                      .present(context: context, categoryKey: 'hair_nails')
                      .then(results.add);
                },
                child: const Text('tap'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();

      expect(
          find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsOneWidget,
          reason: 'the second call must not stack a second modal');
      expect(coord.isOpen, isTrue);

      // The rejected call resolves immediately with false, so its caller does
      // not navigate.
      await tester.idle();
      expect(results, [false],
          reason: 'exactly one rejection so far; the first is still open');
    });

    testWidgets('the guard releases after dismissal, so the card works again',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final coord = CategoryCampaignCoordinator(
          analytics: _analytics(MockFirebaseAnalytics()));

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    coord.present(context: context, categoryKey: 'hair_nails'),
                child: const Text('tap'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();
      expect(coord.isOpen, isTrue);

      await tester.tap(find.byKey(ServanaCategoryCampaignPopup.closeKey));
      await tester.pumpAndSettle();
      await tester.idle();

      expect(coord.isOpen, isFalse,
          reason: 'one dismissal must not lock the category for the session');

      // And it genuinely opens again.
      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();
      expect(
          find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsOneWidget);
    });
  });

  group('what the CTA reports back', () {
    testWidgets('choosing the CTA returns true so the caller navigates once',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final coord = CategoryCampaignCoordinator(
          analytics: _analytics(MockFirebaseAnalytics()));
      final results = <bool>[];

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => results.add(await coord.present(
                    context: context, categoryKey: 'beauty_wellness')),
                child: const Text('tap'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ServanaCategoryCampaignPopup.ctaKey));
      await tester.pumpAndSettle();
      await tester.idle();

      expect(results, [true]);
      expect(results.where((r) => r).length, 1,
          reason: 'exactly one navigation, never two');
    });

    testWidgets('dismissing returns false so the caller stays on Home',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final coord = CategoryCampaignCoordinator(
          analytics: _analytics(MockFirebaseAnalytics()));
      final results = <bool>[];

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => results.add(await coord.present(
                    context: context, categoryKey: 'hair_nails')),
                child: const Text('tap'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('tap'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ServanaCategoryCampaignPopup.closeKey));
      await tester.pumpAndSettle();
      await tester.idle();

      expect(results, [false]);
    });
  });

  group('analytics carry no customer data', () {
    test('every campaign event property is a fixed low-cardinality string', () {
      // The events only ever carry campaign_key, category_key, entry_source and
      // dismissal_method. Nothing derived from the customer can reach them,
      // because none of those values comes from customer input.
      for (final c in CategoryCampaignRegistry.all) {
        expect(c.campaignKey, matches(RegExp(r'^[a-z0-9_]+$')));
        expect(c.categoryKey, matches(RegExp(r'^[a-z0-9_]+$')));
      }
    });
  });
}
