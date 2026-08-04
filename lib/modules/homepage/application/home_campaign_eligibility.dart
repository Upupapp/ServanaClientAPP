import 'package:client/modules/homepage/domain/home_campaign_state.dart';
import 'package:client/modules/homepage/domain/home_promotion.dart';

/// Why a campaign was not shown (LAUNCHBANNER+ §27).
///
/// Every value is an analytics `suppression_reason`. The set is closed so the
/// property stays low-cardinality and the funnel stays readable — a free-text
/// reason would make "why is nobody seeing this campaign" unanswerable.
enum CampaignSuppression {
  none,
  notAuthenticated,
  accountUnresolved,
  campaignDisabled,
  campaignNotStarted,
  campaignExpired,
  appVersionUnsupported,
  configurationUnavailable,
  alreadyCompleted,
  permanentlyDismissed,
  maxImpressions,
  cooldownActive,
  minIntervalNotElapsed,
  shownThisSession,
  homeNotVisible,
  higherPriorityModal,
  deepLinkActive,
  paymentRecoveryActive,
  criticalBookingActive;

  /// Analytics value. lower_snake_case to satisfy the C21 event validator,
  /// which enforces `^[a-z][a-z0-9_]{0,39}$` on every property value key.
  String get analyticsValue => switch (this) {
        CampaignSuppression.none => 'none',
        CampaignSuppression.notAuthenticated => 'not_authenticated',
        CampaignSuppression.accountUnresolved => 'account_unresolved',
        CampaignSuppression.campaignDisabled => 'campaign_disabled',
        CampaignSuppression.campaignNotStarted => 'campaign_not_started',
        CampaignSuppression.campaignExpired => 'campaign_expired',
        CampaignSuppression.appVersionUnsupported => 'app_version_unsupported',
        CampaignSuppression.configurationUnavailable =>
          'configuration_unavailable',
        CampaignSuppression.alreadyCompleted => 'already_completed',
        CampaignSuppression.permanentlyDismissed => 'permanently_dismissed',
        CampaignSuppression.maxImpressions => 'max_impressions',
        CampaignSuppression.cooldownActive => 'cooldown_active',
        CampaignSuppression.minIntervalNotElapsed => 'min_interval_not_elapsed',
        CampaignSuppression.shownThisSession => 'shown_this_session',
        CampaignSuppression.homeNotVisible => 'home_not_visible',
        CampaignSuppression.higherPriorityModal => 'higher_priority_modal',
        CampaignSuppression.deepLinkActive => 'deep_link_active',
        CampaignSuppression.paymentRecoveryActive => 'payment_recovery_active',
        CampaignSuppression.criticalBookingActive => 'critical_booking_active',
      };
}

/// The context an eligibility decision is made against.
///
/// Everything the decision needs is passed in — including `now` — so the rules
/// are a pure function. §6 defines behaviour in terms of elapsed days, and a
/// rule that reads the wall clock internally can only be tested by waiting.
class CampaignEvaluationContext {
  const CampaignEvaluationContext({
    required this.now,
    required this.isAuthenticated,
    required this.accountId,
    required this.appVersion,
    required this.hasConfiguration,
    this.shownThisSession = false,
    this.homeVisible = true,
    this.higherPriorityModalOpen = false,
    this.deepLinkActive = false,
    this.paymentRecoveryActive = false,
    this.hasCriticalBooking = false,
  });

  final DateTime now;
  final bool isAuthenticated;
  final String? accountId;

  /// Dotted-numeric app version, e.g. "1.0.0".
  final String appVersion;

  /// Whether campaign configuration has ever been obtained (§30). Without it
  /// expiry cannot be determined, so the campaign must not be shown.
  final bool hasConfiguration;

  final bool shownThisSession;
  final bool homeVisible;
  final bool higherPriorityModalOpen;
  final bool deepLinkActive;
  final bool paymentRecoveryActive;
  final bool hasCriticalBooking;
}

/// The outcome of an eligibility evaluation.
class CampaignDecision {
  const CampaignDecision.eligible()
      : eligible = true,
        suppression = CampaignSuppression.none;

  const CampaignDecision.suppressed(CampaignSuppression reason)
      : eligible = false,
        suppression = reason;

  final bool eligible;
  final CampaignSuppression suppression;

  @override
  String toString() =>
      eligible ? 'eligible' : 'suppressed(${suppression.analyticsValue})';
}

/// Pure evaluation of every §5/§6 rule.
///
/// Order matters and is deliberate: cheap, permanent reasons are checked before
/// transient ones, so the reported `suppression_reason` is the *most
/// fundamental* one. A customer who both completed the campaign and is in a
/// cooldown should report `already_completed` — reporting `cooldown_active`
/// would suggest they will see it again, and they never will.
abstract final class HomeCampaignEligibility {
  static CampaignDecision evaluate({
    required HomeCampaign campaign,
    required HomeCampaignState? state,
    required CampaignEvaluationContext context,
  }) {
    // ── Identity ────────────────────────────────────────────────────────
    if (!context.isAuthenticated) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.notAuthenticated);
    }
    if (context.accountId == null || context.accountId!.isEmpty) {
      // Without a stable account id the state would be written to the guest
      // namespace and leak across customers. Refusing is the safe failure.
      return const CampaignDecision.suppressed(
          CampaignSuppression.accountUnresolved);
    }

    // ── Campaign configuration ──────────────────────────────────────────
    if (!campaign.enabled) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.campaignDisabled);
    }
    if (!context.hasConfiguration) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.configurationUnavailable);
    }
    if (campaign.startsAt != null && context.now.isBefore(campaign.startsAt!)) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.campaignNotStarted);
    }
    if (campaign.endsAt != null && context.now.isAfter(campaign.endsAt!)) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.campaignExpired);
    }
    if (!_appVersionInRange(
      context.appVersion,
      campaign.minAppVersion,
      campaign.maxAppVersion,
    )) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.appVersionUnsupported);
    }

    // ── Customer history (permanent before transient) ────────────────────
    if (state != null) {
      if (state.completedAt != null) {
        return const CampaignDecision.suppressed(
            CampaignSuppression.alreadyCompleted);
      }
      if (state.permanentlyDismissedAt != null) {
        return const CampaignDecision.suppressed(
            CampaignSuppression.permanentlyDismissed);
      }
      if (state.impressionCount >= campaign.maxImpressions) {
        return const CampaignDecision.suppressed(
            CampaignSuppression.maxImpressions);
      }
      if (state.isInCooldown(context.now)) {
        return const CampaignDecision.suppressed(
            CampaignSuppression.cooldownActive);
      }
      final last = state.lastShownAt;
      if (last != null &&
          context.now.difference(last) < campaign.minTimeBetweenImpressions) {
        return const CampaignDecision.suppressed(
            CampaignSuppression.minIntervalNotElapsed);
      }
    }

    // ── Session and surroundings ────────────────────────────────────────
    if (context.shownThisSession) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.shownThisSession);
    }
    if (!context.homeVisible) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.homeNotVisible);
    }
    // §7 priority: anything below is more important than a promotion.
    if (context.paymentRecoveryActive) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.paymentRecoveryActive);
    }
    if (context.deepLinkActive) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.deepLinkActive);
    }
    if (context.hasCriticalBooking) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.criticalBookingActive);
    }
    if (context.higherPriorityModalOpen) {
      return const CampaignDecision.suppressed(
          CampaignSuppression.higherPriorityModal);
    }

    return const CampaignDecision.eligible();
  }

  /// Inclusive dotted-numeric version comparison.
  ///
  /// Compares component-wise rather than lexically: "1.10.0" is newer than
  /// "1.9.0", which a string comparison gets backwards. Unparseable bounds are
  /// ignored rather than treated as blocking, so a malformed Remote Config
  /// value cannot silently disable the campaign everywhere.
  static bool _appVersionInRange(String version, String? min, String? max) {
    if (min != null && min.isNotEmpty) {
      final c = compareVersions(version, min);
      if (c != null && c < 0) return false;
    }
    if (max != null && max.isNotEmpty) {
      final c = compareVersions(version, max);
      if (c != null && c > 0) return false;
    }
    return true;
  }

  /// Returns <0, 0, >0, or null when either side is not dotted-numeric.
  static int? compareVersions(String a, String b) {
    List<int>? parse(String s) {
      final core = s.split('+').first.split('-').first.trim();
      if (core.isEmpty) return null;
      final parts = core.split('.');
      final out = <int>[];
      for (final p in parts) {
        final n = int.tryParse(p);
        if (n == null) return null;
        out.add(n);
      }
      return out;
    }

    final pa = parse(a);
    final pb = parse(b);
    if (pa == null || pb == null) return null;
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    return 0;
  }
}
