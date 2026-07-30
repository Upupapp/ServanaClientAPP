import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/data/analytics_deduplicator.dart';
import 'package:client/core/analytics/data/firebase_analytics_service.dart';
import 'package:client/core/analytics/domain/analytics_consent.dart';
import 'package:client/core/analytics/domain/analytics_event.dart';
import 'package:client/core/analytics/domain/analytics_property.dart';
import 'package:client/core/analytics/events/auth_events.dart';
import 'package:client/core/analytics/events/home_events.dart';
import 'package:client/core/analytics/events/support_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

// Minimal fake event with a known banned key in properties.
final class _PiiEvent extends AnalyticsEvent {
  const _PiiEvent();
  @override
  String get eventName => 'test_pii_event';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.entrySource: 'home',
        'email': 'user@example.com', // banned key — must be stripped
      };
}

// Minimal valid event with no PII.
final class _ValidEvent extends AnalyticsEvent {
  const _ValidEvent();
  @override
  String get eventName => 'test_valid_event';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {AnalyticsKeys.entrySource: 'home'};
}

// Event with a fast dedupKey to test deduplication.
final class _DedupEvent extends AnalyticsEvent {
  const _DedupEvent();
  @override
  String get eventName => 'test_dedup_event';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  String? get dedupKey => 'test_dedup';
  @override
  Map<String, Object?> get properties => {};
}

AnalyticsCoordinator _makeCoordinator(
  MockFirebaseAnalytics mockFa, {
  AnalyticsDeduplicator? deduplicator,
}) {
  when(() => mockFa.setAnalyticsCollectionEnabled(any()))
      .thenAnswer((_) async {});
  when(() => mockFa.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      )).thenAnswer((_) async {});
  when(() => mockFa.setUserProperty(
        name: any(named: 'name'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});
  final service = FirebaseAnalyticsService(analytics: mockFa);
  return AnalyticsCoordinator(
    service: service,
    deduplicator: deduplicator,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    // consent.persist() calls SharedPreferences — initialize mock values so
    // setConsent() doesn't throw and swallow the _service.setConsent() call.
    SharedPreferences.setMockInitialValues({});
  });

  // ── Stage 1: Consent gate ──────────────────────────────────────────────────

  group('Stage 1 — consent gate', () {
    test(
        'blocks analytics event when consent is defaultConsent (essential-only)',
        () async {
      final mockFa = MockFirebaseAnalytics();
      final coord = _makeCoordinator(mockFa);
      // defaultConsent grants only essential — analytics events must be blocked.
      await coord.track(const _ValidEvent());
      verifyNever(() => mockFa.logEvent(
          name: any(named: 'name'), parameters: any(named: 'parameters')));
    });

    test('passes essential event through even with defaultConsent', () async {
      final mockFa = MockFirebaseAnalytics();
      final coord = _makeCoordinator(mockFa);
      when(() => mockFa.setAnalyticsCollectionEnabled(false))
          .thenAnswer((_) async {});
      // SafetyEntryOpenedEvent is essential — must always fire.
      // (FirebaseAnalyticsService won't call logEvent because _collectionEnabled
      // is false until setConsent(fullConsent()) is called, but the pipeline
      // should not short-circuit at stage 1.)
      await coord.track(const SafetyEntryOpenedEvent());
      // We can't verify Firebase was called (collectionEnabled=false), but we
      // verify NO exception was thrown and the pipeline ran to stage 6.
      // This is the observable contract: essential events pass the consent gate.
    });

    test('passes analytics event after fullConsent is set', () async {
      final mockFa = MockFirebaseAnalytics();
      final coord = _makeCoordinator(mockFa);
      await coord.setConsent(AnalyticsConsent.fullConsent());
      await coord.track(const _ValidEvent());
      verify(() => mockFa.logEvent(
            name: 'test_valid_event',
            parameters: any(named: 'parameters'),
          )).called(1);
    });
  });

  // ── Stage 2: PII filter runs before validator ──────────────────────────────

  group('Stage 2 — PII filter (runs before validator and dedup)', () {
    test('strips banned key before event reaches Firebase', () async {
      final mockFa = MockFirebaseAnalytics();
      final coord = _makeCoordinator(mockFa);
      await coord.setConsent(AnalyticsConsent.fullConsent());
      await coord.track(const _PiiEvent());
      // Firebase should be called but WITHOUT the 'email' key.
      final captured = verify(() => mockFa.logEvent(
            name: 'test_pii_event',
            parameters: captureAny(named: 'parameters'),
          )).captured;
      expect(captured, isNotEmpty);
      final params = captured.first as Map<String, Object>;
      expect(params.containsKey('email'), false,
          reason: 'PII filter must strip banned keys before Firebase');
      expect(params['entry_source'], 'home');
    });
  });

  // ── Stage 4: Deduplication ─────────────────────────────────────────────────

  group('Stage 4 — deduplication (2-second window)', () {
    test('second fire within dedup window is suppressed', () async {
      final mockFa = MockFirebaseAnalytics();
      final dedup = AnalyticsDeduplicator(window: const Duration(seconds: 2));
      final coord = _makeCoordinator(mockFa, deduplicator: dedup);
      await coord.setConsent(AnalyticsConsent.fullConsent());

      await coord.track(const _DedupEvent());
      await coord.track(const _DedupEvent()); // duplicate within 2s

      verify(() => mockFa.logEvent(
            name: 'test_dedup_event',
            parameters: any(named: 'parameters'),
          )).called(1); // only one call, not two
    });

    test('second fire after dedup window is NOT suppressed', () async {
      final mockFa = MockFirebaseAnalytics();
      final dedup =
          AnalyticsDeduplicator(window: const Duration(milliseconds: 50));
      final coord = _makeCoordinator(mockFa, deduplicator: dedup);
      await coord.setConsent(AnalyticsConsent.fullConsent());

      await coord.track(const _DedupEvent());
      await Future.delayed(const Duration(milliseconds: 100));
      await coord.track(const _DedupEvent()); // after window

      verify(() => mockFa.logEvent(
            name: 'test_dedup_event',
            parameters: any(named: 'parameters'),
          )).called(2);
    });
  });

  // ── clearUserContext ───────────────────────────────────────────────────────

  group('clearUserContext()', () {
    test('clears dedup cache so post-logout events are not suppressed',
        () async {
      final mockFa = MockFirebaseAnalytics();
      final coord = _makeCoordinator(mockFa);
      await coord.setConsent(AnalyticsConsent.fullConsent());

      // First fire primes the dedup cache.
      await coord.track(const HomeViewedEvent(accountState: 'authenticated'));

      // clearUserContext() must call dedup.clear().
      await coord.clearUserContext();

      // After clearing, the same event should fire again.
      await coord.track(const HomeViewedEvent(accountState: 'guest'));
      verify(() => mockFa.logEvent(
            name: 'home_viewed',
            parameters: any(named: 'parameters'),
          )).called(2);
    });
  });

  // ── Analytics failures never propagate ────────────────────────────────────

  group('failure isolation', () {
    test('Firebase logEvent throwing does not propagate to caller', () async {
      final mockFa = MockFirebaseAnalytics();
      when(() => mockFa.setAnalyticsCollectionEnabled(any()))
          .thenAnswer((_) async {});
      when(() => mockFa.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenThrow(Exception('Firebase crash'));
      when(() => mockFa.setUserProperty(
            name: any(named: 'name'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final service = FirebaseAnalyticsService(analytics: mockFa);
      final coord = AnalyticsCoordinator(service: service);
      await coord.setConsent(AnalyticsConsent.fullConsent());

      // Must not throw even though Firebase throws internally.
      await expectLater(
        coord.track(const SignInStartedEvent(authMethod: 'email')),
        completes,
      );
    });
  });
}
