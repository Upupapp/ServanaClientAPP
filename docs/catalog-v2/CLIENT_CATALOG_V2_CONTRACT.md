# CLIENT_CATALOG_V2_CONTRACT

The canonical catalog contract the Customer Mobile App consumes.

Frozen 2026-08-11 against **measured production** — the tables on
`192.46.224.126`, the deployed `/api/services*` responses, and the SQL the new
public router issues, executed read-only against the production database. Not
transcribed from a design document.

---

## 1. Why this contract exists

Catalog V2 shipped with exactly one read surface:

```
/api/admin/catalog/*      verifyAuth → verifyRoles([1]) → requirePermission(services.*)
```

A customer app cannot hold role 1, and must not be given a way to (§6, §11,
§12). So there was no canonical hierarchy the Client could legally read, and the
only remaining route to a `Category → Subcategory → Service` tree was to rebuild
the taxonomy in Dart from the legacy option shape — manufacturing the catalog on
the frontend, which §3 and §30 forbid.

**That, not the app code, is what blocked the Client migration.** This contract
is the missing half.

## 2. Surface

Additive. Read-only. Unauthenticated, consistent with the `/api/services*`
reads it sits beside. Backend commit `2bdaf0d`.

| Route | Returns |
|---|---|
| `GET /api/catalog` | `{ categories: Category[], summary: Summary }` |
| `GET /api/catalog/summary` | `Summary` |
| `GET /api/catalog/services` | `{ services: Service[], summary: Summary }` |
| `GET /api/catalog/services/:serviceId` | `ServiceDetail` |

Envelope: `{ "status": "success", "data": … }` /
`{ "status": "failed", "message": …, "code"?: … }`.

`GET /api/catalog` is **one request for the whole hierarchy** — three SQL
statements regardless of catalog size. On today's 3/12/95 shape the per-level
alternative is 16 round trips before the first card renders (§92).

## 3. The canonical bookable entity

```
services.id
```

Same integer through Admin, the public catalog, Service Detail, the booking
draft, the booking payload, `bookings.catalog_service_id` and
`catalog_provider_services.service_id`.

**Measured fact that shapes everything below:** `services.id ==
legacy_service_option_id` for **all 95** promoted rows. The app has therefore
been sending the canonical id all along, under the name `serviceOptionId`.

That equality is an artefact of the promotion migration, **not a rule**. A
Service created through the Admin API takes its id from
`catalog_services_id_seq` and has no legacy option at all. Both the client
handoff and the backend insert resolve through the relationship rather than
copying the number, so both stay correct after the first Admin-created Service.

## 4. Projections

### Service (browse + list)

```
id · subcategoryId · subcategoryName · categoryId · categoryName
name · slug · shortDescription · imageUrl
status · displayOrder · bookable
basePrice · unit · basePriceSummary · estimatedDurationMins
updatedAt
```

### ServiceDetail

The above plus `fullDescription`, `inclusions[]`, `exclusions[]`, `addons[]`,
and **`available`**.

### Addon

```
id · name · unit · basePrice · basePriceSummary · durationMins
```

`addons[].id` is a `service_options.id`. It is **configuration identity and
never a bookable Service id** — routing to Service Detail with it is a bug.

### Category / Subcategory

```
id · name · slug · description · imageUrl · displayOrder
```
plus `subcategoryCount` / `serviceCount` / nested children.

### Summary

```
categories · subcategories · services · lastUpdatedAt
```

## 5. Withheld on purpose (§11, §58, §125)

`providerCount` · `catalog_provider_services` rows · `legacy_service_option_id`
· `legacy_service_family_id` · `archivedAt` · audit fields · content-gap
analytics.

A customer learns what they can book, never how thin supply is behind it or how
the catalog was migrated. `legacy_service_option_id` IS read server-side as the
add-on join key; it is never projected.

## 6. Visibility rules

Browse returns rows where **all three levels** are `status = 'active'`. A live
Service under a deactivated Category is not browsable.

`GET /api/catalog/services/:serviceId` is **deliberately not status-filtered**.
§54 requires an old link to an archived Service to land on "This service is
currently unavailable" rather than a dead end, and §55 requires a moved Service
to keep resolving on the same id. Both need the row to come back.

**`available` is the backend's verdict** and folds in the Subcategory's and
Category's status as well as the Service's own `status` and `bookable`. The
client reads it; it never recomputes it. A client deriving availability from
`status` alone would disagree with the backend the moment a Category is
deactivated.

Status domain: `draft` · `active` · `inactive` · `archived`. The client parses
anything else to `unknown`, which is treated as **not visible and not bookable**
— withholding a real service is recoverable, offering an unbookable one is not.

## 7. Ordering

`display_order, name`.

The name tie-break is load-bearing, not cosmetic. **Every hierarchy row in
production still has `display_order = 0`** because reorder has never been
exercised, so ordering by `display_order` alone hands the customer an arbitrary
insertion order that can change between deploys. The client does not re-sort
(§57).

## 8. Timestamps

ISO 8601 with a UTC designator: `2026-08-11T11:03:23.421Z`.

The underlying columns are **not** in that form — production emits
`2026-08-11 11:03:23.421016+00`, with a space where ISO wants `T` and a
two-digit offset where ISO wants ±HH:MM. The backend normalises on the way out.

Two things worth recording, because they differ by platform:

- **Node** `new Date()` rejects the bare `+00`. A fix that repairs only the
  space returns `NaN` and falls through to the raw value. Both deviations must
  be repaired together.
- **Dart** `DateTime.parse` accepts the raw Postgres form as-is. Verified:
  `DateTime.parse('2026-07-15 02:51:24.993763+00')` →
  `2026-07-15T02:51:24.993763Z`.

The client still routes every backend timestamp through
`parseBackendTimestamp` — defence in depth, and more importantly a single place
that returns `null` instead of throwing, so an unreadable timestamp cannot take
a list builder down. `catalog_contract_test.dart` pins the SDK's actual
behaviour so the Dart claim above is checked rather than believed.

## 9. `level2` is not in this contract

`/api/catalog/*` is **exempt from `parityMiddleware`**, which maps
`name → serviceName | service_name | level2 | level_2`.

Without the exemption a canonical Service arrives carrying `level2: "<its own
name>"` — while `level2` means the **Subcategory** in the legacy model. That
defect was found in production on the admin surface. It matters more here: this
is the contract the Flutter clients actually migrate onto.

Guarded on both sides. Backend: `catalog-public-contract.test.ts` asserts no
banned key appears in any projection and that `app.ts` carries the prefix.
Client: `catalog_contract_test.dart` asserts the model exposes no such key AND
that a poisoned payload carrying `level2` is ignored rather than absorbed.

## 10. Caching

`Cache-Control: public, max-age=300` and a weak ETag derived from
`MAX(services.updated_at)`. An unchanged catalog costs a 304 and no body.

Client policy — two independent signals, answering different questions:

| Signal | Question |
|---|---|
| 6h TTL | is this old? |
| `summary.lastUpdatedAt` | did the catalog actually change? |

An admin edit moves `lastUpdatedAt`, which is exactly the event the client must
not miss. Cache box is `catalog_cache_v2`; the version is in the **box name**,
so an incompatible cache is never opened and there is no parse to get wrong.

## 11. Content coverage — measured, and it constrains the UI

Of 95 active Services:

| Field | Populated |
|---|---:|
| `basePrice` | 95 |
| `bookable` | 95 |
| `shortDescription` | **41** |
| `fullDescription` | **0** |
| `imageUrl` | **0** |
| `estimatedDurationMins` | **0** |

Categories with an image: **0**.

So the app's `serviceImageAsset` keyword map remains the only source of art, and
every duration/description in the UI must tolerate null. `imageUrl` is honoured
first so this stops being true the day the backend fills it in. This is a
content gap, not a contract gap.

## 12. Configuration model

There are **no per-Service options** in the data. The `1 HP / 1.5 HP` pattern
does not exist as configuration: each variant was promoted to its own canonical
Service. Only **add-ons** exist, and only **5 in the entire catalog**, all under
service 1 (`Gluta Drip`).

**There is no questions table.** Customer questions (§71) have no backend model
at all. Not implemented, not stubbed — see the gaps list in the final report.
