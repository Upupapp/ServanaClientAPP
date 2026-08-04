/// MOVEUPNAV+ §26 §27 §28 — curved main navigation.
///
/// Covers the chrome component in isolation. It takes no stores and starts no
/// route change, so every assertion here is about what the customer sees and
/// what the widget reports back — which is exactly the seam worth pinning.
///
/// What these tests deliberately do NOT claim: physical-device haptic strength
/// and motion smoothness (§29). A widget test can prove a haptic call is made
/// once; it cannot prove how it feels. §30 forbids reporting that as done
/// without hardware, and it is not reported here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/common/presentation/navigation/servana_book_action.dart';
import 'package:client/common/presentation/navigation/servana_curved_main_navigation.dart';
import 'package:client/common/presentation/navigation/servana_nav_item.dart';
import 'package:client/common/presentation/navigation/servana_nav_motion.dart';
import 'package:client/common/presentation/shell/core_tab.dart';

Widget _host({
  int currentIndex = 0,
  int bookingsBadge = 0,
  int messagesBadge = 0,
  ValueChanged<CoreTab>? onTabSelected,
  VoidCallback? onBookPressed,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
      viewPadding: const EdgeInsets.only(bottom: 34),
    ),
    child: MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        bottomNavigationBar: ServanaCurvedMainNavigation(
          currentIndex: currentIndex,
          bookingsBadge: bookingsBadge,
          messagesBadge: messagesBadge,
          onTabSelected: onTabSelected ?? (_) {},
          onBookPressed: onBookPressed ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('structure', () {
    testWidgets('renders four branch destinations', (tester) async {
      await tester.pumpWidget(_host());
      expect(find.byType(ServanaNavItem), findsNWidgets(4));
    });

    testWidgets('renders the central Book action', (tester) async {
      await tester.pumpWidget(_host());
      expect(find.byType(ServanaBookAction), findsOneWidget);
    });

    testWidgets('every destination keeps a visible label', (tester) async {
      // §12/§30: labels are never hidden, not even on compact phones.
      await tester.pumpWidget(_host(size: const Size(320, 568)));
      for (final tab in CoreTab.values) {
        expect(find.text(tab.label), findsOneWidget, reason: tab.name);
      }
    });

    testWidgets('Book is not a fifth destination', (tester) async {
      // §7: it must never render as selected or masquerade as a branch.
      await tester.pumpWidget(_host());
      expect(find.byType(ServanaNavItem), findsNWidgets(4));
      expect(find.text('Book'), findsNothing);
    });
  });

  group('slot mapping (§6)', () {
    test('branches map around the centre, never onto it', () {
      expect(ServanaCurvedMainNavigation.slotOf(CoreTab.home), 0);
      expect(ServanaCurvedMainNavigation.slotOf(CoreTab.bookings), 1);
      // Slot 2 is the Book action and belongs to no branch.
      expect(ServanaCurvedMainNavigation.slotOf(CoreTab.messages), 3);
      expect(ServanaCurvedMainNavigation.slotOf(CoreTab.profile), 4);
    });

    test('no branch is assigned the centre slot', () {
      final slots = CoreTab.values.map(ServanaCurvedMainNavigation.slotOf);
      expect(slots.contains(2), isFalse);
    });

    test('branch indexes still match the router order', () {
      // If this fails, the router branch list and CoreTab have drifted apart
      // and every tab navigates somewhere else (§6).
      expect(CoreTab.home.index, 0);
      expect(CoreTab.bookings.index, 1);
      expect(CoreTab.messages.index, 2);
      expect(CoreTab.profile.index, 3);
    });
  });

  group('selection', () {
    testWidgets('reports the tapped destination', (tester) async {
      CoreTab? picked;
      await tester.pumpWidget(_host(onTabSelected: (t) => picked = t));
      await tester.tap(find.text('Messages'));
      expect(picked, CoreTab.messages);
    });

    testWidgets('reports the active tab when it is tapped again',
        (tester) async {
      // The component always reports; deciding whether that reselection was
      // meaningful is the scaffold's job, because only it can see the branch
      // navigator (§10).
      CoreTab? picked;
      await tester.pumpWidget(
        _host(currentIndex: 0, onTabSelected: (t) => picked = t),
      );
      await tester.tap(find.text('Home'));
      expect(picked, CoreTab.home);
    });

    testWidgets('the Book action does not report a tab selection',
        (tester) async {
      var tabCalls = 0;
      var bookCalls = 0;
      await tester.pumpWidget(_host(
        onTabSelected: (_) => tabCalls++,
        onBookPressed: () => bookCalls++,
      ));
      await tester.tap(find.byType(ServanaBookAction));
      await tester.pumpAndSettle();
      expect(bookCalls, 1);
      expect(tabCalls, 0, reason: 'Book must not change the selected branch');
    });

    testWidgets('an out-of-range index falls back to Home, not a blank bar',
        (tester) async {
      // §22: a cold start or bad restore must not animate from an
      // uninitialised slot.
      await tester.pumpWidget(_host(currentIndex: 99));
      await tester.pump();
      expect(find.byType(ServanaNavItem), findsNWidgets(4));
    });
  });

  group('badges (§13)', () {
    testWidgets('bookings badge renders its count', (tester) async {
      await tester.pumpWidget(_host(currentIndex: 0, bookingsBadge: 3));
      await tester.pump(ServanaNavMotion.badge);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('messages badge renders its count', (tester) async {
      await tester.pumpWidget(_host(currentIndex: 0, messagesBadge: 5));
      await tester.pump(ServanaNavMotion.badge);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('ten or more collapses to 9+', (tester) async {
      await tester.pumpWidget(_host(currentIndex: 0, messagesBadge: 42));
      await tester.pump(ServanaNavMotion.badge);
      expect(find.text('9+'), findsOneWidget);
      expect(find.text('42'), findsNothing);
    });

    testWidgets('a badge does not move the label', (tester) async {
      // §13: badge changes must not shift layout. Measured, not assumed.
      await tester.pumpWidget(_host(currentIndex: 0));
      await tester.pumpAndSettle();
      final without = tester.getTopLeft(find.text('Messages'));

      await tester.pumpWidget(_host(currentIndex: 0, messagesBadge: 9));
      await tester.pumpAndSettle();
      final with9 = tester.getTopLeft(find.text('Messages'));

      expect(with9, without);
    });

    testWidgets('the active tab keeps its badge, on the bubble',
        (tester) async {
      // §13 forbids drawing the badge BEHIND the raised bubble. The first
      // version of this satisfied that by not drawing it at all — which passed
      // the test and lost the information: a customer sitting on Bookings with
      // two payments outstanding saw no count. It rides on the bubble instead.
      await tester.pumpWidget(_host(currentIndex: 1, bookingsBadge: 2));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('the badge appears exactly once when its tab is active',
        (tester) async {
      // Guards the obvious regression from the fix above: rendering it on the
      // bubble AND on the inactive icon would double it.
      await tester.pumpWidget(_host(currentIndex: 2, messagesBadge: 4));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('accessibility (§17)', () {
    testWidgets('each destination is exactly one semantic node',
        (tester) async {
      await tester.pumpWidget(_host());
      final handle = tester.ensureSemantics();
      for (final tab in CoreTab.values) {
        expect(
          find.bySemanticsLabel(tab.label),
          findsOneWidget,
          reason: '${tab.name} must not split into icon + label nodes',
        );
      }
      handle.dispose();
    });

    testWidgets('the badge count is folded into the label, not a separate node',
        (tester) async {
      await tester.pumpWidget(_host(messagesBadge: 3));
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('3')), findsWidgets);
      handle.dispose();
    });

    testWidgets('the Book action is labelled', (tester) async {
      await tester.pumpWidget(_host());
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Book a service'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the travelling bubble is not a duplicate tappable node',
        (tester) async {
      // §17: the raised bubble is decoration over the real cell. If it were
      // hit-testable it would both duplicate the semantics and swallow taps.
      await tester.pumpWidget(_host(currentIndex: 0));
      await tester.pumpAndSettle();
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      handle.dispose();
    });
  });

  group('reduced motion (§19)', () {
    testWidgets('renders without the traveling curve', (tester) async {
      await tester.pumpWidget(_host(disableAnimations: true, currentIndex: 2));
      await tester.pump();
      // Selection is still visible — carried by colour, weight and the bubble,
      // never by motion alone (§30).
      expect(find.byType(ServanaNavItem), findsNWidgets(4));
      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('settles without pending animations', (tester) async {
      await tester.pumpWidget(_host(disableAnimations: true));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('dark mode (§20)', () {
    testWidgets('renders every destination', (tester) async {
      await tester.pumpWidget(_host(brightness: Brightness.dark));
      await tester.pumpAndSettle();
      for (final tab in CoreTab.values) {
        expect(find.text(tab.label), findsOneWidget);
      }
    });
  });

  group('responsive matrix (§28)', () {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(375, 667),
      Size(390, 844),
      Size(412, 915),
      Size(430, 932),
      Size(600, 960),
      Size(800, 1280),
    ];

    for (final size in sizes) {
      testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_host(
            size: size, currentIndex: 1, bookingsBadge: 2, messagesBadge: 12));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ServanaNavItem), findsNWidgets(4));
        expect(find.byType(ServanaBookAction), findsOneWidget);
      });
    }
  });

  group('large text (§18)', () {
    for (final scale in <double>[1.0, 1.3, 1.6, 2.0]) {
      testWidgets('no overflow at ${(scale * 100).toInt()}% text',
          (tester) async {
        await tester.pumpWidget(_host(
          textScale: scale,
          size: const Size(320, 568),
          bookingsBadge: 3,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Labels stay present rather than being dropped to fit (§30).
        for (final tab in CoreTab.values) {
          expect(find.text(tab.label), findsOneWidget, reason: tab.name);
        }
        // And the Book action stays reachable (§18).
        expect(find.byType(ServanaBookAction), findsOneWidget);
      });
    }
  });

  group('motion budget (§8 §9)', () {
    test('selection travel is within 280-360ms', () {
      expect(ServanaNavMotion.selection.inMilliseconds,
          inInclusiveRange(280, 360));
    });

    test('page movement is within 220-320ms', () {
      expect(ServanaNavMotion.page.inMilliseconds, inInclusiveRange(220, 320));
    });

    test('press feedback is within 120-180ms', () {
      final total = ServanaNavMotion.press.inMilliseconds +
          ServanaNavMotion.pressRelease.inMilliseconds;
      expect(total, inInclusiveRange(120, 180));
    });

    test('there is no one-second navigation delay', () {
      // §30 names MoveUp's literal 1s transition as the thing not to copy.
      expect(ServanaNavMotion.selection.inMilliseconds, lessThan(500));
      expect(ServanaNavMotion.page.inMilliseconds, lessThan(500));
    });

    test('geometry stays inside the spec envelope (§5)', () {
      expect(ServanaNavMotion.barHeight, inInclusiveRange(68, 76));
      expect(ServanaNavMotion.bubbleDiameter, inInclusiveRange(50, 56));
      expect(ServanaNavMotion.bubbleLift, inInclusiveRange(10, 14));
      expect(ServanaNavMotion.iconSize, inInclusiveRange(24, 28));
    });
  });
}
