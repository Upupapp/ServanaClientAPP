# CLIENT_CATALOG_V2_MIGRATION

Sweep, legacy dependency map, options classification and booking contract for
the Customer Mobile App's Catalog V2 migration.

Measured 2026-08-11 against production and against `main` at `80eff51`.
Companion to `CLIENT_CATALOG_V2_CONTRACT.md`.

---

## 1. Current-state sweep

### 1.1 What the app did before this change

| Concern | Location | Identity | Verdict |
|---|---|---|---|
| Taxonomy registry | `modules/categories/domain/category_experience.dart` | `(familyId, level_2 regex)` **hardcoded in Dart** | KEEP (legacy path retained) |
| Category repository | `modules/categories/data/category_experience_repository.dart` | filters `level_2` client-side | KEEP |
| Category screen | `modules/categories/presentation/screens/category_experience_screen.dart` | legacy | KEEP |
| Search index | `modules/search/data/search_repository.dart` | family id + `level_2` group | **REFACTORED → canonical** |
| Search result model | `modules/search/domain/search_result.dart` | family id | **REFACTORED → `services.id`** |
| Search screen | `modules/homepage/presentation/screens/search_screen.dart` | routed on an app-side enum | **REFACTORED → canonical route** |
| Booking stores | `bw_booking`, `aircon_booking` | raw legacy option map | KEEP, seeded canonically |
| Service art | `common/presentation/widgets/service_thumbnail.dart` | keyword map | KEEP — backend has no imagery |
| Timestamps | ad hoc | — | **NEW** `common/domain/time/iso_timestamp.dart` |
| Canonical catalog | — | — | **NEW** `modules/catalog/**` |

The legacy category path is retained deliberately. Its four route names
(`AirconRepair`, `BeautyWellness`, `HairNails`, `Massage`) are live deep-link and
notification targets; retiring them is a separate step once no build in the
field still emits them (§49, §143). There is one canonical catalog domain — the
legacy screens are a compatibility surface, not a second catalog.

### 1.2 Two measured defects in the pre-migration app

**11 of 95 canonical Services were unbrowsable.** The hardcoded registry mapped
only families 1 and 2, so the standalone `Massage` family (10 Services, now
`Personal Care › Massage & Wellness`) and `Electrical Services` (1) had no entry
point at all.

**1 of those was also unsearchable.** The old index dropped any family
`categoryIdFromService` did not recognise. `Massage` survived by a name-regex
fallback; `Electrical Services` matched nothing and was silently excluded.

Both are closed by sourcing browse and search from the canonical hierarchy: all
95 are now reachable by construction, because nothing filters on a hardcoded
list any more.

## 2. Legacy dependency map

Where each legacy token appears, and what it actually means:

| Token | Occurrences | Classification |
|---|---|---|
| `level2` / `level_2` | categories module, legacy repo | **LEGACY CATALOG IDENTITY** — untouched in the legacy path, absent from the canonical one |
| `level3` / `level_3` | booking stores, option maps | **HISTORICAL COMPATIBILITY** — a legacy *field name* carrying canonical data. `canonicalOptionMap` sets `level3 = services.name` because every existing booking screen reads that key |
| `serviceOptionId` | booking payload | **HISTORICAL COMPATIBILITY** — the wire name is legacy, the value is canonical `services.id` |
| `service_option_id` | backend bookings column | **LEGACY, still authoritative** — untouched; `catalog_service_id` is written alongside |
| `parent_option_id` | backend add-on join | **TRUE SERVICE CONFIGURATION** |
| `MAIN` | backend option type | **LEGACY CATALOG IDENTITY** — all 95 MAIN rows were promoted to Services |
| `ADD_ON` | backend option type | **TRUE SERVICE CONFIGURATION** — the 5 surviving add-ons |
| `serviceFamily` | — | **UNRELATED** — zero occurrences in `lib/` |

By group:

- **Catalog browsing** — canonical (new module). Legacy path retained for routes.
- **Search** — canonical. Result identity, tap target and filter chips all moved.
- **Service detail** — canonical, new.
- **Booking** — canonical identity through a legacy-shaped option map.
- **Pricing** — legacy quote endpoint, unchanged. Values are canonical.
- **History / repeat booking** — legacy, unchanged. Reads snapshots, so stable.
- **Favorites / recent** — **not implemented in this app.** No feature exists to migrate.
- **Deep links** — canonical routes added; legacy names retained.
- **Notifications** — routing unchanged; no catalog payloads exist to migrate.
- **Cache** — `catalog_cache_v2`, versioned in the box name.
- **Analytics** — see §5.

## 3. Service options migration

Classification of every active `service_options` row:

| Class | Count | Disposition |
|---|---:|---|
| **LEGACY TAXONOMY → promoted** | 95 | Each MAIN option became a canonical Service. `services.id == legacy_service_option_id` for all 95. |
| **TRUE ADD-ON** | 5 | Remain configuration, all under service 1 (`Gluta Drip`). Surfaced as `addons[]` on Service Detail. |
| **TRUE OPTION** | 0 | **None exist.** |
| **QUESTION** | 0 | **No questions table exists in the schema.** |
| **UNKNOWN** | 0 | — |

Two consequences worth stating plainly:

**The `1 HP / 1.5 HP` model in the brief does not exist in the data.** Each
variant was promoted to its own Service (`Aircon Cleaning for Cassette Type` is
a separate `services.id` from the window-type equivalent). So §8's "book the
Service, select the option" shape has no per-Service option list to render, and
none was invented — §69 forbids re-presenting promoted level-3 rows as options,
which is exactly what building one would have done.

**Customer questions (§71) have no backend model.** Not deferred, not stubbed —
there is no table. Listed as a gap, not built.

## 4. Booking V2 contract

### What is canonical now

```
Service Detail (services.id)
  → canonicalOptionMap()  id = services.id
  → booking store selectedOption['id']
  → payload  serviceOptionId = services.id
  → backend  INSERT bookings (service_option_id, catalog_service_id)
             catalog_service_id resolved via legacy_service_option_id
  → catalog_provider_services.service_id
```

`bookings.catalog_service_id` was added by migration 020 with the comment
*"written only from Phase 4, for NEW bookings"*. Phase 4 was never built:
migration 021 backfilled history and nothing wrote it again. Measured before the
fix — **109 of 111 bookings carried it, and the two created since the backfill
were NULL**, so a reader could not distinguish "not migrated" from "new
booking". Backend `2bdaf0d` writes it on create.

The insert resolves through a subselect on `legacy_service_option_id` rather
than copying `serviceOptionId`. The copy would pass every test today — the ids
coincide — and write a dangling id for the first Admin-created Service, whose id
comes from `catalog_services_id_seq` and has no legacy option.

### What is NOT migrated, and why

The **payload field is still named `serviceOptionId`**. Renaming it is a
five-consumer breaking change to a live booking contract (§4, §63) and buys
nothing: the value is already canonical. The rename belongs with a versioned
booking endpoint, not with this migration.

Two sub-flows remain keyed on the legacy family and need backend work first:

- **branch/slot selection** — `GET /api/services/:familyId/branches`
- **coverage-geo serviceability** — `/api/services/:familyId/coverage-geo`

Neither is reachable from the canonical handoff for a non-branch Service, which
is every Service in production today. The public catalog deliberately does not
expose `legacyServiceFamilyId` (§125), so re-keying these endpoints to
`services.id` is the correct fix rather than leaking provenance to the client.

## 5. Analytics

Catalog events already carried `serviceCategory` as a **string label**, not a
legacy id, so nothing was emitting `serviceOptionId`-as-service identity. No
event was rewired in this pass, and no new event was added — adding
`categoryId` / `subcategoryId` / `serviceId` dimensions to the catalog funnel is
listed as a gap rather than claimed.

## 6. Cache

Box `catalog_cache_v2`. The version lives in the **box name**, so an
incompatible cache is never opened and there is no parse to get wrong — a
legacy payload deserialised into `Catalog` would not throw, it would yield
Services with `id: 0` and blank hierarchy, which renders as a catalog of blanks
that all route to the same non-existent Service.

`legacyBoxNames` is empty and that is correct: the legacy catalog was
session-memory only and never persisted. Auth, profile, addresses, drafts and
preferences live in other boxes and are untouched (§46).
