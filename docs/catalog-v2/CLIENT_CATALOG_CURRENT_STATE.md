# Client catalog — current state (§3 SWEEP)

Measured 2026-08-11 against `main` @ `c6c3083` and against **production**
(`api.servana.com.ph`, Postgres on 192.46.224.126). Nothing here is inferred
from documentation.

---

## 1. The live hierarchy is FOUR levels, and none are called what V2 calls them

```
services.category         Home Services · Personal Care · Home Maintenance
services.name             Aircon 2 · Beauty & Wellness · Massage · Electrical Services
service_options.level_2   Cleaning · Installation · Repair · Facial · Hair · Nails · Beauty Drip
service_options.level_3   Aircon Cleaning for Cassette Type   <-- what a customer actually books
```

Measured from production:

| services.category | services.name | level_2 | level_3 count |
| --- | --- | --- | --- |
| Home Services | Aircon 2 | Cleaning | 15 |
| Home Services | Aircon 2 | Repair | 10 |
| Home Services | Aircon 2 | Installation | 3 |
| Home Services | Aircon 2 | Maintenance Plan | 1 |
| Home Services | Aircon 2 | Refrigerant (freon) | 1 |
| Personal Care | Beauty & Wellness | Nails | 17 |
| Personal Care | Beauty & Wellness | Hair | 14 |
| Personal Care | Beauty & Wellness | Massage | 10 |
| Personal Care | Beauty & Wellness | Facial | 8 |
| Personal Care | Beauty & Wellness | Beauty Drip | 5 |
| Personal Care | Beauty & Wellness | Beauty Drip (Add Ons) | 5 |
| Personal Care | Massage | Massage & Wellness | 10 |
| Home Maintenance | Electrical Services | Electrical | 1 |

`services` columns: `id, name, category, created_at, service_type, worker_title,
worker_role, deleted_at`.
`service_options` columns: `id, service_id, level_2, level_3, unit, base_price,
option_type, parent_option_id, created_at, is_active, updated_at, duration_mins,
banner_url`.

**There is no `subcategories` table and no `categories` table.** `category` is a
free-text column on `services`.

## 2. The app's "categories" are HARDCODED CLIENT-SIDE

`lib/modules/categories/domain/category_experience.dart` →
`CategoryPresentationRegistry`. Each app category is a `(serviceId, level_2
filter)` pair invented in Dart:

```dart
beautyWellness  serviceId 2  level2AllowList {'drip', 'facial'}
hairAndNails    serviceId 2  level2Pattern  r'hair|nail|manicure|pedicure'
massage         serviceId 2  level2Pattern  r'massage'
aircon          serviceId 1  (no filter — all level_2)
generic         serviceId 0
```

So "Hair & Nails" is not a backend entity. It is a regex over `level_2` shipped
in the app binary. Consequences that matter for V2:

- §43/§44/§45 (backend `displayOrder` for category/subcategory/service) are
  **impossible today** — the backend has no order to send, and the app does not
  ask.
- Adding a category currently requires an **app release**, not an admin action.
- The regexes are matched with `contains`, deliberately
  (`category_experience_repository.dart:40-57`) — the allow-list holds short
  keys while the backend sends full labels. That is load-bearing and already
  caused a defect once.

## 3. Endpoints the client actually calls

From `lib/common/data/backend/servana_api_client.dart`:

```
GET /api/services                                 list of services rows
GET /api/services/full                            whole catalog, nested
GET /api/services/:serviceId/level2               level_2 values for a service
GET /api/services/:serviceId/options-with-addons  level_3 rows + add-ons   <-- the one the UI uses
GET /api/services/:serviceId/branches
GET /api/branches/:branchId/slots
GET /api/services/:serviceId/coverage-geo[/check]
```

All are unauthenticated (verified live: a garbage bearer token still returns
200). `options-with-addons` returns `basePrice` as a **string** ("3190"); the
`/services/full` shape returns `base_price` as a **number**. Both spellings are
handled in `catalog_price.dart`.

## 4. What is bookable today

The customer picks a `service_options` row (a **level_3**). The booking then
carries `serviceId` — which is the `services.id` (1 or 2), i.e. the *container*,
not the thing chosen. The chosen option travels separately through the booking
stores (`BwBookingStore.selectOption` / `AirconBookingStore.selectOption`) as
the raw option map.

**This is the crux of the migration.** See CLIENT_CATALOG_CONTRACT.md §3.

## 5. Catalog surface inventory

| concern | location | notes |
| --- | --- | --- |
| Registry (taxonomy) | `modules/categories/domain/category_experience.dart` | hardcoded, 5 entries |
| Repository | `modules/categories/data/category_experience_repository.dart` | filters level_2 client-side |
| Controller/state | `modules/categories/application/category_experience_controller.dart` | `ChangeNotifier`, idle/loading/success/failure |
| Category screen | `modules/categories/presentation/screens/category_experience_screen.dart` | serves all 4 categories |
| Legacy per-category screens | `aircon_repair`, `beauty_wellness`, `hair_nails`, `massage` | **routed and reachable** via `main_router.dart` + `quick_book_sheet.dart` |
| Home category cards | `modules/homepage/...` | 4 fixed cards |
| Search | `modules/homepage/presentation/screens/search_screen.dart` | own fetch, own error state |
| Campaign popups | `common/presentation/category_campaign/category_campaign_registry.dart` | 4 hardcoded, Remote-Config gated |
| Service thumbnails | `common/presentation/widgets/service_thumbnail.dart` | 6-image keyword map + catch-all |
| Booking stores | `bw_booking`, `aircon_booking` | hold the selected raw option map |

## 6. Compatibility risks for a V2 migration

1. **Two parallel category UIs exist.** `CategoryExperienceScreen` and the four
   legacy screens both ship and are both reachable. Any V2 work must change
   both or delete one first.
2. **`serviceId` means the container, not the choice.** Renaming level_3 to
   "Specific Service" changes which ID is canonical for booking. That ID flows
   to provider matching, admin, payments and history.
3. **No status/visibility field on the taxonomy.** `service_options.is_active`
   exists; `services` has only `deleted_at`. §46–§49 (status filtering,
   archive behaviour) have no backend field to read for categories.
4. **No slug, no description, no image, no displayOrder** on any catalog table.
   §6's models cannot be populated from the current schema.
5. **Search** has a separate fetch and error path from the category screens;
   hierarchy context (§15) does not exist in the payload.
6. **Historical bookings** already store a snapshot; nothing reads a subcategory,
   so §27/§28 are currently satisfied by accident rather than by design.
