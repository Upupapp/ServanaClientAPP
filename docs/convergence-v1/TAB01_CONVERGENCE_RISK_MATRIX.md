# Matrix 3 — Business assumptions and convergence risk

**Servana Client Mobile Backend Convergence V1 · TAB 01**

The first two matrices record what exists. This one records what the client
*believes* — the assumptions baked into shipped code that convergence will
either preserve or break — and prices each one.

| Field | Meaning |
| --- | --- |
| **Assumption** | What the client's code takes to be true. |
| **Status** | `HOLDS` (backend evidence agrees) · `BREAKS` (v1 contradicts it) · `UNVERIFIED` (no local evidence either way). |
| **Severity** | `P0` blocks convergence · `P1` blocks a domain · `P2` degrades a feature · `P3` cleanup. |
| **Owner TAB** | Where the work belongs. Nothing here is scheduled by TAB 01. |

Severity is about *convergence*, not about the app as it stands today.

---

## 1. Register

| ID | Assumption | Client evidence | Backend evidence | Status | Sev | Owner |
| --- | --- | --- | --- | --- | :---: | --- |
| **R-01** | `GET /api/catalog` is served by the environment the app points at. | `catalog_repository.dart:3`; `servana_api_client.dart:525` | Route exists at HEAD (`catalogPublic.routes.ts:27`) and is **absent from `origin/main`**; `booking.routes.ts:44` registers `GET /:id` at the same mount | **BREAKS** | **P0** | Backend deploy — not this repo |
| **R-02** | Booking creation will have a canonical home in v1. | `servana_api_client.dart:664`; both booking stores | `POST /api/bookings` is `KEEP` in `LEGACY_ENDPOINT_MIGRATION_MATRIX.md`; the v1 contract has `GET /api/v1/bookings` and **no create** | **BREAKS** | **P0** | Backend contract command |
| **R-03** | The canonical namespace is reachable. | none — the client has never called it | `src/api/v1/contract.ts` **absent** from `origin/main`; `origin/main:src/app.ts` has **0** `api/v1` mounts; `CLIENT_ENDPOINT_PARITY_MATRIX.md`: *"0 cells on canonical … it is unpushed"* | **BREAKS** | **P0** | Backend deploy |
| **R-04** | A response body is the payload. | `servana_api_client.dart:249-251` returns the decoded map; each caller reaches into its own keys | v1 uses a **third** envelope — `{data, meta}` / `{error:{code,message,details,requestId}}` — deliberately incompatible with both legacy shapes (`src/api/v1/envelope.ts:1-32`) | **BREAKS** | **P0** | Client TAB 02 |
| **R-05** | Editing an address means delete-then-recreate. | `MASTERLIST` SC-043; `address_controller.dart` | v1 adds `PATCH /api/v1/customer/addresses/:addressId`; no legacy equivalent | **BREAKS** *(in the client's favour)* | P1 | Client, after R-03 |
| **R-06** | Payment status is only knowable by re-reading the whole booking. | `payment_webview_screen.dart:41` | v1 adds `GET /api/v1/bookings/:bookingId/payment` and `POST .../refunds` | **BREAKS** *(in the client's favour)* | P2 | Client, after R-03 |
| **R-07** | One catalog shape is enough. | `Merchant*` DTOs **and** `Catalog`/`Category`/`Subcategory`/`Service` both live in `lib/` | `/api/services/full` and `/level2` are `CANONICALIZE`; `/api/catalog*` is `ALIAS` | **BREAKS** | P1 | Client TAB 02 |
| **R-08** | One transport layer reaches the backend. | `ServanaApiClient` **and** `HttpBackend` both post to `/api/auth/signin`, `/api/auth/signup`, `/api/user/adduseraddress`, `/api/services`, `/api/services/:id/coverage-geo`, `/api/auth/resendverification` | both target the same routes | **BREAKS** | P1 | Client TAB 02 |
| **R-09** | Every notification action survives migration. | `deleteNotification` → `DELETE /api/user/notifications/:key` | `KEEP`; no v1 successor. v1 has list, unread-count, read, read-all — **no delete** | **BREAKS** | P2 | Backend contract, then client |
| **R-10** | Opening a booking chat may create the conversation. | `getBookingConversation` → `GET /api/bookings/:id/conversation` | v1 replaces it with an explicit `POST /api/v1/conversations`; SC-038 records the current lazy-create as a defect | **BREAKS** | P2 | Client, after R-03 |
| **R-11** | Reviews migrate as one feature. | 9 review calls in `reviews_repository.dart` | 4 have `ALIAS` successors; 5 (`GET/PUT/DELETE /api/reviews/:id`, `/reviews/me`, `.../report`) are `KEEP` | **BREAKS** | P1 | Backend contract, then client |
| **R-12** | Support migrates as one feature. | 11 support calls in `support_repository.dart` | Only `POST /api/support/tickets` has a v1 relative, and it is narrower — booking-scoped, `ROLE_SPECIFIC`, explicitly *"kept for contact that is genuinely not about a booking"* | **HOLDS** *(support stays legacy for V1)* | P2 | Deferred past V1 |
| **R-13** | The client may supply address coordinates. | SC-039; address write path | `GET /api/location/address-suggestions`, `GET /api/location/address-details/:placeId` exist and the client calls neither; coordinates drive service-area eligibility and transport pricing | **UNVERIFIED** *(route exists; no evidence the write path was hardened)* | P1 | Backend + client |
| **R-14** | The app the matrix describes is the app in customers' hands. | `pubspec.yaml` = `1.0.0+38`; `docs/SESSION_BRIEF.md`: Play serves **`+37`** | — | **BREAKS** | **P0** | Every TAB |
| **R-15** | Unused API surface is harmless. | 14 `ServanaApiClient` methods have no production caller, including `approve` and `mark-cash-paid` — payment approval | routes are role-guarded server-side | **HOLDS** *(no live exposure)* | P3 | Client cleanup |
| **R-16** | Status strings map cleanly to customer-visible state. | `booking_status.dart:112` maps `WORKER_ASSIGNED` → `assigned` | v1 adds `GET /api/v1/bookings/:bookingId/transitions` — server-authored next actions | **HOLDS** *(SC-037 re-verified closed)* | P2 | Client, after R-03 |
| **R-17** | Errors are strings. | `ServanaApiException(statusCode, body)`; the envelope comment records that *"ServanaClient casts `error` to String"* | v1 errors are typed `V1ErrorCode` with a `requestId` | **BREAKS** | P1 | Client TAB 02 |
| **R-18** | The cached catalog and the live catalog have the same shape. | `catalog_cache_v2` stores canonical `Catalog` JSON; box name carries the version | if v1's `CatalogTree` differs from the legacy `/api/catalog` body, the cache must be versioned again | **UNVERIFIED** *(schemas not diffed — see Matrix 2 §13)* | P1 | Client TAB 02 |

---

## 2. The three that gate everything

**R-03 → R-01 → R-14, in that order.**

R-03 is the master blocker and it is not fixable from this repository. The
canonical contract is 95 mounted endpoints, an OpenAPI document, a generated
registry and a passing test suite — all in 51 unpushed commits. Until it is
deployed, "migrate the client to v1" has no target. The backend's own generated
matrix already says this in its own voice: *"That is a deployment gap, not a
design gap, and the matrix says so rather than showing optimistic cells."*

R-01 is the same failure that has already happened once. `d6d32bd` shipped a
client that reads `GET /api/catalog` against a backend where that route lives
in an unpushed commit. `docs/catalog-v2/CLIENT_CATALOG_V2_FINAL_REPORT.md`
flagged it on 2026-08-11 and it is still true at `ce02830`. **Convergence V1
must not repeat this pattern**, and the cheapest guard is procedural: no client
commit targets an endpoint until that endpoint is on `origin/main`.

R-14 is why neither of the above can be fixed by shipping fast. Play serves
`+37`. Any endpoint the installed base calls has to keep working for as long as
customers decline to update, which the backend has already priced in — its
retirement criteria demand **90 consecutive days of zero hits** for a mobile
alias, versus 14 for web.

---

## 3. Sequencing implied by the register

Recorded as a finding of TAB 01, not as a plan. TAB 02 owns the plan.

1. **Nothing client-side can start** until R-03 clears (backend deploy) — and
   deploying is outside this repository's authority.
2. **R-04 and R-17 are one piece of work.** The envelope and the error type
   change together, they touch every one of the 78 API methods, and doing them
   per-domain means the client holds two response conventions at once.
3. **R-02, R-09 and R-11 are backend contract gaps**, not client work. Asking
   the client to migrate a domain whose canonical surface is partial produces
   exactly the `⚠ mixed` state the backend's parity matrix warns about.
4. **R-07 and R-08 are pure client debt** and are the only items here that can
   proceed with no backend dependency at all — the two catalog DTO families and
   the two transport layers. If TAB 02 needs work that is not blocked on a
   deployment, it is these.

---

## 4. Inherited claims re-verified

`docs/MASTERLIST_PENDING_ITEMS_SERVANA_CLIENT_APP.md` carries 151 open findings
and warns that 152 of them are agent-reported and unverified. Four were on the
direct path of this sweep and were checked against current source. All four
have moved:

| ID | Claim | Re-verified finding |
| --- | --- | --- |
| SC-031 / SC-048 | "Resend code calls a route that does not exist." | **Closed.** `POST /:bookingId/resend-otp` is mounted at `booking.routes.ts:43` and is on `origin/main`. |
| SC-036 / SC-058 | "`X-Idempotency-Key` is sent and read by nothing." | **Closed and shipped.** `bookingController.ts:53-58` reads and de-duplicates on it; `bookingIdempotency.ts` is on `origin/main`. |
| SC-024 | "`totalAmount` is not an alias of `finalPrice` — every booking renders ₱0.00." | **Closed.** Aliased in SQL at `bookingService.ts:562-566`, with a comment naming the app's "Amount" field. |
| SC-037 | "`WORKER_ASSIGNED` maps to `enRoute`, so the customer is told the provider is on the way too early." | **Closed.** `booking_status.dart:112-113` maps it to `BookingStatus.assigned`; `enRoute` is reached only from `EN_ROUTE`/`IN_TRANSIT`. |

The masterlist's own maintenance rule is *never delete a row* — these are
recorded here as verified-closed rather than removed, and the masterlist itself
is left untouched by TAB 01.
