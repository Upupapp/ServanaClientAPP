import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:client/common/domain/version_gate/version_gate.dart';
import 'package:client/common/domain/version_gate/version_gate_coordinator.dart';
import 'package:client/common/domain/version_gate/version_gate_repository.dart';
import 'package:client/common/presentation/version_gate/version_gate_barrier.dart';

/// A repository that answers from memory, so the barrier can be driven through
/// every decision without Firebase.
class _FakeRepo implements VersionGateRepository {
  _FakeRepo(this.config);
  VersionGateConfig? config;
  int loads = 0;

  @override
  Future<VersionGateConfig?> load() async {
    loads++;
    return config;
  }

  @override
  Future<void> clearCache() async {}
}

void main() {
  const cfg = VersionGateConfig(
    schemaVersion: 1,
    minimumSupportedBuild: 40,
    recommendedBuild: 45,
    message: 'Servana 1.0 is no longer supported.',
    androidStoreUrl: 'https://play.example/app',
    iosStoreUrl: 'https://apps.example/app',
  );

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<Widget> harness({
    required int build,
    VersionGateConfig? config,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return MaterialApp(
      home: VersionGateBarrier(
        coordinator: VersionGateCoordinator(
          repository: _FakeRepo(config),
          preferences: prefs,
          readBuildNumber: () async => build,
          androidImmediateUpdate: () async {},
        ),
        child: const Scaffold(body: Text('THE APP')),
      ),
    );
  }

  testWidgets('a blocked build never renders the app', (tester) async {
    await tester.pumpWidget(await harness(build: 39, config: cfg));
    await tester.pumpAndSettle();

    // The whole point: the tree is REPLACED, not overlaid. A blocked build must
    // not be able to reach a route or make an authenticated request.
    expect(find.text('THE APP'), findsNothing);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Servana 1.0 is no longer supported.'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('the hard block offers no way to dismiss it', (tester) async {
    await tester.pumpWidget(await harness(build: 39, config: cfg));
    await tester.pumpAndSettle();

    // No close affordance, and nothing to tap that returns to the app.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    expect(find.text('THE APP'), findsNothing,
        reason: 'tapping Update must not release the block');
  });

  testWidgets('a supported build renders the app untouched', (tester) async {
    await tester.pumpWidget(await harness(build: 45, config: cfg));
    await tester.pumpAndSettle();

    expect(find.text('THE APP'), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
  });

  testWidgets('FAILS OPEN — no config renders the app', (tester) async {
    // A gate that blocks the app because the network is unavailable is worse
    // than the problem it solves.
    await tester.pumpWidget(await harness(build: 1, config: null));
    await tester.pumpAndSettle();

    expect(find.text('THE APP'), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
  });

  testWidgets('the app renders while the first evaluation is still in flight',
      (tester) async {
    // No splash gate on a network call. Before the first pump-and-settle the
    // decision has not arrived, and the child must already be on screen.
    await tester.pumpWidget(await harness(build: 39, config: cfg));
    expect(find.text('THE APP'), findsOneWidget,
        reason: 'the barrier must not withhold the app pending a fetch');

    await tester.pumpAndSettle();
    expect(find.text('THE APP'), findsNothing);
  });

  testWidgets('the soft prompt overlays the app rather than replacing it',
      (tester) async {
    await tester.pumpWidget(await harness(build: 42, config: cfg));
    await tester.pumpAndSettle();

    expect(find.text('THE APP'), findsOneWidget,
        reason: 'a recommendation must not take the app away');
    expect(find.textContaining('newer version'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('dismissing the soft prompt returns the app cleanly',
      (tester) async {
    await tester.pumpWidget(await harness(build: 42, config: cfg));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.textContaining('newer version'), findsNothing);
    expect(find.text('THE APP'), findsOneWidget);
  });

  testWidgets('the blocking screen survives the largest supported text scale',
      (tester) async {
    // A clipped "Update now" is a customer with no way forward at all. The
    // accessibility tokens declare 2.0 as supported, so it is asserted at the
    // smallest supported viewport and the largest supported scale together.
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: await harness(build: 39, config: cfg),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update now'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'an overflow here would clip the only way forward');
  });
}
