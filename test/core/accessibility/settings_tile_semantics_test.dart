import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/modules/settings/presentation/widgets/settings_tile.dart';

void main() {
  group('SettingsToggleTile semantics', () {
    testWidgets('has toggled semantics when value is true', (tester) async {
      final handle = tester.ensureSemantics();

      bool currentValue = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) => SettingsToggleTile(
                icon: Icons.analytics_outlined,
                title: 'Analytics',
                value: currentValue,
                onChanged: (v) => setState(() => currentValue = v),
              ),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(SettingsToggleTile));
      expect(semantics.hasFlag(SemanticsFlag.isToggled), isTrue);
      expect(semantics.label, contains('Analytics'));

      handle.dispose();
    });

    testWidgets('has label matching title', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsToggleTile(
              icon: Icons.notifications_outlined,
              title: 'Push notifications',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(SettingsToggleTile));
      expect(semantics.label, contains('Push notifications'));
      expect(semantics.hasFlag(SemanticsFlag.isToggled), isFalse);

      handle.dispose();
    });

    testWidgets('single semantics node — no duplicate from inner Switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsToggleTile(
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // There should be exactly one semantics node for the toggle control.
      // If the inner Switch leaks a node, this count would be > 1.
      final switchFinder = find.bySemanticsLabel(RegExp('Analytics'));
      expect(switchFinder, findsOneWidget);
    });

    testWidgets('tapping the inner Switch inverts value', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) => SettingsToggleTile(
                icon: Icons.analytics_outlined,
                title: 'Analytics',
                value: toggled,
                onChanged: (v) => setState(() => toggled = v),
              ),
            ),
          ),
        ),
      );

      // Tap the Switch widget (physical gesture, not semantics action)
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('saving=true disables the tap action', (tester) async {
      int taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsToggleTile(
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              value: false,
              saving: true,
              onChanged: (_) => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Analytics'));
      await tester.pump();
      expect(taps, equals(0));
    });
  });

  group('SettingsNavTile semantics', () {
    testWidgets('announced as button with title label', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsNavTile(
              icon: Icons.lock_outline,
              title: 'Privacy & Legal',
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(SettingsNavTile));
      expect(semantics.label, contains('Privacy & Legal'));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);

      handle.dispose();
    });
  });

  group('SettingsDestructiveTile semantics', () {
    testWidgets('announced as button', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDestructiveTile(
              icon: Icons.delete_outline,
              title: 'Delete account',
              onTap: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(SettingsDestructiveTile));
      expect(semantics.label, contains('Delete account'));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);

      handle.dispose();
    });
  });
}
