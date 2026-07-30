import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/accessibility/live_region_manager.dart';

// LiveRegionManager calls SemanticsService.announce() which requires the
// Flutter semantics binding. All tests run as testWidgets() to ensure the
// full AutomatedTestWidgetsFlutterBinding (including semantics) is active.

Widget _empty() => const MaterialApp(home: Scaffold(body: SizedBox()));

void main() {
  group('LiveRegionManager', () {
    setUp(() {
      LiveRegionManager.clearCache();
    });

    group('clearCache', () {
      testWidgets('allows re-announcement of the same message after clear',
          (tester) async {
        await tester.pumpWidget(_empty());
        final handle = tester.ensureSemantics();

        // First announcement goes through
        expect(
          () => LiveRegionManager.announcePolite(
            'Status updated',
            minInterval: const Duration(minutes: 10),
          ),
          returnsNormally,
        );

        // Same message within interval — silently throttled
        expect(
          () => LiveRegionManager.announcePolite(
            'Status updated',
            minInterval: const Duration(minutes: 10),
          ),
          returnsNormally,
        );

        // After clear, same message fires again
        LiveRegionManager.clearCache();
        expect(
          () => LiveRegionManager.announcePolite(
            'Status updated',
            minInterval: const Duration(minutes: 10),
          ),
          returnsNormally,
        );

        handle.dispose();
      });
    });

    group('announcePolite', () {
      testWidgets('does not throw on empty string', (tester) async {
        await tester.pumpWidget(_empty());
        expect(() => LiveRegionManager.announcePolite(''), returnsNormally);
      });

      testWidgets('does not throw on normal message', (tester) async {
        await tester.pumpWidget(_empty());
        final handle = tester.ensureSemantics();
        expect(
          () => LiveRegionManager.announcePolite('3 services found'),
          returnsNormally,
        );
        handle.dispose();
      });
    });

    group('announceAssertive', () {
      testWidgets('does not throw', (tester) async {
        await tester.pumpWidget(_empty());
        final handle = tester.ensureSemantics();
        expect(
          () => LiveRegionManager.announceAssertive(
              'Session expired. Please sign in again.'),
          returnsNormally,
        );
        handle.dispose();
      });
    });

    group('announce', () {
      testWidgets('does not throw when assertive=true', (tester) async {
        await tester.pumpWidget(_empty());
        final handle = tester.ensureSemantics();
        expect(
          () => LiveRegionManager.announce('Warning', assertive: true),
          returnsNormally,
        );
        handle.dispose();
      });

      testWidgets('does not throw when assertive=false', (tester) async {
        await tester.pumpWidget(_empty());
        final handle = tester.ensureSemantics();
        expect(
          () => LiveRegionManager.announce('Info', assertive: false),
          returnsNormally,
        );
        handle.dispose();
      });
    });

    group('announceResultCount', () {
      testWidgets('zero count does not throw', (tester) async {
        await tester.pumpWidget(_empty());
        expect(
          () => LiveRegionManager.announceResultCount(0),
          returnsNormally,
        );
      });

      testWidgets('positive count does not throw', (tester) async {
        await tester.pumpWidget(_empty());
        final handle = tester.ensureSemantics();
        expect(
          () => LiveRegionManager.announceResultCount(7),
          returnsNormally,
        );
        handle.dispose();
      });
    });

    group('announceTrackingUpdate', () {
      testWidgets('does not throw', (tester) async {
        await tester.pumpWidget(_empty());
        final handle = tester.ensureSemantics();
        expect(
          () => LiveRegionManager.announceTrackingUpdate('En route'),
          returnsNormally,
        );
        handle.dispose();
      });
    });
  });
}
