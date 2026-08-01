# Masterlist — Pending Items, Servana Customer Mobile App

Every open finding for ServanaClient. Companion to the worker app list at
`ServanaWorker/docs/MASTERLIST_PENDING_ITEMS_SERVANA_WORKER_APP.md`.

**Maintenance rule.** Update at the end of every command. Add new findings, move resolved ones to Closed with the commit that closed them, and move disproved ones to Corrections. **Never delete a row.**

- **Last updated:** 2026-08-01, six-pass audit (SWEEP/STITCH/ALIGN/LEAK/REPEAT/TEST)
- **App:** `Heatclift/ServanaClient` @ `bab66e4` — 983 tests, analyzer 0 errors / 46 infos
- **Backend:** `servana_api` @ `870fd28` + 4 local security commits
- **Per-finding detail:** `docs/audit/<PASS>_CLIENT.md`

## At a glance

| Severity | Open | Closed this session |
| --- | ---: | ---: |
| **P0** | 3 | 12 |
| **P1** | 61 | 5 |
| **P2** | 29 | 3 |
| **P3** | 4 | 1 |
| **info** | 2 | 0 |

**99 open · 21 closed.**

> **Verification status.** 18 P0 claims went through adversarial verification: **17 confirmed, 1 downgraded**. The other 102 findings are agent-reported and were NOT independently verified — re-read the cited files before acting on one.

## P0 — open (3)

| ID | Pass | Finding | Fix in | Release | Verified |
| --- | --- | --- | --- | --- | --- |
| SC-005 | LEAK | ANSWER TO OPEN QUESTION — PUT /api/workers/bookings/:id/{accept,start,complete,decline} has NO auth middleware and the ?workerUid= query param is neve | backend | no | **yes** |
| SC-013 | REPEAT | PROVIDER.PROFILE.READ has one unprojected implementation serving provider, admin and customer — customer app pulls the provider's earnings ledger and  | backend | no | **yes** |
| SC-015 | TEST | The only ServanaApiClient contract test pins a URL the backend does not serve, certifying a broken booking flow as green | backend | no | **yes** |

## P1 — open (61)

| ID | Pass | Finding | Fix in | Release | Verified |
| --- | --- | --- | --- | --- | --- |
| SC-016 | SWEEP | 'Pay Now' CTA is unreachable on booking detail — `_needsPayment` can never be true | backend | no | agent |
| SC-017 | SWEEP | `GET /api/services/:id/options-with-addons` — client path has one more segment than the registered route (404) | backend | no | agent |
| SC-018 | SWEEP | `paymentMethod` value vocabulary diverges: 'PAYMONGO' is never written to `payments.method` or `bookings.payment_method` | backend | no | agent |
| SC-019 | SWEEP | `totalAmount` is not a registered alias of `finalPrice` — customer booking detail renders ₱0.00 for every booking | backend | no | agent |
| SC-020 | SWEEP | Booking response carries no `latitude`/`longitude` — live-tracking destination pin resolves to (0,0) | backend | no | agent |
| SC-021 | SWEEP | Bookings list invents the service name — every booking without addons is labelled 'Beauty & Wellness' | client-mobile | yes | agent |
| SC-022 | SWEEP | Customer booking payload omits `serviceName`/`serviceCategory` — admin and provider get them, customer does not | backend | no | agent |
| SC-023 | SWEEP | Customer notification taxonomy: client recognises 22 types, backend emits exactly 1 | backend | no | agent |
| SC-024 | STITCH | 'Resend code' on the booking OTP screen calls a route that does not exist, leaving the OTP step with no recovery path | backend | no | agent |
| SC-025 | STITCH | 'Resend email OTP' sends no request body at all, so it always returns 400 | backend | no | agent |
| SC-026 | STITCH | `AssignmentPollResult.isAssigned` can never be true for a real assignment, so both confirmation screens always run the full 60 s poll and then report  | client-mobile | yes | agent |
| SC-027 | STITCH | `assignNearestWorker` returning `{assigned:false}` is silently discarded — the booking is stranded at CONFIRMED with no worker, no notification and no | backend | no | agent |
| SC-028 | STITCH | `confirmOtp` is non-atomic: the booking is set CONFIRMED before worker assignment, so an assignment failure is reported to the customer as an invalid  | backend | no | agent |
| SC-029 | STITCH | `POST /api/bookings` has no idempotency — the client sends `X-Idempotency-Key` and the backend never reads it | backend | no | **yes** |
| SC-030 | STITCH | `WORKER_ASSIGNED` maps to `enRoute`, so the customer is told 'Your service professional is on the way' the instant a provider is assigned — potentiall | client-mobile | yes | agent |
| SC-031 | STITCH | A booking chat conversation is created the moment the customer opens the screen, with no provider-assignment or confirmation gate | backend | no | agent |
| SC-032 | STITCH | Address coordinates are supplied by the client and written verbatim — they then drive service-area eligibility and transport-fee pricing | backend | no | agent |
| SC-033 | STITCH | Address save shows 'Address saved!' while the coordinate write is fire-and-forget; a failed Mongo write makes the address silently unbookable forever | backend | no | agent |
| SC-034 | STITCH | Chat messages emit a Socket.IO event but never an FCM push, so a backgrounded customer never learns a provider replied | backend | no | agent |
| SC-036 | STITCH | Editing a saved address is implemented as delete-then-recreate, so a failure between the two calls destroys the customer's address | backend | yes | agent |
| SC-037 | STITCH | In-app email verification is permanently broken: the client posts `{otp}` but the backend requires `{email, otp}` | backend | no | agent |
| SC-038 | STITCH | Logout never calls `POST /api/auth/logout`, so the Firebase token is never revoked server-side — the stale credential stays valid after sign-out | client-mobile | yes | agent |
| SC-039 | STITCH | The bookings list returns guest bookings matched by phone number, but the detail route refuses them — tapping such a booking always 403s | backend | no | agent |
| SC-041 | STITCH | The Firebase ID token is stored as the Servana session token and never refreshed — sessions die roughly hourly with no recovery | client-mobile | yes | agent |
| SC-044 | ALIGN | `options-with-addons` path mismatch — ServanaClient calls a 3-segment path the backend does not register | backend | no | agent |
| SC-045 | ALIGN | `X-Idempotency-Key` is sent on booking creation and read by nothing — the customer path has no idempotency while the admin path has a full implementat | backend | no | agent |
| SC-046 | ALIGN | Admin read model places `guestCustomerId` inside `customerUid` — direct §7 violation | backend | no | agent |
| SC-047 | ALIGN | Bookings list hardcodes every booking's service as "Beauty & Wellness" | client-mobile | yes | agent |
| SC-048 | ALIGN | Customer booking read model omits canonical service identity — booking detail shows an empty service name | backend | no | agent |
| SC-049 | ALIGN | Customer booking surface receives no §13 canonical status; `statusLower` is a false normalisation | backend | no | agent |
| SC-050 | ALIGN | Customer notifications have one producer for a client that implements 22 types and 9 deep-link targets | backend | no | agent |
| SC-051 | ALIGN | Email-OTP verification is permanently broken on customer mobile — the backend requires `email` in the body, the client sends only the token | backend | no | agent |
| SC-052 | ALIGN | No customer-originated mutation produces a backend audit event | backend | no | agent |
| SC-053 | ALIGN | PayMongo webhook overwrites `bookings.status` with `PAID`, regressing an in-progress or completed booking | backend | no | agent |
| SC-055 | LEAK | All six /api/additional/* customer-and-worker lifecycle routes are completely unauthenticated, including a booking-scoped read | backend | no | agent |
| SC-056 | LEAK | Client — the 401/session-expiry path deletes the session but does not reset any private-data store, so the next account signing in on the same device  | client-mobile | yes | agent |
| SC-057 | LEAK | POST /api/admin/admin-users/bootstrap-super-admin is callable with any customer's Firebase token and fails OPEN when no active super admin exists | backend | no | agent |
| SC-058 | LEAK | Socket.IO root namespace join_room — a client-supplied `type` label bypasses the booking ownership check, allowing any authenticated identity into any | backend | no | **yes** |
| SC-059 | LEAK | verifyAuthOptional silently downgrades an invalid or expired token to anonymous, making "no credentials" the most privileged state on all three routes | backend | no | agent |
| SC-060 | REPEAT | Booking lifecycle status and assignment status are collapsed into one wire field; the customer app maps WORKER_ASSIGNED to 'en route' and never reads  | backend | no | agent |
| SC-061 | REPEAT | BOOKING.ADDONS: relational booking_addons rows are written only by the admin path — add-ons the customer paid for are invisible to provider and admin | backend | no | agent |
| SC-062 | REPEAT | BOOKING.ADDRESS: customer bookings hold a mutable FK instead of a booking-time snapshot, so editing a saved address rewrites past bookings | backend | no | agent |
| SC-063 | REPEAT | BOOKING.CREATE: app-originated bookings write no timeline or audit event, so Admin Booking 360 shows two different histories depending on origin | backend | no | agent |
| SC-064 | REPEAT | BOOKING.CREATE: the customer path ignores X-Idempotency-Key while the admin path has a full idempotency table | backend | no | agent |
| SC-065 | REPEAT | BOOKING.OWNERSHIP.RESOLVE is implemented twice with different rules — the list endpoint returns bookings the detail endpoint then refuses | backend | no | agent |
| SC-066 | REPEAT | BOOKING.PROVIDER.ASSIGN has four independent implementations with different guards, different side effects and different prices | backend | no | agent |
| SC-067 | REPEAT | LOCATION.ID is derived in four places, and the admin path coerces the canonical loc_<lat>_<lon> string to a Number so it is always null | backend | no | agent |
| SC-068 | REPEAT | NOTIFICATION.CUSTOMER.EMIT: the app understands 21 notification types, the backend produces exactly one, and the two route shapes are incompatible | backend | no | agent |
| SC-069 | REPEAT | PAYMENT.RECORD.RESOLVE: the booking↔payment join is scoped by additional_request_id in the provider read model but not in the customer or payment-muta | backend | no | agent |
| SC-070 | REPEAT | PAYMENT.SETTLE has four implementations that leave the system in four different states | backend | no | agent |
| SC-071 | REPEAT | SERVICE.OPTIONS.LIST is the one route in service.route.ts registered outside the /services family, and the only live caller 404s | backend | no | agent |
| SC-072 | REPEAT | The customer app re-parses a human display label as if it were a canonical status code | client-mobile | yes | agent |
| SC-073 | REPEAT | Two complete booking read stacks inside the customer app — the canonical model, mapper and repository are dead code | client-mobile | yes | agent |
| SC-074 | TEST | Backend contract tests catalog-service.test.ts and admin-dedup.test.ts are excluded from jest and pass vacuously when no server is running | backend | no | agent |
| SC-075 | TEST | Backend production deploy runs no tests, no typecheck and no contract guard — 22 jest suites gate nothing | backend | no | agent |
| SC-076 | TEST | Entire messaging module has 0% test coverage; ConversationMapper's unguarded `as num?` cast on a COUNT(*)-derived field silently empties the Messages  | backend | no | agent |
| SC-077 | TEST | guard-protected-contracts.mjs cannot detect removal of any route ServanaClient actually calls, and is not wired to CI | backend | no | agent |
| SC-078 | TEST | Logout is entirely untested — all six skipped tests defer to an integration_test harness that does not exist | client-mobile | yes | agent |
| SC-079 | TEST | No test asserts the Authorization header is sent, and onUnauthorized (which wipes the session globally on any 401) has zero coverage | client-mobile | no | agent |
| SC-080 | TEST | No test asserts X-Idempotency-Key is sent, and the backend does not read it for customer booking creation — double-submit creates two bookings | backend | no | agent |
| SC-081 | TEST | The auth-guard test re-implements the router's guard instead of executing it, and explicitly asserts the /settings deep-link gap is correct | client-mobile | yes | agent |

## P2 — open (29)

| ID | Pass | Finding | Fix in | Release | Verified |
| --- | --- | --- | --- | --- | --- |
| SC-082 | SWEEP | Booking reference diverges between the app's own two screens: list shows `BK-<id>`, detail shows `SVN-000<id>` | client-mobile | yes | agent |
| SC-083 | SWEEP | Customer app reads five booking fields that no backend response anywhere produces | backend | no | agent |
| SC-084 | SWEEP | Customer mobile generates the canonical `locationId` and supplies raw coordinates the backend persists unvalidated | backend | no | agent |
| SC-085 | SWEEP | Parity registry mirrors are out of sync — `token` and `email` groups exist only in the backend | admin | no | agent |
| SC-086 | STITCH | Logout deletes the session before calling `DELETE /api/user/fcm-token`, so the request 401s and the device token is never cleared server-side | client-mobile | yes | agent |
| SC-087 | STITCH | Notification deep link for `SettingsTarget` pushes `/settings`, which is not a registered route | client-mobile | yes | agent |
| SC-088 | STITCH | PayMongo verification falls back from `paymentStatus` to booking status, so a null payment status makes a merely-CONFIRMED booking read as paid | client-mobile | yes | agent |
| SC-089 | STITCH | Submitting a review overwrites `bookings.status` with `REVIEWED`, which can remove a still-active paid job from the provider's list | backend | no | agent |
| SC-090 | STITCH | The booking OTP screen tells the customer the code was sent by SMS; the backend emails it | client-mobile | yes | agent |
| SC-092 | STITCH | The operation journal and the persisted booking idempotency key are written but never read — crash recovery for booking creation does not exist | client-mobile | yes | agent |
| SC-093 | STITCH | User/address controllers return raw exception text to the client and mutate module-level shared response objects | backend | no | agent |
| SC-095 | ALIGN | `booking_tracking.status` is an undeclared fourth status vocabulary, and its free-text `note` is returned verbatim to customers | backend | no | agent |
| SC-096 | ALIGN | `GET /api/:id/tracking` runs timeline rows through the booking formatter, stamping every event with `bookingCode: "SVN-undefined"` | backend | no | agent |
| SC-097 | ALIGN | `POST /api/auth/logout` exists but the customer app never calls it — no server-side session termination | client-mobile | yes | agent |
| SC-098 | ALIGN | `WORKER_ASSIGNED` renders as "On the way" on customer mobile but "assigned" in admin — same row, two realities | client-mobile | yes | agent |
| SC-099 | ALIGN | Booking conversation is created before a provider is assigned or confirmed | backend | no | agent |
| SC-101 | ALIGN | Notification `route` payload has two incompatible shapes and neither is in the parity registry | backend | no | agent |
| SC-102 | ALIGN | Payment response envelopes diverge three ways on one surface, and `checkout_url` is the only snake_case key in the customer contract | backend | no | agent |
| SC-103 | LEAK | Booking conversation is created on the customer's first access with no assigned/confirmed state gate (§24) | backend | unknown | agent |
| SC-104 | LEAK | Client router guard is case-sensitive — six /settings/* routes and /HelpSupport fall outside the isProtected prefix list | client-mobile | yes | agent |
| SC-105 | REPEAT | ADDRESS.CREATE has three client implementations and one endpoint that silently doubles as ADDRESS.UPDATE | backend | no | agent |
| SC-106 | REPEAT | AUTH.SIGN_IN returns two different session shapes, reconciled by scattered client-side fallback chains | backend | no | agent |
| SC-107 | REPEAT | Class F: otp_code and worker_code are produced by one generator but mean two different things, and the app carries both names for one field | backend | no | agent |
| SC-108 | REPEAT | The existing REPEAT parity test suite covers only provider capabilities — no customer capability has a parity test | backend | no | agent |
| SC-109 | TEST | CI collects coverage but enforces no threshold — measured line coverage is 17.10%, and 149 of 470 lib files have no coverage record at all | client-mobile | no | agent |
| SC-110 | TEST | CustomerBooking.fromApiMap silently substitutes DateTime.now() for a missing schedule and no test pins that fallback | client-mobile | yes | agent |
| SC-111 | TEST | http_backend.dart is 0% covered and holds a second divergent status mapper plus an unauthenticated address write | client-mobile | yes | agent |
| SC-112 | TEST | No payment-state tests: PayMongo WebView, pending-payment recovery and the payment chips are all 0% covered | client-mobile | yes | agent |
| SC-113 | TEST | No session-expiry or token-validity test; splash and the auth bloc disagree on what counts as a valid session and neither branch is tested | client-mobile | yes | agent |

## P3 — open (4)

| ID | Pass | Finding | Fix in | Release | Verified |
| --- | --- | --- | --- | --- | --- |
| SC-114 | SWEEP | `currency` is invented client-side on customer bookings while every other platform receives it from the backend | backend | no | agent |
| SC-115 | SWEEP | `fullname` is bridged by ad-hoc service code instead of the parity registry, and splits names naively | backend | no | agent |
| SC-116 | SWEEP | Three more booking fields fabricated by the customer app: `downPayment`, `numberOfPersonnel`, `distanceFromOffice` | none | no | agent |
| SC-117 | ALIGN | Client resolves customer identity with the canonical `customerUid` last in precedence | client-mobile | yes | agent |

## Closed this session

| ID | Finding | Commit |
| --- | --- | --- |
| SC-001 | `addUserAddress` update branch overwrites any address by ID — the authenticated uid is never used in the WHERE clause | `6d78313` |
| SC-002 | Payment settlement handlers `approve` and `mark-cash-paid` skip the booking-ownership check — any authenticated user can mark any booking PAID | `6d78313` |
| SC-003 | `POST /api/:bookingId/approve` and `/mark-cash-paid` skip the booking-access check their sibling payment routes enforce | `6d78313` |
| SC-004 | `POST /api/bookings/:id/cancel` is auth-optional and its ownership check short-circuits for anonymous callers — cancellation is unauthenticated and un | `bd8c355` |
| SC-006 | GET /api/user/:userId/addresses — identical anonymous-bypass; unauthenticated read of any customer's saved home addresses | `bd8c355` |
| SC-007 | GET /api/users/:userId/bookings — ownership check is skipped entirely when the caller omits the Authorization header | `bd8c355` |
| SC-008 | POST /api/:bookingId/approve — any authenticated user can mark any booking PAID (no ownership assertion, unlike its sibling payment routes) | `6d78313` |
| SC-009 | POST /api/:bookingId/mark-cash-paid — same missing ownership assertion; any authenticated user can force any booking to CASH/PAID | `6d78313` |
| SC-010 | POST /api/bookings/:id/cancel — an anonymous caller can cancel any customer's booking, and the audit row records a NULL actor | `bd8c355` |
| SC-011 | POST /api/user/adduseraddress with an addressId performs a cross-user UPDATE — the owner uid is never in the WHERE clause | `6d78313` |
| SC-012 | CUSTOMER.BOOKING.LIST joins guest_customers on a column that does not exist (gc.phone_number) | `880d5bc` |
| SC-014 | leak-isolation.test.js pins three address operations but omits updateUserAddress, whose UPDATE has no uid predicate (cross-user address overwrite) | `6d78313` |
| SC-035 | Customer cancellation does not notify the assigned provider — the provider can travel to a job that was cancelled hours earlier | `bd8c355` |
| SC-040 | The entire customer notification system has exactly one producer — nothing notifies the customer of assignment, payment, completion or cancellation | `bd8c355` |
| SC-042 | The PayMongo webhook confirms payment in the database but notifies neither the customer nor the provider, unlike the manual `approve` path | `6d78313` |
| SC-043 | Two parallel timeline tables: the customer's own cancellation is written to `booking_timeline_events` but the customer app reads `booking_tracking`, s | `bd8c355` |
| SC-054 | Two parallel booking timelines — the customer's own cancellation is written to the table the customer cannot read | `bd8c355` |
| SC-091 | The cancellation sheet collapses every backend error into one message, discarding actionable state and authorization errors | `bd8c355` |
| SC-094 | `approvePayment` / `markCashPaid` have no state guard and no idempotency — replay resets paid_at and re-fires the provider payout notification | `6d78313` |
| SC-100 | Guest bookings are linked to a client account by an unverified, non-unique phone number — any customer can harvest another party's guest bookings | `880d5bc` |
| SC-118 | Canonical §13 statuses `new` and `disputed` are unmapped and untested; unknown statuses are grouped under cancelled | `bd8c355` |

## Carried over from other work

| Item | Where |
| --- | --- |
| Rotate Firebase keys — previously-committed ones remain in git history | ServanaClient |
| 36 unauthenticated legacy worker routes; migration step 2 needs a mobile release | `servana_api` + ServanaWorker |
| 4 backend security commits are local-only and undeployed | `servana_api`, no upstream configured |

## Unverified — evidence not obtainable

- Client suite state IS verified: I ran `flutter test --no-pub -r compact` in servana_client-main and observed 983 passed, 6 skipped, 0 failed. I did NOT run `flutter analyze`, so the stated 46-info baseline is unconfirmed. Note the local Flutter SDK's own git checkout is corrupt (`flutter --version` reports a packfile inflate error on `fetch --tags`); the tooling still runs but SDK self-update is broken, which may affect CI-vs-local parity.
- Customer Web portal: UNAVAILABLE. The servana_Customer_WebPortal repo contains zero committed files, so no claim in this report describes customer-web behaviour, and every 'both customer surfaces' statement covers customer mobile only.
- Customer Web portal: UNAVAILABLE. servana_Customer_WebPortal contains 0 committed files, so no customer-web routes, models or status handling could be inspected. Every 'Customer Mobile ↔ Customer Web parity' obligation in REPEAT §20 is unassessable in this pass.
- Deployed backend commit on production. Every finding is stated against the local servana_api-main working tree, which is AHEAD of the inventory supplied with this task — booking.routes.ts:20,28-30 and payment.routes.ts:8-11 now carry verifyAuth and bookingAccessService.ts exists, contradicting the inventory's §3.1/3.3/3.6 LEAK claims. Evidence needed: `git rev-parse HEAD` in the deploy directory on Linode 192.46.224.126 and `pm2 describe servana-prod`, to confirm which of these routes are actually hardened in production.
- I did not audit the chat/messaging parity group (conversationId, senderUid, senderRole, clientMsgId, unreadCount, isClosed, lastMessageAt, lastReadMessageId) or the support/review groups field-by-field. Spot checks showed the backend emits camelCase via toCamel() and the client mappers accept camel+snake for every field, so I found no gap, but this is not an exhaustive result. Evidence needed: a field-by-field diff of servana_api-main/src/chat/chat.repository.ts:13-350 against servana_client-main/lib/modules/messaging/data/models/*.
- I did not execute the backend jest suite (`npm run test:ci`) — I only enumerated it with `npx jest --listTests` (22 suites). Its current pass/fail state is unknown; the CI-gate finding stands regardless of whether the suites currently pass.
- I did not verify whether ServanaWorker sends an Authorization header on the unauthenticated /workers/* routes — that bears on whether the provider-side routes can be hardened without a protected release, but it is outside this SWEEP pass. Evidence needed: the HTTP client/interceptor in C:/Users/paulg/OneDrive/Desktop/ServanaWorker.
- Real-device verification of the FCM foreground/background/terminated paths generally. All notification-chain findings here are derived from source; none were observed on hardware. flutter analyze was not run because this pass made no code changes (§60 applies to implementation, not inspection).
- ServanaWorker's behaviour if verifyAuth is added to technician.routes.ts:10-21. I verified the Dio interceptor attaches a bearer token on every request (ServanaWorker/lib/core/api/servana_api_config.dart:75-78), but I did not verify the token is already present on the very first call after a cold start, before session restore completes.
- Severity of the (0,0) tracking destination in practice — I confirmed the value chain produces 0.0 but did not run the app to see how the map widget behaves (it may clamp, or fit-bounds across half the globe). Evidence needed: an executable run of the live-tracking screen with a real assigned booking.
- That node-pg returns the COUNT(*)-derived `unread_count` as a JavaScript string in this deployment. I verified there is no `pg.types.setTypeParser` anywhere in servana_api-main/src (0 grep hits) and that Postgres COUNT(*) is bigint, which is node-pg's documented string-returning case — but I did not observe an actual response body. Evidence needed: `curl -H 'Authorization: Bearer <customer token>' https://api.servana.com.ph/api/chat/conversations` and inspect the JSON type of unreadCount.
- The BACKEND INVENTORY supplied with this task is STALE relative to servana_api-main @ 870fd28. I verified that several of its P0 LEAK claims no longer hold: POST /api/bookings now carries verifyAuth and takes identity from the token (src/routes/booking.routes.ts:20, src/controllers/bookingController.ts:16-22, which explicitly ignores ?userId=); GET /api/:id, GET /api/:id/tracking and POST /api/:id/confirm-otp now carry verifyAuth plus assertBookingAccess (booking.routes.ts:28-30, bookingController.ts:71,92). Any downstream pass that relies on that inventory's section 3 should re-verify against the actual route files.
- The BACKEND INVENTORY supplied with this task is STALE. It describes servana_api-main @ 870fd28, but the local working tree is at commit 52667b35eb6211bbf4f365da4e0e5be3afd8845d. Many P0s listed in that inventory are already fixed in the code I read: POST /api/bookings now has verifyAuth and takes identity from the token (src/routes/booking.routes.ts:20, src/controllers/bookingController.ts:15-21); GET /api/:id, /api/:id/tracking and POST /api/:id/confirm-otp now have verifyAuth plus assertBookingAccess (booking.routes.ts:28-30, bookingController.ts:71,92,153); all four payment routes now have verifyAuth (payment.routes.ts:8-11). Findings above are stated against 52667b3, not 870fd28. Still open at 52667b3 and re-verified by me: address.service.ts:56-60 (no uid predicate) and provider.gateway.ts:96-97 (join_room falls through without a DB check for any type label other than 'provider'/'booking', so {roomKey:'booking:123', type:'support'} joins a booking room unchecked).
- The BookingStatusMapper label round-trip failures ('Worker Assigned' → unknown, 'In Progress' → unknown) are derived from reading booking_status.dart:51-53, which only uppercases and trims. I did not execute flutter test or flutter analyze in this pass (§60), so this is source-level reasoning, not an executed result. A three-line unit test in the client repo would confirm or refute it without requiring a release.
- The exact live column list of the `bookings` table. I established that no code path in servana_api-main writes or selects `bookings.latitude`/`bookings.longitude`/`service_name`, and that only five columns are added by runtime ALTER TABLE statements (guest_customer_id, admin_created, admin_created_by, service_address, cancelled_at). A column added out-of-band by a manual migration would not appear in the source. Evidence needed: `\d+ <schema>.bookings` against the production DB.
- Whether ServanaClient's Messages screen renders an empty state rather than an error banner if GET /api/bookings/:id/conversation starts returning 404 for unconfirmed bookings. This gates whether the §24 fix is release-free. Evidence needed: the error branch of servana_client-main/lib/modules/messaging/.../messaging_repository.dart:28 and its consuming store.
- Whether ServanaWorker attaches a Bearer token on the technician routes (technician.routes.ts:10-21, 28-36, 49-77). This determines whether those routes can be promoted to verifyAuth without a Provider Mobile release (§2). I inspected only ServanaClient's HTTP client in this pass. Evidence needed: the `_headers()` / interceptor equivalent in C:/Users/paulg/OneDrive/Desktop/ServanaWorker.
- Whether ServanaWorker attaches a bearer token on its HTTP calls. I inspected only its service-catalog call (ServanaWorker/lib/core/api/servana_api.dart:305) this pass. This matters for any future tightening of the shared unauthenticated `/api/workers/*` routes — several ALIGN fixes above stop at the customer boundary specifically because provider-side header behaviour is unconfirmed. Evidence needed: the Dio interceptor / header builder in ServanaWorker/lib/core/api/.
- Whether ServanaWorker attaches a bearer token on the technician routes. I did not open C:/Users/paulg/OneDrive/Desktop/ServanaWorker in this pass, so I cannot say whether the remaining unauthenticated /workers/* routes can be promoted to verifyAuth without a provider-mobile release. Evidence needed: the HTTP client / interceptor in ServanaWorker.
- Whether ServanaWorker calls the /api/additional/* routes, and if so which ones. I confirmed ServanaWorker attaches a bearer token globally (ServanaWorker/lib/core/api/servana_api_config.dart:52,74-78), so adding verifyAuth is almost certainly release-free, but I did not enumerate its additional-work call sites. Evidence needed: grep for 'additional' in ServanaWorker/lib/core/api/servana_api.dart.
- Whether `POST /api/bookings` currently rejects ServanaClient in production. The route now requires verifyAuth (booking.routes.ts:20) and the client does send a bearer token (servana_api_client.dart:376), so it should pass — but I did not execute a live request to confirm the token is accepted by verifyIdToken for customer-role principals.
- Whether `booking_tracking.note` is rendered verbatim in the customer timeline widget. I confirmed BookingRepository.getTimeline returns the raw maps unfiltered (booking_repository.dart:97-101) but did not open the consuming widget, so the severity of the 'Worker declined' text leak assumes it is displayed.
- Whether `customer_reviews.client_request_id` carries a UNIQUE constraint. review_form_controller.dart:178-187 builds a deterministic key from (uid, bookingId), so a delete-then-re-review reuses the same key; customerReviewService.ts:277-281 excludes soft-deleted rows from the idempotency lookup, so a second INSERT is attempted with a previously-used key. Evidence needed: the DDL for customer_reviews.
- Whether `guest_customers.phone_number` and `user_credentials.phone_number` are normalised to one Philippine format (§59). If they are not, the guest-linkage join matches only on exact string equality, narrowing but not closing the exposure. Evidence needed: a sample of both columns.
- Whether `user_credentials.phone_number` carries a UNIQUE constraint at the database level. No migration/DDL file for that table was located in src/. If a UNIQUE constraint exists, the guest-linkage attack (P0) requires the victim's number to be unclaimed rather than merely known, which changes exploitability but not the fix. Evidence needed: `\d user_credentials` on the production schema.
- Whether a `payments` row can be absent for a booking that reaches the PayMongo webview. This is the reachability condition for the ghost-success fallback in payment_webview_screen.dart:218-224. bookingService.ts:98-104 always inserts one for customer-created bookings, but I did not confirm whether adminCreateBookingService does, nor whether createCheckoutSession (paymentService.ts:224-234) fails loudly when its UPDATE matches zero rows. Evidence needed: read adminCreateBookingService.ts's payments INSERT and the rowCount handling at paymentService.ts:224-240.
- Whether adminBookingService's payments joins also omit the additional_request_id discriminator. grep found the filter only in technicianService.ts:158 and :1529; I did not read every payments join in adminBookingService.ts to confirm each one lacks it.
- Whether any live consumer calls the two-segment /api/:serviceId/options-with-addons form. I confirmed ServanaClient calls only the three-segment form; I did not exhaustively grep servana_adminportal or Servana.com.ph for it. Evidence needed: grep -r 'options-with-addons' across both web repos.
- Whether any of the P0 routes have been exploited in production. This audit is static analysis only; I ran no requests against any environment. Evidence needed: access-log review for unauthenticated GET /api/users/*/bookings, GET /api/user/*/addresses, POST /api/bookings/*/cancel, and PUT /api/workers/bookings/*/complete.
- Whether booking_addons is ever populated for app-created bookings by an out-of-repo job (cron, migration, manual backfill). I proved adminCreateBookingService.ts:724 is the only writer inside servana_api-main/src. Evidence needed: SELECT count(*) FROM booking_addons ba JOIN bookings b ON b.id=ba.booking_id WHERE b.admin_created IS NOT TRUE.
- Whether firebaseAuthLoginController (/api/auth/firebase-login, upserts role '2') can be reached by a customer to create a provider-role account on first sign-in. Noted while tracing AUTH.SIGN_IN but not pursued — it belongs to the LEAK pass. Evidence needed: read userService.upsertFirebaseUser's INSERT/UPDATE role handling.
- Whether production actually runs backend commit 870fd28. Every backend claim here is stated against the local checkout only, and the supplied backend inventory was demonstrably stale (it described POST /api/bookings, GET /api/:id, /confirm-otp, /tracking and the payment routes as unauthenticated, whereas booking.routes.ts:20,22,28,29,30 and payment.routes.ts:8-12 now carry verifyAuth plus assertBookingAccess in bookingAccessService.ts). Evidence needed: `git rev-parse HEAD` in the deploy directory on the Linode host, or `pm2 describe servana-prod`. If production is older than 870fd28, the booking/payment LEAK findings from the stale inventory are still live and outrank several findings above.
- Whether production actually runs commit 52667b3. Evidence needed: `git rev-parse HEAD` in the deploy dir on the Linode host, or `pm2 describe servana-prod`. All backend claims above are against the local tree only.
- Whether production currently has at least one row satisfying `is_super_admin = TRUE AND account_status = 'active'` in admin_users. This is the sole precondition separating the bootstrap-super-admin finding from a live P0 privilege escalation. Evidence needed: `SELECT count(*) FROM <schema>.admin_users WHERE is_super_admin AND account_status='active'` against the production DB.
- Whether production is running backend 870fd28. Every backend finding above is stated against the local checkout at that SHA; several routes that a prior inventory recorded as unauthenticated (POST /api/bookings, GET /api/:id, GET /api/:id/tracking, POST /api/:id/confirm-otp, and all four payment routes) have since been given verifyAuth in this commit, so the deployed reality could differ in either direction. Evidence needed: `git rev-parse HEAD` in the deploy directory on Linode 192.46.224.126, or `pm2 describe servana-prod`.
- Whether production runs backend 870fd28. All backend citations are against the local checkout. Important caveat: the BACKEND INVENTORY supplied with this task is materially stale relative to that commit — booking.routes.ts:20 now carries verifyAuth, payment.routes.ts:8-11 now carry verifyAuth, bookingController.createBooking now takes identity from the token (bookingController.ts:16), and src/services/bookingAccessService.ts exists. Several LEAK items described in the inventory as open are already closed at 870fd28. Evidence needed: git rev-parse HEAD in the deploy dir / pm2 describe servana-prod.
- Whether production runs backend 870fd28. Every finding above is stated against the local commit only. Evidence needed: deployed SHA on the Linode host (`pm2 describe servana-prod`, or `git rev-parse HEAD` in the deploy directory).
- Whether production's guest_customers table has a phone_number column. This decides whether finding 1 is a hard 500 on the customer Bookings tab or a live phone-based identity merge. Evidence needed: SELECT column_name FROM information_schema.columns WHERE table_name='guest_customers' on the Linode prod DB (192.46.224.126).
- Whether the 'Beauty & Wellness' literal is actually visible to end users on every non-BW booking, or whether some other code path overwrites merchantServiceName before render. I traced http_backend.dart:452 → :482 → JobOrder.merchantServiceName but did not trace every list-widget render path. Evidence needed: a widget test rendering the bookings list from a fixture aircon booking response.
- Whether the MongoDB `addresses` write actually fails in production at any measurable rate. The fire-and-forget catch at address.service.ts:41-45 logs but does not count, so the blast radius of the unbookable-address finding is unquantified. Evidence needed: grep production logs for '[address.service] MongoDB location write failed'.
- Whether the ServanaClient Messages inbox is in fact empty for real users today. The exception is swallowed at messaging_store.dart:114-115, so the failure is silent and would not appear in crash reporting. Evidence needed: a device/emulator session against production with a customer who has at least one conversation.
- Whether the admin portal binds any UI column or navigation target to the coalesced `customerUid` from adminBookingService.ts:298. I did not open servana_adminportal source for this finding, so the compatibility-alias recommendation (keep a legacy `partyUid`) is precautionary rather than evidence-driven.
- Whether the cold-start notification deep link (main.dart:153-168) races the splash screen's own navigation. The post-frame push fires while AuthStateService may still be `unknown`, in which case main_router.dart:120 returns null and the guard is skipped; whether the splash then clobbers the pushed route was not traced. Evidence needed: a device run tapping a notification from a terminated app state.
- Whether the customer WEB portal has any of these exposures. UNAVAILABLE — servana_Customer_WebPortal contains zero committed files (docs-only greenfield), so nothing about it can be inspected or inferred.
- Whether the customer web portal uses any of these field names. servana_Customer_WebPortal contains 0 committed files (docs-only greenfield) — UNAVAILABLE. All cross-platform claims above are limited to admin portal, provider web, provider mobile and customer mobile.
- Whether the provider WEB portal (Servana.com.ph) or the admin portal call GET /api/users/:userId/bookings or GET /api/user/:userId/addresses without a token. If either does, promoting those two routes to verifyAuth would break them. Evidence needed: grep for both paths across Servana.com.ph/src and servana_adminportal/src, plus confirmation that their HTTP interceptors attach a bearer token.

