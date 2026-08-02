# HOME_LAUNCH_CAMPAIGN_REPORT

LAUNCHBANNER+ V1 §40. Executed results only — anything not run is listed under
[Not verified](#not-verified) rather than implied.

---

## 1. Sweep (§2)

Nine parallel inspections of Home, auth, modals, the existing campaign system,
routing, persistence, Remote Config, analytics and accessibility.

Three findings changed the design:

**The existing campaign system was dead code.** `HomeCampaignController` and
`showCampaignSpotlight` had zero references in `lib/` — only tests. Home carried
a tombstone comment (`home_screen.dart:103`) recording that the previous
overlay "interrupted every launch with a full-screen modal a second after Home
appeared, before the customer had read anything", and that the machinery was
"left in place so a future campaign can use them deliberately". §2 forbids
building a competing system, so this is an extension of that code, not a
replacement — and its removal also clears the dead code.

**Home already opens a modal on the same frame.** `_maybeShowConsentGate` runs
in a post-frame callback from `initState`. Left alone, the campaign would have
raced it and two modals could target the same first frame. The campaign now
`await`s the consent gate before evaluating.

**The old controller had a double-show race.** `ConsentGateService` sets its
`_shown` guard *before* its first `await`, with a comment explaining why.
`HomeCampaignController.isSpotlightEligible` awaited `SharedPreferences
.getInstance()` with its gate still open. The new controller claims the
presentation before any suspension point.

## 2. Asset (§10, §11)

| | bytes | note |
|---|---:|---|
| Source PNG (941×1672) | 1,846,186 | preserved at `assets_src/campaigns/`, **not** bundled |
| PNG re-encode, lossless | 1,759,777 | 95% — not worth shipping |
| WebP lossless | 1,400,388 | 76%, pixel-identical |
| **WebP q95 — shipped** | **293,770** | **16% of source, 84% saved** |

Quality was verified rather than assumed. Global PSNR is dominated by large flat
gradients, so the six smallest-text regions were scored individually; the worst
was the footer line at **36.7 dB**. That region was then rendered at 3×
nearest-neighbour against the original and compared visually: glyph edges,
accent blues and background gradient are indistinguishable.

Shipped as `.webp`, not the `.png` filename §10 names — the format change is
what produces the saving, and §11 explicitly permits derivatives.

## 3. Architecture

```
domain/home_campaign_state.dart          impressions, cooldown, completion
domain/home_promotion.dart               HomeCampaign extended with lifecycle
data/home_campaign_repository.dart       account-scoped persistence
data/home_campaign_remote_config.dart    Remote Config overlay + kill switch
application/home_campaign_eligibility.dart   pure §5/§6 rules
presentation/controllers/home_campaign_controller.dart   scheduling + state
presentation/widgets/servana_launch_benefits_modal.dart
presentation/widgets/servana_launch_benefits_accessible_view.dart
```

Eligibility is a **pure function** taking `now` as an argument. §6 defines
behaviour in elapsed days; a rule that reads the wall clock internally can only
be tested by waiting a week.

## 4. Frequency and eligibility (§5, §6)

Implemented exactly as specified: first eligible authenticated Home visit, max
3 impressions per customer per campaign version, 1 per session, 7-day
remind-later cooldown, 7-day minimum spacing, CTA completes, Close permanently
dismisses, Back and barrier map to remind-later.

Suppression reasons are a closed vocabulary (19 values) so the funnel stays
readable. Permanent reasons are checked before transient ones: a customer who
completed the campaign *and* is in cooldown reports `already_completed`, since
`cooldown_active` would imply they will see it again.

## 5. Priority (§7)

`payment_recovery` > `deep_link` > `critical_booking` > `higher_priority_modal`.
The consent gate is sequenced ahead of the campaign by `await`, not by ordering
luck.

## 6. Account scoping (§23, §38)

`home_campaign_state/acct_<customerId>/<campaignId>/v<version>`

A missing account id is refused outright rather than written to the guest
scope — that would let the next signed-in customer inherit it. History
deliberately survives logout, or a customer could clear a permanent dismissal
by signing out and back in.

## 7. Remote Config (§21, §22)

`firebase_remote_config ^5.1.3` added. Six Firebase plugins were already
present, so no new initialisation or Gradle configuration was required.

Ships with `enabled: false` per §21's production default — the campaign is dark
until switched on remotely after release-candidate testing.

Guarded by `kIsWeb`, because `main.dart` initialises Firebase inside
`if (!kIsWeb)` and any Firebase singleton throws on web. Zero or negative
numeric parameters are treated as unset, so a console default of `0` cannot
silently cap impressions at zero.

**16 KB alignment re-verified after the dependency was added**: all four arm64
libraries still 16 KB aligned. Adding a Firebase plugin mid-release could have
reintroduced the Play blocker fixed earlier the same day; it did not.

## 8. Two defects found during implementation

Both were found by tests, both would have shipped, and both are the kind that
survive review because the control *looks* correct.

**The CTA was not tappable.** `GestureDetector` defaults to
`HitTestBehavior.deferToChild`, and the hotspot's child was an
`AnimatedContainer` with a null colour — a box that paints nothing is not
hit-testable. Every tap fell through to the modal barrier and *dismissed* the
campaign instead of opening services. §41 rates this High. Rebuilt on
`Material` + `InkWell` over a transparent `ColoredBox`, which paints and
therefore receives pointers.

**The CTA rendered below the fold on a standard phone.** The card was wrapped
in a `SingleChildScrollView`; because the creative is 941×1672, the content
exceeded the viewport on a 390×844 device — measured at **480pt of viewport
against 622pt of artwork** — putting the "Explore Services" pill 60pt
off-screen. A screenshot of the modal's top looks perfect. The artwork now
scales to fit via `AspectRatio`'s height constraint; §32 wants scrolling as a
fallback for short devices, not the normal case.

Regression tests assert the CTA rect stays inside the viewport at 320, 360, 390
and 430 widths, and that its height never drops below the 56pt §13 requires.

## 9. Analytics (§27, §28)

Eight events in `home_events.dart`. Four new property keys registered in
`AnalyticsKeys` **and** the privacy allowlist: `campaign_id`,
`campaign_version`, `impression_number`, `suppression_reason`.

`platform` and `app_version` are injected by `AnalyticsContextProvider` and are
deliberately **not** declared on these events — declaring them would duplicate
them on every row.

No customer identifier, booking id, address or search text is emitted.
Impressions fire only after the campaign has rendered.

## 10. Tests executed

| Suite | Result |
|---|---|
| `home_campaign_controller_test.dart` | **42 passed** |
| `launch_banner_modal_test.dart` | **30 passed** |
| Full suite | **1167 passed**, 6 skipped |
| `dart format --set-exit-if-changed .` | exit 0 |
| `flutter analyze --no-fatal-infos` | exit 0 — 0 warnings, 0 errors |

Coverage includes: first eligible sign-in, unauthenticated, unresolved account,
Home not visible, disabled, not started, expired, config never obtained,
app-version bounds (including numeric-vs-lexical comparison and an unparseable
bound), permanent-before-transient reason ordering, CTA completion, Close,
3-impression cap, cooldown expiry, minimum spacing, once-per-session, all four
§7 priorities, account isolation (§38), campaign-version independence, corrupt
persisted state, impression clearing a spent cooldown, scheduling, cancellation,
duplicate-schedule refusal, claim release after a lapsed presentation, artwork
rendering, image-failure fallback, large-text switchover, all outcomes, semantic
labels, touch-target sizes, five viewport sizes, and reduced motion.

## 11. Not verified

- **Physical device.** No Android or iOS hardware attached. Real haptics, real
  TalkBack/VoiceOver, and true edge-to-edge insets on a notched device are not
  claimable from a widget test.
- **iOS build.** No macOS host. §43.43 cannot be marked done.
- **Live Remote Config round-trip.** The parameters do not yet exist in the
  Firebase console, so the kill switch has been exercised only through injected
  values, not a real fetch.
- **On-device visual check of the campaign.** The modal has not been seen on the
  emulator; the campaign ships disabled, so it cannot appear until switched on.
- **Cross-device state (§24).** No backend endpoint for campaign state exists —
  `servana_api` exposes nothing resembling onboarding or campaign persistence.
  Frequency capping is therefore **device-specific**: a customer who dismisses
  on their phone will see the campaign again on a tablet. No endpoint was
  invented.

## 12. Before enabling

1. Create the ten `home_launch_banner_*` parameters in Remote Config with the
   §21 defaults, `enabled` **false**.
2. Verify the modal on a physical device at 100% and 200% text.
3. Confirm impression, CTA and dismissal events arrive in Firebase.
4. Set `home_launch_banner_enabled` to `true` for a limited audience first.

The kill switch is the reason this is safe to ship dark: if the creative is
wrong or the timing is bad, it is a console toggle rather than an app update.
