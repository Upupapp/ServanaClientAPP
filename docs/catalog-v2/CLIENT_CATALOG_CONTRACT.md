# Backend Catalog contract (§4) — and why V2 cannot be built yet

Measured 2026-08-11 against `servana_api-main` @ `d0f1658` (= deployed HEAD)
and production Postgres.

---

## 1. Catalog V2 does not exist on the backend

Searched the backend source for the concept the command is built on:

```
grep -rniE "subcateg|sub_categ" src/ --include=*.ts   ->  ZERO matches
```

- No `subcategories` table. No `categories` table.
- No `/catalog/v2` route, no versioned catalog route, no contract discriminator.
- The only versioned catalog namespace is `/provider-catalog/v1/offerings`,
  which is provider-facing and unrelated to customer discovery.

§4 says *"Do not invent the mobile API contract."* §2 says *"Do not calculate
authoritative category relationships locally"* and *"Do not manufacture services
from frontend data."* With no backend hierarchy, any Category/Subcategory model
I add to the app would be exactly that — manufactured. So the app work is
gated, not merely unstarted.

## 2. The contract as it actually is

| endpoint | auth | returns |
| --- | --- | --- |
| `GET /api/services` | none | `{status, data[]}` — `id, name, category, serviceName, level2, …` |
| `GET /api/services/full` | none | nested catalog; `base_price` **number** |
| `GET /api/services/:id/level2` | none | level_2 labels for one service |
| `GET /api/services/:id/options-with-addons` | none | level_3 rows; `basePrice` **string** |
| `GET /api/services/:id/branches` · `/branches/:id/slots` | none | scheduling |
| `GET /api/services/:id/coverage-geo[/check]` | none | serviceability |

Live samples: `/api/services` 200 / 5,988 B · `/api/services/full` 200 / 32,231 B ·
`/api/services/1/options-with-addons` 200 / 25,556 B ·
`/api/services/2/options-with-addons` 200 / 51,042 B. Unauthenticated, and a
garbage bearer token still returns 200.

**Absent from every response**, and required by §6/§11/§43–§49:
`slug`, `description`, `image`, `displayOrder`, `status`, `bookable`,
`duration` (except `duration_mins` on options), and any subcategory id.

## 3a. DECIDED 2026-08-11 — and my §3 below contained a factual error

**Canonical rule (owner decision): `services.id` is the bookable entity.**
Categories and Subcategories are discovery/taxonomy. `service_options` are
configuration underneath a Service and must never be the canonical bookable
identity.

```
categories.id -> subcategories.id -> services.id (BOOKABLE) -> service_options.id -> addons/questions
bookings.service_id          -> services.id
provider_services.service_id -> services.id
```

**Correction to §3 below: I wrote that bookings today carry `services.id`.
They do not.** Measured on production:

```
bookings columns: id, user_id, user_address_id, service_option_id, schedule, ...
                                                ^^^^^^^^^^^^^^^^^
```

There is **no `service_id` column on `bookings` at all**. Real rows:

| booking | service_option_id | level_2 | level_3 | services.id |
| --- | --- | --- | --- | --- |
| 110 | 4 | Beauty Drip | Emperor's Drip | 2 |
| 107 | 15 | Facial | Pimple Facial | 2 |

So production **already books against `service_options.id` (level_3)** — the
"legacy representation" the decision anticipates. That is now measured, not
assumed, and it answers the question the decision left open.

A second fact neither document had: **provider capability is at a different
level from booking.** `employee_services.service_id` references `services.id`,
so a provider is qualified for "Beauty & Wellness" as a whole while the customer
books "Emperor's Drip". Promoting level_3 to `services` therefore does not just
move a foreign key — it changes what provider qualification *means*, and
`employee_services` rows must be expanded from 4 coarse services to ~90 specific
ones or the matching pool collapses to zero.

Scope of the migration this implies (backend-side, not mobile):

1. Create `categories` and `subcategories` with `id, name, status, displayOrder`
   (+ `categoryId` on subcategory).
2. Promote each customer-selectable `level_3` to a `services` row with a NEW id,
   `subcategory_id`, `status`, `displayOrder`, `bookable`.
3. Keep a legacy map `service_options.id -> services.id` so the 109 existing
   bookings stay readable without rewriting history.
4. Add `bookings.service_id`, dual-write it alongside `service_option_id`, and
   only later stop writing the old column.
5. Expand `employee_services` from 4 rows-per-provider to the promoted services,
   or auto-derive capability from the parent, before any matching runs on the
   new ids.
6. Verify against Mobile, Provider Web, Provider Mobile and Admin before
   retiring level_3-as-bookable.

**Mobile impact of the decision: none yet, and that is the point.** The app
sends `serviceId` in the booking payload and the backend resolves the option;
until `bookings.service_id` exists and is authoritative, there is nothing for
the client to change. Client prep work that is safe today is in §5.

## 3. THE BLOCKING DECISION — what is a "Specific Service"? (superseded by §3a)

The command's own example is:

```
Air Conditioning  ->  AC Cleaning  ->  Split-Type AC Cleaning
```

Mapped onto live data, that is:

```
services.name "Aircon 2"  ->  level_2 "Cleaning"  ->  level_3 "Aircon Cleaning for Cassette Type"
```

So **Specific Service = a `service_options` row (level_3)**.

But today the booking carries `serviceId` = `services.id` (1 or 2) — the
*container*. The level_3 the customer actually chose travels separately as a raw
option map inside the booking stores.

That produces a direct conflict inside the command:

- §19 *"The booking request must continue sending canonical `serviceId`"*
- §2 *"Do not regenerate Service IDs"*
- §25 *"Must continue booking with the same Specific Service ID used by provider
  eligibility/matching"*

If Specific Service is level_3, then the canonical booking identifier must
change from `services.id` to `service_options.id`. That is not an app change.
It changes the booking contract for **all five consumers** — customer mobile,
customer web, provider mobile, provider web, admin — plus provider matching,
pricing, payments and 109 rows of booking history.

If instead Specific Service stays `services.id`, then Servana has exactly
**four** bookable services and the command's example is wrong.

**Only the backend/product owner can decide this. Everything in §6–§128 depends
on the answer, and picking one in the app would silently fork the taxonomy from
Web (§78) — the precise outcome §2 forbids.**

## 4. What the backend must ship before the app work can start

1. A decision on §3 above, written down.
2. `categories` and `subcategories` as real entities with stable ids, or an
   explicit statement that `services.category` / `level_2` ARE those entities
   and will be given ids.
3. Per-entity `status` and `displayOrder` — §43–§49 are unimplementable without
   them, and today `services` has only `deleted_at`.
4. `slug`, `description`, `image` where the V2 models require them, or a
   documented decision that the app keeps supplying its own art (it does today,
   via a 6-image keyword map).
5. A contract discriminator (§86), so the client is not left guessing JSON
   shapes during the migration window.
6. A statement of the compatibility window (§5, §113): how long legacy
   `Category -> Services` stays supported.

## 5. What can proceed in the app WITHOUT the backend

These are genuinely independent and worth doing regardless of the decision:

- **Delete one of the two parallel category UIs.** `CategoryExperienceScreen`
  and the four legacy screens both ship and are both routed. This is prep work,
  not V2 work, and it halves the surface any migration must touch.
- **Move the taxonomy out of the binary.** Today adding a category needs an app
  release. Even without V2 the registry could be fed from Remote Config, which
  the app already uses for campaigns.
- **Cache versioning (§36/§37).** A `catalogCacheVersion` can be introduced now
  and is required later either way.
- **Hierarchy context in search results (§15).** Needs a payload field; blocked.

## 6. Verdict input

The gate is §4, and it fails: there is no V2 contract to build against, and the
one structural question — which row is the bookable entity — is a
cross-platform booking-contract decision, not a mobile one.
