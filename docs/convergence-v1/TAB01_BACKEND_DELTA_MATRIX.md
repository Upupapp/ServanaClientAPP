# Matrix 2 — Backend delta matrix

**Servana Client Mobile Backend Convergence V1 · TAB 01**

Every outbound call the customer app makes, checked against **actual local
backend route evidence** — the mounted Express route tree and the generated
OpenAPI/contract documents in `servana_api-main`. Nothing in this matrix is
inferred from a written API description alone; every "exists" cell names a
`file:line` that mounts the handler.

| | |
| --- | --- |
| Client | `servana_client-main` @ `ce02830` |
| Backend @ HEAD | `servana_api-main` @ `36ca152` (local `main`) |
| Backend @ pushed | `servana_api-main` @ `origin/main` — **51 commits behind local `main`** |
| Canonical contract | `src/api/v1/contract.ts` → `docs/api/API_ENDPOINT_REGISTRY.md` (95 implemented, 4 planned) |
| OpenAPI | `docs/api/openapi.v1.json` — 82 paths / 99 operations |
| Migration dispositions | `docs/api/LEGACY_ENDPOINT_MIGRATION_MATRIX.md` — 520 legacy routes classified |

> **Scope of the availability claim.** "Deployed" below means *present on
> `origin/main`*. No request was made to `api.servana.com.ph` — probing
> production is outside this task's authorisation. `origin/main` is the
> strongest local evidence of what production can be serving, and every gap it
> shows is a real gap; a gap it does *not* show could still exist if production
> trails `origin/main`.

---

## 1. Headline

| Question | Answer | Evidence |
| --- | --- | --- |
| Client calls that hit **no backend route at all** | **0 of 76** | route-tree scan below |
| Client calls whose route exists only in **unpushed** backend commits | **3** | rows 17–19, all `/api/catalog*`. A fourth catalog route, `GET /api/catalog/services`, is equally unpushed and the client does not call it. |
| Client calls already on the canonical `/api/v1` namespace | **0** | `grep -rn 'api/v1' lib test` → no match |
| Canonical `/api/v1` endpoints reachable in production | **0** | `src/api/v1/contract.ts` **absent** from `origin/main`; `origin/main:src/app.ts` contains **0** `api/v1` mounts |
| Client legacy calls with a canonical v1 successor already built | 39 | `ALIAS_TEMPORARILY` rows |
| Client legacy calls that must *become* canonical (no successor yet) | 3 | `CANONICALIZE` rows |
| Client legacy calls with no successor and none planned | 34 | 31 `KEEP` + 3 `ROLE_SPECIFIC` rows |

39 + 3 + 34 = 76, the full client call set. By verdict the same 76 rows are
36 `OK · V1_READY`, 34 `OK · NO_V1`, 3 `OK · CANONICALIZE` and 3 `LOCAL_ONLY` —
the 3-row gap between 39 `ALIAS` and 36 `V1_READY` is exactly rows 17–19, which
have a built successor *and* an unpushed legacy route.

**Two findings dominate everything else in TAB 01.**

1. **The canonical namespace is not deployable-as-shipped.** `/api/v1` was
   added in `8186a5d` (2026-08-11) and has never been pushed. The backend's own
   generated parity matrix says so without hedging: *"0 cells on canonical. No
   client has migrated. The v1 namespace is mounted, tested and documented, and
   it is unpushed — nothing can migrate against a contract that is not
   serving."* Convergence V1 therefore cannot begin with client code changes;
   it begins with a backend deployment that is not this repository's to make.

2. **The client has already shipped ahead of the backend once.** Commit
   `d6d32bd` migrated the customer app to read `GET /api/catalog`, and those
   four catalog routes exist only in the unpushed `2bdaf0d`. On the pushed
   branch `GET /api/catalog` does not exist, and `booking.routes.ts:44`
   registers `GET /:id` at the same mount point — so the request resolves to
   the booking getter and answers 401 (unauthenticated) or 400 "Invalid booking
   id". `CatalogRepository.load()` rethrows on a cold cache, so the browse
   surface degrades to `CatalogUnavailableScreen`.

---

## 2. Verdict legend

| Verdict | Meaning |
| --- | --- |
| `OK · V1_READY` | Legacy route exists and is on `origin/main`; a canonical v1 successor is built (but not deployed). Safe to migrate once v1 ships. |
| `OK · CANONICALIZE` | Legacy route exists and is on `origin/main`; it is *designated* to become canonical, no successor built. Needs a backend command before the client can move. |
| `OK · NO_V1` | Legacy route exists and is on `origin/main`; no canonical successor exists or is planned. The client stays on it. |
| `LOCAL_ONLY` | Route exists at backend HEAD but **not** on `origin/main`. The client calls something the pushed backend does not serve. |
| `ABSENT` | No backend route. **Zero rows.** |

---

## 3. Authentication and identity

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 1 | `POST /api/auth/customer-firebase-login` | `servana_api_client.dart:324` | `auth.route.ts:124` | yes | ROLE_SPECIFIC | `POST /api/v1/auth/login` (not collapsed — see note) | `OK · NO_V1` |
| 2 | `POST /api/auth/refresh` | `:189` | `auth.route.ts:121` | yes | ALIAS | `POST /api/v1/auth/refresh` | `OK · V1_READY` |
| 3 | `POST /api/auth/logout` | `:461` | `auth.route.ts:130` | yes | ALIAS | `POST /api/v1/auth/logout` | `OK · V1_READY` |
| 4 | `POST /api/auth/verify-email-otp` | `:434` | `auth.route.ts:105` | yes | ALIAS | `POST /api/v1/auth/verify-email` | `OK · V1_READY` |
| 5 | `POST /api/auth/resend-email-otp` | `:445` | `auth.route.ts:106` | yes | ALIAS | `POST /api/v1/auth/resend-verification` | `OK · V1_READY` |
| 6 | `POST /api/auth/signup` *(no caller)* | `:286` | `auth.route.ts:104` | yes | ALIAS | `POST /api/v1/auth/register` | `OK · V1_READY` |
| 7 | `POST /api/auth/signin` *(no caller)* | `:307` | `auth.route.ts:107` | yes | ALIAS | `POST /api/v1/auth/login` | `OK · V1_READY` |
| 8 | `GET /api/auth/resendverification` *(no caller)* | `:338` | `auth.route.ts:122` | yes | ALIAS | `POST /api/v1/auth/resend-verification` | `OK · V1_READY` |

**Note on row 1.** The migration matrix explicitly refuses to collapse
`customer-firebase-login` into `/api/v1/auth/login`: its link-collision
contract is a **200 carrying `status: "failed"` and no token**, because the
installed customer app throws on any non-2xx before reading the body and fires
`onUnauthorized` on 401. Either would show "session expired" to somebody who
has no session yet. Changing that shape requires a client release. This is the
clearest example in the whole matrix of the backend already having reasoned
about the installed base.

## 4. Customer profile and addresses

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 9 | `GET /api/user/profile` | `:417` | `user.route.ts:21` | yes | ROLE_SPECIFIC | none (returns the customer *aggregate*, not the identity record) | `OK · NO_V1` |
| 10 | `PUT /api/user/updateprofile` | `:400` | `user.route.ts:22` | yes | ALIAS | `PATCH /api/v1/customer/profile` | `OK · V1_READY` |
| 11 | `GET /api/user/alluseraddresses` | `:376` | `user.route.ts:12` | yes | ALIAS | `GET /api/v1/customer/addresses` | `OK · V1_READY` |
| 12 | `POST /api/user/adduseraddress` | `:348` | `user.route.ts:18` | yes | ALIAS | `POST /api/v1/customer/addresses` | `OK · V1_READY` |
| 13 | `PUT /api/user/makeaddressprimary` | `:361` | `user.route.ts:23` | yes | ALIAS | `POST /api/v1/customer/addresses/:addressId/default` | `OK · V1_READY` |
| 14 | `DELETE /api/user/deleteaddress` | `:392` | `user.route.ts:25` | yes | ALIAS | `DELETE /api/v1/customer/addresses/:addressId` | `OK · V1_READY` |
| 15 | `GET /api/user/getaddressbyid` *(no caller)* | `:384` | `user.route.ts:19` | yes | KEEP | none | `OK · NO_V1` |
| 16 | `GET /api/user/registereduser` *(no caller)* | `:473` | `user.route.ts:7` | yes | KEEP | none | `OK · NO_V1` |

v1 introduces `PATCH /api/v1/customer/addresses/:addressId`, which the legacy
surface has no equivalent of. That is the fix for SC-043 (address edit is
currently delete-then-recreate, so a failure between the two calls destroys the
address). **Convergence removes a real data-loss path** — recorded as risk
**R-05**.

## 5. Catalog and service discovery

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 17 | `GET /api/catalog` | `:525` | `catalogPublic.routes.ts:27` | **NO** | ALIAS | `GET /api/v1/catalog` | **`LOCAL_ONLY`** |
| 18 | `GET /api/catalog/summary` | `:532` | `catalogPublic.routes.ts:28` | **NO** | ALIAS | `GET /api/v1/catalog/summary` | **`LOCAL_ONLY`** |
| 19 | `GET /api/catalog/services/:id` | `:545` | `catalogPublic.routes.ts:30` | **NO** | ALIAS | `GET /api/v1/catalog/services/:serviceId` | **`LOCAL_ONLY`** |
| — | *(`GET /api/catalog/services` — not called by the client)* | — | `catalogPublic.routes.ts:29` | **NO** | ALIAS | `GET /api/v1/catalog/services` | **`LOCAL_ONLY`** |
| 20 | `GET /api/services` | `:481` | `service.route.ts:8` | yes | KEEP | none | `OK · NO_V1` |
| 21 | `GET /api/services/:id/level2` | `:489` | `service.route.ts:11` | yes | CANONICALIZE | none built | `OK · CANONICALIZE` |
| 22 | `GET /api/services/:id/options-with-addons` | `:497` | `service.route.ts:24` | yes | CANONICALIZE | none built | `OK · CANONICALIZE` |
| 23 | `GET /api/services/full` *(no caller)* | `:503` | `service.route.ts:10` | yes | CANONICALIZE | none built | `OK · CANONICALIZE` |
| 24 | `GET /api/services/:id/branches` | `:553` | `service.route.ts:25` | yes | KEEP | none | `OK · NO_V1` |
| 25 | `GET /api/branches/:id/slots` | `:563` | `service.route.ts:26` | yes | KEEP | none | `OK · NO_V1` |
| 26 | `POST /api/branches/slots` *(no caller)* | `:955` | `service.route.ts:34` | yes | KEEP | none | `OK · NO_V1` |
| 27 | `GET /api/services/:id/coverage-geo` *(no caller)* | `:574` | `service.route.ts:27` | yes | KEEP | none | `OK · NO_V1` |
| 28 | `POST /api/services/:id/coverage-geo` *(no caller)* | `:586` | `service.route.ts:35` | yes | KEEP | none | `OK · NO_V1` |

Rows 17–19 are the only `LOCAL_ONLY` rows in the entire matrix, and they are
the ones the current release depends on. The backend's own mount comment at
`src/app.ts:228-243` documents the shadowing hazard and the fix, and both live
in unpushed commits.

Rows 21–23 are the reverse problem: the legacy LEVEL-2/LEVEL-3 projection is
what the *installed* build reads, it is designated `CANONICALIZE`, and the
migration matrix states it *"cannot be retired until ServanaClient migrates: it
is the only catalog either Flutter app has ever consumed."* Backend and client
are each waiting on the other; TAB 02 has to break that loop explicitly.

## 6. Booking lifecycle

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 29 | `POST /api/quote` | `:594` | `pricing.routes.ts:40` | yes | KEEP | none | `OK · NO_V1` |
| 30 | **`POST /api/bookings`** | `:664` | `booking.routes.ts:24` | yes | **KEEP** | **none — and none planned** | `OK · NO_V1` |
| 31 | `GET /api/users/:userId/bookings` | `:606` | `booking.routes.ts:21` | yes | ALIAS | `GET /api/v1/bookings` | `OK · V1_READY` |
| 32 | `GET /api/:id` | `:678` | `booking.routes.ts:44` | yes | ALIAS | `GET /api/v1/bookings/:bookingId` | `OK · V1_READY` |
| 33 | `GET /api/:id/timeline` | `:807` | `booking.routes.ts:63` | yes | ALIAS | `GET /api/v1/bookings/:bookingId/timeline` | `OK · V1_READY` |
| 34 | `GET /api/:id/tracking` | `:719` | `booking.routes.ts:45` | yes | ALIAS | `GET /api/v1/bookings/:bookingId/tracking` | `OK · V1_READY` |
| 35 | `POST /api/bookings/:id/cancel` | `:779` | `booking.routes.ts:30` | yes | ALIAS | `POST /api/v1/bookings/:bookingId/cancel` | `OK · V1_READY` |
| 36 | `POST /api/:id/confirm-otp` | `:699` | `booking.routes.ts:36` | yes | ALIAS | `POST /api/v1/bookings/:bookingId/otp/verify` | `OK · V1_READY` |
| 37 | `POST /api/:id/resend-otp` | `:713` | `booking.routes.ts:43` | yes | ALIAS | `POST /api/v1/bookings/:bookingId/otp/request` | `OK · V1_READY` |
| 38 | `GET /api/booking/:id/provider` | `:633` | `provider.routes.ts:282` | yes | KEEP | none | `OK · NO_V1` |
| 39 | `GET /api/booking/:id/provider-location` | `:652` | `provider.routes.ts:281` | yes | ALIAS | `GET /api/v1/bookings/:bookingId/tracking` | `OK · V1_READY` |

**Row 30 is the largest structural gap in the convergence.** The canonical v1
contract has `GET /api/v1/bookings` and nine booking sub-resources, and **no
create**. `POST /api/bookings` is classified `KEEP` — "not a duplicate of
anything canonical" — so the customer app's primary conversion action has no
canonical home. A client fully migrated to v1 would still have to reach back
into the legacy namespace to create a booking. Risk **R-02**.

Three legacy claims were **re-verified and are now closed**, and the matrix
records that rather than carrying them forward:

- **SC-031 / SC-048** — "Resend code calls a route that does not exist."
  `POST /:bookingId/resend-otp` is mounted at `booking.routes.ts:43` and is on
  `origin/main`. **Closed.**
- **SC-036 / SC-058** — "`X-Idempotency-Key` is sent and read by nothing."
  `bookingController.ts:53-58` normalises the header and looks the booking up
  by it; `src/services/bookingIdempotency.ts` is present on `origin/main`.
  **Closed and shipped.**
- **SC-024** — "`totalAmount` is not an alias of `finalPrice`."
  `bookingService.ts:562-566` aliases it in SQL with a comment naming the app's
  "Amount" field. **Closed.**

## 7. Payments

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 40 | `POST /api/:id/paymongo/create` | `:756` | `payment.routes.ts:11` | yes | ALIAS | `POST /api/v1/bookings/:bookingId/payment-intents` | `OK · V1_READY` |
| 41 | `POST /api/:id/gcash-submit` *(no caller)* | `:728` | `payment.routes.ts:8` | yes | KEEP | none | `OK · NO_V1` |
| 42 | `POST /api/:id/approve` *(no caller)* | `:740` | `payment.routes.ts:9` | yes | KEEP | none | `OK · NO_V1` |
| 43 | `POST /api/:id/mark-cash-paid` *(no caller)* | `:748` | `payment.routes.ts:10` | yes | KEEP | none | `OK · NO_V1` |

v1 adds `GET /api/v1/bookings/:bookingId/payment` and
`POST /api/v1/bookings/:bookingId/refunds`, neither of which the client has any
equivalent for. Payment *status* is currently inferred by re-reading the whole
booking (`payment_webview_screen.dart:41`). Risk **R-06**.

## 8. Notifications and devices

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 44 | `POST /api/user/fcm-token` | `:815` | `user.route.ts:41` | yes | ALIAS | `POST /api/v1/me/devices` | `OK · V1_READY` |
| 45 | `DELETE /api/user/fcm-token` | `:825` | `user.route.ts:42` | yes | ALIAS | `DELETE /api/v1/me/devices` | `OK · V1_READY` |
| 46 | `GET /api/user/notifications` | `:922` | `user.route.ts:49` | yes | ALIAS | `GET /api/v1/notifications` | `OK · V1_READY` |
| 47 | `GET /api/user/notifications/unread-count` | `:928` | `user.route.ts:47` | yes | ALIAS | `GET /api/v1/notifications/unread-count` | `OK · V1_READY` |
| 48 | `PATCH /api/user/notifications/:key/read` | `:934` | `user.route.ts:50` | yes | ALIAS | `PATCH /api/v1/notifications/:key/read` | `OK · V1_READY` |
| 49 | `POST /api/user/notifications/mark-all-read` | `:940` | `user.route.ts:48` | yes | ALIAS | `POST /api/v1/notifications/read-all` | `OK · V1_READY` |
| 50 | `DELETE /api/user/notifications/:key` | `:946` | `user.route.ts:51` | yes | KEEP | none | `OK · NO_V1` |

Row 50 is a one-way door: the client can delete a notification today and v1
offers no way to. Migrating notifications wholesale would silently remove a
user-visible capability. Risk **R-09**.

## 9. Messaging

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 51 | `GET /api/bookings/:id/conversation` | `:837` | `chat.routes.ts:14` | yes | ALIAS | `POST /api/v1/conversations` | `OK · V1_READY` |
| 52 | `GET /api/chat/conversations` | `:844` | `chat.routes.ts:11` | yes | ALIAS | `GET /api/v1/conversations` | `OK · V1_READY` |
| 53 | `GET /api/chat/conversations/:id/messages` | `:858` | `chat.routes.ts:18` | yes | ALIAS | `GET /api/v1/conversations/:conversationId/messages` | `OK · V1_READY` |
| 54 | `POST /api/chat/conversations/:id/messages` | `:870` | `chat.routes.ts:19` | yes | ALIAS | `POST /api/v1/conversations/:conversationId/messages` | `OK · V1_READY` |
| 55 | `POST /api/chat/conversations/:id/read` | `:888` | `chat.routes.ts:24` | yes | ALIAS | `POST /api/v1/conversations/:conversationId/read` | `OK · V1_READY` |
| 56 | `POST /api/chat/conversations/:id/messages/:msgId/report` | `:905` | `chat.routes.ts:28` | yes | KEEP | none | `OK · NO_V1` |

Row 51 changes shape under v1: a GET that lazily creates becomes an explicit
`POST /api/v1/conversations`. That is the fix for SC-038 (a conversation is
created the moment the customer opens the screen, with no assignment gate), and
it is a semantic change the client cannot make transparently. Risk **R-10**.

## 10. Support and safety

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 57 | `GET /api/support/tickets` | `:967` | `customerSupport.routes.ts:13` | yes | KEEP | none | `OK · NO_V1` |
| 58 | `POST /api/support/tickets` | `:979` | `customerSupport.routes.ts:14` | yes | ROLE_SPECIFIC | `POST /api/v1/bookings/:bookingId/support-cases` (booking-scoped only) | `OK · NO_V1` |
| 59 | `GET /api/support/tickets/:ticketKey` | `:995` | `customerSupport.routes.ts:15` | yes | KEEP | none | `OK · NO_V1` |
| 60 | `POST /api/support/tickets/:ticketKey/replies` | `:1004` | `customerSupport.routes.ts:16` | yes | KEEP | none | `OK · NO_V1` |
| 61 | `POST /api/support/tickets/:ticketKey/mark-read` | `:1014` | `customerSupport.routes.ts:17` | yes | KEEP | none | `OK · NO_V1` |
| 62 | `POST /api/support/tickets/:ticketKey/close` | `:1020` | `customerSupport.routes.ts:18` | yes | KEEP | none | `OK · NO_V1` |
| 63 | `POST /api/support/tickets/:ticketKey/reopen` | `:1026` | `customerSupport.routes.ts:19` | yes | KEEP | none | `OK · NO_V1` |
| 64 | `GET /api/support/unread-count` | `:1032` | `customerSupport.routes.ts:12` | yes | KEEP | none | `OK · NO_V1` |
| 65 | `GET /api/support/safety/emergency-config` | `:1038` | `customerSupport.routes.ts:22` | yes | KEEP | none | `OK · NO_V1` |
| 66 | `GET /api/support/safety/incidents` | `:1044` | `customerSupport.routes.ts:23` | yes | KEEP | none | `OK · NO_V1` |
| 67 | `POST /api/support/safety/incidents` | `:1057` | `customerSupport.routes.ts:24` | yes | KEEP | none | `OK · NO_V1` |

The migration matrix is explicit about row 58: the general contact surface
*"carries no bookingId, so a quality complaint raised through it arrives with
no way to see which visit it is about. Kept for contact that is genuinely not
about a booking."* The v1 successor is narrower, not equivalent — the whole
support domain stays legacy for V1.

## 11. Reviews

| # | Client call | Client evidence | Backend route @ HEAD | On `origin/main` | Disposition | Canonical v1 successor | Verdict |
| --- | --- | --- | --- | :---: | --- | --- | --- |
| 68 | `GET /api/bookings/:id/review-eligibility` | `:1076` | `customerReview.routes.ts:23` | yes | ALIAS | `GET /api/v1/bookings/:bookingId/review` | `OK · V1_READY` |
| 69 | `POST /api/bookings/:id/reviews` | `:1090` | `customerReview.routes.ts:24` | yes | ALIAS | `POST /api/v1/bookings/:bookingId/review` | `OK · V1_READY` |
| 70 | `GET /api/bookings/:id/reviews` | `:1107` | `customerReview.routes.ts:25` | yes | ALIAS | `GET /api/v1/bookings/:bookingId/review` | `OK · V1_READY` |
| 71 | `GET /api/reviews/:reviewId` | `:1113` | `customerReview.routes.ts:36` | yes | KEEP | none | `OK · NO_V1` |
| 72 | `PUT /api/reviews/:reviewId` | `:1126` | `customerReview.routes.ts:37` | yes | KEEP | none | `OK · NO_V1` |
| 73 | `DELETE /api/reviews/:reviewId` | `:1142` | `customerReview.routes.ts:38` | yes | KEEP | none | `OK · NO_V1` |
| 74 | `GET /api/reviews/me` | `:1148` | `customerReview.routes.ts:29` | yes | KEEP | none | `OK · NO_V1` |
| 75 | `POST /api/reviews/:reviewId/report` | `:1158` | `customerReview.routes.ts:39` | yes | KEEP | none | `OK · NO_V1` |
| 76 | `GET /api/providers/:uid/rating` | `:1171` | `customerReview.routes.ts:45` | yes | ALIAS | `GET /api/v1/reviews/providers/:providerUid/rating` | `OK · V1_READY` |

Reviews are the sharpest example of a **partial** canonical surface: the
booking-scoped three have successors, the review-lifecycle five (read, edit,
delete, list-mine, report) do not. Migrating the first three alone puts one
feature across two namespaces — the `⚠ mixed` state the backend's own parity
matrix warns about. Risk **R-04**.

## 12. Endpoints the backend offers and the client does not use

Not gaps, but the option space TAB 02+ can draw on. All exist at HEAD; all are
on `origin/main` unless noted.

| Backend route | Why it matters |
| --- | --- |
| `GET /api/location/address-suggestions`, `GET /api/location/address-details/:placeId` | Server-side place lookup. The client currently supplies coordinates itself (SC-039), which drives service-area eligibility and transport pricing. |
| `POST /api/account/deletion-request`, `.../me` | Store-policy account deletion. The client has no deletion path. |
| `GET /api/additional/booking/:bookingId` + 6 sibling routes | The additional-work flow. The client has `AddAdditionalItemMenuScreen` mounted and no call into this family. |
| `GET /api/services/:id/coverage-geo/check` | Serviceability check the client re-implements against the full coverage polygon. |
| `GET /api/auth/me` | Identity record; the client uses `/api/user/profile` for everything. |
| `GET /api/v1/search`, `GET /api/v1/home`, `GET /api/v1/home/sections` | Canonical search and home. **v1 only — not on `origin/main`.** The client's home and search are wholly local/legacy. |
| `GET /api/v1/bookings/:bookingId/transitions` | Server-authored list of what the customer may do next, replacing client-side status→action inference. **v1 only.** |
| `POST/GET /api/v1/bookings/:bookingId/reschedule` | No legacy equivalent; no client surface. **v1 only.** |
| `POST/GET /api/v1/bookings/:bookingId/disputes` | No legacy equivalent; no client surface. **v1 only.** |

---

## 13. What this matrix does not establish

Stated plainly so no later TAB reads a silence as a clearance:

- **Production reality.** Every availability cell is `origin/main`, not a live
  probe. If production trails `origin/main`, more rows are `LOCAL_ONLY` than
  shown.
- **Response-body shape.** This is a route-existence and disposition matrix.
  Field-level DTO conformance between legacy responses and v1 schemas was not
  diffed; three specific field claims were re-verified (§6) and the rest of the
  `MASTERLIST` shape findings are untouched and still open.
- **Authorization equivalence.** The `auth` column of the v1 contract was read,
  not exercised. `SECURITY_AUTHZ_MATRIX.md` exists in the backend and was not
  audited here.
- **The installed base.** Rows describe `ce02830`. Play serves `+37`, whose
  call set is a subset this matrix does not enumerate.
