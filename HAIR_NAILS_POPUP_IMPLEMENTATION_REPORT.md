# HAIRNAILSPOPUP+ V1 — Implementation Report

**Hair & Nails** was implemented together with the other category campaign, because
they are the same feature with two creatives and one reusable component serves
both (§5 of each command).

The full evidence — sweep results, verified category id and route, measured CTA
geometry, behaviour, analytics, validation output, limitations and corrections —
is in a single shared document rather than duplicated across two:

> **[CATEGORY_POPUP_IMPLEMENTATION_REPORT.md](CATEGORY_POPUP_IMPLEMENTATION_REPORT.md)**

## Hair & Nails specifics

| | |
|---|---|
| Campaign key | `hair_nails_category_popup_v1` |
| Category key | `hair_nails` |
| Enum | `ServiceCategoryId.hairAndNails` |
| Asset | `assets/images/categories/hair_nails_popup_v1.png` |
| Real dimensions | **941 × 1672** |
| Canonical route | `HairNailsScreen.routeName` |
| Measured CTA | `left 0.1265, top 0.8989, width 0.7418, height 0.0574` |

## Two things worth reading before accepting this

1. **This command's stated image size is wrong (it says 928 × 1648; the file is 941 × 1672).**
   See §2 of the shared report.
2. **There was no old popup to replace.** Tapping the category navigated
   straight through. The blue panel described in §4 is
   `category_reveal_overlay.dart`, which renders *inside* the category screen
   *after* navigation — it is not a modal and has not been touched. This work
   inserts new behaviour before navigation. See §1.
