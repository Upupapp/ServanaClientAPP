# HOME_SPACING_IMPLEMENTATION_REPORT

HOMESPACING+ V1 §27 — what changed, why, and what I could not verify.

Commit: `06bedfd` — *fix(home): HOMESPACING+ — one responsive gutter,
content-driven header*

Companion: [HOME_SPACING_AUDIT.md](HOME_SPACING_AUDIT.md) (§2, before-state).

---

## §27.1 The single change everything else follows from

```dart
double homeGutter(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 360) return AppSpacing.lg;      // 16 — compact phones
  if (width < 600) return AppSpacing.xl;      // 20 — standard phones
  return AppSpacing.section;                  // 24 — large phones, tablets
}
```

Every Home section calls this. That is the whole fix for defects 1, 2 and 8.

The alternative — publishing a constant and asking developers to use it —
is what the codebase already had, in the form of nine available values. A
constant is a suggestion. A function that takes `BuildContext` is the only
way to get the value at all, so sections land on the same guide **by
construction** rather than by everyone remembering.

`AppSpacing` is deliberately short (2/4/8/12/16/20/24/32). A longer scale
just relocates the original problem: with ten options, picking one is still
a judgement call every time.

## §27.2 Changes, by defect

| # | Defect | Fix | File |
|---|---|---|---|
| 1 | Three left edges | all sections → `homeGutter(context)` | 6 files |
| 2 | "See All" misaligned by `TextButton` default | `padding: EdgeInsets.zero`, `minimumSize: Size(48, 48)` | `home_screen.dart` |
| 3 | 48pt trench below search | header owns the gap (`AppSpacing.section`); Services block is gutter-only | `home_screen.dart` |
| 4 | Header height hardcoded | content-driven `Stack`, atmosphere via `Positioned.fill` | `home_screen.dart`, `home_atmosphere.dart` |
| 5 | Benefit section triple padding | inner `vertical: 8` removed | `home_benefit_section.dart` |
| 6 | Trailing 40 double-counts nav | → `AppSpacing.section` | `home_screen.dart` |
| 7 | Nine off-scale values | `AppSpacing` scale | `app_spacing.dart` (new) |
| 8 | No responsiveness | three breakpoints in `homeGutter` | `app_spacing.dart` |
| 9 | Promo accent line as false underline | 48×2 `Container` deleted | `home_promotion_banner.dart` |

## §27.3 Defect 2 is worth its own note

Zeroing the `TextButton` padding removes 8pt of *tap target*, not just 8pt of
space. Shrinking a control below 48pt to win an alignment is a downgrade, so
the padding removal is paired with `minimumSize: Size(48, 48)`: the label now
aligns with the cards below it and the touch target stays at the accessible
minimum. Alignment was not bought with reachability.

## §27.4 Defect 4 — why the header could not simply be given a better number

The obvious fix is to change `76.0 + 80.0` to a number that measures
correctly today. That reproduces the bug at the next text size.

The header now sizes to its children, and the gradient backdrop — which
genuinely cannot be told a height up front, since it must match whatever the
content comes to — is painted behind via `Positioned.fill` inside the same
`Stack`. `ServanaHomeAtmosphere.height` became nullable for this: it fills
its parent when it is not given one.

This is what removes `BOTTOM OVERFLOWED BY 5.0 PIXELS`, and it removes it at
every text scale rather than at 1.0×.

## §27.5 §19 — wide screens

`homeHorizontalPadding(context)` caps the content column at
`kHomeMaxContentWidth = 760` and converts the remainder to outer margin. Past
that width a promo banner stretched edge-to-edge is a shallow rectangle
nobody designed.

## §27.6 Tests (§26)

`test/homepage/home_spacing_test.dart` — 11 tests, all passing.

Two kinds, deliberately:

1. **Behavioural** — `homeGutter` and `homeHorizontalPadding` across
   320/360/375/390/412/430/600/800/1400pt, including that the result is
   always on the scale and that wide screens centre rather than stretch.

2. **Source-level** — asserting the specific literals from §2 have not come
   back. A future edit reintroducing `EdgeInsets.symmetric(horizontal: 16)`
   on one section would pass every rendering test ever written and silently
   restore the misalignment, because nothing *renders* wrong; the section is
   simply on a different guide from its neighbours. These read the file with
   `//` comments stripped, so documenting a removed value does not fail the
   test that removed it.

Home pulls four MobX stores, GoRouter and a live catalog, so pumping the real
screen would have measured the mocks rather than the layout. That is why the
regression net is source-level rather than a widget test that would mostly
assert its own scaffolding.

## §27.6b Two defects the source audit missed and the device caught

Both were found by putting the build on `emulator-5554` and measuring the
screenshot, not by reading the files. Worth recording, because §2 was
written from source and confidently missed both.

**1. The category grid was inheriting the status bar.**

A vertical `GridView`/`ListView` with `padding: null` does not default to
zero. `BoxScrollView.build` substitutes `MediaQuery.padding` — so this
mid-page grid silently adopted the device's *top inset* as its own top
padding, opening a ~48pt hole between the "Services" heading and the first
card that varied by device. Fixed with an explicit `padding: EdgeInsets.zero`.

Nothing in the file says 48. The gap was contributed by the framework, which
is why reading the widget tree did not reveal it.

**2. My own §2 fix for "See All" was still ~4pt off.**

Zeroing the padding and adding `minimumSize: Size(48, 48)` kept the tap
target — but "See All" is *narrower* than 48pt, and a button centres its
child, so the accessibility minimum was itself holding the label inside the
guide. `alignment: Alignment.centerRight` pins the text to the gutter while
the 48pt box stays.

A fix that is verified only by re-reading the diff will not catch this. It
needed a screenshot and a pixel measurement.

## §27.6c Out of scope, found while verifying — not fixed here

- **`search_screen.dart:419`** has the same `padding: null` scroll view. It
  is *horizontal*, where the inherited inset is the left/right padding —
  0 in portrait, non-zero in landscape on a cutout device. Latent, not
  currently visible, and on another screen; left alone rather than widening a
  release diff.
- **Beauty & Wellness category header**: the subtitle "Feel refreshed,
  confident, and cared for." renders *underneath the back arrow* — the same
  class of text-over-control defect as the welcome-screen chip. Reproducible
  on every load of that screen. Not a Home defect, so not fixed in this
  commit; needs its own change.

## §27.7 Verification performed

| Gate | Result |
|---|---|
| `dart format --set-exit-if-changed .` | exit 0 |
| `flutter analyze --no-fatal-infos` | **exit 0**, 0 warnings, 0 errors |
| `flutter test --coverage` | 1089 passed, 0 failed |
| `flutter build apk --debug` | exit 0 |
| Same four, from a **clean clone of the pushed commit** | reproduced |
| On `emulator-5554` (Android 17, 16 KB image) | 0 RenderFlex overflows in logcat across the whole session |

On-device checks, by reported bug:

| Reported | Verified |
|---|---|
| Distorted text under the plumbing box | Gone — chips render clean on all three welcome screens |
| Welcome screens should auto-advance after 3s | Reaches screen 3 of 3 with no input |
| Remove the "One app…" onboarding screen | Gone — page indicator shows 3 dots |
| Cleaning/Gardening → Massage/Nails | `welcome_screen.dart:487,491` |
| Line below the Home buttons | Gone |
| Cannot scroll to the bottom; nav covers content | Last card clears the nav with ~23pt to spare |
| `BOTTOM OVERFLOWED BY 5.0 PIXELS` | Not reproduced; logcat overflow count 0 |

The clean-clone run is not ceremony. The previous CI failure was caused by a
file that existed locally and was not tracked by git, so a local green proved
nothing about what CI would receive. `app_spacing.dart` — which every Home
section now imports — was untracked at the moment the gate first passed
locally, and would have failed CI on the first compile had it been pushed
then.

## §27.8 What I could not verify

- **§29 / §31.36 physical-device testing.** No physical Android or iOS device
  is attached. Haptic feel, real scroll momentum and true edge-to-edge inset
  behaviour on a notched device are not claimable from an emulator.
- **iOS.** No macOS host, so no iOS build or simulator run. The gutter logic
  is platform-independent, but safe-area behaviour on iOS is unverified.
- **Golden tests (§25).** Not added. Goldens on a screen backed by live
  catalog data would encode the fixture, not the layout, and would need a
  deterministic harness that does not exist yet. Recording them now would
  produce a test that fails on catalog changes and gets regenerated
  unexamined — worse than no golden.
