# HOME_SPACING_AUDIT

HOMESPACING+ V1 §2 — what Home's spacing actually was before any change.

Measured by reading every widget that contributes horizontal or vertical
space to the Home scroll, not by eyeballing the emulator. Values are logical
pixels as written in source.

---

## §2.1 The finding, in one line

Home had no page gutter. It had six of them, and which one a section got
depended on which file it lived in.

---

## §2.2 Horizontal gutters, before

| Section | File | Gutter | Source |
|---|---|---|---|
| Header + greeting | `home_screen.dart` | 16 | `EdgeInsets.fromLTRB(16, 16, 16, 0)` |
| Search field | `home_search.dart` | 20 | `EdgeInsets.symmetric(horizontal: 20)` |
| Active booking card | `home_screen.dart` | 16 | `EdgeInsets.symmetric(horizontal: 16)` |
| "Services" heading | `home_screen.dart` | 16 | `EdgeInsets.fromLTRB(16, 20, 16, 0)` |
| Category grid | `home_category_grid.dart` | 20 | `margin: EdgeInsets.symmetric(horizontal: 20)` |
| Featured heading | `home_screen.dart` | 20 | `EdgeInsets.only(left: 20, bottom: 12)` |
| Featured "See All" | `home_screen.dart` | 20 **− 8** | heading 20, then `TextButton` padding 8 |
| Featured carousel | `home_screen.dart` | 20 | `EdgeInsets.only(left: 20)` |
| Promotion banner | `home_promotion_banner.dart` | 20 | `margin: EdgeInsets.symmetric(horizontal: 20)` |
| Benefit section | `home_benefit_section.dart` | 20 | `EdgeInsets.symmetric(horizontal: 20, vertical: 8)` |

**Three distinct left edges on one screen: 12, 16 and 20.**

The 12 is the worst of them and is not written anywhere. It is the Featured
"See All" button: the heading row sits at 20, and `TextButton`'s default
`EdgeInsets.symmetric(horizontal: 8)` pulls its *text* inward from the right
edge — so the tap target's visible label never aligns with the card edges
below it, at any screen size. Nobody wrote 12; it is what 20 minus a default
comes to.

None of these values were wrong on their own. The defect is that no rule
selected between them, so a developer adding a section had to guess, and the
guess was correct about half the time.

## §2.3 Vertical rhythm, before

| Gap | Value | Composed of |
|---|---|---|
| Search → "Services" | **48** | `SizedBox(height: 28)` in the header **+** `top: 20` on the Services block |
| Benefit section internal | **8 + 8 + parent** | `vertical: 8` on the container, plus its own children's padding |
| Last section → end of scroll | **40** | `SliverToBoxAdapter(SizedBox(height: 40))` |

The 48 is the one a reader would notice as "a hole in the page". It is not in
either file as the number 48. The header ends with 28 and the next section
begins with 20, and neither file can see the other, so neither author saw a
48pt trench.

The trailing 40 double-counts: `Scaffold` already reserves the bottom
navigation height, so this added a second nav's worth of empty scroll.

## §2.4 The header height bug (§6)

```dart
const contentH = 76.0 + 80.0;     // assumed greeting + assumed search
final totalH   = topPad + contentH;
```

The header declared its own height as a sum of two guesses about how tall its
children would render.

This is wrong at the default text size by about 5pt, which the emulator
reports as:

```
BOTTOM OVERFLOWED BY 5.0 PIXELS
```

and the error grows with every accessibility text-size step, because the
constant does not, while the text inside it does. At 1.3× the greeting alone
exceeds its 76pt allowance.

A height computed from assumed child sizes is only ever correct for the one
device and one text size it was tuned on.

## §2.5 Off-scale values in use

§4 asks for a short scale. Before the change, Home used **8, 10, 12, 14, 16,
20, 22, 28 and 40**, with no documented meaning for any of them and no way to
tell which to reach for.

## §2.6 Responsiveness, before

None. Every gutter was a `const`. A 320pt device and a 600pt tablet got the
same 16 or 20, so the small phone felt cramped and the tablet had a narrow
column of content floating in whitespace.

## §2.7 Summary of defects carried into implementation

| # | Defect | Section |
|---|---|---|
| 1 | Three left edges (12/16/20) on one screen | §3 |
| 2 | "See All" label misaligned by a framework default | §3 |
| 3 | 48pt trench below the search, invisible in either file | §8 |
| 4 | Header height hardcoded from assumed child sizes → 5px overflow | §6 |
| 5 | Benefit section stacks a third nested vertical padding | §16 |
| 6 | Trailing 40 double-counts nav height the Scaffold reserves | §18 |
| 7 | Nine off-scale spacing values, no rule to choose between them | §4 |
| 8 | No responsiveness at any breakpoint | §3 |
| 9 | 48×2 promo accent line reading as an underline on the CTA | reported bug |
