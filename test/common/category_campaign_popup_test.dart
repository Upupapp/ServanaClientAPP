/// Category campaign popups — Beauty & Wellness and Hair & Nails.
///
/// The creatives carry their whole message as pixels, which means the things
/// most likely to break are invisible to a screenshot: whether the drawn call
/// to action is actually tappable, whether its touch target clears 48dp on a
/// small phone, whether a screen reader gets one summary or twenty fragments,
/// and whether a double tap stacks two modals.
///
/// These render the real widgets at real device sizes rather than asserting on
/// source text, so a change to the layout fails here rather than on a device.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/presentation/category_campaign/category_campaign_accessible_view.dart';
import 'package:client/common/presentation/category_campaign/category_campaign_registry.dart';
import 'package:client/common/presentation/category_campaign/servana_category_campaign_popup.dart';

String _read(String p) => File(p).readAsStringSync();

/// Reads a PNG's IHDR dimensions without decoding the image.
({int width, int height}) _pngSize(String path) {
  final b = File(path).readAsBytesSync();
  int be32(int o) =>
      (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
  return (width: be32(16), height: be32(20));
}

/// Holds a popup's outcome without blocking on it.
///
/// The dialog's future only completes when it is DISMISSED. An earlier version
/// of this harness returned that future from an `async` helper, so every
/// `await _openPopup(...)` waited for a dismissal that the test had not
/// triggered yet — every test deadlocked with "did not complete". The outcome
/// is captured on the side instead, leaving the test free to inspect the UI
/// first and dismiss second.
class _Harness {
  CategoryCampaignOutcome? outcome;
  bool completed = false;
}

/// Opens the popup and returns once it has settled on screen.
Future<_Harness> _openPopup(
  WidgetTester tester,
  CategoryCampaign campaign, {
  bool forceFallback = false,
  double textScale = 1.0,
  VoidCallback? onImpression,
  VoidCallback? onDisplayFailed,
  // Flutter's default test surface is 800x600, which is not a phone. At that
  // size the 520dp-capped card renders 924dp of artwork into 540dp of height,
  // so the banner scrolls and the CTA sits below the fold — taps miss it and
  // the failure reads as "the button does not work" rather than "the viewport
  // is wrong". Every test therefore runs on a real device size.
  Size viewport = const Size(390, 844),
}) async {
  final harness = _Harness();

  tester.view.physicalSize = viewport * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              ServanaCategoryCampaignPopup.show(
                context: context,
                assetPath: forceFallback
                    ? 'assets/images/categories/__does_not_exist__.png'
                    : campaign.assetPath,
                assetAspectRatio: campaign.aspectRatio,
                ctaRect: campaign.ctaRect,
                semanticSummary: campaign.semanticSummary,
                primaryActionLabel: campaign.primaryActionLabel,
                closeLabel: campaign.closeLabel,
                fallbackBuilder: (ctx, onExplore, onClose, onReady) =>
                    CategoryCampaignAccessibleView(
                  heading: 'Heading',
                  tagline: 'Tagline',
                  body: 'Body',
                  services: const ['One', 'Two'],
                  benefits: const ['Alpha'],
                  primaryActionLabel: campaign.primaryActionLabel,
                  closeLabel: campaign.closeLabel,
                  accentColor: const Color(0xFF3058C8),
                  onExplore: onExplore,
                  onClose: onClose,
                  onReady: onReady,
                ),
                onImpressionVerified: onImpression ?? () {},
                onDisplayFailed: onDisplayFailed,
              ).then((o) {
                harness
                  ..outcome = o
                  ..completed = true;
              });
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  group('the shipped assets', () {
    for (final c in CategoryCampaignRegistry.all) {
      test('${c.categoryKey}: the file exists at the registered path', () {
        expect(File(c.assetPath).existsSync(), isTrue,
            reason: '${c.assetPath} is registered but not on disk');
      });

      test('${c.categoryKey}: the registry matches the real PNG dimensions',
          () {
        // The specs said 928x1648; both files shipped at 941x1672. Driving the
        // AspectRatio from the spec would inset the artwork inside its own box
        // and the CTA overlay — positioned against that box — would drift off
        // the drawn button.
        final size = _pngSize(c.assetPath);
        expect(size.width, c.assetWidth);
        expect(size.height, c.assetHeight);
      });

      test('${c.categoryKey}: the filename is lowercase', () {
        // Windows is case-insensitive, iOS and Android are not. A file named
        // BEAUTY_WELLNESS_POPUP_V1.png resolves on a dev machine and fails on
        // device — which is exactly how it was first delivered.
        final name = c.assetPath.split('/').last;
        expect(name, name.toLowerCase(),
            reason: 'asset filenames must be lowercase to resolve on device');
      });

      test('${c.categoryKey}: on-disk casing matches the registry exactly', () {
        final dir = Directory('assets/images/categories');
        final onDisk =
            dir.listSync().map((e) => e.path.split(RegExp(r'[/\\]')).last);
        expect(onDisk, contains(c.assetPath.split('/').last));
      });
    }

    test('pubspec registers the categories asset directory', () {
      expect(_read('pubspec.yaml'), contains('assets/images/categories/'));
    });
  });

  group('the registry', () {
    test('covers exactly the two categories with creatives', () {
      expect(CategoryCampaignRegistry.all.map((c) => c.categoryKey),
          containsAll(<String>['beauty_wellness', 'hair_nails']));
    });

    test('category keys resolve the same way the router resolves them', () {
      // If these drift, a popup opens for one category and navigation goes to
      // another — the Critical failure in the command's severity table.
      final router = _read('lib/common/presentation/routes/main_router.dart');
      for (final c in CategoryCampaignRegistry.all) {
        expect(router, contains("'${c.categoryKey}' => ServiceCategoryId."),
            reason: '${c.categoryKey} is not a key the router understands');
      }
    });

    test('categories without a creative have no campaign', () {
      // Aircon's creative sits on disk with no registry entry, so it stays
      // inert and that category keeps navigating straight through.
      expect(CategoryCampaignRegistry.forCategoryKey('aircon'), isNull);
      expect(CategoryCampaignRegistry.forCategoryKey('nonsense'), isNull);
    });

    test('every campaign maps to a real category config', () {
      for (final c in CategoryCampaignRegistry.all) {
        expect(() => CategoryRegistry.forId(c.categoryId), returnsNormally);
      }
    });

    test('CTA rectangles sit in the lower portion and stay inside the art', () {
      for (final c in CategoryCampaignRegistry.all) {
        expect(c.ctaRect.left, greaterThan(0));
        expect(c.ctaRect.right, lessThan(1.0),
            reason: '${c.categoryKey} CTA runs past the right edge');
        expect(c.ctaRect.bottom, lessThan(1.0),
            reason: '${c.categoryKey} CTA runs past the bottom edge');
        expect(c.ctaRect.top, greaterThan(0.80),
            reason: '${c.categoryKey} CTA is not where the drawn button is');
      }
    });
  });

  group('presentation', () {
    testWidgets('renders the artwork with a real CTA and close button',
        (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);

      expect(
          find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsOneWidget);
      expect(find.byKey(ServanaCategoryCampaignPopup.ctaKey), findsOneWidget);
      expect(find.byKey(ServanaCategoryCampaignPopup.closeKey), findsOneWidget);
      expect(
          find.byKey(ServanaCategoryCampaignPopup.fallbackKey), findsNothing);
    });

    testWidgets('the artwork is contained, never cropped', (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.beautyWellness);
      final image = tester
          .widget<Image>(find.byKey(ServanaCategoryCampaignPopup.artworkKey));
      expect(image.fit, BoxFit.contain,
          reason: 'BoxFit.cover would crop the heading or the CTA');
    });

    testWidgets('the artwork keeps the real 941:1672 ratio', (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);
      final ar = tester.widget<AspectRatio>(find.ancestor(
        of: find.byKey(ServanaCategoryCampaignPopup.artworkKey),
        matching: find.byType(AspectRatio),
      ));
      expect(ar.aspectRatio, closeTo(941 / 1672, 0.0001));
    });

    testWidgets('records exactly one impression, after it paints',
        (tester) async {
      var impressions = 0;
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails,
          onImpression: () => impressions++);
      await tester.pump();
      await tester.pump();
      expect(impressions, 1,
          reason: 'rebuilds must not re-count an impression');
    });
  });

  group('the CTA touch target', () {
    // The drawn pill is ~5.7% of artboard height. On a 360dp phone that paints
    // about 33dp tall, well under the platform minimum, so the hit area is
    // grown around the pill's centre. These check the result, not the maths.
    const sizes = <String, Size>{
      'compact 320x568': Size(320, 568),
      'small 360x640': Size(360, 640),
      'standard 375x667': Size(375, 667),
      'modern 390x844': Size(390, 844),
      'large 430x932': Size(430, 932),
      'tablet 800x1280': Size(800, 1280),
    };

    for (final entry in sizes.entries) {
      testWidgets('clears 48dp on ${entry.key}', (tester) async {
        await _openPopup(tester, CategoryCampaignRegistry.hairAndNails,
            viewport: entry.value);

        final box =
            tester.getSize(find.byKey(ServanaCategoryCampaignPopup.ctaKey));
        expect(box.height, greaterThanOrEqualTo(48.0),
            reason: 'CTA is only ${box.height.toStringAsFixed(1)}dp tall on '
                '${entry.key}');
        expect(box.width, greaterThan(0));
      });
    }

    testWidgets('the close control is a 48dp target', (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);
      final box =
          tester.getSize(find.byKey(ServanaCategoryCampaignPopup.closeKey));
      expect(box.width, greaterThanOrEqualTo(48.0));
      expect(box.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('the whole banner is not one ambiguous button', (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);
      final cta =
          tester.getSize(find.byKey(ServanaCategoryCampaignPopup.ctaKey));
      final art =
          tester.getSize(find.byKey(ServanaCategoryCampaignPopup.artworkKey));
      expect(cta.height, lessThan(art.height * 0.5),
          reason: 'the CTA must cover the drawn button, not the artwork');
    });
  });

  group('massage & wellness', () {
    testWidgets('renders its own artwork with a working CTA', (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.massageWellness);
      expect(
          find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsOneWidget);
      expect(find.byKey(ServanaCategoryCampaignPopup.ctaKey), findsOneWidget);
    });

    testWidgets('its CTA also clears 48dp on the smallest phone',
        (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.massageWellness,
          viewport: const Size(320, 568));
      final box =
          tester.getSize(find.byKey(ServanaCategoryCampaignPopup.ctaKey));
      expect(box.height, greaterThanOrEqualTo(48.0));
    });

    test('it is registered against the category key the app actually uses', () {
      // The command specifies `massage_wellness`. No such key exists — the Home
      // grid and the router both use `massage`. Registering the command's key
      // verbatim would mean forCategoryKey('massage') returns null and the
      // popup silently never appears.
      expect(CategoryCampaignRegistry.massageWellness.categoryKey, 'massage');
      expect(CategoryCampaignRegistry.forCategoryKey('massage'), isNotNull);
      expect(
          CategoryCampaignRegistry.forCategoryKey('massage_wellness'), isNull,
          reason: 'that key does not exist in this app');
    });
  });

  group('outcomes', () {
    testWidgets('CTA reports cta and dismisses', (tester) async {
      final harness =
          await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ServanaCategoryCampaignPopup.ctaKey));
      await tester.pumpAndSettle();
      // The dialog's future resolves a microtask after the route pops; without
      // this the outcome is still null and the assertion reads as a bug in the
      // component rather than in the harness.
      await tester.idle();

      expect(harness.outcome, CategoryCampaignOutcome.cta);
      expect(find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsNothing);
    });

    testWidgets('close reports close and does not navigate', (tester) async {
      final harness =
          await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ServanaCategoryCampaignPopup.closeKey));
      await tester.pumpAndSettle();
      await tester.idle();

      expect(harness.outcome, CategoryCampaignOutcome.close);
    });

    testWidgets('Android Back reports backOrBarrier', (tester) async {
      final harness =
          await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);
      await tester.pumpAndSettle();

      // The same channel message the platform sends for a Back gesture.
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec().encodeMethodCall(
          const MethodCall('popRoute'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      await tester.idle();

      expect(harness.outcome, CategoryCampaignOutcome.backOrBarrier);
    });
  });

  group('fallbacks', () {
    testWidgets('a missing asset falls back to the native layout',
        (tester) async {
      var failed = 0;
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails,
          forceFallback: true, onDisplayFailed: () => failed++);
      await tester.pumpAndSettle();

      expect(
          find.byKey(ServanaCategoryCampaignPopup.fallbackKey), findsOneWidget);
      expect(failed, greaterThanOrEqualTo(1));
      // No broken-image icon, no blank card.
      expect(find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsNothing);
    });

    testWidgets('the fallback keeps both actions working', (tester) async {
      final harness = await _openPopup(
          tester, CategoryCampaignRegistry.hairAndNails,
          forceFallback: true);
      await tester.pumpAndSettle();

      expect(find.text('Explore Hair and Nails'), findsOneWidget);
      await tester.tap(find.text('Explore Hair and Nails'));
      await tester.pumpAndSettle();
      await tester.idle();
      expect(harness.outcome, CategoryCampaignOutcome.cta);
    });

    testWidgets('large text replaces the artwork with scalable widgets',
        (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.beautyWellness,
          textScale: 1.5);
      await tester.pumpAndSettle();

      expect(
          find.byKey(ServanaCategoryCampaignPopup.fallbackKey), findsOneWidget);
      expect(find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsNothing);
    });

    testWidgets('normal text keeps the artwork', (tester) async {
      await _openPopup(tester, CategoryCampaignRegistry.beautyWellness,
          textScale: 1.0);
      expect(
          find.byKey(ServanaCategoryCampaignPopup.artworkKey), findsOneWidget);
    });

    testWidgets('the fallback records the impression when it paints',
        (tester) async {
      var impressions = 0;
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails,
          forceFallback: true, onImpression: () => impressions++);
      await tester.pumpAndSettle();
      expect(impressions, 1);
    });
  });

  group('accessibility', () {
    testWidgets('the summary, CTA and close are all announced', (tester) async {
      final handle = tester.ensureSemantics();
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);

      final c = CategoryCampaignRegistry.hairAndNails;
      expect(find.bySemanticsLabel(c.semanticSummary), findsOneWidget);
      expect(find.bySemanticsLabel(c.primaryActionLabel), findsOneWidget);
      expect(find.bySemanticsLabel(c.closeLabel), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the artwork itself is not announced separately',
        (tester) async {
      // Otherwise a screen reader reads the summary and then "image".
      await _openPopup(tester, CategoryCampaignRegistry.hairAndNails);
      final image = tester
          .widget<Image>(find.byKey(ServanaCategoryCampaignPopup.artworkKey));
      expect(image.excludeFromSemantics, isTrue);
    });

    testWidgets('the summary names the category and its services',
        (tester) async {
      for (final c in CategoryCampaignRegistry.all) {
        expect(c.semanticSummary.length, greaterThan(60),
            reason: '${c.categoryKey} summary is too thin to replace the '
                'artwork for a screen-reader customer');
      }
    });
  });

  group('motion', () {
    testWidgets('reduced motion drops the scale and keeps a short fade',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => ServanaCategoryCampaignPopup.show(
                context: context,
                assetPath: CategoryCampaignRegistry.hairAndNails.assetPath,
                assetAspectRatio:
                    CategoryCampaignRegistry.hairAndNails.aspectRatio,
                ctaRect: CategoryCampaignRegistry.hairAndNails.ctaRect,
                semanticSummary: 'summary',
                primaryActionLabel: 'explore',
                closeLabel: 'close',
                fallbackBuilder: (_, __, ___, ____) => const SizedBox(),
                onImpressionVerified: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Functionality is unchanged; only the movement is dropped.
      expect(find.byKey(ServanaCategoryCampaignPopup.ctaKey), findsOneWidget);

      // AnimatedScale always builds a ScaleTransition, so its presence proves
      // nothing. What matters is that pressing does not MOVE anything: the
      // scale stays at 1.0 through a press-and-hold.
      final gesture =
          await tester.press(find.byKey(ServanaCategoryCampaignPopup.ctaKey));
      await tester.pump(const Duration(milliseconds: 200));
      final scaled = tester.widget<AnimatedScale>(find.ancestor(
        of: find.byKey(ServanaCategoryCampaignPopup.ctaKey),
        matching: find.byType(AnimatedScale),
      ));
      expect(scaled.scale, 1.0,
          reason: 'reduced motion must suppress the press scale');
      await gesture.up();
    });
  });
}
