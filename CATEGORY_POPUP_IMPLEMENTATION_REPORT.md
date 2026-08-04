# Category Campaign Popups — Implementation Report

Covers **HAIRNAILSPOPUP+ V1** and **BEAUTYWELLNESSPOPUP+ V1**. They were
implemented together because they are the same feature with two creatives; one
reusable component serves both, which is what §5 of each command asks for.

Date: 2026-08-04 · Branch: `main` · Base: `e874262`

---

## 1. What the sweep found, and where the commands were wrong

Both commands assume an existing popup to replace. **There was none.**

| Question | Verified answer | Source |
|---|---|---|
| Category enum | `ServiceCategoryId.beautyWellness` / `.hairAndNails` | `service_category_config.dart:6-7` |
| Category keys | `beauty_wellness`, `hair_nails` | `main_router.dart:74-75` |
| Config | `CategoryRegistry.beautyWellness` / `.hairAndNails` | `service_category_config.dart:49,60` |
| Canonical routes | `BeautyWellnessScreen.routeName`, `HairNailsScreen.routeName` | screen files |
| Destination | `CategoryExperienceScreen(categoryId: …)` | `main_router.dart:272-279` |
| Tap handler | `_handleCategoryTap(String key)` | `home_screen.dart:315` |
| Prior behaviour | **`context.pushNamed(...)` — immediate navigation, no modal** | same |
| Haptics | `AppHaptics.{selection,medium,light,categoryEntry,…}` | `app_haptics.dart` |
| Guard precedent | `HomeCampaignController._presentationClaimed` | `home_campaign_controller.dart:102` |
| Modal precedent | `ServanaLaunchBenefitsModal` | `servana_launch_benefits_modal.dart` |

### The "plain blue popup" is not a popup

Both commands describe a blue panel with decorative circles, a text heading and
an *Explore now* button, and instruct that it be removed. That is
`category_reveal_overlay.dart` — a **full-screen reveal transition mounted
inside the category screen, after navigation**. It is not a modal, it is not
shown on tap, and it belongs to the category-delight feature.

**It has not been touched.** Verified: zero changes under
`lib/common/presentation/category_delight/`. If it should also go, that is a
separate change and should be asked for explicitly.

Consequence: §4 of both commands ("remove the old popup") had nothing to
remove, and §28/§30's "the old popup does not appear" is satisfied vacuously.
This work **inserts new behaviour between tap and navigation** rather than
replacing anything.

---

## 2. Assets

| | Beauty & Wellness | Hair & Nails |
|---|---|---|
| Path | `assets/images/categories/beauty_wellness_popup_v1.png` | `assets/images/categories/hair_nails_popup_v1.png` |
| Spec said | 941 × 1672 | **928 × 1648** |
| **Actually is** | **941 × 1672** | **941 × 1672** |
| Size | 1.97 MB | 1.91 MB |

### Two asset defects found before they shipped

**The Hair & Nails spec states the wrong dimensions.** It says 928 × 1648; the
file is 941 × 1672. `AspectRatio` is therefore driven from the **real file**
(`assetWidth / assetHeight` in the registry). Using the spec'd ratio would inset
the artwork inside its own box by ~0.05%, and since the CTA overlay is
positioned against that box, the touch target would drift off the drawn button.

**`BEAUTY_WELLNESS_POPUP_V1.png` was delivered uppercase.** Windows is
case-insensitive, so it would have resolved correctly through every minute of
development and **failed on both iOS and Android**, which are case-sensitive.
Renamed to lowercase; `category_campaign_popup_test.dart` now fails if any
registered asset name is not lowercase, and if on-disk casing does not match
the registry exactly.

`pubspec.yaml` declares `assets/images/categories/` as a directory, so a new
creative ships by being dropped in.

---

## 3. Architecture

```
CategoryCampaignRegistry      per-creative config: asset, real dimensions,
                              measured CTA rect, semantics, labels
        │
CategoryCampaignCoordinator   single-instance guard + analytics funnel
        │                     returns bool: "did they choose the CTA?"
        │
ServanaCategoryCampaignPopup  modal shell: ratio, CTA overlay, close,
        │                     motion, reduced motion, Escape, PopScope
        │
        ├── artwork path      Image.asset(BoxFit.contain) + real button overlay
        └── fallback path     CategoryCampaignAccessibleView (native widgets)
```

**The popup performs no navigation and the coordinator performs no navigation.**
`_handleCategoryTap` in `home_screen.dart` decides, exactly as it did before, so
no second route or category id was introduced.

A category with no registry entry keeps its previous behaviour: immediate
navigation. `massage` and `aircon` are unchanged and tested as such.

---

## 4. CTA hit target — measured, not estimated

The pill was located by scanning the real PNG for saturated warm pixels against
the dark backdrop.

| | Beauty & Wellness | Hair & Nails |
|---|---|---|
| Pixels | x 133–806, y 1492–1585 | x 119–816, y 1503–1598 |
| `left` | 0.1413 | 0.1265 |
| `top` | 0.8923 | 0.8989 |
| `width` | 0.7163 | 0.7418 |
| `height` | 0.0562 | 0.0574 |

### The proportional target cannot meet 48 dp

At ~5.7% of artboard height, the drawn pill renders:

| Card width | Rendered height | Drawn CTA |
|---|---|---|
| 296 dp | 526 dp | **30 dp** |
| 328 dp | 583 dp | **34 dp** |
| 398 dp | 707 dp | **41 dp** |
| 520 dp (tablet cap) | 924 dp | 53 dp ✅ |

Only the tablet cap clears the platform minimum. The touch target is therefore
**grown around the pill's centre** until it reaches 48 dp, clamped inside the
artwork. The painted button does not move; only the invisible hit area does.

Asserted at six device sizes — 320×568, 360×640, 375×667, 390×844, 430×932,
800×1280 — all ≥ 48 dp.

The CTA is also asserted to cover **less than half** the artwork height, so the
banner is never one ambiguous button.

---

## 5. Behaviour

**Presentation** — only from an explicit Home category-card tap. Deep links
resolve the category route directly through the router and never reach
`_handleCategoryTap`, so they cannot trigger a popup. Category-screen rebuilds,
tab reselection and returning from a service detail likewise do not.

**Guard** — claimed synchronously before the first `await`, released in
`finally`. Two presentations dispatched in the same frame produce one modal; the
second resolves `false` immediately so its caller does not navigate. A dismissal
releases the guard, and the card works again — one failure cannot lock a
category for the session.

**Navigation** — occurs once, only on `CategoryCampaignOutcome.cta`, only after
the modal's route has finished popping, and only if the State is still mounted.

**Authentication** — untouched. The popup is a preview, not a gate; whatever
`CategoryExperienceScreen` enforced before, it enforces now.

**Close** — 48 × 48 dp control, dark translucent circle, white icon, its own
semantics label. Back and Escape both dismiss via `PopScope` and a `DismissIntent`
action. Barrier dismissal is enabled.

**Haptics** — `AppHaptics.medium()` on CTA, `AppHaptics.light()` on close,
**none** on Back or barrier. `AppHaptics.categoryEntry()` already fires on the
category tap itself, so no second haptic is added there.

**Motion** — 250 ms fade + 0.97→1.00 scale, `easeOutCubic`; 120 ms press scale
to 0.98. Reduced motion drops both and keeps a 100 ms fade, with functionality
unchanged.

**Accessibility** — one route-scoped summary sentence, plus exactly two actions.
The artwork is `excludeFromSemantics`, so a screen reader is not told "image"
after the summary. The barrier carries a *distinct* label ("Dismiss promotion")
— sharing the close button's label announced two identical targets.

**Large text / image failure** — at `textScaler ≥ 1.3`, or if the asset fails to
decode, `CategoryCampaignAccessibleView` replaces the artwork with native
scalable widgets carrying the same copy. Both actions keep working. No
broken-image icon, no blank card. A display failure emits its own event.

**Performance** — both creatives are precached **after** Home's first frame, via
`addPostFrameCallback`, with failures ignored. Precaching before first paint
would trade ~4 MB of decode against Home's startup for a saving only realised if
the customer taps that category.

---

## 6. Analytics

Four events, no PII:

| Event | When |
|---|---|
| `category_campaign_opened` | only after the banner or fallback has actually painted |
| `category_campaign_cta_selected` | CTA chosen |
| `category_campaign_dismissed` | with `dismissal_method` ∈ {`close_button`, `back`, `barrier`} |
| `category_campaign_display_failed` | artwork failed to decode |

Properties are `campaign_key`, `category_key`, `entry_source`,
`dismissal_method`. `platform` and `app_version` are injected by
`AnalyticsContextProvider` and deliberately not redeclared. Two new keys were
added to `AnalyticsKeys` **and to the privacy filter's allowlist** — the filter
is an allowlist, so an unlisted key would have been silently dropped.

The impression event carries a dedup key, so a rebuild cannot double-count.

---

## 7. Validation — what was actually run

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | **exit 0** |
| `flutter analyze` | **exit 0** — 53 infos, no warnings, no errors |
| `flutter test` | **exit 0 — 1319 passed**, 6 skipped (was 1274) |
| `flutter build apk --debug` | **exit 0** |
| `flutter build apk --release` | see §9 |
| `flutter build appbundle` | **NOT RUN** |
| `flutter build ios --no-codesign` | **CANNOT RUN — requires macOS** |

45 new tests across two files.

**iOS cannot be built from this machine.** It is Windows; there is no Xcode.
The repository's `build-ios` CI job on `macos-latest` covers it, but only once
this work is pushed. Reporting it as passed would be a lie.

---

## 8. Known limitations

1. **iOS build unverified locally** — see above.
2. **Landscape not explicitly tested.** The modal is `SafeArea` + scrollable and
   capped at 90% viewport height, so it should degrade to scrolling, but no test
   asserts a landscape viewport.
3. **Test suite is slower.** Two ~2 MB PNGs across ~38 widget tests measurably
   lengthened the run. If CI time becomes a concern, a smaller fixture asset for
   the layout tests would fix it without weakening them.
4. **`category_reveal_overlay.dart` still runs** after navigation, so a customer
   who taps the CTA sees the campaign, then the category reveal. That is the
   pre-existing behaviour; whether two successive presentations is desirable is a
   product decision, not a defect.
5. **No frequency cap.** Per §13/§19 the popup shows on every deliberate tap.

---

## 9. Corrections made during implementation

Recorded because each was wrong in a way that looked right:

- **The test harness deadlocked every test.** `_showPopup` was `async` and
  returned the dialog's outcome future, so `await _showPopup(...)` waited for a
  dismissal the test had not yet triggered. All 38 reported "did not complete".
  The outcome is now captured on the side. **I had described these tests as
  asserting the 48 dp floor before ever seeing them run.**
- **Flutter's default test surface is 800 × 600, which is not a phone.** At that
  size the card scrolls and the CTA sits below the fold, so taps missed and the
  failure read as "the button does not work". Every test now runs on a real
  device viewport.
- **The barrier and the close button shared one semantics label**, producing two
  identical targets for a screen reader.
- **`expect(find.byType(ScaleTransition), findsNothing)` was the wrong reduced-motion
  assertion** — `AnimatedScale` always builds one. It now asserts the scale stays
  at 1.0 through a press.
