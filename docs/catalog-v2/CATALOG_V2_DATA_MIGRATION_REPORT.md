# Catalog V2 — data migration baseline (§41)

Measured on **production** 2026-08-11. Not a projection from documentation.

---

## CANONICAL STATEMENT (§45, verbatim)

```
CANONICAL CATALOG V2 BOOKABLE ENTITY:
services.id

CURRENT PRODUCTION LEGACY BOOKABLE ENTITY:
bookings.service_option_id → legacy service_options Level 3

CURRENT PRODUCTION PROVIDER CAPABILITY:
employee_services.service_id → legacy coarse services.id

TARGET PROVIDER CAPABILITY:
provider/employee service capability → canonical specific services.id

MIGRATION REQUIREMENT:
Bookings and provider capabilities must be migrated independently and converge
on the same canonical services.id BEFORE Catalog V2 matching is enabled.
```

---

## 1. Inventory

| quantity | measured |
| --- | --- |
| Distinct `services.category` (candidate Categories) | **12** |
| `services` rows, not deleted (legacy coarse) | **19** |
| Distinct `(service_id, level_2)` (candidate Subcategories) | **13** |
| Active `service_options` (candidate Specific Services) | **100** |
| Providers (`role` 2 or 4) | **74** |
| `employee_services` rows | **105** |
| Providers holding ANY capability row | **20** |

## 2. Provider fan-out projection (§13, §18)

Descendant-aware, per §14 — each provider's coarse capability expanded only to
Specific Services beneath it. No cross product.

| quantity | measured |
| --- | --- |
| Legacy coarse capability rows | 105 |
| **Projected canonical specific capability rows** | **1,188** (≈11× fan-out) |
| Specific Services with ZERO providers after fan-out | **1 of 100** |
| Providers with legacy capability | 20 |
| Providers with V2 capability after fan-out | 19 |
| **Providers LOSING ALL capability** | **1** |

### §19 / §21 gate: PASSES on the numbers, with one defect to resolve

Only **one** provider would drop to zero capability, and only **one** Specific
Service would have no supply. Candidate-pool collapse — the risk flagged as the
hard release gate — **is not what the data predicts**, provided the fan-out is
descendant-aware.

**But the single loss has a clear, fixable cause.** See §3.

## 3. The real finding: the catalog is mostly junk rows, and providers are attached to them

Of 19 legacy coarse `services`, only **4** carry any options at all:

| services.id | name | providers | specific services |
| --- | --- | --- | --- |
| 1 | Aircon 2 | 14 | 30 |
| 2 | Beauty & Wellness | 12 | 59 |
| 52 | Massage | 6 | 10 |
| 62 | test193 | 7 | **0** |
| 65 | Service 0156 | 7 | **0** |
| 63 | dasdasd | 6 | **0** |
| 56 | sadas | 6 | **0** |
| 57 | sdsd | 6 | **0** |
| 58 | Computer Repair | 6 | **0** |
| 59 | sdsa | 6 | **0** |
| 61 | dsad | 6 | **0** |
| 53 | Hair | 6 | **0** |

**15 coarse services carry provider capability but have zero active options.**
Names like `test193`, `dasdasd`, `sadas`, `sdsd`, `sdsa`, `dsad` are test data
sitting in the production catalog with **6–7 providers approved against each**.

Consequences for the migration:

1. Those 15 services fan out to nothing, which is where the single
   zero-capability provider comes from.
2. Any Category/Subcategory built from `services.category` will inherit the junk
   unless it is filtered or deleted first — 12 "categories" is not 12 real ones.
3. `Hair` and `Computer Repair` are plausible-looking but have no options, so it
   is not safe to assume every zero-option row is disposable. Each of the 15
   needs an explicit keep/delete decision before Phase B.

**Recommendation: a catalog clean-up is a prerequisite to Phase B, not a
follow-up.** Building canonical taxonomy on top of this produces 12 categories
and 19 services of which most are noise, and the mapping CSV (§5) would carry
that noise permanently.

## 4. Booking migration (§7, §8)

- `bookings` has `service_option_id`, and **no `service_id` column**.
- All sampled bookings resolve cleanly to an active option (110 → option 4
  "Emperor's Drip"; 107 → option 15 "Pimple Facial").
- 109 bookings total; 0 completions ever.

Backfill looks low-risk **once** the level_3 → canonical services map exists,
because every booking points at exactly one option. Ambiguity classes
(`UNMAPPED` / `MULTIPLE_MATCHES` / `INVALID_LEGACY_REFERENCE`) cannot be counted
until that map is authored — no active level_3 may remain unmapped (§5).

## 5. What does NOT exist yet, and blocks §47

- No `categories` table. No `subcategories` table.
- No `status` or `displayOrder` on any catalog entity (`services` has only
  `deleted_at`; options have `is_active`).
- No `bookable` flag.
- No `bookings.service_id`.
- No legacy↔canonical mapping table.
- No canonical provider-capability projection endpoint (§29).

## 6. Mobile impact today

**None.** The client sends `serviceId` and the backend resolves the option. No
client change is possible or safe until the §47 minimum contract exists. Client
prep work that is safe now, and its status:

| item | status |
| --- | --- |
| Delete the duplicate category UI | **DONE** — `4d2b2a0`, four dead screens removed, route names preserved |
| Taxonomy out of the binary (Remote Config) | not started |
| `catalogCacheVersion` | not started |
