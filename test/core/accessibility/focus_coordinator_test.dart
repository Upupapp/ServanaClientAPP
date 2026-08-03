import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/accessibility/focus_coordinator.dart';

void main() {
  group('FocusCoordinator', () {
    group('requestFocusPostFrame', () {
      testWidgets('does not throw when called with a valid node',
          (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Focus(
                focusNode: node,
                child: const SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        );

        expect(
          () => FocusCoordinator.requestFocusPostFrame(
            tester.element(find.byType(Scaffold)),
            node: node,
          ),
          returnsNormally,
        );
        await tester.pump(); // settle the post-frame callback
      });

      testWidgets('does not throw when context is unmounted', (tester) async {
        late BuildContext capturedContext;
        final node = FocusNode();
        addTearDown(node.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox();
            }),
          ),
        );

        // Replace the widget tree so the context is unmounted
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        expect(
          () => FocusCoordinator.requestFocusPostFrame(capturedContext,
              node: node),
          returnsNormally,
        );
        await tester.pump(); // should silently no-op
      });
    });

    group('restoreToNode', () {
      testWidgets('does not throw when called with a valid node',
          (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Focus(
                focusNode: node,
                child: const SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        );

        expect(() => FocusCoordinator.restoreToNode(node), returnsNormally);
        await tester.pump();
      });

      testWidgets('does not throw when node is null', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        expect(() => FocusCoordinator.restoreToNode(null), returnsNormally);
        await tester.pump();
      });
    });

    group('focusFirstError', () {
      testWidgets('does not throw with a mix of null and valid nodes',
          (tester) async {
        final first = FocusNode();
        final second = FocusNode();
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Focus(
                      focusNode: first,
                      child: const SizedBox(width: 44, height: 44)),
                  Focus(
                      focusNode: second,
                      child: const SizedBox(width: 44, height: 44)),
                ],
              ),
            ),
          ),
        );

        expect(
          () => FocusCoordinator.focusFirstError(
            tester.element(find.byType(Scaffold)),
            fieldsInOrder: [null, first, second],
          ),
          returnsNormally,
        );
        await tester.pump();
      });

      testWidgets('does not throw when all nodes in list are null',
          (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        expect(
          () => FocusCoordinator.focusFirstError(
            tester.element(find.byType(SizedBox)),
            fieldsInOrder: [null, null],
          ),
          returnsNormally,
        );
        await tester.pump();
      });
    });

    group('clearStaleFocus', () {
      testWidgets('does not throw when context is mounted', (tester) async {
        final node = FocusNode();
        addTearDown(node.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Focus(
                focusNode: node,
                child: const SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        );

        expect(
          () => FocusCoordinator.clearStaleFocus(
              tester.element(find.byType(Scaffold))),
          returnsNormally,
        );
        await tester.pump();
      });
    });

    group('createModalTrap', () {
      test('returns a focusable, non-skip-traversal node', () {
        final trap = FocusCoordinator.createModalTrap();
        expect(trap.canRequestFocus, isTrue);
        expect(trap.skipTraversal, isFalse);
        addTearDown(trap.dispose);
      });
    });
  });
}
