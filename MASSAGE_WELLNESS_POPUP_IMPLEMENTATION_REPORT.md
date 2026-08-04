# MASSAGEWELLNESSPOPUP+ V1 — Implementation Report

Massage & Wellness now uses the shared category-campaign architecture built for
Beauty & Wellness and Hair & Nails (§3 of this command). No second popup widget
was created; the work was a registry entry, fallback copy, and tests.

Full architectural evidence is in
**[CATEGORY_POPUP_IMPLEMENTATION_REPORT.md](CATEGORY_POPUP_IMPLEMENTATION_REPORT.md)**.
This document covers what is specific to Massage & Wellness.

---

## 1. Sweep — and the one place this command is wrong

| Question | Verified answer | Source |
|---|---|---|
| Enum | `ServiceCategoryId.massage` | `service_category_config.dart:8` |
| **Category key** | **`massage`** | `main_router.dart:76`, `home_category_grid.dart:38` |
| Config | `CategoryRegistry.massage`, title `Massage` | `service_category_config.dart:72` |
| Canonical route | `MassageScreen.routeName` = `'Massage'` | `massage_screen.dart:13` |
| Destination | `CategoryExperienceScreen(categoryId: massage)` | `main_router.dart:286` |
| Tap handler | `_handleCategoryTap(String key)` | `home_screen.dart:328` |
| Prior behaviour | `context.pushNamed(MassageScreen.routeName)` — immediate navigation | same |

### ⚠️ The specified category key does not exist

§3 of this command specifies:

```dart
categoryKey: 'massage_wellness',
```

**There is no such key in this application.** The Home grid, the router and
`home_promotion.dart` all use `massage`. A repository-wide search for
`massage_wellness` returned nothing.

Registering the command's value verbatim would have been the worst kind of
failure: `forCategoryKey('massage')` returns null, the popup never appears, no
exception is thrown, and every test that asserts "the popup opens" would have
been written against the wrong key and passed. The category would simply have
kept navigating straight through, and it would have looked like the feature was
never wired.

**Resolution:** `categoryKey: 'massage'` — the real key. The creative's own name
survives in `campaignKey: 'massage_wellness_category_popup_v1'`, which is only
an analytics label and matches §23. A test asserts both: that `massage` resolves
and that `massage_wellness` does not.

### No old popup existed

As with the previous two categories, tapping Massage & Wellness navigated
immediately. The "plain solid-colour background with generic circular
decoration and an *Explore now* button" described in §5 is
`category_reveal_overlay.dart`, which renders **inside** the category screen
**after** navigation. It is not a modal, and it has not been touched. §5 had
nothing to remove.

---

## 2. Asset

| | |
|---|---|
| Delivered as | `massage_and_Wellness_Popup.png` — **mixed case** |
| Now | `assets/images/categories/massage_wellness_popup_v1.png` |
| Dimensions | **941 × 1672** — matches the command |
| Size | 1.99 MB |

The delivered name mixed case. Windows is case-insensitive, so it would have
resolved through development and **failed on iOS and Android**. Renamed via a
temporary name, because a case-only rename is a no-op on Windows. A test fails
on any registered asset whose name is not lowercase.

### `flutter clean` is required after renaming an asset

Renaming the file and running `flutter pub get` was **not** enough — the asset
resolved to `Unable to load asset` in tests while sitting correctly on disk with
its directory registered. Clearing `.dart_tool/flutter_build` did not fix it
either. Only `flutter clean` regenerated the manifest.

This cost three failing tests that looked like a rendering defect and were
actually a stale bundle. Anyone renaming a creative should run `flutter clean`.

---

## 3. CTA geometry — measured, not estimated

Located by scanning the shipped PNG for the saturated pill against the dark
backdrop:

| | |
|---|---|
| Pixels | x 134–805, y 1497–1590 |
| `ctaLeftRatio` | 0.1424 |
| `ctaTopRatio` | 0.8953 |
| `ctaWidthRatio` | 0.7141 |
| `ctaHeightRatio` | 0.0562 |

At 5.62% of artboard height the drawn pill renders ~30 dp on a 320 dp phone —
below the platform minimum, exactly as with the other two creatives. The touch
target grows around the pill's centre to 48 dp; the artwork does not move.
Asserted at 320 × 568 specifically for this campaign, plus the shared matrix.

---

## 4. Behaviour

Inherited unchanged from the shared component, so only the summary:

- **Presentation** — explicit Home tap only. Deep links resolve the route
  directly and never reach `_handleCategoryTap`.
- **Ratio** — `AspectRatio(941/1672)` driven from the real file,
  `BoxFit.contain`, never cropped or stretched.
- **Close** — 48 × 48 dp control, plus Android Back, keyboard Escape and barrier.
- **Haptics** — `medium()` on CTA, `light()` on close, none on Back or barrier.
- **Motion** — 250 ms fade + 0.97→1.00 scale; reduced motion keeps a 100 ms fade
  and suppresses the press scale.
- **Accessibility** — one route-scoped summary, two actions, artwork excluded
  from semantics; native scalable fallback at `textScaler ≥ 1.3` or on image
  failure, carrying all four services and three benefits from §18.
- **Analytics** — the four shared events, `campaign_key` =
  `massage_wellness_category_popup_v1`, `category_key` = `massage`. No PII.
- **Guard** — claimed before the first `await`, released in `finally`.

### §24 session safety

New in this command relative to the previous two, and now covered by tests: a
route torn down externally — which is what logout looks like from the
coordinator's side — still releases the guard, leaves no stale modal, and the
category opens normally afterwards. Verified with a `GlobalKey<NavigatorState>`
popping the route out from under the modal.

---

## 5. Validation — what was actually run

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | **exit 0** |
| `flutter analyze` | **exit 0** — 53 infos, no warnings, no errors |
| `flutter test` | **exit 0 — 1328 passed**, 6 skipped |
| Campaign suites alone | **54 passed** |
| `flutter build apk --release` | **exit 0** — 63.2 MB, rebuilt after `flutter clean`; asset verified inside the APK |
| `flutter build appbundle` | **NOT RUN** |
| `flutter build ios --no-codesign` | **CANNOT RUN — requires macOS** |

**iOS cannot be built from this machine.** It is Windows with no Xcode. The
repository's `build-ios` CI job on `macos-latest` covers it once pushed.
Reporting it as passed would be untrue.

An earlier pair of APK builds in the same session predated `flutter clean` and
did not contain the renamed asset. Those are not what the table above reports:
the release APK was rebuilt afterwards, and
`massage_wellness_popup_v1.png` was confirmed present inside the archive at its
registered path rather than inferred from a green build.

---

## 6. Limitations

1. **iOS build unverified locally.**
2. **Landscape not explicitly asserted.** The modal is `SafeArea` + scrollable
   and capped at 90% viewport height, so it should degrade to scrolling.
3. **`category_reveal_overlay.dart` still runs after navigation**, so a customer
   who taps the CTA sees the campaign and then the category reveal. Pre-existing
   behaviour; whether two successive presentations is wanted is a product call.
4. **No frequency cap** — per §13 it shows on every deliberate tap.
5. **Aircon has since been implemented too** (AIRCONREPAIRPOPUP+ V1), so all
   four Home categories now show a campaign on tap. At the time this document
   was first written aircon was still inert; the statement is corrected rather
   than left to mislead.
