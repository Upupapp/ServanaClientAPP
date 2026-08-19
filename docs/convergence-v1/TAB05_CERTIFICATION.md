# TAB 05 certification — Home composition + banners/campaigns preservation

**Master project** Servana Client Mobile — Backend Convergence V1
**Date** 2026-08-16 · **Client** `servana_client-mobile` @ `2148c15` (branch `main`)
**Backend alignment** Backend TAB 11 (`home.feed`, `home.sections`)

---

## 1. Verdict

> ## `CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS`

The composition layer is complete, wired and tested. The one gap is the same
upstream one every tab since TAB 01 has carried: `/api/v1` is absent from the
backend's `origin/main`, so the canonical transport is built and gated off
rather than serving traffic. That is a backend deployment, not a client defect.

---

## 2. What TAB 05 found

The tree already contained an uncommitted Home composition layer from a prior
session. Its architecture was sound and was kept. Reading the backend's actual
`homeService.ts` / `homePolicy.ts` against it surfaced **two defects that would
have shipped broken**, and neither was visible from the client alone.

### Defect 1 — the parser could not read the payload

`HomeComposition.fromJson` expected `sections` to be a map keyed by type.
`composeHome` returns an **array of section envelopes**:

```json
{ "sections": [ {"type","status","items","reason","ttlSeconds"} ],
  "meta": {"requested","unavailable","personalized","generatedAt"} }
```

Given an array, the `node is Map` branch failed, `source` fell back to the root
object, and the only keys there were `sections` and `meta` — neither a valid
section name. Every section was dropped, the composition parsed empty, and
`isUsable` reads an empty composition as a **blank Home**.

Fixed: the array form is now the primary path. The map form is retained because
the compatibility source assembles its composition that way and both feed one
constructor.

### Defect 2 — `fetchSection` called the registry for content

It issued `GET /api/v1/home/sections?section=<name>`. That route is
`homeService.describeSections` — the section **registry**: type, audience,
failureMode, ownedBy, referenceId, ttlSeconds. The contract states it plainly:
*"METADATA, not content — it names no account and no resource"*. It accepts no
`section` parameter.

Fixed: a single section is fetched by narrowing the composition endpoint,
`GET /api/v1/home?sections=<name>`. This is the Master Command's "do not
fabricate server behavior" rule catching a real instance.

### Consequence found while fixing defect 2

`composeHome` filters the requested names through `isSectionType` and, **if
nothing survives, falls back to every section**. The client enum calls the
section `promotions`; the backend registry calls it `banners`. Requesting
`promotions` would therefore not narrow the response — it would silently widen
it to the whole page. `HomeSectionType.requestName` now emits the backend's
spelling. Reading still accepts both.

---

## 3. Section semantics now carried through

The backend draws a distinction the UI must not collapse — *"an empty recents
list is a new customer, an unavailable one is a backend that failed"*. `reason`
now decides the outcome **type**, not merely the copy:

| `reason` | `status` | Client outcome | Why |
| --- | --- | --- | --- |
| `UNAVAILABLE` | `unavailable` | `HomeSectionFailed`, retryable | genuinely failed server-side |
| `NOT_CONFIGURED` | `ok` | `HomeSectionAbsent` | backend does not offer it; a retry button would be noise |
| `REQUIRES_AUTH` | `ok` | `HomeSectionAbsent` | a signed-out customer, not an error |
| `EMPTY` / null | `ok` | `HomeSectionLoaded` (may be empty) | a real answer with no rows |

---

## 4. Design preservation

| Protected asset | Status | Note |
| --- | --- | --- |
| `HomeScreen` visual hierarchy | **untouched** | no widget file changed in this tab |
| Home banners / campaign cards | **untouched** | `HomeCampaignController`, `HomePromotionRepository` and the Remote Config kill switch remain the banner source |
| Floating promo assets, welcome transitions | **untouched** | — |
| `assets/`, `assets_src/`, `pubspec.yaml` | **untouched** | `git status --porcelain` on those paths is empty |

`promotions` was deliberately **not** wired to the composition. The banners are
typed `HomePromotion` objects feeding purpose-built widgets under a Remote
Config kill switch; flattening them into generic map rows to pass through a
transport would degrade protected creative. The backend independently arrives
at the same place — it reports `banners` as `NOT_CONFIGURED` because it has no
promotions source and *declines to invent one*. Neither side owns promotion
truth, which is the correct outcome under "NO DUPLICATE BUSINESS TRUTH".

---

## 5. Compatibility loaders — why only one

| Section | Compatibility source | Reason |
| --- | --- | --- |
| `categories` | `CatalogRepository.categories()` | canonical Catalog V2 hierarchy, so Home and the catalog cannot disagree about what exists |
| `featuredServices`, `popularServices`, `recentServices` | none → **Absent** | no legacy endpoint exists. Absent, not failed: there is nothing to retry until the composition endpoint ships |
| `promotions` / `banners` | none → **Absent** | see §4 |
| `activeBooking` | none → **Absent** | no legacy assembly that would not duplicate booking truth |
| `notificationSummary` | none → **Absent** | `NotificationsController` already owns the unread count; a second one assembled here would be a duplicate truth |

---

## 6. Acceptance gate

| TAB 05 requirement | Status | Evidence |
| --- | --- | --- |
| Welcome and Home visual identity remain intact | **PASS** | §4; no presentation file touched |
| Home can consume `/api/v1/home` locally when available | **PASS** | `HomeCompositionCanonicalDataSource`, gated on `V1Capability.home` |
| Partial section failures degrade gracefully | **PASS** | `one failing section does not take the others with it`; `isUsable` true with a failed section |
| One composition fetch rather than serial requests | **PASS** | `fetchComposition hits /api/v1/home once` |
| Remote Config stays presentation-only | **PASS** | campaign kill switch untouched; no canonical truth behind it |
| Logout clears personalized home state | **PASS** | `homeComposition` cleanup step in `AuthenticationBloc` |

---

## 7. Verification

| Check | Command | Result |
| --- | --- | --- |
| Static analysis | `flutter analyze --no-fatal-infos` | **exit 0** — 0 errors, 0 warnings, 39 infos (174.4 s) |
| Focused tests | `flutter test test/homepage test/catalog test/modules/authentication test/core/session` | **exit 0** — 220 passed, 0 failed |
| TAB 05 suite alone | `flutter test test/homepage/home_composition_test.dart` | **exit 0** — 18 passed |
| Protected assets untouched | `git status --porcelain -- assets assets_src pubspec.yaml` | **empty** |

The 39 infos are the pre-existing baseline recorded in TAB 01 (`prefer_const*`
in settings screens and two test files). TAB 05 added two and both were removed
before commit, so the count is unchanged.

Full `flutter test` and `flutter build apk --debug` are **deliberately not run
here** — the Master Command's focused-to-full rule reserves them for TAB 20.

---

## 8. Working tree and commits

- **Branch** `main`. One local commit: `2148c15`.
- **Pre-existing unstaged modification preserved.** `lib/common/config/app_theme.dart`
  carries `const` promotions in `buildDarkAppTheme` that predate this session.
  TAB 05 did not author, stage, commit or revert them. Still unstaged.
- **Commit scope** — staged by explicit path; nine files, all TAB 05.
- **Nothing pushed, nothing deployed.** No production configuration, data or
  credential was read or written. The backend repository was read only.

---

## 9. Environment / production-only gaps

| Gap | Owner | Why TAB 05 could not close it |
| --- | --- | --- |
| `/api/v1` absent from backend `origin/main` (51 unpushed commits) | backend deploy | Outside this repository and outside local authority. The canonical source is built, tested and gated off. |
| `/api/v1/home` never exercised against a live server | backend deploy | Follows from the above. Its contract conformance is asserted against the backend's own source, not a running instance. |

Neither invalidates local correctness.

---

## 10. Next indexed TAB

**TAB 06** — Search + canonical service discovery (Backend TAB 03).
