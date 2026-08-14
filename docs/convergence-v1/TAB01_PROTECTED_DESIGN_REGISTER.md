# Protected design screens and assets

**Servana Client Mobile Backend Convergence V1 · TAB 01**

Convergence V1 is a **data-layer** migration. Nothing in it has a reason to
touch presentation. This register names what must survive it byte-for-byte, so
that a later TAB changing a repository or a DTO can be checked against a list
rather than against somebody's memory.

> **Scope note.** The bound Master Command names the protected design screens
> and assets by reference. That list is not present in this repository, so this
> register is derived from repository evidence — the four campaign
> implementation reports, the launch campaign report, the declared asset bundle
> in `pubspec.yaml`, and the design-bearing screens those documents name. If
> the Master Command's list is wider, this file is the place to extend, and any
> entry added later inherits the same rule.

**The rule.** Files in §1 and §2 are read-only for the duration of Convergence
V1. A TAB that believes it must change one stops and says so instead.

---

## 1. Design screens

### 1.1 Category campaign popups — all four creatives

One reusable component serves all four campaigns
(`CATEGORY_POPUP_IMPLEMENTATION_REPORT.md`). Changing the component changes
every campaign at once, which is why it is listed alongside the creatives.

| Category key | Creative asset | Command of record |
| --- | --- | --- |
| `beauty_wellness` | `assets/images/categories/beauty_wellness_popup_v1.webp` | `BEAUTY_WELLNESS_POPUP_IMPLEMENTATION_REPORT.md` |
| `hair_nails` | `assets/images/categories/hair_nails_popup_v1.webp` | `HAIR_NAILS_POPUP_IMPLEMENTATION_REPORT.md` |
| `massage` | `assets/images/categories/massage_wellness_popup_v1.webp` | `MASSAGE_WELLNESS_POPUP_IMPLEMENTATION_REPORT.md` |
| `aircon` | `assets/images/categories/aircon_repair_popup_v1.webp` | `AIRCON_REPAIR_POPUP_IMPLEMENTATION_REPORT.md` |

Two of the four commands originally specified a category key that does not
exist in this app (`massage_wellness`, `aircon_repair`) and would have failed
silently. The keys above are the corrected, working ones. **A convergence
change that renames a category key breaks all four campaigns silently** — the
registry lookup misses and the popup simply never shows. Category keys are
therefore protected data, not just protected pixels.

### 1.2 Launch campaign

| Surface | Asset | Report |
| --- | --- | --- |
| Home launch campaign | `assets/images/campaigns/servana_launch_benefits_v1.webp` | `docs/HOME_LAUNCH_CAMPAIGN_REPORT.md` |

### 1.3 Screens with an accepted visual specification

Their layout, spacing and copy are signed off in a report in this repository.
Convergence may change what feeds them; it may not change how they look.

| Screen | File | Specification |
| --- | --- | --- |
| `HomeScreen` | `modules/homepage/presentation/screens/home_screen.dart` | `docs/HOME_SPACING_AUDIT.md`, `docs/HOME_SPACING_IMPLEMENTATION_REPORT.md` |
| `CategoryExperienceScreen` | `modules/categories/presentation/screens/category_experience_screen.dart` | the four popup reports |
| `SplashScreen` | `modules/landing/presentation/screens/splash_screen.dart` | brand assets, §2.2 |
| `WelcomeScreen` | `modules/landing/presentation/screens/welcome_screen.dart` | three-page onboarding creative |
| `CatalogBrowseScreen`, `CategoryScreen`, `SubcategoryScreen`, `ServiceDetailScreen` | `modules/catalog/presentation/screens/` | `docs/catalog-v2/CLIENT_CATALOG_V2_FINAL_REPORT.md` |
| `CatalogUnavailableScreen` | `modules/catalog/presentation/screens/catalog_unavailable_screen.dart` | the sanctioned degraded state for risk R-01 — **must not be bypassed or replaced with placeholder catalog data (§50)** |

### 1.4 Theme

`lib/common/config/app_theme.dart` and `lib/common/config/app_config.dart` hold
the brand tokens — seed `#F89040`, primary `#3058C8`, Poppins, the dark
scaffold `#121218`. Protected.

> This file carries an **unstaged modification that predates TAB 01** — six
> `const` promotions in `buildDarkAppTheme`, no token values altered. TAB 01
> preserved it untouched and did not author it.

---

## 2. Assets

97 files under `assets/`. The whole tree is protected; these are the ones a
convergence change is most likely to orphan.

### 2.1 Declared bundle (`pubspec.yaml`)

```
assets/images/            assets/images/home/       assets/images/messages/
assets/images/services/   assets/images/splash/     assets/images/states/
assets/images/welcome/    assets/images/campaigns/  assets/images/categories/
assets/animations/        assets/icons/             assets/payment_icons/
assets/jsons/philippine-addresses/
```

`assets/images/categories/` and `assets/images/campaigns/` are declared as
directories so a new creative ships by being dropped in. **Filenames must stay
lowercase** — Windows is case-insensitive, iOS and Android are not, and that
exact mismatch was present when `categories/` was first populated.

### 2.2 Brand and identity

`assets/app_icon.png`, `assets/images/Default.webp`,
`assets/images/splash/logo_blue.svg`, `assets/images/splash/logo_orange.svg`,
`assets/images/splash/vector_1.png` … `vector_7.png`.

### 2.3 Service and category imagery

`assets/images/services/` (6 service images + 6 `service_icon/` glyphs) —
bound to catalog identity. **A convergence change that renumbers service ids or
renames categories can orphan these silently**; the image resolves to nothing
and the card renders blank. Any TAB touching catalog identity re-checks this
directory.

### 2.4 Payments, onboarding, state

`assets/payment_icons/` (10 files — GCash, Maya, GrabPay, the card schemes);
`assets/images/welcome/page_{1,2,3}_bg.webp`;
`assets/images/states/end_of_list.png`; `assets/animations/pulse.json`.

### 2.5 Reference data

`assets/jsons/philippine-addresses/{region,province,city,barangay}.json` —
bundled address hierarchy. Note for R-13: the backend offers
`GET /api/location/address-suggestions` and `.../address-details/:placeId`, so
a future TAB may make this data redundant. **Redundant is not the same as
removable** — the installed base still reads it. Protected until the installed
base moves.

### 2.6 Editable originals — deliberately not bundled

`assets_src/` holds the uncompressed campaign sources. They are intentionally
absent from `pubspec.yaml`; bundling both would forfeit the compression.
Protected as sources, not shipped.

---

## 3. Verification hook

A convergence TAB can prove it respected this register with:

```
git diff --stat <base>..HEAD -- assets/ assets_src/ lib/common/config/
```

An empty result is the expected outcome for every TAB in Convergence V1.
