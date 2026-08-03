import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

// Governed Crashlytics access.
// All callers use this wrapper — never FirebaseCrashlytics.instance directly.
//
// Privacy rules (§72):
//   - User identifier is pseudonymous only (analyticsId), never email/name/phone
//   - Custom keys exclude all PII (only approved stable keys below)
//   - Breadcrumb values are safe technical strings, never form values
//   - Non-fatal errors sampled/filtered — routine offline errors are NOT recorded
final class CrashlyticsService {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _fc = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _fc;

  // Set after login — uses pseudonymous ID, never raw customer UID.
  Future<void> setUserIdentifier(String pseudonymousId) async {
    if (kDebugMode) return; // Crashlytics disabled in debug
    try {
      await _fc.setUserIdentifier(pseudonymousId);
    } catch (_) {}
  }

  Future<void> clearUserIdentifier() async {
    if (kDebugMode) return;
    try {
      await _fc.setUserIdentifier('');
    } catch (_) {}
  }

  // Safe custom keys — only approved keys from the registry below.
  Future<void> setKeys(Map<String, String> safeKeys) async {
    if (kDebugMode) return;
    for (final entry in safeKeys.entries) {
      if (!_approvedKeys.contains(entry.key)) continue;
      try {
        await _fc.setCustomKey(entry.key, entry.value);
      } catch (_) {}
    }
  }

  // Record a non-fatal error. Only call for actionable, unexpected errors —
  // NOT for routine offline/network errors or expected validation failures.
  Future<void> recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    if (kDebugMode) return;
    try {
      await _fc.recordError(error, stack, reason: reason, fatal: false);
    } catch (_) {}
  }

  // Safe breadcrumb — technical string only, no user data.
  Future<void> log(String safeTechnicalMessage) async {
    if (kDebugMode) return;
    try {
      _fc.log(safeTechnicalMessage);
    } catch (_) {}
  }

  // Approved custom key names — all others are silently ignored.
  static const Set<String> _approvedKeys = {
    'app_version',
    'build_number',
    'environment',
    'current_screen',
    'active_feature',
    'session_state',
    'account_state',
    'lifecycle_stage',
    'connectivity_state',
    'booking_status_category',
  };
}
