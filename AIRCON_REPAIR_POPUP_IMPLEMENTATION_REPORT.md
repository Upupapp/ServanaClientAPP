# AIRCONREPAIRPOPUP+ V1 — Implementation Report

Aircon Repair is the fourth creative on the shared category-campaign
architecture (§3). No fourth popup widget was written: a registry entry,
fallback copy and tests. All four Home categories now have campaigns.

Architectural evidence is in
**[CATEGORY_POPUP_IMPLEMENTATION_REPORT.md](CATEGORY_POPUP_IMPLEMENTATION_REPORT.md)**.
This covers what is specific to Aircon Repair.

---

## 1. Sweep

| Question | Verified answer | Source |
|---|---|---|
| Enum | `ServiceCategoryId.aircon` | `service_category_config.dart:9` |
| **Category key** | **`aircon`** | `home_category_grid.dart:45`, `main_router.dart` |
| Config | `CategoryRegistry.aircon`, title `Aircon Services` | `service_category_config.dart:84` |
| Canonical route | `AirconRepairScreen.routeName` = `'AirconRepair'` | `aircon_repair_screen.dart:13` |
| Destination | `CategoryExperienceScreen(categoryId: aircon)` | `main_router.dart` |
| Tap handler | `_handleCategoryTap(String key)` | `home_screen.dart:328` |
| Prior behaviour | `context.pushNamed(AirconRepairScreen.routeName)` — immediate | same |

### ⚠️ The specified category key does not exist

§3 specifies `categoryKey: 'aircon_repair'`. **No such key exists** — a
repository search returns nothing. The Home grid uses `aircon`.

This is the same defect as the Massage command, and it fails the same silent
way: `forCategoryKey('aircon')` returns null, the popup never appears, nothing
throws, and tests written against the wrong key would pass. Registered against
`aircon`; the creative's name survives in `campaignKey`, which §24 only uses as
an analytics label. Tests assert `aircon` resolves and `aircon_repair` does not.

### §11 category scope

The banner advertises AC Cleaning, Repair, Preventive Maintenance, and
Installation & Checkup. `ServiceCategoryId.aircon` is the **parent** category —
its config title is *Aircon Services* and its subtext reads "Cleaning,
installation, and repair by certified technicians." The CTA therefore opens the
parent category results, which is §11's first branch. No single service is
hard-coded.

### No old popup existed

As with the other three, tapping navigated immediately. The presentation
described in §5 is `category_reveal_overlay.dart`, which renders **inside** the
category screen **after** navigation. Untouched. §5 had nothing to remove.

---

## 2. Asset

| | |
|---|---|
| Delivered as | `aircon_repair_pop_up.png` |
| Now | `assets/images/categories/aircon_repair_popup_v1.png` |
| Dimensions | **941 × 1672** — matches §4 |
| Size | 2.04 MB |

`flutter clean` was run after the rename. Learned on the Massage creative:
renaming an asset leaves a stale manifest that `flutter pub get` does not
regenerate, and the file resolves to `Unable to load asset` while sitting
correctly on disk in a registered directory.

---

## 3. CTA geometry — measured, then double-checked

| | |
|---|---|
| Pixels | x 135–801, y 1445–1561 |
| `ctaLeftRatio` | 0.1435 |
| `ctaTopRatio` | 0.8642 |
| `ctaWidthRatio` | 0.7088 |
| `ctaHeightRatio` | **0.0700** |

This creative's pill is **116 px tall against ~95 px on the other three** —
0.070 of artboard height versus ~0.056. That looked like a detector artefact,
because the warm-pixel scan tuned for the other three could have fallen through
to a looser heuristic on a cool-toned banner.

It did not. A row-by-row profile of 1400–1620 shows a solid orange→red gradient
from `rgb(238,143,84)` at y=1445 to `rgb(245,44,44)` at y=1560, with genuinely
empty rows at 1410–1440 above and 1565–1585 below, and the footer starting near
y=1590. The pill really is taller. A test asserts the value stays above 0.065,
so a future "tidy-up" that normalises it to match the others — which would move
the hit area off the drawn button — fails.

At 0.070, the drawn CTA renders ~37 dp on a 320 dp phone: still under the
minimum, so the same growth-to-48 dp applies. Asserted at 320 × 568.

---

## 4. Behaviour

Inherited unchanged from the shared component:

- **Presentation** — explicit Home tap only; deep links, notifications and
  booking/payment restoration all resolve routes directly and never reach
  `_handleCategoryTap`.
- **Ratio** — `AspectRatio(941/1672)` from the real file, `BoxFit.contain`.
- **Close** — 48 × 48 dp control, Android Back, keyboard Escape, barrier.
- **Haptics** — `medium()` CTA, `light()` close, none on Back or barrier.
- **Motion** — 250 ms fade + 0.97→1.00 scale; reduced motion keeps a 100 ms fade
  and suppresses the press scale.
- **Accessibility** — one summary, two actions, artwork excluded from semantics;
  native scalable fallback at `textScaler ≥ 1.3` or on image failure, carrying
  all four services and three benefits from §19.
  The fallback heading reads **"Aircon Repair"** — the creative's words — not
  the config's "Aircon Services", so a customer who never sees the artwork reads
  what it would have said.
- **Analytics** — the four shared events; `campaign_key` =
  `aircon_repair_category_popup_v1`, `category_key` = `aircon`. No PII.
- **Guard** — claimed before the first `await`, released in `finally`.
- **§25 session safety** — an externally popped route releases the guard, leaves
  no stale modal, and the category opens normally afterwards. Tested.

---

## 5. Validation — what was actually run

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | **exit 0** |
| `flutter analyze` | **exit 0** — 53 infos, no warnings, no errors |
| `flutter test` | **exit 0 — 1336 passed**, 6 skipped |
| Campaign suites alone | **62 passed** |
| `flutter build apk --release` | **exit 0** — 63.2 MB, and all four creatives verified present at the exact registered paths inside the APK |
| `flutter build appbundle` | **NOT RUN** |
| `flutter build ios --no-codesign` | **CANNOT RUN — requires macOS** |

**iOS cannot be built from this machine** — Windows, no Xcode. CI's `build-ios`
job on `macos-latest` covers it once pushed.

The release APK was rebuilt against this exact tree after `flutter clean`, and
each creative was confirmed present inside the archive at its registered path —
not merely assumed from a successful build. `flutter build appbundle` was still
not run.

---

## 6. Limitations

1. **iOS not built.** The Android release APK was built against this exact tree
   and all four creatives verified inside it; iOS needs macOS and is covered by
   CI's `build-ios` job on push. `flutter build appbundle` was not run.
2. **Landscape not explicitly asserted.**
3. **`category_reveal_overlay.dart` still runs after navigation**, so choosing
   the CTA shows the campaign then the category reveal. Pre-existing.
4. **No frequency cap** — per §14 it shows on every deliberate tap.
5. **Bundle impact, measured (§23):**

   | Creative | Size |
   |---|---|
   | `aircon_repair_popup_v1.png` | 1.95 MB |
   | `beauty_wellness_popup_v1.png` | 1.88 MB |
   | `hair_nails_popup_v1.png` | 1.82 MB |
   | `massage_wellness_popup_v1.png` | 1.90 MB |
   | **Total added** | **7.55 MB** |

   All four are precached after Home's first frame, so ~7.5 MB is decoded into
   memory shortly after Home settles regardless of which category the customer
   taps. That is a real cost and worth revisiting: precaching lazily on first
   category tap, or compressing the PNGs, would recover most of it. Neither was
   in scope here, and no compression was applied because §31 forbids altering
   the approved artwork.
