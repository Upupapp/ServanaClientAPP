/// LAUNCHBANNER+ §37 — eligibility, frequency capping and account scoping.
///
/// Every §6 frequency rule is expressed in elapsed days, so the eligibility
/// logic takes `now` as an argument rather than reading the clock. That is what
/// makes "suppressed for 7 days, then eligible again" testable in milliseconds
/// instead of a week.
///
/// This replaces the pre-LAUNCHBANNER+ test. The old controller stored one bool
/// per campaign and could express only "dismissed", so its assertions have no
/// counterpart in the new model — there was nothing to port.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:client/modules/homepage/application/home_campaign_eligibility.dart';
import 'package:client/modules/homepage/data/home_campaign_repository.dart';
import 'package:client/modules/homepage/domain/home_campaign_state.dart';
import 'package:client/modules/homepage/domain/home_promotion.dart';
import 'package:client/modules/homepage/presentation/controllers/home_campaign_controller.dart';

final _t0 = DateTime.utc(2026, 8, 2, 12);

HomeCampaign _campaign({
  bool enabled = true,
  DateTime? startsAt,
  DateTime? endsAt,
  int maxImpressions = 3,
  Duration cooldown = const Duration(days: 7),
  Duration minGap = const Duration(days: 7),
  String version = '1',
  String? minAppVersion,
  String? maxAppVersion,
}) {
  return HomeCampaign(
    id: 'servana_launch_benefits',
    version: version,
    title: 'Everything you need, all in one app',
    subtitle: 'Browse services, choose your schedule.',
    ctaLabel: 'Explore Services',
    ctaTarget: const HomeTargetSearch(),
    motionPreset: HomeMotionPreset.productReveal,
    enabled: enabled,
    startsAt: startsAt,
    endsAt: endsAt,
    maxImpressions: maxImpressions,
    remindLaterCooldown: cooldown,
    minTimeBetweenImpressions: minGap,
    minAppVersion: minAppVersion,
    maxAppVersion: maxAppVersion,
  );
}

CampaignEvaluationContext _ctx({
  DateTime? now,
  bool isAuthenticated = true,
  String? accountId = 'CUST_A',
  String appVersion = '1.0.0',
  bool hasConfiguration = true,
  bool shownThisSession = false,
  bool homeVisible = true,
  bool higherPriorityModalOpen = false,
  bool deepLinkActive = false,
  bool paymentRecoveryActive = false,
  bool hasCriticalBooking = false,
}) {
  return CampaignEvaluationContext(
    now: now ?? _t0,
    isAuthenticated: isAuthenticated,
    accountId: accountId,
    appVersion: appVersion,
    hasConfiguration: hasConfiguration,
    shownThisSession: shownThisSession,
    homeVisible: homeVisible,
    higherPriorityModalOpen: higherPriorityModalOpen,
    deepLinkActive: deepLinkActive,
    paymentRecoveryActive: paymentRecoveryActive,
    hasCriticalBooking: hasCriticalBooking,
  );
}

CampaignDecision _decide({
  HomeCampaign? campaign,
  HomeCampaignState? state,
  CampaignEvaluationContext? context,
}) {
  return HomeCampaignEligibility.evaluate(
    campaign: campaign ?? _campaign(),
    state: state,
    context: context ?? _ctx(),
  );
}

HomeCampaignState _state({
  int impressions = 0,
  DateTime? lastShownAt,
  DateTime? remindAfter,
  DateTime? completedAt,
  DateTime? dismissedAt,
  String version = '1',
}) {
  return HomeCampaignState(
    campaignId: 'servana_launch_benefits',
    campaignVersion: version,
    impressionCount: impressions,
    firstShownAt: lastShownAt,
    lastShownAt: lastShownAt,
    remindAfter: remindAfter,
    completedAt: completedAt,
    permanentlyDismissedAt: dismissedAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('§5 first eligible sign-in', () {
    test('a customer with no history is eligible', () {
      expect(_decide().eligible, isTrue);
    });

    test('an unauthenticated customer is never eligible', () {
      final d = _decide(context: _ctx(isAuthenticated: false));
      expect(d.eligible, isFalse);
      expect(d.suppression, CampaignSuppression.notAuthenticated);
    });

    test('an unresolved account is refused, not written to the guest scope',
        () {
      // Writing under `guest` would let the next signed-in customer inherit it.
      expect(_decide(context: _ctx(accountId: null)).suppression,
          CampaignSuppression.accountUnresolved);
    });

    test('Home not visible suppresses', () {
      expect(_decide(context: _ctx(homeVisible: false)).suppression,
          CampaignSuppression.homeNotVisible);
    });
  });

  group('§21 campaign configuration', () {
    test('disabled campaign is suppressed', () {
      expect(_decide(campaign: _campaign(enabled: false)).suppression,
          CampaignSuppression.campaignDisabled);
    });

    test('campaign that has not started is suppressed', () {
      final c = _campaign(startsAt: _t0.add(const Duration(days: 1)));
      expect(_decide(campaign: c).suppression,
          CampaignSuppression.campaignNotStarted);
    });

    test('expired campaign is suppressed', () {
      final c = _campaign(endsAt: _t0.subtract(const Duration(days: 1)));
      expect(_decide(campaign: c).suppression,
          CampaignSuppression.campaignExpired);
    });

    test('§30 config never obtained suppresses, because expiry is unknowable',
        () {
      expect(_decide(context: _ctx(hasConfiguration: false)).suppression,
          CampaignSuppression.configurationUnavailable);
    });
  });

  group('app-version targeting', () {
    test('below minimum is suppressed', () {
      expect(_decide(campaign: _campaign(minAppVersion: '2.0.0')).suppression,
          CampaignSuppression.appVersionUnsupported);
    });

    test('above maximum is suppressed', () {
      expect(_decide(campaign: _campaign(maxAppVersion: '0.9.0')).suppression,
          CampaignSuppression.appVersionUnsupported);
    });

    test('inside the range is eligible', () {
      final c = _campaign(minAppVersion: '1.0.0', maxAppVersion: '2.0.0');
      expect(_decide(campaign: c).eligible, isTrue);
    });

    test('compares numerically, not lexically', () {
      // The bug this guards: as strings "1.10.0" < "1.9.0", which would exclude
      // every customer on a double-digit minor version.
      expect(HomeCampaignEligibility.compareVersions('1.10.0', '1.9.0'),
          greaterThan(0));
      expect(HomeCampaignEligibility.compareVersions('1.0.0', '1.0'), 0);
    });

    test('an unparseable bound is ignored rather than blocking everyone', () {
      // A malformed Remote Config value must not silently kill the campaign.
      expect(
          _decide(campaign: _campaign(minAppVersion: 'not-a-version')).eligible,
          isTrue);
    });
  });

  group('§6 frequency policy', () {
    test('permanent reasons outrank transient ones in the reported reason', () {
      // A completed customer who is also in cooldown must report
      // already_completed — cooldown_active would imply they see it again.
      final s = _state(
        completedAt: _t0,
        remindAfter: _t0.add(const Duration(days: 3)),
      );
      expect(
          _decide(state: s).suppression, CampaignSuppression.alreadyCompleted);
    });

    test('CTA completion suppresses forever', () {
      expect(_decide(state: _state(completedAt: _t0)).suppression,
          CampaignSuppression.alreadyCompleted);
    });

    test('Close suppresses forever', () {
      expect(_decide(state: _state(dismissedAt: _t0)).suppression,
          CampaignSuppression.permanentlyDismissed);
    });

    test('three impressions is the cap', () {
      expect(_decide(state: _state(impressions: 3)).suppression,
          CampaignSuppression.maxImpressions);
    });

    test('two impressions still allows a third', () {
      final s = _state(
        impressions: 2,
        lastShownAt: _t0.subtract(const Duration(days: 8)),
      );
      expect(_decide(state: s).eligible, isTrue);
    });

    test('remind-later suppresses inside the 7-day window', () {
      final s =
          _state(impressions: 1, remindAfter: _t0.add(const Duration(days: 7)));
      expect(_decide(state: s).suppression, CampaignSuppression.cooldownActive);
    });

    test('remind-later releases after the window elapses', () {
      final remindAfter = _t0.add(const Duration(days: 7));
      final s = _state(impressions: 1, remindAfter: remindAfter);
      final after = remindAfter.add(const Duration(minutes: 1));
      expect(_decide(state: s, context: _ctx(now: after)).eligible, isTrue);
    });

    test('minimum spacing applies even without a remind-later', () {
      final s = _state(
          impressions: 1, lastShownAt: _t0.subtract(const Duration(days: 2)));
      expect(_decide(state: s).suppression,
          CampaignSuppression.minIntervalNotElapsed);
    });

    test('once per session', () {
      expect(_decide(context: _ctx(shownThisSession: true)).suppression,
          CampaignSuppression.shownThisSession);
    });
  });

  group('§7 higher-priority experiences win', () {
    test('payment recovery', () {
      expect(_decide(context: _ctx(paymentRecoveryActive: true)).suppression,
          CampaignSuppression.paymentRecoveryActive);
    });

    test('deep link', () {
      expect(_decide(context: _ctx(deepLinkActive: true)).suppression,
          CampaignSuppression.deepLinkActive);
    });

    test('critical booking', () {
      expect(_decide(context: _ctx(hasCriticalBooking: true)).suppression,
          CampaignSuppression.criticalBookingActive);
    });

    test('another modal already open', () {
      expect(_decide(context: _ctx(higherPriorityModalOpen: true)).suppression,
          CampaignSuppression.higherPriorityModal);
    });

    test('payment recovery outranks a deep link', () {
      final d = _decide(
          context: _ctx(paymentRecoveryActive: true, deepLinkActive: true));
      expect(d.suppression, CampaignSuppression.paymentRecoveryActive);
    });
  });

  group('§23 account scoping', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keys embed account AND campaign version', () {
      final a = HomeCampaignRepository.keyFor(
          campaignId: 'c', campaignVersion: '1', accountId: 'A');
      final b = HomeCampaignRepository.keyFor(
          campaignId: 'c', campaignVersion: '1', accountId: 'B');
      final v2 = HomeCampaignRepository.keyFor(
          campaignId: 'c', campaignVersion: '2', accountId: 'A');
      expect(a, isNot(b));
      expect(a, isNot(v2));
      expect(a, contains('acct_A'));
    });

    test('a null account uses the guest scope, never a bare key', () {
      final k = HomeCampaignRepository.keyFor(
          campaignId: 'c', campaignVersion: '1', accountId: null);
      expect(k, contains('guest'));
      expect(k, isNot(contains('acct_')));
    });

    test('§38 Customer A dismissal does not affect Customer B', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = HomeCampaignRepository(prefs: prefs);
      final campaign = _campaign();

      await repo.write(_state(dismissedAt: _t0), accountId: 'CUST_A');

      final a = await repo.read(
          campaignId: campaign.id,
          campaignVersion: campaign.version,
          accountId: 'CUST_A');
      final b = await repo.read(
          campaignId: campaign.id,
          campaignVersion: campaign.version,
          accountId: 'CUST_B');

      expect(a?.permanentlyDismissedAt, isNotNull);
      expect(b, isNull, reason: 'Customer B must start with no history');
      expect(_decide(state: a).suppression,
          CampaignSuppression.permanentlyDismissed);
      expect(_decide(state: b).eligible, isTrue);
    });

    test('a new campaign version becomes eligible independently', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = HomeCampaignRepository(prefs: prefs);
      await repo.write(_state(dismissedAt: _t0), accountId: 'CUST_A');

      final v2 = await repo.read(
          campaignId: 'servana_launch_benefits',
          campaignVersion: '2',
          accountId: 'CUST_A');
      expect(v2, isNull);
      expect(_decide(campaign: _campaign(version: '2'), state: v2).eligible,
          isTrue);
    });

    test('corrupt persisted state degrades to no-history, not a crash',
        () async {
      SharedPreferences.setMockInitialValues({
        HomeCampaignRepository.keyFor(
          campaignId: 'servana_launch_benefits',
          campaignVersion: '1',
          accountId: 'CUST_A',
        ): 'not json at all',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = HomeCampaignRepository(prefs: prefs);
      final read = await repo.read(
          campaignId: 'servana_launch_benefits',
          campaignVersion: '1',
          accountId: 'CUST_A');
      expect(read, isNull);
    });
  });

  group('controller state transitions', () {
    late HomeCampaignController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      controller = HomeCampaignController(
          repository: HomeCampaignRepository(prefs: prefs));
    });

    test('an impression increments the count and stamps both timestamps',
        () async {
      final s = await controller.recordImpression(
          campaign: _campaign(), accountId: 'CUST_A', now: _t0);
      expect(s.impressionCount, 1);
      expect(s.firstShownAt, _t0);
      expect(s.lastShownAt, _t0);
      expect(controller.shownThisSession, isTrue);
    });

    test('an impression clears a spent remind-later', () async {
      final c = _campaign();
      await controller.recordRemindLater(
          campaign: c, accountId: 'CUST_A', now: _t0);
      final later = _t0.add(const Duration(days: 8));
      final s = await controller.recordImpression(
          campaign: c, accountId: 'CUST_A', now: later);
      expect(s.remindAfter, isNull,
          reason: 'a stale cooldown would suppress the next eligible check');
    });

    test('remind-later sets the cooldown and is not a permanent rejection',
        () async {
      final c = _campaign(cooldown: const Duration(days: 7));
      await controller.recordRemindLater(
          campaign: c, accountId: 'CUST_A', now: _t0);
      final s = await controller.stateFor(c, accountId: 'CUST_A');
      expect(s?.remindAfter, _t0.add(const Duration(days: 7)));
      expect(s?.permanentlyDismissedAt, isNull);
    });

    test('CTA completion and Close are stored distinctly', () async {
      final c = _campaign();
      await controller.recordCtaCompleted(
          campaign: c, accountId: 'CUST_A', now: _t0);
      final done = await controller.stateFor(c, accountId: 'CUST_A');
      expect(done?.completedAt, isNotNull);
      expect(done?.permanentlyDismissedAt, isNull);

      await controller.recordPermanentDismissal(
          campaign: c, accountId: 'CUST_B', now: _t0);
      final closed = await controller.stateFor(c, accountId: 'CUST_B');
      expect(closed?.permanentlyDismissedAt, isNotNull);
      expect(closed?.completedAt, isNull);
    });

    test('resetSessionState clears the session flag but not history', () async {
      final c = _campaign();
      await controller.recordImpression(
          campaign: c, accountId: 'CUST_A', now: _t0);
      controller.resetSessionState();
      expect(controller.shownThisSession, isFalse);
      final s = await controller.stateFor(c, accountId: 'CUST_A');
      expect(s?.impressionCount, 1,
          reason: 'signing out must not reset frequency capping');
    });
  });

  group('§8 scheduled presentation', () {
    late HomeCampaignController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      controller = HomeCampaignController(
          repository: HomeCampaignRepository(prefs: prefs));
    });

    test('presents when still eligible at fire time', () async {
      var shown = false;
      final scheduled = controller.schedulePresentation(
        delay: const Duration(milliseconds: 10),
        stillEligible: () => true,
        present: () => shown = true,
      );
      expect(scheduled, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(shown, isTrue);
    });

    test('does NOT present when eligibility lapsed during the delay', () async {
      // The customer navigated away, or another modal opened.
      var shown = false;
      controller.schedulePresentation(
        delay: const Duration(milliseconds: 10),
        stillEligible: () => false,
        present: () => shown = true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(shown, isFalse);
    });

    test('cancellation stops a pending presentation', () async {
      var shown = false;
      controller.schedulePresentation(
        delay: const Duration(milliseconds: 30),
        stillEligible: () => true,
        present: () => shown = true,
      );
      controller.cancelPendingPresentation();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(shown, isFalse);
      expect(controller.hasPendingPresentation, isFalse);
    });

    test('a second scheduler cannot queue a duplicate', () {
      controller.schedulePresentation(
        delay: const Duration(milliseconds: 50),
        stillEligible: () => true,
        present: () {},
      );
      final second = controller.schedulePresentation(
        delay: const Duration(milliseconds: 50),
        stillEligible: () => true,
        present: () {},
      );
      expect(second, isFalse,
          reason: 'the claim is taken before any await, so a racing '
              'post-frame callback cannot also pass');
      controller.cancelPendingPresentation();
    });

    test('a lapsed presentation releases the claim for a later attempt',
        () async {
      controller.schedulePresentation(
        delay: const Duration(milliseconds: 10),
        stillEligible: () => false,
        present: () {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      var shown = false;
      final again = controller.schedulePresentation(
        delay: const Duration(milliseconds: 10),
        stillEligible: () => true,
        present: () => shown = true,
      );
      expect(again, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(shown, isTrue);
    });
  });
}
