import 'package:flutter/foundation.dart';

import '../data/analytics_deduplicator.dart';
import '../data/analytics_event_validator.dart';
import '../data/analytics_privacy_filter.dart';
import '../data/firebase_analytics_service.dart';
import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_user_context.dart';
import 'analytics_context_provider.dart';

// Central dispatch point for ALL analytics in the Servana Customer app.
// Features depend ONLY on this class — never on Firebase or the filter directly.
//
// C21 rules enforced here:
//   § Privacy filter strips PII before any event reaches Firebase
//   § Consent gate: ANALYTICS consent required for non-essential events
//   § Deduplicator prevents widget-rebuild and rapid-repeat fires
//   § Validator enforces event name format and property key format
//   § Context provider attaches platform/version to every event
//   § Analytics failure NEVER propagates to callers (catch-all at bottom)
class AnalyticsCoordinator {
  AnalyticsCoordinator({
    required FirebaseAnalyticsService service,
    AnalyticsEventValidator? validator,
    AnalyticsPrivacyFilter? privacyFilter,
    AnalyticsDeduplicator? deduplicator,
  })  : _service = service,
        _validator = validator ?? const AnalyticsEventValidator(),
        _filter = privacyFilter ?? const AnalyticsPrivacyFilter(),
        _dedup = deduplicator ?? AnalyticsDeduplicator();

  final FirebaseAnalyticsService _service;
  final AnalyticsEventValidator _validator;
  final AnalyticsPrivacyFilter _filter;
  final AnalyticsDeduplicator _dedup;

  AnalyticsConsent _consent = AnalyticsConsent.defaultConsent();
  AnalyticsUserContext _userContext = AnalyticsUserContext.guest;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _consent = await AnalyticsConsent.load();
    await _service.setConsent(_consent);
    if (kDebugMode) {
      debugPrint('[Analytics] initialized — consent: '
          '${_consent.grantedCategories.map((c) => c.name).join(", ")}');
    }
  }

  Future<void> track(AnalyticsEvent event) async {
    try {
      // 1. Consent gate
      if (!_consent.allows(event.consentCategory)) {
        if (kDebugMode) {
          debugPrint(
              '[Analytics] BLOCKED (no consent) → ${event.eventName}');
        }
        return;
      }

      // 2. Privacy filter — strip PII before any further processing
      final (:clean, :violations) = _filter.filter(event);
      if (violations.isNotEmpty && kDebugMode) {
        debugPrint('[Analytics] PRIVACY violations in ${event.eventName}: '
            '${violations.join(", ")}');
      }

      // 3. Validation
      final validation = _validator.validate(event);
      if (!validation.isValid) {
        if (kDebugMode) {
          debugPrint(
              '[Analytics] INVALID ${event.eventName}: ${validation.reason}');
        }
        return;
      }

      // 4. Deduplication
      final key = event.dedupKey;
      if (key != null && _dedup.shouldSuppress(key)) {
        if (kDebugMode) {
          debugPrint('[Analytics] DEDUPED → ${event.eventName}');
        }
        return;
      }

      // 5. Attach context (platform, version, environment)
      final withContext = {
        ...AnalyticsContextProvider.instance.contextProperties,
        ...clean,
      };

      // 6. Delegate to Firebase (non-blocking, failure-safe)
      await _service.track(event, withContext);

      if (kDebugMode) {
        debugPrint('[Analytics] ✓ ${event.eventName} ${clean.isEmpty ? "" : clean.toString()}');
      }
    } catch (e) {
      // Analytics failure MUST NEVER surface to the user (§123).
      if (kDebugMode) {
        debugPrint('[Analytics] ERROR tracking ${event.eventName}: $e');
      }
    }
  }

  Future<void> setUserContext(AnalyticsUserContext ctx) async {
    try {
      _userContext = ctx;
      await _service.setUserContext(ctx);
    } catch (_) {}
  }

  Future<void> clearUserContext() async {
    try {
      _userContext = AnalyticsUserContext.guest;
      _dedup.clear();
      await _service.clearUserContext();
    } catch (_) {}
  }

  Future<void> setConsent(AnalyticsConsent consent) async {
    try {
      _consent = consent;
      await consent.persist();
      await _service.setConsent(consent);
    } catch (_) {}
  }

  AnalyticsUserContext get currentUserContext => _userContext;
  AnalyticsConsent get currentConsent => _consent;
}
