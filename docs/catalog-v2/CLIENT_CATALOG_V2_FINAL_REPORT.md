# CLIENT CATALOG V2 — FINAL REPORT

2026-08-11. Backend `servana_api` `2bdaf0d` + `db0fcc5`; client `d6d32bd`.
**Both local. Nothing pushed, nothing deployed, nothing released.**

---

## What the command assumed, and what was actually true

The command opened with *"the backend + Admin Catalog V2 contract is
production-certified"*. That is correct, and it is only half the picture.

Catalog V2 shipped with exactly **one** read surface — `/api/admin/catalog/*`,
gated `verifyAuth → verifyRoles([1]) → requirePermission(services.*)`. A
customer app cannot hold role 1 and must not be given a way to. So there was no
canonical hierarchy the Client could legally read, and the only remaining route
to a `Category → Subcategory → Service` tree was to rebuild the taxonomy in Dart
from the legacy option shape — manufacturing the catalog on the frontend, which
§3 and §30 forbid.

**That was the blocker, and it was in the backend, not the app.** It is now
closed by an additive public read API.

The second surprise cut the other way. `services.id == legacy_service_option_id`
for **all 95** promoted rows, and the app already sends exactly that integer as
`serviceOptionId`. The customer's selection and the booking's service identity
had already converged; nobody had noticed, and nothing depended on it staying
true.

## Measured baseline

| Quantity | Measured |
|---|---:|
| Categories / Subcategories / Services | 3 / 12 / 95 |
| Services active · bookable · priced | 95 · 95 · 95 |
| `services.id == legacy_service_option_id` | **95 of 95** |
| Active MAIN options ↔ Services | 95 ↔ 95, exact |
| Active ADD_ON options | 5 (all under service 1) |
| Per-Service options | **0 — the concept has no data** |
| Questions | **0 — no table exists** |
| Bookings · carrying `catalog_service_id` before the fix | 111 · 109 |
| Provider capabilities | 1,128 |
| Services with an image · duration · full description | **0 · 0 · 0** |
| Services with a short description | 41 |

## Defects found and closed

**`bookings.catalog_service_id` had no writer.** Migration 020 added it saying
it would be *"written only from Phase 4, for NEW bookings"*; 021 backfilled
history; Phase 4 was never built. The two bookings created since the backfill
were already NULL, so a reader could not tell "not migrated" from "new booking".
Now written on create — resolved through a subselect on
`legacy_service_option_id`, not by copying `serviceOptionId`, because the copy
passes every test today and writes a dangling id for the first Admin-created
Service.

**11 of 95 Services were unbrowsable.** The hardcoded Dart registry mapped only
families 1 and 2, so `Massage & Wellness` (10) and `Electrical` (1) had no entry
point. **1 of those was also unsearchable** — the old index dropped any family
its name regex did not recognise.

**Search resolved to the wrong thing.** Results were keyed on the legacy family
id grouped by `level_2`, so "pimple" matched the group "Facial" and landed the
customer on every Beauty & Wellness treatment with their query discarded.

## Defects found in my own work

**`GET /api/catalog` was unreachable.** `booking.routes` registers `GET /:id` at
the `/api` root and mounted first, so the browse root bound `id = "catalog"` and
answered 401 to exactly the unauthenticated app it was built for. The three
deeper `/catalog/*` paths worked, which is what made it look healthy.

My contract tests could not have caught it — they call `catalogPublicService`
directly and never exercise routing. Found by a parallel session's route-shadow
sweep. `catalog-route-shadow.test.ts` now drives a real listening Express
instance and reproduces the shadow with the order reversed. The `app.ts` hoist
itself sits in that session's working tree and is **not** in my commits, because
`app.ts` now also imports untracked `./api/v1/register`.

**I pinned an identifier name in a test — twice.** `catalog-public-contract`
asserted the literal `CANONICAL_CATALOG_PREFIXES`, which has since been renamed
to take `/api/v1`, so the test failed while the guarantee had actually widened.
The same mistake I had just corrected in `catalog-admin-contract`.

**I asserted a false premise about Dart.** I wrote that `DateTime.parse` rejects
the Postgres timestamp form. It does not — that is a JavaScript limitation. The
test now pins the SDK's real behaviour, and the client-side repair is documented
as defence in depth rather than the load-bearing fix it is on the backend.

## Gates

| Gate | Result |
|---|---|
| Backend typecheck | 0 |
| Backend tests | **157 suites / 3,000 tests** |
| Backend protected-contracts guard | green |
| Client `dart format` | 0 |
| Client `flutter analyze` | **0 errors, 0 warnings**, 41 infos |
| Client tests | **1,519 / 6 skipped** (was 1,466) |
| Client Android debug arm64 build | exit 0 |
| iOS build | not run — no macOS host |
| Production write | none. Every DB statement was read-only |

---

## CLIENT CATALOG V2 VERDICT

```
CERTIFIED_WITH_NONBLOCKING_GAPS
```

Certified for the browse, detail, search and identity path. Not certified as a
finished release — nothing is pushed, deployed or device-tested.

```
CANONICAL CLIENT HIERARCHY:
Category → Subcategory → Service

CANONICAL BOOKABLE ENTITY:
services.id

CATEGORY MODEL:                       MIGRATED
SUBCATEGORY MODEL:                    MIGRATED
SERVICE MODEL:                        MIGRATED
LEGACY LEVEL-3-AS-SERVICE:            COMPATIBILITY_ONLY
LEGACY service_option_id AS BOOKABLE: COMPATIBILITY_ONLY (wire name only —
                                      the value is canonical services.id)
LEVEL2 PARITY REGRESSION GUARD:       PASS
ISO TIMESTAMP GUARD:                  PASS
CATALOG CACHE:                        V2
SEARCH:                               CANONICAL
SERVICE DETAIL:                       CANONICAL
BOOKING DRAFT:                        CANONICAL
BOOKING PAYLOAD:                      CANONICAL (legacy field NAME retained)
ADMIN ↔ CLIENT PARITY:                PASS (same tables, same ids)
CLIENT ↔ PROVIDER SERVICE-ID PARITY:  PASS by construction —
                                      catalog_provider_services.service_id
                                      and bookings.catalog_service_id are the
                                      same services.id. NOT yet proven by a
                                      live end-to-end booking.
MOBILEVIEW:                           PASS at 320×568 (widget tests);
                                      not device-verified
ACCESSIBILITY:                        PASS by construction (semantics, 44dp,
                                      reduced motion); no TalkBack/VoiceOver run
ANDROID:                              PASS
iOS:                                  BLOCKED_BY_ENVIRONMENT
```

## Non-blocking gaps — stated, not implied

1. **Nothing is pushed or deployed.** The client migration is inert until the
   backend API is live; the app calls a route production does not yet serve.
2. **`app.ts` mount-order hoist is uncommitted**, in a parallel session's tree.
   Until it lands, `GET /api/catalog` is shadowed and my shadow test fails —
   which is the correct signal, not a broken test.
3. **No live end-to-end booking** has traversed catalog → booking → matching.
   The identity is correct by construction and by test; it is not yet observed.
4. **Branch/slot and coverage-geo still key on the legacy family.** Backend
   re-keying to `services.id` is the right fix; the public catalog deliberately
   does not expose `legacyServiceFamilyId`.
5. **Favorites and recent-services do not exist** in this app. Nothing to
   migrate; §38/§39 are vacuous here rather than done.
6. **Customer questions have no backend table.** Not deferred — absent.
7. **Catalog analytics dimensions not added.** No event was emitting a legacy id
   as service identity, so nothing was wrong; adding
   `categoryId`/`subcategoryId`/`serviceId` is still outstanding.
8. **No device, TalkBack/VoiceOver, or 200%-text verification.**
9. **Legacy category screens remain routed.** Deliberate — their route names are
   live deep-link targets (§49). Retiring them is a separate step.
10. **The catalog has no imagery, durations or long descriptions.** A content
    task for Admin, not a build task.

## Next actions

**My side** — nothing further without a decision; the work is committed and
green locally.

**Your side**

1. Decide whether to push. `servana_api` `2bdaf0d` + `db0fcc5` must deploy
   **before** the client build ships, or the app calls a 404. The parallel
   session's `app.ts` hoist must be in that same deploy.
2. Smoke `GET /api/catalog` on production after deploy — it is the one route
   that was shadowed.
3. Make one real booking end to end and confirm `bookings.catalog_service_id` is
   populated on a NEW row.
4. Decide whether the canonical `/catalog` browse replaces the home category
   cards, or ships alongside them for one release.
