import 'package:client/common/presentation/widgets/servana_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ServanaPrimaryButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        ServanaPrimaryButton(label: 'Confirm', onPressed: () {}),
      ));
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        ServanaPrimaryButton(label: 'Go', onPressed: () => taps++),
      ));
      await tester.tap(find.byType(ElevatedButton));
      expect(taps, equals(1));
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const ServanaPrimaryButton(label: 'Go', onPressed: null),
      ));
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(_wrap(
        ServanaPrimaryButton(
          label: 'Go',
          onPressed: () {},
          isLoading: true,
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Go'), findsNothing);
    });

    testWidgets('is disabled when isLoading is true', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        ServanaPrimaryButton(
          label: 'Go',
          onPressed: () => taps++,
          isLoading: true,
        ),
      ));
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(taps, equals(0));
    });
  });

  group('ServanaOutlinedButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        ServanaOutlinedButton(label: 'Cancel', onPressed: () {}),
      ));
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        ServanaOutlinedButton(label: 'Cancel', onPressed: () => taps++),
      ));
      await tester.tap(find.byType(OutlinedButton));
      expect(taps, equals(1));
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const ServanaOutlinedButton(label: 'Cancel', onPressed: null),
      ));
      final btn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('darkSurface renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        ServanaOutlinedButton(
          label: 'Skip',
          onPressed: () {},
          darkSurface: true,
        ),
      ));
      expect(find.text('Skip'), findsOneWidget);
    });
  });
}
