import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:client/common/domain/auth/auth_return_intent.dart';
import 'package:client/common/domain/deep_links/deep_link_coordinator.dart';

void main() {
  late List<String> navigated;
  late List<AuthReturnIntent?> gated;
  late StreamController<Uri> stream;

  DeepLinkCoordinator build({
    Uri? initial,
    bool authed = true,
  }) {
    navigated = [];
    gated = [];
    stream = StreamController<Uri>.broadcast();
    return DeepLinkCoordinator(
      initialLink: () async => initial,
      linkStream: stream.stream,
      navigate: navigated.add,
      navigateToAuthGate: (_, intent) => gated.add(intent),
      isAuthenticated: () => authed,
    );
  }

  tearDown(() => stream.close());

  test('a cold-start link is handled, not lost', () async {
    // A link that launches a terminated app arrives once at startup. Handling
    // only the stream loses the majority of real links.
    final c = build(initial: Uri.parse('https://servana.com.ph/services/180'));
    await c.start();
    expect(navigated, ['/services/180']);
    await c.dispose();
  });

  test('a warm-start link is handled too', () async {
    final c = build();
    await c.start();
    stream.add(Uri.parse('https://servana.com.ph/services/7'));
    await Future<void>.delayed(Duration.zero);
    expect(navigated, ['/services/7']);
    await c.dispose();
  });

  test('an unclaimed link does NOTHING — it does not go home', () async {
    // Being dropped somewhere else is a bug report, not a destination.
    final c = build();
    expect(
        c.handle(Uri.parse('https://servana.com.ph/admin/payouts')), isFalse);
    expect(c.handle(Uri.parse('https://evil.example.com/bookings/1')), isFalse);
    expect(navigated, isEmpty);
    expect(gated, isEmpty);
  });

  test('a signed-out arrival holds the destination through the auth gate', () {
    final c = build(authed: false);
    expect(c.handle(Uri.parse('https://servana.com.ph/bookings/42')), isTrue);
    expect(navigated, isEmpty, reason: 'must not reach the booking yet');
    expect(gated, hasLength(1));
    expect(gated.single, isNotNull,
        reason: 'sign-in must return them to the booking, not to Home');
  });

  test('a public destination does not demand a session', () {
    final c = build(authed: false);
    expect(c.handle(Uri.parse('https://servana.com.ph/services/180')), isTrue);
    expect(navigated, ['/services/180']);
    expect(gated, isEmpty,
        reason: 'an auth wall on the one link a stranger receives is a funnel '
            'with no top');
  });

  test('a failing initial-link lookup does not break startup', () async {
    final c = DeepLinkCoordinator(
      initialLink: () async => throw StateError('platform channel missing'),
      linkStream: const Stream<Uri>.empty(),
      navigate: (_) => fail('must not navigate'),
      navigateToAuthGate: (_, __) => fail('must not gate'),
      isAuthenticated: () => true,
    );
    await c.start();
    await c.dispose();
  });

  test('a reset-password link never carries its token into the app', () {
    final c = build(authed: false);
    c.handle(Uri.parse('https://servana.com.ph/reset-password?token=SECRET'));
    expect(navigated, ['/reset-password']);
    expect(navigated.single.contains('SECRET'), isFalse);
  });
}
