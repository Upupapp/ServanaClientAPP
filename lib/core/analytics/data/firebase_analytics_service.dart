import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_user_context.dart';

// Production implementation of the analytics abstraction.
// Features never import this file — they depend on AnalyticsCoordinator only.
final class FirebaseAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _fa = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _fa;
  bool _collectionEnabled = false;

  Future<void> setCollectionEnabled(bool enabled) async {
    if (_collectionEnabled == enabled) return;
    _collectionEnabled = enabled;
    try {
      await _fa.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('[Analytics] setCollectionEnabled error: $e');
    }
  }

  Future<void> track(AnalyticsEvent event, Map<String, Object?> filteredProps) async {
    if (!_collectionEnabled) return;
    if (kIsWeb) return; // Firebase Analytics SDK does not support Flutter Web
    try {
      if (event.eventName == 'screen_view') {
        await _fa.logEvent(
          name: 'screen_view',
          parameters: _toParams(filteredProps),
        );
      } else {
        await _fa.logEvent(
          name: event.eventName,
          parameters: filteredProps.isEmpty ? null : _toParams(filteredProps),
        );
      }
    } catch (e) {
      // Analytics failure MUST NOT propagate to callers (§123).
      debugPrint('[Analytics] logEvent(${event.eventName}) error: $e');
    }
  }

  Future<void> setUserContext(AnalyticsUserContext ctx) async {
    if (!_collectionEnabled) return;
    try {
      // Set pseudonymous analytics ID only — never raw customer ID.
      if (ctx.analyticsId.isNotEmpty) {
        // We do NOT call setUserId for Firebase Analytics (third-party system).
        // Instead, use a user property for optional aggregation in GA4.
        await _fa.setUserProperty(
            name: 'account_state', value: ctx.accountState);
        await _fa.setUserProperty(
            name: 'lifecycle_stage', value: ctx.lifecycleStage);
        await _fa.setUserProperty(
            name: 'profile_completion_band', value: ctx.profileCompletionBand);
        await _fa.setUserProperty(
            name: 'has_completed_booking',
            value: ctx.hasCompletedBooking ? 'true' : 'false');
      }
    } catch (e) {
      debugPrint('[Analytics] setUserContext error: $e');
    }
  }

  Future<void> clearUserContext() async {
    if (!_collectionEnabled) return;
    try {
      await _fa.setUserProperty(name: 'account_state', value: null);
      await _fa.setUserProperty(name: 'lifecycle_stage', value: null);
      await _fa.setUserProperty(
          name: 'profile_completion_band', value: null);
      await _fa.setUserProperty(
          name: 'has_completed_booking', value: null);
    } catch (e) {
      debugPrint('[Analytics] clearUserContext error: $e');
    }
  }

  Future<void> setConsent(AnalyticsConsent consent) async {
    await setCollectionEnabled(consent.allows(ConsentCategory.analytics));
  }

  Map<String, Object> _toParams(Map<String, Object?> raw) =>
      Map.fromEntries(raw.entries
          .map((e) => MapEntry(e.key, _toFirebaseParam(e.value)))
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!)));

  // Firebase Analytics parameters must be String, int, double, or bool.
  Object? _toFirebaseParam(Object? value) {
    if (value == null) return null;
    if (value is String || value is int || value is double || value is bool) {
      return value;
    }
    return value.toString();
  }
}
