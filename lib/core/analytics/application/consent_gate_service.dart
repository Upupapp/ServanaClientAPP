import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_consent.dart';
import 'package:client/core/analytics/presentation/analytics_consent_sheet.dart';
import 'package:client/core/accessibility/focus_coordinator.dart';
import 'package:flutter/material.dart';

/// Guards the consent dialog so it shows exactly once per app install.
///
/// In-memory [_shown] prevents double-shows within a session (e.g. both
/// WelcomeScreen and HomeScreen call [maybeShow]). SharedPreferences
/// [AnalyticsConsent.hasUserDecided()] prevents re-shows after app restart.
class ConsentGateService {
  bool _shown = false;

  /// Shows the consent dialog if the user has not yet decided.
  /// Safe to call from multiple screens — only fires once per install.
  Future<void> maybeShow(BuildContext context, AnalyticsCoordinator coordinator) async {
    if (_shown) return;
    // Set before first await — prevents concurrent callers from both passing the
    // guard during the hasUserDecided() suspension window.
    _shown = true;
    final decided = await AnalyticsConsent.hasUserDecided();
    if (decided) return;
    if (!context.mounted) return;
    final priorFocus = FocusScope.of(context).focusedChild;
    final accepted = await showAnalyticsConsentSheet(context);
    FocusCoordinator.restoreToNode(priorFocus);
    final consent = accepted ? AnalyticsConsent.fullConsent() : AnalyticsConsent.defaultConsent();
    await coordinator.setConsent(consent);
  }
}
