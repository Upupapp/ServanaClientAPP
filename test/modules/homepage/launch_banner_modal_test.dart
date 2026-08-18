/// LAUNCHBANNER+ §39 — modal behaviour, accessibility and failure paths.
///
/// The campaign asset IS available to the test bundle, because it is declared
/// in pubspec.yaml. So the artwork path is what renders by default, and the
/// §29 fallback has to be provoked deliberately with a missing asset — an
/// earlier draft of this file assumed the opposite and every fallback
/// assertion silently tested the wrong path.
///
/// Three presentations are therefore exercised separately:
///   * artwork          — real asset, normal text scale
///   * accessible (a11y)— real asset, text scale >= 1.3 (§33)
///   * fallback         — missing asset, forcing the §29 error path
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/modules/homepage/presentation/widgets/servana_launch_benefits_accessible_view.dart';
import 'package:client/modules/homepage/presentation/widgets/servana_launch_benefits_modal.dart';

const _realAsset = 'assets/images/campaigns/servana_launch_benefits_v1.webp';
const _missingAsset = 'assets/images/campaigns/__does_not_exist__.webp';
const _aspect = 941 / 1672;

/// Opens the modal and records its completion value.
class _Host extends StatelessWidget {
  const _Host({
    required this.onResult,
    this.assetPath = _realAsset,
    this.textScale = 1.0,
    this.reduceMotion = false,
    this.onImpression,
    this.onDisplayFailed,
  });

  final void Function(LaunchBannerOutcome?) onResult;
  final String assetPath;
  final double textScale;
  final bool reduceMotion;
  final VoidCallback? onImpression;
  final VoidCallback? onDisplayFailed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: Builder(
        builder: (inner) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final r = await ServanaLaunchBenefitsModal.show(
                  context: inner,
                  assetPath: assetPath,
                  assetAspectRatio: _aspect,
                  onImpressionVerified: onImpression ?? () {},
                  onDisplayFailed: onDisplayFailed,
                );
                onResult(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pumps the host at a phone-shaped surface.
///
/// The default test surface is 800x600 — wider than it is tall, which no phone
/// is. At that shape the card is taller than the viewport and the CTA sits
/// below the fold, reachable only by scrolling. That is correct behaviour
/// (§32's scrollable fallback) but it is not the geometry most customers see,
/// so tests that assert on the CTA set a realistic surface first.
Future<void> _open(
  WidgetTester tester,
  Widget host, {
  Size surface = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(host);

  // Decode the artwork before opening, exactly as Home does (§31 precache).
  //
  // Without this the impression assertion races the decode. The impression
  // fires from Image.asset's frameBuilder once a frame exists, and
  // pumpAndSettle does NOT wait on real image I/O — so on a slower machine the
  // assertion runs first and sees zero. That passed on a fast local machine
  // and failed in CI, which is the worst way for a test to be wrong.
  //
  // runAsync is required: real async work is disallowed inside the fake-async
  // zone a widget test normally runs in.
  //
  // Skipped for the fallback tests: they point at an asset that deliberately
  // does not exist, and precaching it would report a Flutter error the test
  // binding treats as a failure — drowning the condition actually under test.
  if (_hostAsset(host) == _realAsset) {
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(_realAsset),
        tester.element(find.text('open')),
      );
    });
    await tester.pump();
  }

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The asset the host was configured with, so precache targets the right one.
String _hostAsset(Widget host) => host is _Host ? host.assetPath : _realAsset;

void main() {
  group('artwork presentation (real asset, normal text)', () {
    testWidgets('renders the creative, not the native text layout',
        (tester) async {
      await _open(tester, _Host(onResult: (_) {}));
      expect(find.byType(Image), findsWidgets);
      // The headline lives in the artwork, so there is no Text for it here.
      expect(find.text('Everything you need, all in one app'), findsNothing);
    });

    testWidgets('§13 the CTA is a real, labelled button over the artwork',
        (tester) async {
      await _open(tester, _Host(onResult: (_) {}));
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Explore Servana services'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('§13 the hotspot is not the whole image', (tester) async {
      await _open(tester, _Host(onResult: (_) {}));
      final image = tester.getSize(find.byType(Image).first);
      final hotspot = tester.getSize(
        find
            .descendant(
              of: find.byType(Stack),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      expect(hotspot.width, lessThan(image.width),
          reason: 'a full-bleed tap target would be ambiguous');
    });

    testWidgets('tapping the CTA returns cta', (tester) async {
      LaunchBannerOutcome? captured;
      await _open(tester, _Host(onResult: (o) => captured = o));
      // Addressed by key, not by semantics label: the label is the customer's
      // contract, but a Semantics node's BOX can be larger than the control it
      // annotates, so tapping its centre is not guaranteed to hit the gesture
      // detector. The label is asserted separately, above.
      await tester.tap(find.byKey(ServanaLaunchBenefitsModal.ctaKey));
      await tester.pumpAndSettle();
      expect(captured, LaunchBannerOutcome.cta);
    });

    testWidgets('one verified impression is recorded', (tester) async {
      var impressions = 0;
      await _open(
          tester, _Host(onResult: (_) {}, onImpression: () => impressions++));
      expect(impressions, 1);
    });
  });

  group('§32 the CTA is actually on screen, not below the fold', () {
    // Regression. The card was briefly wrapped in a SingleChildScrollView, so
    // the 941x1672 creative overflowed an ordinary phone viewport and the
    // "Explore Services" pill rendered 60pt BELOW the visible area. Everything
    // looked correct in a screenshot of the top of the modal, and the primary
    // action was unreachable without scrolling a picture.
    for (final surface in const [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
    ]) {
      testWidgets(
          'CTA is within the viewport at ${surface.width.toInt()}x'
          '${surface.height.toInt()}', (tester) async {
        await _open(tester, _Host(onResult: (_) {}), surface: surface);
        final cta =
            tester.getRect(find.byKey(ServanaLaunchBenefitsModal.ctaKey));
        expect(cta.bottom, lessThanOrEqualTo(surface.height),
            reason: 'CTA bottom ${cta.bottom} exceeds the ${surface.height}pt '
                'viewport — it would need scrolling to reach');
        expect(cta.top, greaterThanOrEqualTo(0));
        expect(cta.height, greaterThanOrEqualTo(56),
            reason: '§13 requires at least a 56pt effective target height');
      });
    }

    testWidgets('the close control is reachable at the smallest size',
        (tester) async {
      await _open(tester, _Host(onResult: (_) {}),
          surface: const Size(320, 568));
      final close =
          tester.getRect(find.byKey(ServanaLaunchBenefitsModal.closeKey));
      expect(close.bottom, lessThanOrEqualTo(568));
      expect(close.right, lessThanOrEqualTo(320));
      expect(close.width, greaterThanOrEqualTo(48));
      expect(close.height, greaterThanOrEqualTo(48));
    });
  });

  group('§29 fallback when the artwork cannot load', () {
    testWidgets('the native layout renders instead of a blank modal',
        (tester) async {
      await _open(tester, _Host(onResult: (_) {}, assetPath: _missingAsset));
      expect(find.text('Everything you need, all in one app'), findsOneWidget);
      expect(find.text('Explore Services'), findsOneWidget);
      expect(find.text('Remind me later'), findsOneWidget);
    });

    testWidgets('all three benefits appear as structured content',
        (tester) async {
      await _open(tester, _Host(onResult: (_) {}, assetPath: _missingAsset));
      for (final (_, title, _)
          in ServanaLaunchBenefitsAccessibleView.benefits) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });

    testWidgets('the failure is reported', (tester) async {
      var failures = 0;
      await _open(
        tester,
        _Host(
          onResult: (_) {},
          assetPath: _missingAsset,
          onDisplayFailed: () => failures++,
        ),
      );
      expect(failures, greaterThan(0));
    });

    testWidgets('§28 the fallback still counts exactly one impression',
        (tester) async {
      // It DID display — just not as artwork. What must not happen is two
      // impressions (image attempt + fallback) or zero.
      var impressions = 0;
      await _open(
        tester,
        _Host(
          onResult: (_) {},
          assetPath: _missingAsset,
          onImpression: () => impressions++,
        ),
      );
      expect(impressions, 1);
    });
  });

  group('§33 accessible layout at large text', () {
    testWidgets('text scale 2.0 switches to the native layout', (tester) async {
      await _open(tester, _Host(onResult: (_) {}, textScale: 2.0));
      expect(find.text('Everything you need, all in one app'), findsOneWidget,
          reason: 'rasterised text cannot scale, so the artwork is replaced');
    });

    testWidgets('every action stays reachable at 200%', (tester) async {
      await _open(tester, _Host(onResult: (_) {}, textScale: 2.0));
      expect(tester.takeException(), isNull);
      expect(find.text('Explore Services'), findsOneWidget);
      expect(find.text('Remind me later'), findsOneWidget,
          reason: '§33 forbids hiding the secondary action at large text');
    });

    testWidgets('text scale 1.0 keeps the artwork', (tester) async {
      await _open(tester, _Host(onResult: (_) {}, textScale: 1.0));
      expect(find.text('Everything you need, all in one app'), findsNothing);
    });
  });

  group('§6 outcomes are distinguishable', () {
    testWidgets('Remind me later returns remindLater', (tester) async {
      LaunchBannerOutcome? captured;
      await _open(tester, _Host(onResult: (o) => captured = o));
      await tester.tap(find.text('Remind me later'));
      await tester.pumpAndSettle();
      expect(captured, LaunchBannerOutcome.remindLater);
    });

    testWidgets('Close returns close, distinct from remindLater',
        (tester) async {
      LaunchBannerOutcome? captured;
      await _open(tester, _Host(onResult: (o) => captured = o));
      await tester.tap(find.byKey(ServanaLaunchBenefitsModal.closeKey));
      await tester.pumpAndSettle();
      expect(captured, LaunchBannerOutcome.close);
      expect(captured, isNot(LaunchBannerOutcome.remindLater),
          reason: 'Close is a rejection; remind-later is a deferral');
    });
  });

  group('§34 accessibility', () {
    testWidgets('every control is an announced button', (tester) async {
      await _open(tester, _Host(onResult: (_) {}));
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Explore Servana services'), findsOneWidget);
      expect(find.bySemanticsLabel('Remind me later'), findsOneWidget);
      expect(find.bySemanticsLabel('Close launch banner'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('benefit rows are single nodes, not three fragments each',
        (tester) async {
      await _open(tester, _Host(onResult: (_) {}, assetPath: _missingAsset));
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(
            RegExp('Wide service selection.*all in one place')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('remind-later target is at least 48 high', (tester) async {
      await _open(tester, _Host(onResult: (_) {}));
      final size =
          tester.getSize(find.widgetWithText(TextButton, 'Remind me later'));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('§32 responsive', () {
    for (final size in const [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
      Size(800, 1280),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _open(tester, _Host(onResult: (_) {}), surface: size);
        expect(tester.takeException(), isNull);
        expect(find.text('Remind me later'), findsOneWidget);
      });
    }
  });

  group('§19 reduced motion', () {
    testWidgets('still presents and remains fully operable', (tester) async {
      LaunchBannerOutcome? captured;
      await _open(
          tester, _Host(onResult: (o) => captured = o, reduceMotion: true));
      await tester.tap(find.text('Remind me later'));
      await tester.pumpAndSettle();
      expect(captured, LaunchBannerOutcome.remindLater);
    });
  });

  group('§13 CTA hotspot geometry', () {
    test('the measured artboard fractions bound the drawn pill', () {
      // Measured from the 941x1672 source: x 194..769, y 1467..1580.
      expect(ServanaLaunchBenefitsModal.ctaLeftFraction,
          closeTo(194 / 941, 0.002));
      expect(ServanaLaunchBenefitsModal.ctaRightFraction,
          closeTo(770 / 941, 0.002));
      expect(ServanaLaunchBenefitsModal.ctaTopFraction,
          closeTo(1467 / 1672, 0.002));
      expect(ServanaLaunchBenefitsModal.ctaBottomFraction,
          closeTo(1581 / 1672, 0.002));
    });

    test('the hotspot sits inside the artboard and is not full-width', () {
      expect(ServanaLaunchBenefitsModal.ctaLeftFraction, greaterThan(0.0));
      expect(ServanaLaunchBenefitsModal.ctaRightFraction, lessThan(1.0));
      const width = ServanaLaunchBenefitsModal.ctaRightFraction -
          ServanaLaunchBenefitsModal.ctaLeftFraction;
      expect(width, lessThan(0.75));
      expect(width, greaterThan(0.4));
    });
  });
}
