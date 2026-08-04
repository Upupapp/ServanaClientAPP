import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:client/modules/homepage/application/home_campaign_eligibility.dart';
import 'package:client/modules/homepage/data/home_campaign_remote_config.dart';
import 'package:client/modules/homepage/data/home_campaign_repository.dart';
import 'package:client/modules/homepage/domain/home_campaign_state.dart';
import 'package:client/modules/homepage/domain/home_promotion.dart';

/// Owns campaign eligibility, frequency capping and presentation scheduling
/// (LAUNCHBANNER+ §5–§8, §23, §26).
///
/// Held as a singleton so the once-per-session flag genuinely means the
/// session. Home lives in a `StatefulShellRoute.indexedStack` branch, so its
/// `initState` already runs once per shell lifetime — but a controller owned by
/// the widget would still reset whenever the shell was rebuilt, and "once per
/// session" would quietly become "once per Home construction".
///
/// This replaces the pre-LAUNCHBANNER+ controller, which stored a single bool
/// per campaign. A bool can express "dismissed" and nothing else: no impression
/// count, no cooldown, and no distinction between a customer who engaged and
/// one who declined. Its account-scoped key scheme was sound and survives in
/// [HomeCampaignRepository].
class HomeCampaignController {
  HomeCampaignController({
    HomeCampaignRepository? repository,
    HomeCampaignRemoteConfig? remoteConfig,
  })  : _repo = repository ?? HomeCampaignRepository(),
        _remote = remoteConfig ?? HomeCampaignRemoteConfig();

  final HomeCampaignRepository _repo;
  final HomeCampaignRemoteConfig _remote;

  /// Non-persistent, per-app-session (§26). Reset only by [resetSessionState].
  bool _shownThisSession = false;

  /// Guards against two callers racing into presentation.
  ///
  /// Claimed BEFORE the first `await`. `ConsentGateService` does exactly this
  /// and documents why; the previous controller did not, and awaited
  /// `SharedPreferences.getInstance()` with the gate still open — two
  /// post-frame callbacks in the same frame could both pass it.
  bool _presentationClaimed = false;

  Timer? _pendingPresentation;

  bool get shownThisSession => _shownThisSession;
  bool get hasPendingPresentation => _pendingPresentation?.isActive ?? false;

  /// Whether campaign configuration has ever been obtained (§30).
  bool get hasConfiguration => _remote.hasConfiguration;

  /// Fetches Remote Config. Safe to call repeatedly; never throws.
  Future<void> initialise(HomeCampaign campaign) async {
    await _remote.initialise(fallback: campaign);
  }

  /// Applies Remote Config overrides to the compiled-in campaign (§21).
  HomeCampaign resolve(HomeCampaign campaign) => _remote.apply(campaign);

  Future<HomeCampaignState?> stateFor(
    HomeCampaign campaign, {
    required String? accountId,
  }) =>
      _repo.read(
        campaignId: campaign.id,
        campaignVersion: campaign.version,
        accountId: accountId,
      );

  /// Evaluates every §5/§6 rule against persisted state.
  Future<CampaignDecision> evaluate({
    required HomeCampaign campaign,
    required CampaignEvaluationContext context,
  }) async {
    final resolved = resolve(campaign);
    final state = await stateFor(resolved, accountId: context.accountId);
    return HomeCampaignEligibility.evaluate(
      campaign: resolved,
      state: state,
      context: context,
    );
  }

  /// Schedules [present] after [delay], provided [stillEligible] holds when the
  /// timer fires (§8).
  ///
  /// The re-check is the whole point. Between scheduling and firing the
  /// customer may have navigated away, backgrounded the app, opened another
  /// modal or followed a deep link — §8 lists every one as a cancellation
  /// trigger, and an eligibility decision taken 800 ms ago is a stale claim
  /// about the world.
  ///
  /// Returns false when a presentation is already claimed or pending, so a
  /// second caller cannot queue a duplicate.
  bool schedulePresentation({
    required Duration delay,
    required bool Function() stillEligible,
    required void Function() present,
  }) {
    if (_presentationClaimed || _shownThisSession) return false;
    if (_pendingPresentation?.isActive ?? false) return false;

    _presentationClaimed = true;
    _pendingPresentation = Timer(delay, () {
      _pendingPresentation = null;
      if (!stillEligible()) {
        // Release the claim: nothing was shown, so a later eligible moment in
        // this same session may still legitimately present.
        _presentationClaimed = false;
        return;
      }
      present();
    });
    return true;
  }

  /// Cancels any pending presentation and releases the claim (§8, §25).
  ///
  /// Must be called from Home's `dispose`, on logout and on account switch. A
  /// Timer holds its closure alive independently of the widget tree, so an
  /// uncancelled one fires into a disposed context.
  void cancelPendingPresentation() {
    _pendingPresentation?.cancel();
    _pendingPresentation = null;
    _presentationClaimed = false;
  }

  /// Records a VERIFIED impression — the campaign actually rendered (§28).
  ///
  /// Never call from scheduling, precaching or a failed image load. The
  /// impression cap is the customer's protection against being interrupted
  /// three times; spending it on a modal they never saw is a silent theft of
  /// that budget.
  Future<HomeCampaignState> recordImpression({
    required HomeCampaign campaign,
    required String? accountId,
    required DateTime now,
  }) async {
    _shownThisSession = true;
    final next = (await _existing(campaign, accountId)).withImpression(now);
    await _repo.write(next, accountId: accountId);
    return next;
  }

  /// The customer chose the CTA — complete, never show this version again (§6).
  Future<void> recordCtaCompleted({
    required HomeCampaign campaign,
    required String? accountId,
    required DateTime now,
  }) async {
    final existing = await _existing(campaign, accountId);
    await _repo.write(existing.copyWith(completedAt: now),
        accountId: accountId);
    _presentationClaimed = false;
  }

  /// The customer chose Close — permanent dismissal of this version (§6).
  ///
  /// Deliberately distinct from completion. Both suppress the campaign forever,
  /// but one means "engaged" and the other "declined"; collapsing them destroys
  /// the only signal that says whether the campaign worked.
  Future<void> recordPermanentDismissal({
    required HomeCampaign campaign,
    required String? accountId,
    required DateTime now,
  }) async {
    final existing = await _existing(campaign, accountId);
    await _repo.write(existing.copyWith(permanentlyDismissedAt: now),
        accountId: accountId);
    _presentationClaimed = false;
  }

  /// "Remind me later", system Back, or barrier dismissal (§6, §18).
  ///
  /// Back and barrier taps are NOT permanent rejections. A customer who
  /// reflexively swipes back has decided nothing, and recording that as "never
  /// again" silently destroys reach.
  Future<void> recordRemindLater({
    required HomeCampaign campaign,
    required String? accountId,
    required DateTime now,
  }) async {
    final existing = await _existing(campaign, accountId);
    await _repo.write(
      existing.copyWith(remindAfter: now.add(campaign.remindLaterCooldown)),
      accountId: accountId,
    );
    _presentationClaimed = false;
  }

  Future<HomeCampaignState> _existing(
      HomeCampaign campaign, String? accountId) async {
    return await stateFor(campaign, accountId: accountId) ??
        HomeCampaignState(
          campaignId: campaign.id,
          campaignVersion: campaign.version,
        );
  }

  /// Resets in-memory session state (§25, §26).
  ///
  /// Persisted history is deliberately untouched: a customer must not be able
  /// to clear a permanent dismissal by signing out and back in.
  void resetSessionState() {
    cancelPendingPresentation();
    _shownThisSession = false;
  }

  /// Removes single-bool campaign keys written before LAUNCHBANNER+.
  ///
  /// The old scheme cannot be migrated with any fidelity — a bare `true` says
  /// nothing about impressions or cooldowns. Deleting is honest; keeping it
  /// would be dead storage that looks meaningful to the next reader.
  static Future<void> purgeLegacyKeys(SharedPreferences prefs) async {
    const legacyPrefix = 'home_campaign_dismissed_';
    final keys =
        prefs.getKeys().where((k) => k.startsWith(legacyPrefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
