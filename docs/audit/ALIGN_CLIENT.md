# ALIGN — Servana Customer Mobile App

Canonical contract alignment — status, catalog, identity, auth, payment, notification, audit.

| | |
| --- | --- |
| Target | `Heatclift/ServanaClient` @ `bab66e4` |
| Backend | `servana_api` @ `870fd28` (canonical, §3) |
| Also inspected | admin portal `101016d`, provider web `42fbec9`, provider mobile `451eaf6` |
| Customer web | **UNAVAILABLE** — repo has 0 committed files |
| Findings | 23 |

**P0: 2 · P1: 11 · P2: 9 · P3: 1**

## SC-003 · `POST /api/:bookingId/approve` and `/mark-cash-paid` skip the booking-access check their sibling payment routes enforce — **FIXED** in `6d78313`

**P0** · rule §11, §12, §43 · fix in **backend** · protected release: **no**

The payment router was hardened correctly for two of its four booking-scoped routes: `gcashSubmit` calls `assertBookingAccess` (paymentController.ts:13) and so does `createPaymongoPayment` (:51). `approve` (:28-36) and `markCashPaid` (:38-46) were left with `verifyAuth` alone — authenticated, but not authorized. `bookingId` is taken straight from the URL and the service UPDATEs `payments` by `booking_id` with no owner predicate and no state guard (paymentService.ts:75-84, 111-120). Any logged-in customer can therefore settle a stranger's booking as PAID and trigger a false 'Payment Received' payout notification to that booking's provider (:97-105, :133-141). §12 is explicit that unauthorized calls must fail when made directly outside the UI.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:434-448 (approveGcashPayment / approveCashPayment target these routes)
- **Backend:** servana_api-main/src/routes/payment.routes.ts:9-10 (verifyAuth only) + src/controllers/paymentController.ts:28-36,38-46 (no assertBookingAccess, unlike :13 and :51) + src/services/paymentService.ts:75-84,111-120 (UPDATE payments SET status='PAID' WHERE booking_id=$1, no owner predicate, no state guard); negative proof: src/app.ts:115 mounts at /api with cors only and src/middleware/verifyAuth.ts:36-38 performs authentication with no role/ownership check
- **Other:** servana_api-main/src/services/paymentService.ts:97-105, :133-141 (both then fire an 'earnings_payout / Payment Received' notification to the assigned provider)
- **Canonical contract:** Every booking-scoped payment mutation resolves the actor via assertBookingAccess(bookingId, token.uid) before touching the payments row; settlement (`status='PAID'`) additionally requires actor role ∈ {admin} or {assigned provider, method='CASH'}.
- **Test gap:** tests/leak-isolation.test.js covers no payment route. Add request-level tests: customer B calls approve on customer A's booking → 403; payments row unchanged; no provider notification emitted.

**Recommendation.** Backend-only, one line each: add `await assertBookingAccess(bookingId, (req as any).user?.uid)` at the top of `approve` and `markCashPaid`, exactly as gcashSubmit does at paymentController.ts:13, and map the error through `sendBookingAccessError`. Then tighten further — approving a payment is a finance action, so gate it to admin (`verifyRoles([1])`) or to the assigned provider for cash collection; a customer should never be able to declare their own booking PAID (§43 separates declaration from verification). ServanaClient's approve methods are dead code (zero call sites in lib/ or test/), so no client behaviour changes.

## SC-004 · `POST /api/bookings/:id/cancel` is auth-optional and its ownership check short-circuits for anonymous callers — cancellation is unauthenticated and unattributable — **FIXED** in `bd8c355`

**P0** · rule §11, §12, §15, §16 · fix in **backend** · protected release: **no**

Every other booking route in this router was promoted to `verifyAuth` with a controller-side `assertBookingAccess` — create (:20), confirm-otp (:28), get (:29), tracking (:30). Cancel (:22) was left on `verifyAuthOptional`, and the ownership predicate in `customerCancelBooking` is written as `if (customerUid && ownerId && ownerId !== customerUid)` (bookingService.ts:546), which evaluates false for an anonymous caller. Sending no Authorization header is therefore strictly more privileged than sending a valid one: any unauthenticated caller can cancel any booking not in a terminal state, and the audit row written at :565-574 records `actor_uid = NULL` with `actor_type = 'customer'` — an unattributable mutation, which §15/§16 exist to prevent. ServanaClient already sends a bearer token on this call (servana_api_client.dart:479), so the auth-optional path exists for no live consumer.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:471-479 (cancelBooking sends the bearer token); lib/modules/bookings/data/booking_repository.dart:76-81
- **Backend:** servana_api-main/src/routes/booking.routes.ts:22 (verifyAuthOptional on POST /bookings/:id/cancel, vs verifyAuth at :20,:28,:29,:30) + src/services/bookingService.ts:546 (`if (customerUid && ownerId && ownerId !== customerUid)` — guard short-circuits when customerUid is null) + src/controllers/bookingController.ts:197 (`req.user?.uid ?? null`, no presence check) + src/middleware/verifyAuthOptional.ts:26-27,36-41 (missing OR invalid token both pass through with req.user unset) + src/app.ts:109 (mounted at /api, no global auth or rate-limit middleware at :36-90)
- **Other:** servana_api-main/src/services/bookingService.ts:565-574 (timeline row written with actor_uid = NULL, actor_type = 'customer'); src/routes/booking.routes.ts:20,28,29,30 (the sibling booking routes were all promoted to verifyAuth)
- **Canonical contract:** Cancellation: authenticated actor required; actor resolved via assertBookingAccess → {customer|provider|admin}; timeline/audit row always carries a non-null actorUid and the resolved actorRole; reason is mandatory; reasonCode optional.
- **Test gap:** No test asserts that an anonymous cancel is rejected. Add: POST cancel with no Authorization header → 401, booking status unchanged, no timeline row.

**Recommendation.** Backend-only. Change booking.routes.ts:22 to `verifyAuth` and replace the conditional in bookingService.ts:546 with `assertBookingAccess(bookingId, actorUid)` (bookingAccessService.ts:101-114), matching the pattern the sibling routes already use. Make `actor_uid` NOT NULL on the timeline insert. ServanaClient already authenticates this call, so no protected release is required — this is the same reasoning already recorded in the comment at booking.routes.ts:23-27.

## SC-044 · `options-with-addons` path mismatch — ServanaClient calls a 3-segment path the backend does not register — **FIXED** in `65b4337`

**P1** · rule §4, §30, ALIGN §0.4 · fix in **backend** · protected release: **no**

The provider mobile app and the ALIGN protected-route list both use the 2-segment form `/api/:serviceId/options-with-addons`, which is what the backend registers. ServanaClient calls the 3-segment form `/api/services/:id/options-with-addons` (servana_api_client.dart:264). No router in the mount chain matches a 3-segment path of that shape and no path-rewriting middleware exists (app.ts:67,69 alias field *names* only), so the call 404s. Its three call sites — aircon add-ons (aircon_booking_store.dart:257), Beauty & Wellness add-ons (bw_booking_store.dart:233) and the Category Experience screen (category_experience_repository.dart:18) — therefore never receive add-on data. The customer app is the only caller of the wrong form; the admin portal and provider web call neither.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:264 ('/api/services/$serviceId/options-with-addons')
- **Backend:** servana_api-main/src/routes/service.route.ts:12 (router.get("/:serviceId/options-with-addons") — mounted at /api, so the live path is /api/:serviceId/options-with-addons)
- **Other:** ServanaWorker/lib/core/api/servana_api.dart:305 ('/api/$serviceId/options-with-addons' — 2 segments, matches the backend)
- **Canonical contract:** Canonical: `GET /api/:serviceId/options-with-addons` (protected — ServanaWorker). Accepted alias: `GET /api/services/:serviceId/options-with-addons` (same controller, same response shape).
- **Test gap:** No route-contract test enumerates the paths ServanaClient actually calls against the registered router table. Add a generated cross-check from servana_api_client.dart URIs to the Express route list.

**Recommendation.** Add one alias route in the backend: `router.get("/services/:serviceId/options-with-addons", serviceController.listOptionsWithAddons)` immediately after service.route.ts:12. Purely additive, does not touch the 2-segment route ServanaWorker depends on, and repairs three customer screens with no protected release. Do not remove the 2-segment route.

## SC-045 · `X-Idempotency-Key` is sent on booking creation and read by nothing — the customer path has no idempotency while the admin path has a full implementation

**P1** · rule §17, §10 · fix in **backend** · protected release: **no**

The customer app does everything right: it generates a stable idempotency key, persists it against the draft so a retry reuses it (draft_repository.dart:58,93) and sends it as `X-Idempotency-Key` (servana_api_client.dart:374-378). The backend reads no such header anywhere — I grepped the whole of src/ and the only idempotency machinery is `booking_create_idempotency`, wired exclusively into the admin create path (adminCreateBookingService.ts:120-128, 501-504). `createBooking` (bookingService.ts:15-132) inserts a booking row and a payments row with no dedupe, so a double-submit or a retry after the 30s client timeout (servana_api_client.dart:883-901) produces two bookings and two payment rows for one customer intent. §17 names exactly this case ('double-click create → one booking'), and §10 requires the equivalent capability to be one shared backend service rather than an admin-only one.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:374-378 (sets 'X-Idempotency-Key' on POST /api/bookings); lib/core/recovery/draft_repository.dart:58,93 (persists booking_idem_v1_<uid>_<draftId> so the key is stable across retries)
- **Backend:** servana_api-main/src/controllers/bookingController.ts:9-53 (createBooking never reads any header); src/services/bookingService.ts:15-132 (INSERT with no dedupe of any kind)
- **Other:** servana_api-main/src/services/adminCreateBookingService.ts:120-128 (booking_create_idempotency table, UNIQUE(idempotency_key, admin_actor_uid)) and :501-504 (pre-flight lookup) — the canonical capability already exists, admin-only
- **Canonical contract:** BOOKING.CREATE is idempotent on (idempotencyKey, actorUid). Key source: `X-Idempotency-Key` header (mobile) or `idempotencyKey` body field (admin). A repeat returns the original bookingId with the original status and creates no second payments row.
- **Test gap:** No test posts the same X-Idempotency-Key twice. Add: two identical creates → one bookings row, one payments row, same bookingId returned.

**Recommendation.** Backend-only, additive: extract the admin idempotency helper into a shared BOOKING.CREATE capability keyed on `(idempotency_key, actor_uid)` — the existing table already has that UNIQUE constraint (adminCreateBookingService.ts:128) — and have `bookingController.createBooking` read `X-Idempotency-Key`, returning the previously created booking on a repeat. Absent header = current behaviour, so nothing regresses. The client already sends the key, so this closes the gap with no protected release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-046 · Admin read model places `guestCustomerId` inside `customerUid` — direct §7 violation

**P1** · rule §7, §8 · fix in **backend** · protected release: **no**

§7 states plainly that `guestCustomerId` must NEVER be placed in `customerUid`. The admin booking list does exactly that: `COALESCE(cu.uid, b.guest_customer_id::text) AS customer_uid` (adminBookingService.ts:298), surfaced as `customerUid` (:371). For every guest booking the canonical client-identity key holds a guest UUID, not a Firebase UID. `customerType` sits alongside it as the only discriminator, so any consumer that reads `customerUid` without also branching on `customerType` — and the customer mobile model does exactly that, customer_booking.dart:199-201 — resolves a guest UUID as a customer identity. The detail view got this right (`guestCustomerId` emitted separately at :552); the list view was missed.

- **Client:** servana_client-main/lib/common/domain/booking/customer_booking.dart:199-201 (client resolves customerId ← customerId ?? userId ?? customerUid — it will accept whatever is under that key)
- **Backend:** servana_api-main/src/services/adminBookingService.ts:298 (COALESCE(cu.uid, b.guest_customer_id::text) AS customer_uid) and :371 (customerUid: row.customer_uid); same pattern at :476
- **Other:** servana_api-main/src/services/adminBookingService.ts:551-552 (the detail view DOES emit guestCustomerId separately — the list view does not)
- **Canonical contract:** { customerType: 'client'|'guest', customerUid: <Firebase UID | null>, guestCustomerId: <UUID | null> } — exactly one of the two identity fields is non-null; they are never merged into one key.
- **Test gap:** No test asserts customerUid is null for guest bookings. Add an assertion to the admin booking list contract test.

**Recommendation.** Backend-only, additive: in the list projection emit `customerUid: cu.uid` (NULL for guests) and add a sibling `guestCustomerId: b.guest_customer_id`, keeping `customerType` as-is. To avoid breaking any admin-portal column already bound to the coalesced value, keep a clearly-named legacy alias (e.g. `partyUid`) carrying the old COALESCE for one release. Add `guestCustomerId` to PARITY_REGISTRY (fieldParity.ts) with no aliases so no middleware ever coalesces it into the customerUid group.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-047 · Bookings list hardcodes every booking's service as "Beauty & Wellness"

**P1** · rule §3, §30 · fix in **client-mobile** · protected release: **yes**

`_mapApiBookingToJobOrder` is the mapper behind the /Bookings tab (bookings_screen.dart:134 classifies `JobOrder`). It initialises `serviceName` to the literal `'Beauty & Wellness'` (http_backend.dart:452) and only overrides it if `pricingBreakdown.addons[0].level_3` happens to exist (:453-462). It never reads `serviceName`. An aircon repair booking therefore appears in the customer's own booking list labelled "Beauty & Wellness" — fabricated display data in a primary flow, and a value the customer cannot reconcile with what they booked. The mapper also ignores the canonical `serviceName` key entirely, so the backend fix in the previous finding will not reach this screen on its own.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:452 (String serviceName = 'Beauty & Wellness';) and :453-462, :484
- **Backend:** servana_api-main/src/services/bookingService.ts:321-368 (no service identity in the payload — the client has nothing correct to read)
- **Other:** servana_client-main/lib/modules/bookings/presentation/screens/bookings_screen.dart:134 (list screen consumes JobOrder, i.e. this mapper)
- **Canonical contract:** JobOrder.merchantServiceName ← booking.serviceName (canonical) → booking.serviceType → pricingBreakdown.addons[0].level_3 → '' (never a hardcoded category).
- **Test gap:** No test asserts the bookings list label matches the booked service. Add a mapper test with an aircon fixture asserting the label is not 'Beauty & Wellness'.

**Recommendation.** Ship the backend `serviceName` field first (previous finding). Then, in the next scheduled customer-mobile release, change http_backend.dart:452 to read `b['serviceName'] ?? b['serviceType']` and drop the hardcoded literal, keeping the pricingBreakdown derivation only as a last-resort fallback. Do not ship this as a standalone release; batch it with the status remap (finding 2).

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-048 · Customer booking read model omits canonical service identity — booking detail shows an empty service name

**P1** · rule §30, §5, §9 · fix in **backend** · protected release: **no**

The admin booking read model carries `serviceId`, `serviceOptionId`, `serviceName` and `specificServiceName` (adminBookingService.ts:380-383). The customer booking read model carries none of them: both customer queries select `b.*` plus payment/branch/address/worker columns and never join `service_options`, so `serviceName`, `serviceType`, `level_2` and `level_3` are absent from the payload. The customer detail screen reads `b['serviceName']` and falls back to the empty string (booking_detail_screen.dart:201-205), so today it renders a booking with no service name at all. `CustomerBooking.fromApiMap` (customer_booking.dart:204-213) has the same problem. This is one business entity described two different ways depending on which portal asks (§9).

- **Client:** servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:201-205 (merchantServiceName: b['serviceName'] ?? … ?? ''); lib/common/domain/booking/customer_booking.dart:204-213
- **Backend:** servana_api-main/src/services/bookingService.ts:321-368 (getBookingsByUserId) and :207-238 (getBookingById) — neither joins service_options/services; no serviceName/serviceType/level_2/level_3 in the SELECT
- **Other:** servana_api-main/src/services/adminBookingService.ts:382-383 (admin read model DOES emit serviceName and specificServiceName)
- **Canonical contract:** Booking read model (all surfaces): { serviceId, serviceOptionId, serviceName /* = service_options.level_2 */, serviceType /* = service_options.level_3 */ } — identical keys on the customer, provider and admin payloads.
- **Test gap:** No contract test asserts that the customer booking payload and the admin booking payload describe the same service with the same keys.

**Recommendation.** Backend-only, additive: join `service_options so ON so.id = b.service_option_id` (and `services s ON s.id = so.service_id`) in `getBookingsByUserId` and `getBookingById`, and emit optional `serviceId`, `serviceName` (level_2) and `serviceType` (level_3) through `formatBooking`. These names already exist in PARITY_REGISTRY (fieldParity.ts:206-224), and the customer detail screen and CustomerBooking already read `serviceName`, so the fix lands with no client release. `serviceOptionId` already flows via `b.*` + toCamel.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-049 · Customer booking surface receives no §13 canonical status; `statusLower` is a false normalisation

**P1** · rule §13, §9 · fix in **backend** · protected release: **no**

The backend has exactly one §13 canonical status mapper (`mapOperationsStatus`, adminBookingService.ts:181-200) and it is wired only into the admin read model (`operationsStatus`, :369). The customer read model (`formatBooking`) emits the raw DB value plus `statusLower`, which is nothing more than `raw.toLowerCase()` (bookingService.ts:507). That produces `pending_otp`, `worker_assigned`, `confirmed` — strings that LOOK like the §13 snake_case canonical family but are not members of it (`new`, `awaiting_assignment`, `assigned`, `accepted`, `in_progress`, `completed`, `cancelled`, `disputed`). Any consumer that normalises on `statusLower` — the customer app, the future customer web portal — silently derives a wrong canonical value. Two platforms therefore hold two status models for the same booking row.

- **Client:** servana_client-main/lib/common/domain/booking/booking_status.dart:51-123
- **Backend:** servana_api-main/src/services/bookingService.ts:507 (statusLower = raw.toLowerCase()); src/services/adminBookingService.ts:181-200 (mapOperationsStatus — admin-only); src/services/adminBookingService.ts:369 (operationsStatus emitted only on the admin read model)
- **Canonical contract:** Booking read model (all surfaces): { status: <raw UPPERCASE, unchanged>, statusLower: <raw lowercase, unchanged, deprecated>, operationsStatus: 'new'|'awaiting_assignment'|'assigned'|'accepted'|'in_progress'|'completed'|'cancelled'|'disputed' }
- **Test gap:** No test asserts that the customer booking payload carries a §13-valid status. Add a contract test over formatBooking asserting operationsStatus ∈ the §13 set for every raw status the backend writes.

**Recommendation.** Additive backend change only: lift `mapOperationsStatus` out of adminBookingService into a shared domain helper and call it from `formatBooking` (bookingService.ts:483-511), emitting an optional `operationsStatus` field alongside the existing `status`/`statusLower`. Do not change, rename, or remove `status` or `statusLower` — ServanaClient reads `status` first (customer_booking.dart:164-165) and ServanaWorker/admin read the raw uppercase values. Adding one optional key is invisible to every current consumer and gives the next customer-mobile release and the customer web portal a single canonical value to bind to.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-050 · Customer notifications have one producer for a client that implements 22 types and 9 deep-link targets

**P1** · rule §45, §9, ALIGN §9 · fix in **backend** · protected release: **no**

`createCustomerNotification` is called exactly once in the whole backend — `booking_created` on booking creation (bookingController.ts:38-47). By contrast `createNotification` (provider) has 10 call sites across 6 service files. Every lifecycle transition the customer actually cares about produces a provider notification and no customer notification: worker assigned (technicianService.ts:941), payment confirmed (paymentService.ts:97,133), job started, job completed, provider declined, admin cancellation. The customer app has a complete notifications module — 22 typed events, 9 deep-link targets, FCM foreground/background handling, unread counts, per-uid caching — fed by a single event. The delivery machinery is symmetric (sendFcmPushToCustomer exists, notification.service.ts:578, 803); only the producers are missing.

- **Client:** servana_client-main/lib/modules/notifications/domain/notification_type.dart:26-74 (22 ServanaNotificationType values); lib/modules/notifications/domain/notification_target.dart:39-59 (9 routeKeys handled)
- **Backend:** servana_api-main/src/controllers/bookingController.ts:38-47 — the sole createCustomerNotification call site in the entire backend (type 'booking_created')
- **Other:** servana_api-main/src/services/technicianService.ts:941 (assigned_job → provider only); src/services/paymentService.ts:97, :133 (earnings_payout → provider only); src/services/adminCreateBookingService.ts:817, adminOnboardingService, serviceApplicationService — 10 provider call sites across 6 files
- **Canonical contract:** Every booking lifecycle transition emits a paired notification: provider ← createNotification(route {page, bookingId}); customer ← createCustomerNotification(route {routeKey, resourceId}). Both carry a deterministic notificationKey of the form <entity>:<id>:<event> for exactly-once delivery.
- **Test gap:** No test asserts a customer notification is created on assignment/completion/payment. Add one per transition, plus a replay test proving the notificationKey dedupes.

**Recommendation.** Backend-only, additive: add `createCustomerNotification` calls beside each existing provider notification, using routeKeys the client already handles (notification_target.dart:39-54) — `booking_assigned`/BOOKING_DETAILS at technicianService.ts:941, `payment_confirmed`/PAYMENT_DETAILS at paymentService.ts:97 and :133, `booking_started`/BOOKING_TRACKING, `booking_completed`/BOOKING_DETAILS, `booking_cancelled`/BOOKING_DETAILS at bookingService.ts:565. Pass a deterministic `notificationKey` (e.g. `bk:<id>:assigned`) so the ON CONFLICT DO NOTHING dedupe at notification.service.ts:766-777 makes each event exactly-once. No client release: the app already renders any type it receives and falls back to UnknownTarget for unrecognised keys (notification_target.dart:57-58).

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-051 · Email-OTP verification is permanently broken on customer mobile — the backend requires `email` in the body, the client sends only the token

**P1** · rule §4, §7, ALIGN §7 · fix in **backend** · protected release: **no**

Both OTP routes derive identity from a body field the customer app never sends. `verifyEmailOtp` requires `{email, otp}` (auth.service.ts:161-166) and gets `{otp}`; `resendEmailOtp` requires `{email}` (:203-208) and gets an empty body. Neither route carries auth middleware (auth.route.ts:51-52), so the `Authorization: Bearer` header the client always attaches (`_headers()`) is thrown away and there is no second identity source. Every email-verification attempt from the customer app returns 400. This is an identity-alignment defect, not a client bug: the routes take identity from an unauthenticated body field rather than from the verified token (§7).

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:217-225 (verifyEmailOtp posts {'otp': otp} only) and :227-231 (resendEmailOtp posts no body at all)
- **Backend:** servana_api-main/src/services/auth.service.ts:161-166 (verifyEmailOtp throws 'Missing required parameters' unless both email and otp are present) and :203-208 (resendEmailOtp throws unless email is present); src/routes/auth.route.ts:51-52 (otpLimiter only — no auth middleware, so the bearer token the client attaches is discarded)
- **Other:** servana_client-main/lib/modules/profile/data/profile_repository.dart:46-54 (the only callers — Settings → verify email)
- **Canonical contract:** OTP routes: identity = req.user.email (verified token) when present, else req.body.email (legacy unauthenticated path). Body `email` is ignored whenever it conflicts with the token subject, and the conflict is logged without PII — the same precedence bookingController.ts:16-22 already applies to ?userId=.
- **Test gap:** No test posts verify-email-otp with a bearer token and no body email. Add one asserting 200 and that the token subject's email was verified.

**Recommendation.** Backend-only, additive: add `verifyAuthOptional` to auth.route.ts:51-52 and, in both controllers, fall back to the token's `email` claim when `req.body.email` is absent. Existing web/provider callers that send `email` keep working byte-for-byte; the customer app starts working with no release. This also improves the security posture — when a token is present the OTP is bound to the authenticated subject instead of an arbitrary body field.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-052 · No customer-originated mutation produces a backend audit event

**P1** · rule §15, §16, ALIGN §11 · fix in **backend** · protected release: **no**

The backend has a proper audit capability (`auditFire`/adminAuditService) and applies it consistently across every admin mutation and even permission denials (requirePermission.ts). Not one customer-originated mutation reaches it. Booking creation writes a bookings row, a payments row and an email (bookingService.ts:73-120) and nothing else; OTP confirmation writes a `booking_tracking` row (:158) which is operational history, not governance evidence — §16 is explicit that timeline text is not sufficient audit evidence; GCash evidence submission (paymentService.ts:58-73) writes an attacker-suppliable `proof_url` with no record of who submitted it. Cancellation is the only customer action that records an actor, and per an earlier finding it records NULL for anonymous callers. Money moves and bookings are created on this platform with no immutable actor trail.

- **Client:** servana_client-main/lib/modules/aircon_booking/data/aircon_booking_store.dart:431 (createBooking); lib/common/presentation/screens/booking_otp_screen.dart:98 (confirmOtp); lib/common/data/backend/servana_api_client.dart:425 (gcash-submit)
- **Backend:** servana_api-main/src/services/bookingService.ts:73-132 (createBooking — no audit write), :135-201 (confirmOtp — booking_tracking only), src/services/paymentService.ts:58-73 (submitGcash — no audit write)
- **Other:** servana_api-main/src/services/adminAuditService.ts + auditFire call sites confined to controllers/adminBookingController.ts, adminCommunicationController.ts, adminOnboardingController.ts, adminProviderController.ts, middleware/requirePermission.ts, services/adminFinanceService.ts, adminGuestService.ts, adminPermissionService.ts, providerCatalogService.ts — zero customer-path callers
- **Canonical contract:** Audit event: { eventId, eventType, entityType:'booking'|'payment', entityId, customerUid, providerUid?, bookingId, paymentId?, actorUid, actorRole:'customer'|'provider'|'admin'|'system', source, reasonCode?, previousState, newState, requestId, idempotencyKey?, createdAt } — backend-generated, immutable, idempotent on (eventType, entityId, idempotencyKey).
- **Test gap:** No test asserts an audit row exists after a customer booking create or payment submission.

**Recommendation.** Backend-only, additive: call the existing `auditFire` from the customer mutation paths with the canonical envelope — createBooking, confirmOtp, cancelBooking, gcashSubmit, approve, markCashPaid, and the PayMongo webhook. Actor is already available from the verified token on every one of these routes now that they carry `verifyAuth` (booking.routes.ts:20,28-30; payment.routes.ts:8-11); the webhook's actor is `system`. Reuse `req.requestId` (stamped at app.ts:41-44) as the audit requestId. Nothing on the wire changes.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-053 · PayMongo webhook overwrites `bookings.status` with `PAID`, regressing an in-progress or completed booking

**P1** · rule §13, §18, §43 · fix in **backend** · protected release: **no**

The webhook branch for `checkout_session.payment.paid` writes `bookings.status = 'PAID'` with no guard on the current status. Payment can land after assignment (the app supports a PayMongo "pay later" path — http_backend.dart:382-389 renders 'Payment Required' on top of PENDING_OTP/CONFIRMED/WORKER_ASSIGNED), so a booking already at `WORKER_ASSIGNED`, `IN_PROGRESS` or `COMPLETED` is silently rewound to `PAID`. §18 forbids silently overwriting newer state. The admin surface hides the damage because `mapOperationsStatus` lets `workerStatus` win (adminBookingService.ts:192-195); the customer surface has no such fallback and watches its booking go backwards mid-service. Root cause is a §13 alignment defect: `bookings.status` carries both a lifecycle value and a payment value, and `PAID` has no §13 booking equivalent — the payment axis already lives in `payments.status`.

- **Client:** servana_client-main/lib/common/domain/booking/booking_status.dart:69-71 (PAID → BookingStatus.paid); lib/common/data/backend/http_backend.dart:409-412 (PAID → 'Paid')
- **Backend:** servana_api-main/src/services/paymentService.ts:470-477 (UPDATE bookings SET status='PAID' WHERE id=$1 — no state predicate)
- **Other:** servana_api-main/src/services/adminBookingService.ts:192-198 (admin masks the regression because workerStatus wins)
- **Canonical contract:** Two independent axes, never merged: bookings.status = lifecycle (PENDING_OTP → CONFIRMED → WORKER_ASSIGNED → IN_PROGRESS → COMPLETED | CANCELLED); payments.status = settlement (PENDING | PAID | FAILED). `PAID` may only be written to bookings.status from a pre-assignment lifecycle state, and is deprecated in favour of paymentStatus.
- **Test gap:** No test covers a webhook arriving after assignment. Add: assign worker → fire paid webhook → assert bookings.status is still WORKER_ASSIGNED and payments.status is PAID.

**Recommendation.** Backend-only, additive: (a) make the webhook UPDATE conditional — `SET status='PAID' WHERE id=$1 AND status IN ('PENDING_OTP','CONFIRMED')` — so payment can never move a booking that has already advanced; (b) always update `payments.status` (already done at paymentService.ts:431-442) as the authoritative payment axis; (c) let `operationsStatus` derive from the lifecycle axis only. No wire value changes, no client release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-054 · Two parallel booking timelines — the customer's own cancellation is written to the table the customer cannot read — **FIXED** in `bd8c355`

**P1** · rule §9, §16, ALIGN §11 · fix in **backend** · protected release: **no**

Servana keeps two timeline stores for one booking. `booking_tracking` receives the lifecycle writes (confirmOtp bookingService.ts:158, assignment technicianService.ts:936, payment paymentService.ts:456,481) and is the only one the customer can read — `GET /api/:id/tracking` selects from it (bookingService.ts:375-386). `booking_timeline_events` receives the admin-era writes and, critically, the customer's own cancellation (bookingService.ts:565-574). Admin reads and merges both (adminBookingService.ts:626,632); the customer reads only one. Net effect: a customer cancels their booking and their own timeline never shows it, and no admin-recorded action is ever visible to them. This is §9 duplicate reality for the same business object, and §16's timeline/audit distinction collapsed into two half-timelines instead.

- **Client:** servana_client-main/lib/modules/bookings/data/booking_repository.dart:93-102 (getTimeline reads the tracking envelope only); lib/common/data/backend/servana_api_client.dart:497 (getBookingTimeline delegates to /api/:id/tracking)
- **Backend:** servana_api-main/src/services/bookingService.ts:565-574 (customer cancel INSERTs into booking_timeline_events) vs :375-386 (getTracking SELECTs from booking_tracking — a different table)
- **Other:** servana_api-main/src/services/adminBookingService.ts:626 and :632 (admin reads BOTH tables and merges them); src/services/technicianService.ts:936, src/services/paymentService.ts:456,481 (lifecycle writes go to booking_tracking); src/services/adminCreateBookingService.ts:785 (admin-created bookings write to booking_timeline_events)
- **Canonical contract:** One canonical booking timeline per bookingId. Customer read model = union(booking_tracking, booking_timeline_events) projected to {status, safeNote, createdAt}; admin read model = the same union plus actorUid, actorRole, previousState, newState, reason.
- **Test gap:** No test asserts the cancellation appears on the customer tracking timeline. Add: cancel → GET /api/:id/tracking contains a cancelled event.

**Recommendation.** Backend-only, additive: keep both tables (destructive migration is forbidden, §57) and make `getTracking` return the UNION, normalised to the tracking row shape `{status, note, createdAt}` and ordered by createdAt. Simultaneously dual-write the customer cancellation to `booking_tracking` so the union is correct even for old rows. The client already renders whatever rows it receives (booking_repository.dart:97-101), so this needs no release.

## SC-094 · `approvePayment` / `markCashPaid` have no state guard and no idempotency — replay resets paid_at and re-fires the provider payout notification — **FIXED** in `6d78313`

**P2** · rule §17, §18, §43, §45 · fix in **backend** · protected release: **no**

Distinct from the authorization gap on the same two routes: even for a correctly authorized caller these mutations are not replay-safe. Neither UPDATE carries a current-state predicate, so calling approve twice rewrites `paid_at` to the later timestamp and fires a second 'Payment Received' notification to the provider (paymentService.ts:97-105, 133-141). `markCashPaid` additionally forces `method='CASH'`, so calling it on an already-settled GCASH payment silently rewrites the payment method and destroys the evidence linkage (§43). The webhook path in the same file gets this right — it dedupes on `webhook_event_id` (:407-419) — so the capability exists and was simply not applied here.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:434-448 (approveGcashPayment / approveCashPayment)
- **Backend:** servana_api-main/src/services/paymentService.ts:75-84 (UPDATE payments SET status='PAID', paid_at=NOW() — no `AND status <> 'PAID'`) and :111-120 (same, plus it forces method='CASH')
- **Other:** servana_api-main/src/services/paymentService.ts:97-105, :133-141 (unconditional createNotification on every call); contrast :407-419 where the webhook path DOES dedupe on webhook_event_id
- **Canonical contract:** PAYMENT.SETTLE(bookingId, method) is idempotent: it transitions PENDING→PAID exactly once, never rewrites paid_at or method on an already-PAID row, and emits at most one earnings_payout notification per booking.
- **Test gap:** No test calls approve twice. Add: approve ×2 → one notification, paid_at unchanged on the second call.

**Recommendation.** Backend-only: add `AND status <> 'PAID'` to both UPDATEs and emit the provider notification only when `rowCount > 0`, so a replay is a no-op rather than a second payout signal. For `markCashPaid`, add `AND method = 'CASH'` (or refuse when a GCASH reference/proof already exists) so a cash settlement can never overwrite submitted GCASH evidence.

## SC-095 · `booking_tracking.status` is an undeclared fourth status vocabulary, and its free-text `note` is returned verbatim to customers

**P2** · rule §13, §21, §58 · fix in **backend** · protected release: **no**

`booking_tracking.status` uses values that exist in no other status registry — `PAYMENT_PAID` and `ADDITIONAL_PAID` are written only here and `ADDITIONAL_PAID` falls through the client mapper to `unknown` (booking_status.dart:120-121). Worse, `technicianService.ts:1074` writes a tracking row whose status *regresses* to `CONFIRMED` carrying the note `'Worker declined — seeking reassignment'`. `getTracking` (bookingService.ts:375-386) returns `note` untouched and the client renders the raw map (booking_repository.dart:97-101), so an internal dispatch decision about a named provider's refusal is shown to the customer. That is operational detail the customer surface should never carry (§21/§58) and a timeline that moves backwards.

- **Client:** servana_client-main/lib/modules/bookings/data/booking_repository.dart:93-102 (returns raw tracking maps to the UI unfiltered)
- **Backend:** servana_api-main/src/services/paymentService.ts:481-485 ('PAYMENT_PAID'), :456-460 ('ADDITIONAL_PAID'); src/services/technicianService.ts:1074-1077 (status 'CONFIRMED', note 'Worker declined — seeking reassignment'); src/services/bookingService.ts:375-386 (getTracking returns status+note+created_at as-is)
- **Other:** servana_client-main/lib/common/domain/booking/booking_status.dart:120-121 ('ADDITIONAL_PAID' → unknown)
- **Canonical contract:** Tracking event: { eventStatus: <§13 family value>, rawStatus: <legacy value, unchanged>, safeNote: <customer-safe string>, note: <internal, admin/provider only>, createdAt }
- **Test gap:** No test asserts that customer-visible tracking notes exclude provider-decision text.

**Recommendation.** Backend-only: introduce an explicit tracking-event vocabulary aligned to the §13 family, and split `note` into an internal `note` (admin/provider only, already read at adminBookingService.ts:626) and an optional `safeNote` returned to customers. Emit `safeNote` on the customer path and keep `note` for backward compatibility until the next client release stops reading it. Replace the 'Worker declined' text on the customer path with a neutral 'Finding another provider'.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-096 · `GET /api/:id/tracking` runs timeline rows through the booking formatter, stamping every event with `bookingCode: "SVN-undefined"`

**P2** · rule §4, §9 · fix in **backend** · protected release: **no**

`getTracking` returns rows shaped `{status, note, created_at}` — no `id`. The controller passes them through `formatBookings`, the booking-entity formatter (bookingController.ts:161). `bookingPk` resolves to `undefined`, and because the `bookingCode` line at bookingService.ts:497 is unconditional (unlike every other alias on that object, which is guarded by an `in c` check), `String(undefined).padStart(6,'0')` yields the literal `"SVN-undefined"` on every timeline event. Each row also gains a spurious `statusLower`. The timeline contract is polluted with booking-entity fields that are meaningless or actively wrong, and the client hands the whole map to the UI unfiltered.

- **Client:** servana_client-main/lib/modules/bookings/data/booking_repository.dart:97-101 (returns the raw maps to the timeline UI, so every injected key is carried into the widget layer)
- **Backend:** servana_api-main/src/controllers/bookingController.ts:161 (res.json({tracking: formatBookings(tracking)})); src/services/bookingService.ts:497 (bookingCode: c.bookingCode ?? `SVN-${String(bookingPk).padStart(6,'0')}` — emitted unconditionally) and :375-386 (getTracking returns {status, note, created_at} — there is no id column)
- **Other:** servana_api-main/src/services/bookingService.ts:483-511 (formatBooking's own docblock scopes it to booking rows: 'Booking `id` = numeric PK')
- **Canonical contract:** Tracking/timeline event payload = { status, safeNote, createdAt } only. Booking-entity aliases (bookingId, bookingCode, scheduleAt, providerUid, customerUid) are never injected into non-booking rows.
- **Test gap:** No test asserts the tracking payload shape. Add one asserting the response contains no bookingCode key.

**Recommendation.** Backend-only: stop applying the booking formatter to tracking rows. Add a dedicated `formatTrackingEvent` (or call `toCamel` alone) at bookingController.ts:161. Independently, guard the bookingCode line at bookingService.ts:497 the same way its neighbours are guarded, so no future misuse can synthesise `SVN-undefined`. Additive keys the client currently reads (`status`, `note`, `createdAt`) are preserved, so no release is required.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-097 · `POST /api/auth/logout` exists but the customer app never calls it — no server-side session termination

**P2** · rule §4, ALIGN §7 · fix in **client-mobile** · protected release: **yes**

The backend implemented `POST /api/auth/logout` behind `verifyAuth` (auth.route.ts:62). The customer app's `HttpBackend.logout()` is still an empty stub carrying a TODO that asserts the endpoint does not exist (http_backend.dart:163-167). Logout therefore clears local Hive state only; the Firebase ID token remains valid server-side until natural expiry. The stale half of this is worth recording: MOBILE_BACKEND_COMPATIBILITY_REPORT GAP-001 blames the backend, but the backend side is done — only the client wiring is missing.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:163-167 (logout() is an empty method with a TODO saying the backend endpoint does not exist); lib/modules/auth/.../authentication_bloc.dart:304 (repo.logout() is the only logout call)
- **Backend:** servana_api-main/src/routes/auth.route.ts:62 (router.post("/auth/logout", verifyAuth, authController.logoutController) — implemented)
- **Other:** servana_client-main/lib/common/data/backend/servana_api_client.dart:37-47 (client attaches the bearer on every call, so it is capable of calling logout)
- **Canonical contract:** Logout sequence: POST /api/auth/logout (authenticated) → DELETE /api/user/fcm-token (authenticated) → local session/state teardown. All backend calls occur while the bearer token is still present.
- **Test gap:** No test asserts logout calls the backend before clearing the session. Add a bloc test asserting call order.

**Recommendation.** Client fix, but do not spend a release on it alone — batch it with the status/serviceName work. Wire `HttpBackend.logout()` to `ServanaApiClient` → `POST /api/auth/logout`, called BEFORE `SessionService.deleteSession()`. Fixing the ordering also repairs the related FCM defect: `DELETE /api/user/fcm-token` currently runs after the session is destroyed (authentication_bloc.dart:308 before :359) so it always 401s and the token row survives. One ordering change closes both.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-098 · `WORKER_ASSIGNED` renders as "On the way" on customer mobile but "assigned" in admin — same row, two realities

**P2** · rule §13, §9 · fix in **client-mobile** · protected release: **yes**

`assignWorker` writes `bookings.status = 'WORKER_ASSIGNED'` at the moment a provider is *assigned*, before any acceptance. The admin mapper correctly reads that as §13 `assigned` (adminBookingService.ts:195). The customer app's canonical mapper folds it into `BookingStatus.enRoute` (booking_status.dart:86-87), i.e. "on the way". Assignment is not departure — §22 explicitly separates assigned from accepted, and neither is en-route. The customer is told the provider is travelling while the provider has not even confirmed. Note the client is internally inconsistent too: its own legacy mapper labels the same value 'Worker Assigned' (http_backend.dart:406), so the Bookings list and the tracking screen disagree with each other.

- **Client:** servana_client-main/lib/common/domain/booking/booking_status.dart:82-87 (WORKER_ASSIGNED → BookingStatus.enRoute)
- **Backend:** servana_api-main/src/services/technicianService.ts:931 (UPDATE bookings SET status='WORKER_ASSIGNED'); src/services/adminBookingService.ts:195 (WORKER_ASSIGNED → 'assigned')
- **Other:** servana_client-main/lib/common/data/backend/http_backend.dart:400-407 (same value → statusLabel 'Worker Assigned')
- **Canonical contract:** Raw `WORKER_ASSIGNED` ≡ operationsStatus `assigned` ≡ customer label "Provider assigned". `enRoute` is reserved for raw `EN_ROUTE`/`IN_TRANSIT`, which this backend never writes (only reads, bookingService.ts:520).
- **Test gap:** booking_status_test has no case pinning WORKER_ASSIGNED to the same bucket the admin mapper uses. Add a shared status-parity fixture derived from mapOperationsStatus.

**Recommendation.** Do not change the wire value `WORKER_ASSIGNED` — it is a protected status consumed by ServanaWorker and the admin portal (§4, ALIGN §17 stop condition). Land the backend `operationsStatus` field first (finding 1); then in the next scheduled customer-mobile release remap `WORKER_ASSIGNED` → `BookingStatus.assigned` and bind the label to `operationsStatus` when present, keeping the raw-status switch as the fallback. This must not be shipped as its own release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-099 · Booking conversation is created before a provider is assigned or confirmed

**P2** · rule §24, §25 · fix in **backend** · protected release: **no**

§24 requires a booking conversation to exist only once the booking has an assigned provider who has confirmed (or an admin confirmed on their behalf). `getOrCreateConversation` (chat.service.ts:59-78) has no booking-state gate at all: it creates the conversation row on first access and syncs whatever participants happen to exist, tolerating an empty worker list (:70-76). The customer opening the messages screen on a brand-new `PENDING_OTP` booking therefore materialises a canonical conversation with one participant and nobody to talk to. Authorization is correct here — `resolveAccessForBooking` runs first (chat.controller.ts:44) — this is purely a lifecycle-alignment defect.

- **Client:** servana_client-main/lib/modules/messaging/data/messaging_repository.dart:28 (getBookingConversation called whenever the booking messages screen opens); lib/common/presentation/routes/main_router.dart:481 (/bookings/:bookingId/messages)
- **Backend:** servana_api-main/src/chat/chat.service.ts:59-78 (getOrCreateConversation — creates unconditionally, no booking-state check); src/chat/chat.controller.ts:37-54 (getBookingConversation authorizes the actor, then creates)
- **Other:** servana_api-main/src/chat/chat.service.ts:70-76 (participant sync tolerates an empty worker list, so a conversation with only the customer is a valid outcome)
- **Canonical contract:** One booking → at most one conversation, created only when the booking has an active provider assignment. Before that, GET /api/bookings/:id/conversation returns 409 CONVERSATION_NOT_AVAILABLE.
- **Test gap:** No test asserts a PENDING_OTP booking cannot open a conversation.

**Recommendation.** Backend-only: add a state gate in `getOrCreateConversation` — create only when the booking has a `booking_workers` row in {ASSIGNED, ACCEPTED, IN_PROGRESS, COMPLETED}; otherwise return null and have the controller respond with a safe domain code (e.g. `CONVERSATION_NOT_AVAILABLE`, 409) rather than a raw error. The client already surfaces API errors from this call, so no release is needed; verify the messaging screen renders an empty state rather than crashing before shipping.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-100 · Guest bookings are linked to a client account by an unverified, non-unique phone number — any customer can harvest another party's guest bookings — **FIXED** in `880d5bc`

**P2** · rule §7, §8, §11, §37 · fix in **backend** · protected release: **no**

`getBookingsByUserId` deliberately widens the customer's booking list to include any guest booking whose `guest_customers.phone_number` equals the caller's `user_credentials.phone_number` (bookingService.ts:352-361). The caller controls that value completely: `PUT /api/user/updateprofile` with `{mobileNumber}` reaches `updateUserPhoneNumber` (user.service.ts:348-361), a bare UPDATE with no OTP challenge, no uniqueness constraint enforcement, and no update to `is_phone_verified`. So any authenticated customer can set their profile phone to a number they do not own and immediately receive that party's guest bookings — including, per the same SELECT, the guest's address line, city, price, payment status, reference number, proof URL and assigned provider. This is exactly the §8 prohibition on merging guest identity into a client identity on a weak key, executed with no verification at all, and it produces cross-user data access (§11).

- **Client:** servana_client-main/lib/modules/profile/data/profile_repository.dart:19-32 (updateProfile sends mobileNumber); lib/common/data/backend/servana_api_client.dart:192 (PUT /api/user/updateprofile)
- **Backend:** servana_api-main/src/services/bookingService.ts:352-361 (guest bookings joined into the customer's list via `gc.phone_number = uc.phone_number`); src/services/user.service.ts:348-361 (updateUserPhoneNumber — bare UPDATE, no verification, no uniqueness check, never touches is_phone_verified); src/services/user.service.ts:296-298, 322-324 (mobileNumber from ServanaClient routed straight into it)
- **Other:** servana_api-main/src/services/user.service.ts:444 (is_phone_verified exists as a column and is read, but no write path sets it)
- **Canonical contract:** Guest→client linkage is an explicit, audited backend action producing `guest_customers.linked_customer_uid = <customerUid>`; it is never inferred from phone, name or email equality. `guestCustomerId` is never placed in `customerUid`.
- **Test gap:** tests/leak-isolation.test.js pins listUserBookings' JWT branch (:91) but nothing covers the guest phone-match branch. Add: customer A sets phone to guest G's number → GET /api/users/A/bookings must not return G's bookings.

**Recommendation.** Backend-only. Gate the guest join on verified ownership: require `uc.is_phone_verified = TRUE` in the subquery at bookingService.ts:352-361, and add an explicit `guest_customers.linked_customer_uid` column set only by a deliberate, audited link action (§8 'may later be linked'). Separately, make `updateUserPhoneNumber` refuse to change a phone number without an OTP challenge and clear `is_phone_verified` on any change. Both are backend changes; ServanaClient already calls the same endpoint and is unaffected. Until the OTP flow exists, the interim fix is to drop the phone-equality branch entirely — guest bookings are served by phone/Messenger and have no app surface (bookingAccessService.ts:53-57 already states this).

## SC-101 · Notification `route` payload has two incompatible shapes and neither is in the parity registry

**P2** · rule §46, ALIGN §9 · fix in **backend** · protected release: **no**

The same `route` JSONB column carries two mutually unintelligible shapes: `{routeKey, resourceId}` for customers and `{page, bookingId}` for providers. Neither key set appears in PARITY_REGISTRY (fieldParity.ts), so the alias middleware cannot bridge them. The consequence is concrete at notification.service.ts:798-802: the FCM data builder only copies `routeKey`/`resourceId`, so any notification written in the provider shape produces a push with no deep-link fields — and the customer client, which requires `routeKey` (notification_target.dart:37), would render it as untargeted. As soon as customer notifications are added for lifecycle events (previous finding), copy-pasting the provider shape will produce silently undeep-linkable pushes.

- **Client:** servana_client-main/lib/modules/notifications/domain/notification_target.dart:37-38 (reads route['routeKey'] and route['resourceId'] only); lib/modules/notifications/data/notification_mapper.dart:49-54 (FCM path reads data['routeKey']/data['resourceId'])
- **Backend:** servana_api-main/src/controllers/bookingController.ts:44 (customer: {routeKey:'BOOKING_DETAILS', resourceId}); src/services/paymentService.ts:103 and src/services/technicianService.ts:947 (provider: {page:'earnings'|'jobs', bookingId})
- **Other:** servana_api-main/src/services/notification.service.ts:798-802 (the FCM builder only forwards routeKey/resourceId — a provider-shaped route silently produces an FCM payload with no deep link at all)
- **Canonical contract:** route = { routeKey: <SCREAMING_SNAKE destination>, resourceId: <string id>, page: <legacy alias of routeKey>, bookingId: <legacy alias of resourceId> } — all four emitted, none removed.
- **Test gap:** No test asserts the FCM data payload carries a deep link for provider-shaped routes.

**Recommendation.** Backend-only, additive: register the deep-link group in PARITY_REGISTRY (canonical `routeKey` with alias `page`; canonical `resourceId` with alias `bookingId`) and have the notification writer emit both shapes into the `route` object. Existing provider and customer consumers each keep finding the key they already read; new producers cannot get it wrong. Do not rename either existing key (§46).

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-102 · Payment response envelopes diverge three ways on one surface, and `checkout_url` is the only snake_case key in the customer contract

**P2** · rule §4, ALIGN §0.7 · fix in **backend** · protected release: **no**

Four routes on one router return three different envelopes: `gcashSubmit` → `{success, payment}` (paymentController.ts:21), `approve`/`markCashPaid` → `{status:'success', data}` (:32,:42 — the admin convention on a customer-facing route), `createPaymongoPayment` → `{success, checkout_url}` (:55-58). `checkout_url` is the only snake_case key anywhere in the customer payment contract and it is not registered in PARITY_REGISTRY, so `parityMiddleware` does not add a camelCase alias. The customer app works only because it defensively probes both spellings (aircon_booking_store.dart:478-480) and unwraps `res['data'] ?? res`. Every new consumer has to rediscover this.

- **Client:** servana_client-main/lib/modules/aircon_booking/data/aircon_booking_store.dart:478-480 (data['checkoutUrl'] ?? data['checkout_url'] — the client defends against both); lib/modules/bookings/data/booking_repository.dart:9-11 (documents two different envelope conventions)
- **Backend:** servana_api-main/src/controllers/paymentController.ts:21 ({success, payment}), :32 and :42 ({status:'success', data}), :55-58 ({success, checkout_url})
- **Other:** servana_api-main/src/utils/fieldParity.ts:34-356 (checkoutUrl is absent from PARITY_REGISTRY, so no middleware aliases it)
- **Canonical contract:** Customer-facing envelope: { success: boolean, <entity>: {...}, message?: string }. Admin envelope: { status: 'success'|'error', data: ..., meta?: {...} }. Every URL field is emitted camelCase with the snake_case form retained as a parity alias.
- **Test gap:** No envelope-shape contract test exists for the payment router.

**Recommendation.** Backend-only, additive and non-destructive: add `checkoutUrl` to PARITY_REGISTRY (canonical `checkoutUrl`, alias `checkout_url`) so the parity middleware emits both, and add `success: true` alongside the existing `status:'success'` on approve/markCashPaid. Never remove `checkout_url`, `status` or `data` — ServanaClient and the admin portal read them today.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-117 · Client resolves customer identity with the canonical `customerUid` last in precedence

**P3** · rule §7, ALIGN §0.7 · fix in **client-mobile** · protected release: **yes**

PARITY_REGISTRY declares `customerUid` canonical and `customerId` a legacy alias (fieldParity.ts:177-180). The client's precedence is the reverse: `customerId ?? userId ?? customerUid` (customer_booking.dart:199-201), and the same inversion appears for provider identity, `workerUid ?? worker_uid ?? providerUid` (:224-226). Today this is harmless because `formatBooking` derives all three customer keys from the single `user_id` column (bookingService.ts:504-505), so they can never disagree. It becomes a real defect the moment any producer emits them independently — for example the guest work in the previous finding, or an admin-created booking snapshot.

- **Client:** servana_client-main/lib/common/domain/booking/customer_booking.dart:199-201 (customerId ?? userId ?? customerUid); :224-226 (workerUid ?? worker_uid ?? providerUid)
- **Backend:** servana_api-main/src/services/bookingService.ts:504-505 (formatBooking emits customerId and customerUid from the same user_id — currently always equal)
- **Other:** servana_api-main/src/utils/fieldParity.ts:177-180 (customerUid declared canonical, customerId listed as an alias)
- **Canonical contract:** Precedence on every surface: customerUid → customerId → userId; providerUid → workerUid → worker_uid. Producers must derive all aliases from a single source column so precedence is never load-bearing.
- **Test gap:** None required while the backend derives all aliases from one column; add a producer-side test asserting customerId === customerUid in formatBooking output.

**Recommendation.** No backend change needed and no release should be spent on this alone. Record the inversion in the alias precedence documentation, and when the client is next opened for the status/serviceName work, flip both chains to canonical-first: `customerUid ?? customerId ?? userId` and `providerUid ?? workerUid ?? worker_uid`. Meanwhile keep `formatBooking` deriving all aliases from one column so they cannot diverge.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

