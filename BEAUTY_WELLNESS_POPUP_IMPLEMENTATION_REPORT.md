# BEAUTYWELLNESSPOPUP+ V1 — Implementation Report

**Beauty & Wellness** was implemented together with the other category campaign, because
they are the same feature with two creatives and one reusable component serves
both (§5 of each command).

The full evidence — sweep results, verified category id and route, measured CTA
geometry, behaviour, analytics, validation output, limitations and corrections —
is in a single shared document rather than duplicated across two:

> **[CATEGORY_POPUP_IMPLEMENTATION_REPORT.md](CATEGORY_POPUP_IMPLEMENTATION_REPORT.md)**

## Beauty & Wellness specifics

| | |
|---|---|
| Campaign key | `beauty_wellness_category_popup_v1` |
| Category key | `beauty_wellness` |
| Enum | `ServiceCategoryId.beautyWellness` |
| Asset | `assets/images/categories/beauty_wellness_popup_v1.png` |
| Real dimensions | **941 × 1672** |
| Canonical route | `BeautyWellnessScreen.routeName` |
| Measured CTA | `left 0.1413, top 0.8923, width 0.7163, height 0.0562` |

## Two things worth reading before accepting this

1. **This command's stated image size is correct, but the file was delivered with an UPPERCASE name that would have failed on iOS and Android.**
   See §2 of the shared report.
2. **There was no old popup to replace.** Tapping the category navigated
   straight through. The blue panel described in §4 is
   `category_reveal_overlay.dart`, which renders *inside* the category screen
   *after* navigation — it is not a modal and has not been touched. This work
   inserts new behaviour before navigation. See §1.
