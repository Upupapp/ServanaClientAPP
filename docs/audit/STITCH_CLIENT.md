# STITCH — Servana Customer Mobile App

End-to-end workflow tracing — client to API to persistence to notification to refresh, and where the chain breaks.

| | |
| --- | --- |
| Target | `Heatclift/ServanaClient` @ `bab66e4` |
| Backend | `servana_api` @ `870fd28` (canonical, §3) |
| Also inspected | admin portal `101016d`, provider web `42fbec9`, provider mobile `451eaf6` |
| Customer web | **UNAVAILABLE** — repo has 0 committed files |
| Findings | 39 |

**P0: 3 · P1: 25 · P2: 11**

## SC-001 · `addUserAddress` update branch overwrites any address by ID — the authenticated uid is never used in the WHERE clause — **FIXED** in `6d78313`

**P0** · rule §11, §12 · fix in **backend** · protected release: **no**

The sibling operations were scoped correctly (`makeAddressPrimary` and `deleteAddress` both carry `AND uid = $2`) but `updateUserAddress` was missed. Any authenticated user who supplies another customer's `addressId` rewrites that customer's street address, city, label, primary flag, `location_id` and — via the fire-and-forget `updateLocationInDB` at address.service.ts:86-88 — their MongoDB coordinates. Because `location_id` drives coverage checks and worker-distance pricing at booking time (bookingService.ts:54-60), this is also a booking-corruption vector, not just a privacy one. The ServanaClient never sends `addressId`, so this is reachable only by direct API call — which is exactly what §12 says must still fail.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:140-150 (addUserAddress posts an arbitrary payload map; nothing prevents an `addressId` key)
- **Backend:** servana_api-main/src/services/address.service.ts:57-60 and :68-80 — `UPDATE ${dbSchema}.user_address SET ... WHERE address_id = $11 returning *` with uid bound only at $8 (updated_by); reached via servana_api-main/src/controllers/user.controller.ts:29-33 behind servana_api-main/src/routes/user.route.ts:16 (`verifyAuth` only). Contrast servana_api-main/src/services/address.service.ts:197 and :224 which both use `AND uid = $2`.
- **Canonical contract:** ADDRESS.UPDATE — ownership predicate in SQL, uid from token only.
- **Test gap:** No test asserts `AND uid` is present in the updateUserAddress SQL. leak-isolation.test.js:48-66 pins this for makeAddressPrimary/deleteAddress; extend the same source assertion to updateUserAddress.

**Recommendation.** Change the WHERE clause to `WHERE address_id = $11 AND uid = $12` and pass the token uid. Keep the existing `rows.length == 0 → throw` so a mismatched owner fails closed as 'Failed to update address'.

## SC-002 · Guest-owned bookings can be cancelled by any authenticated user — POST /api/bookings/:id/cancel fails open when bookings.user_id is NULL — **FIXED** in `a062ef9`

**P0** · rule §11, §12, §15, §8 · fix in **?** · protected release: **no**

bd8c355 hardened the cancel route to `verifyAuth`, but the ownership guard one layer deeper was left in its fail-open shape. Admin-created guest bookings carry `user_id = NULL`, so the guard short-circuits and never denies. Any Servana account holder can cancel any guest booking by iterating sequential booking ids, and the audit trail records them as the customer who did it.


**Recommendation.** Add `await assertBookingAccess(bookingId, (req as any).user?.uid)` as the first statement in `cancelBooking` (bookingController.ts:187) and route errors through `sendBookingAccessError`, exactly as getBooking/getTracking do. Independently, delete the fail-open shape in the service: make `customerCancelBooking` require a non-null `customerUid` AND a non-null `ownerId` that matches, and throw 403 otherwise, so a NULL owner denies rather than permits. Backend-only; ServanaClient sends a Bearer token on this call already (servana_api_client.dart:471-486), so no protected release.

## SC-003 · Payment settlement handlers `approve` and `mark-cash-paid` skip the booking-ownership check — any authenticated user can mark any booking PAID — **FIXED** in `6d78313`

**P0** · rule §11, §12, §43 · fix in **backend** · protected release: **no**

A hardening pass added `assertBookingAccess` to three of the five payment handlers (gcashSubmit, createPaymongoPayment, webhook is HMAC-gated) but missed `approve` and `markCashPaid`. Both take `bookingId` straight from the URL and issue an unscoped UPDATE. Any Servana account holder — including a role-3 customer with a valid Firebase token — can settle a stranger's booking by iterating sequential booking IDs, and each call fires an 'earnings_payout / Payment Received' notification to the assigned provider (paymentService.ts:97-105, :133-141), producing a false payout signal on the provider side.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:434-448 (approveGcashPayment / approveCashPayment — both currently dead call-sites, so the client does not depend on the present behaviour)
- **Backend:** servana_api-main/src/controllers/paymentController.ts:28-46 (approve/markCashPaid call paymentService with bookingId straight from the URL and no assertBookingAccess, unlike :13 and :51) + servana_api-main/src/routes/payment.routes.ts:9-10 (verifyAuth only) + servana_api-main/src/middleware/verifyAuth.ts:36-38 (verifyIdToken only, no role or ownership check) + servana_api-main/src/services/paymentService.ts:79-83 and :115-119 (UPDATE payments SET status='PAID' WHERE booking_id=$1 — no owner predicate, no state guard)
- **Canonical contract:** PAYMENT.SETTLE — actor must hold an authorized relationship to the booking; settlement is admin/provider-initiated, never customer-initiated.
- **Test gap:** tests/leak-isolation.test.js has no case for /approve or /mark-cash-paid. Add a request-level test: customer A's token → POST /api/<customerB booking>/approve must 403.

**Recommendation.** Add `await assertBookingAccess(bookingId, (req as any).user?.uid)` as the first statement in both handlers (paymentController.ts:30 and :40) and route errors through `sendBookingAccessError`, mirroring gcashSubmit. Additionally restrict these two to admin/provider actors — a customer should never be able to self-declare a cash payment settled. Both client methods are dead code, so no mobile release is involved.

## SC-031 · 'Resend code' on the booking OTP screen calls a route that does not exist, leaving the OTP step with no recovery path

**P1** · rule §20 · fix in **backend** · protected release: **no**

The booking OTP is generated once at creation (bookingService.ts:71) and emailed once (bookingService.ts:107-120). If that email is delayed, filtered or lost, the customer's only remedy — the Resend button — hits a non-existent route and always errors. The booking is then permanently stuck in PENDING_OTP, which is also the state that blocks worker assignment. There is no self-service escape.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:405-413 (`POST /api/$bookingId/resend-otp`, with an in-code warning at :406-408); called from lib/common/presentation/screens/booking_otp_screen.dart:131-132, surfaced as 'Could not resend code. Please try again.' at :140
- **Backend:** servana_api-main — a repo-wide grep for `resend-otp` across src/ returns zero hits. src/routes/booking.routes.ts registers no such path.
- **Canonical contract:** BOOKING.OTP.RESEND — rate-limited, state-gated on PENDING_OTP, ownership-checked.
- **Test gap:** No test exercises the resend path.

**Recommendation.** Add `POST /api/:id/resend-otp` with `verifyAuth` + `assertBookingAccess`, rate-limited, that regenerates `bookings.otp_code` only while status is PENDING_OTP and re-sends the existing `verify_booking_otp` template. The client route string already matches, so this closes the loop with no mobile release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-032 · 'Resend email OTP' sends no request body at all, so it always returns 400

**P1** · rule §4, §20 · fix in **backend** · protected release: **no**

Combined with the verify-email-otp defect, the customer has no working path to verify their email address from inside the app: they can neither request a fresh code nor submit one. The backend's neutral-response design (auth.service.ts:211) is never reached.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:227-231 — `_client.post(uri, headers: await _headers())` with no `body:` argument. Called from lib/modules/profile/data/profile_repository.dart:48.
- **Backend:** servana_api-main/src/services/auth.service.ts:203-208 — `const { email } = payload; if (!email) throw "Missing required parameters";`; controller maps to 400 (auth.controller.ts:76-90).
- **Canonical contract:** AUTH.EMAIL_OTP.RESEND — token-derived identity fallback.
- **Test gap:** No contract test issues a bodyless POST against the route.

**Recommendation.** Same backend-side remedy: `verifyAuthOptional` on `POST /auth/resend-email-otp`, deriving `email` from the token subject when the body omits it. Additive, no mobile release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-033 · `AssignmentPollResult.isAssigned` can never be true for a real assignment, so both confirmation screens always run the full 60 s poll and then report a timeout

**P1** · rule §20, §3 · fix in **client-mobile** · protected release: **yes**

The only window in which `isAssigned` could evaluate true is a booking that has a `workerUid` while still reporting status CONFIRMED — which the backend never produces, because worker_uid and status='WORKER_ASSIGNED' are written in the same UPDATE. The practical result is that the successful-assignment branch of both confirmation screens is dead: every booking polls 12 times, `stop()` is never called early, `onTimeout` fires, and the screen falls into its timed-out presentation even though a technician was assigned within seconds. The screen simultaneously holds a populated `workerName` (fetched at assignment_polling_service.ts:106-108), so it has the evidence and ignores it.

- **Client:** servana_client-main/lib/common/services/assignment_polling_service.dart:19-22 (`isAssigned` requires `status == BookingStatus.assigned || status == BookingStatus.confirmed`) and :99-100 (status is read from `booking['status']`, the booking-level field); lib/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart:37, :63-66, :297-303 and lib/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart:36, :63-66, :306-312
- **Backend:** servana_api-main/src/services/technicianService.ts:624 writes `bookings.status='WORKER_ASSIGNED'` at the same moment `worker_uid` is set, so by the first poll the status is already WORKER_ASSIGNED, which the client maps to `enRoute` (booking_status.dart:86-87) — not to `assigned` or `confirmed`.
- **Canonical contract:** BOOKING.ASSIGN.OBSERVE — assignment is proven by a non-empty providerUid on a non-terminal booking, not by a status literal.
- **Test gap:** No test feeds a WORKER_ASSIGNED payload into AssignmentPollingService and asserts isAssigned.

**Recommendation.** Ship the `canonicalStatus` backend field described in the WORKER_ASSIGNED finding, then change `isAssigned` to key off the presence of `workerUid` plus a non-terminal status rather than an exact status match. As an interim, non-release mitigation the backend can also populate `assignmentStatus` on the customer payload (formatBooking already does, bookingService.ts:509) — but the client does not currently read it.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-034 · `assignNearestWorker` returning `{assigned:false}` is silently discarded — the booking is stranded at CONFIRMED with no worker, no notification and no escalation

**P1** · rule §3, §20, §45 · fix in **backend** · protected release: **no**

When no provider is online or every candidate is busy within the ±2 h window, the backend applies a transport fee and returns a negative result that nobody reads. No `booking_tracking` row is written, no customer notification is created, no admin alert is raised. The customer's confirmation screen polls for 60 s, times out, and the booking then behaves like any other confirmed booking. The 'awaiting_assignment' canonical state (§13) exists conceptually but is never persisted or surfaced, so a booking that will never be served is indistinguishable from one that is about to be.

- **Client:** servana_client-main/lib/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart:63-66 (the only consequence is a local `_pollTimedOut` flag after 60 s); lib/common/services/assignment_polling_service.dart:37-38 (12 attempts × 5 s, then give up)
- **Backend:** servana_api-main/src/services/technicianService.ts:591-599 (`return { assigned:false, reason:"NO_WORKER_ONLINE" }` / `"NO_WORKER_AVAILABLE"`); src/services/bookingService.ts:190-195 — the return value of `assignNearestWorker` is not captured or inspected
- **Other:** servana_adminportal — no admin queue is fed by this path; the booking simply sits in CONFIRMED with `worker_uid IS NULL`
- **Canonical contract:** BOOKING.ASSIGN — a failed auto-assignment must produce a persisted `awaiting_assignment` state plus a customer notification and an operations exception.
- **Test gap:** No test covers the no-worker-online branch end to end.

**Recommendation.** Capture the result in `bookingService.confirmOtp`. On `assigned:false`, write a `booking_tracking` row (status `AWAITING_ASSIGNMENT`, note carrying the reason code), call `createCustomerNotification(userId, {type:'booking_awaiting_assignment', ...})`, and raise an admin-visible exception row so operations can assign manually via the existing `PUT /api/admin/bookings/:bookingId/assign` (technician.routes.ts:24).

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-035 · `confirmOtp` is non-atomic: the booking is set CONFIRMED before worker assignment, so an assignment failure is reported to the customer as an invalid OTP and cannot be retried

**P1** · rule §19, §20, §21 · fix in **backend** · protected release: **no**

There is no transaction around confirmOtp. Once the UPDATE at bookingService.ts:142-147 commits, the booking is CONFIRMED. If the downstream address/coverage/assignment work then throws, the customer receives HTTP 400 and the OTP screen shows 'Invalid code. Please try again.' Re-entering the correct code now fails permanently, because the UPDATE is guarded by `AND status='PENDING_OTP'` (:146) which no longer matches — the customer is told their code is wrong forever on a booking that is actually confirmed. Note also that when `getLatLonByLocationId` throws, it throws a string primitive, so `e.message` at bookingController.ts:77 is `undefined` and the response body carries no message at all.

- **Client:** servana_client-main/lib/common/presentation/screens/booking_otp_screen.dart:96-122 (any non-2xx → `_errorText = _messageFrom(e)` → default string 'Invalid code. Please try again.' at :172); :100-104 also treats `success:false` as a bad code
- **Backend:** servana_api-main/src/services/bookingService.ts:140-150 (UPDATE ... SET status='CONFIRMED' commits first), then :185 `throw new Error("Address missing locationId.")` and :187 `getLatLonByLocationId` (which throws the bare string 'Location not found', address.service.ts:240) and :190 `await assignNearestWorker(...)` — all inside the same try, all rethrown at :199. Controller maps everything to 400 (bookingController.ts:76-78).
- **Canonical contract:** BOOKING.OTP.CONFIRM — commit the state transition atomically; assignment is a downstream, retryable side effect.
- **Test gap:** No test forces assignNearestWorker to throw and asserts the booking status and the OTP-retry outcome.

**Recommendation.** Wrap the status transition and the tracking insert in a transaction, and move `assignNearestWorker` outside the request-failure path (fire-and-forget with its own error handling and an admin escalation on failure), so assignment problems never mask OTP success. Separately, make `confirmOtp` idempotent: if the booking is already CONFIRMED and the supplied OTP matches, return success rather than 'not in PENDING_OTP'. Normalise thrown strings to Error objects so §21 messages survive.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-036 · `POST /api/bookings` has no idempotency — the client sends `X-Idempotency-Key` and the backend never reads it — **CONFIRMED**

**P1** · rule §17, §10 · fix in **backend** · protected release: **no**

The 30-second client timeout (servana_api_client.dart:14, :890-897) converts a slow-but-successful create into a `ServanaApiException(408)`, which resets `isSubmitting` (aircon_booking_store.dart:465) and re-enables the Confirm button. A retry then executes a second full `createBooking`: a second `bookings` row, a second `payments` row (bookingService.ts:98-104), a second booking-created customer notification (bookingController.ts:38 — called without a `notificationKey`, so the ON CONFLICT dedupe at notification.service.ts:766-776 is bypassed) and a second confirmation email carrying a different OTP. Review, support, safety-incident and chat all implement idempotency; booking creation — the highest-value mutation in the product — does not.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:374-378 (header attached); lib/modules/aircon_booking/data/aircon_booking_store.dart:391,431-435 and lib/modules/bw_booking/data/bw_booking_store.dart:373 (key generated and passed)
- **Backend:** servana_api-main/src/routes/booking.routes.ts:20 — `router.post("/bookings", verifyAuth, bookingController.createBooking)` (verifyAuth only, no idempotency middleware); confirmed by bookingController.ts:9-54 + bookingService.ts:15-132 reading no header, and a case-insensitive repo-wide grep for `X-Idempotency-Key` returning zero matches across servana_api-main. Mitigation evidence: bookingService.ts:80 (row created as PENDING_OTP), :98-104 (payments row status PENDING), :190 (assignNearestWorker runs only inside confirmOtp).
- **Other:** servana_adminportal — the admin Create Booking path is protected; the customer path is not, so the two produce different guarantees for the same canonical operation.
- **Canonical contract:** BOOKING.CREATE — `(idempotencyKey, actorUid)` unique; replay returns the original bookingId.
- **Test gap:** No test issues two identical POST /api/bookings with the same X-Idempotency-Key and asserts one row.

**Recommendation.** Read `X-Idempotency-Key` in `bookingController.createBooking` and reuse the proven admin pattern: a `booking_create_idempotency (idempotency_key, actor_uid, booking_id)` table with a UNIQUE constraint, checked pre-flight and inside the transaction (adminCreateBookingService.ts:501-506, :636-648, :764-770). Return the original booking on replay. This is purely additive — the client already sends the header.

## SC-037 · `WORKER_ASSIGNED` maps to `enRoute`, so the customer is told 'Your service professional is on the way' the instant a provider is assigned — potentially days before the appointment

**P1** · rule §13, §9 · fix in **client-mobile** · protected release: **yes**

Assignment and departure are collapsed into one client-side state. Because assignment happens synchronously at OTP-confirmation time, a booking scheduled for next week displays 'Provider En Route' from the moment it is confirmed, and is filed under 'active' instead of 'upcoming'. The genuinely correct client state — `BookingStatus.assigned`, 'Service Professional Assigned' (booking_status.dart:77-79, :138-139) — is unreachable, because the backend writes `ASSIGNED`/`ACCEPTED` only to `booking_workers.status`, never to `bookings.status`. Meanwhile the app's `enRoute`/`arrived` UI is permanently dead because no code path ever writes those values.

- **Client:** servana_client-main/lib/common/domain/booking/booking_status.dart:86-87 (`case 'WORKER_ASSIGNED': return BookingStatus.enRoute`); :142-143 label 'Provider En Route'; :190-191 'Your service professional is on the way.'; :288-289, :382-383; :378-386 groups enRoute under `active` rather than `upcoming`
- **Backend:** servana_api-main/src/services/technicianService.ts:624 and :931 — `status='WORKER_ASSIGNED'` is written the moment a provider is picked, immediately inside `confirmOtp` (bookingService.ts:190). A repo-wide grep shows `EN_ROUTE` and `ARRIVED` are never written anywhere: the only occurrences are read-side guard lists at src/services/bookingService.ts:520 and src/services/serviceService.ts:120.
- **Canonical contract:** BOOKING.STATUS — `WORKER_ASSIGNED` ≡ canonical `assigned`. `en_route` requires an explicit provider departure event, which does not currently exist.
- **Test gap:** booking_status_test has no case asserting that WORKER_ASSIGNED is not presented as departure.

**Recommendation.** Backend-additive first: expose the already-existing canonical mapper in the customer payload. `formatBooking` (bookingService.ts:483-511) should add a non-breaking `canonicalStatus` field computed by the same logic as `mapOperationsStatus` (adminBookingService.ts:181-200), which already yields `assigned` for `WORKER_ASSIGNED`. The client change to prefer `canonicalStatus`, and to stop mapping `WORKER_ASSIGNED → enRoute`, then rides the next scheduled ServanaClient release rather than forcing one. Do not change the `status` string itself — ServanaWorker depends on it.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-038 · A booking chat conversation is created the moment the customer opens the screen, with no provider-assignment or confirmation gate

**P1** · rule §24 · fix in **backend** · protected release: **no**

§24 requires that a conversation exist only once a booking exists AND a provider is assigned AND that provider has confirmed (or an authorised admin confirmed on their behalf). Here a conversation and participant set materialise for a booking still in PENDING_OTP with no worker, producing empty orphan conversations that then appear in the inbox listing (`listConversationsForUser`) as real threads the customer can type into with no recipient. Authorization is correct; the state gate is simply absent.

- **Client:** servana_client-main/lib/modules/messaging/domain/repositories/messaging_repository.dart:28 → lib/common/data/backend/servana_api_client.dart:524-530 (`GET /api/bookings/:id/conversation`) — called on screen open with no state precondition
- **Backend:** servana_api-main/src/chat/chat.controller.ts:37-54 — authorization is checked (`resolveAccessForBooking`, :44) but there is no booking-state check before `chatService.getOrCreateConversation(bookingId)` at :48. src/chat/chat.service.ts:59-77 creates the conversation and participant rows unconditionally.
- **Canonical contract:** CONVERSATION.OPEN — gated on booking + assigned + confirmed; one booking → one conversation.
- **Test gap:** No test asserts that an unassigned booking cannot open a conversation.

**Recommendation.** Add a state precondition in `getBookingConversation`: resolve the booking's `worker_uid` and the `booking_workers.status`, and return 409 `CONVERSATION_NOT_AVAILABLE` unless an assignment exists in ACCEPTED (or ASSIGNED, if product accepts pre-confirmation chat). Keep `getOrCreateConversation` itself unchanged so the provider-side and admin-side callers are unaffected.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-039 · Address coordinates are supplied by the client and written verbatim — they then drive service-area eligibility and transport-fee pricing

**P1** · rule §38, §39, §42 · fix in **backend** · protected release: **no**

§39 states plainly that browser/client-entered coordinates must not be treated as authoritative and that the backend owns resolution and the location ID. Here the inverse holds: the client is the geocoder of record. Because the derived coordinates decide both whether the booking is accepted at all (coverage) and how much the customer is charged (transport fee added to final_price), a wrong or manipulated coordinate is a pricing-integrity issue, not only a data-quality one. The `loc_{lat}_{lon}` format is correct per §42 but is being generated on the wrong side.

- **Client:** servana_client-main/lib/common/data/repositories/address_repository.dart:65-83 — the client computes `locationId: 'loc_${lat.toStringAsFixed(6)}_${lon.toStringAsFixed(6)}'` and posts `lat`/`lon` directly; duplicated at lib/common/presentation/screens/drawer_placeholder_screens.dart:327 and :390-391
- **Backend:** servana_api-main/src/services/address.service.ts:9-53 — `addUserAddress` takes `locationId`, `lat`, `lon` from the request body and writes them to MongoDB unchanged (:40-45). No geocoding, no normalisation, no confidence check. Those coordinates are then read back by `bookingService.createBooking` at :58 and fed to `checkCoverageGeo` (:60) and to `assignNearestWorker` (:190), which computes the transport fee from the haversine distance (technicianService.ts:607, :618, :629 — `final_price = quoted_price + transpo_fee`).
- **Other:** servana_adminportal resolves addresses server-side into `bookings.service_address` JSONB (adminCreateBookingService.ts:167), i.e. the admin path already follows the canonical flow and the mobile path does not.
- **Canonical contract:** ADDRESS.RESOLVE — human-readable in, backend-derived coordinates and locationId out; client coordinates are hints, never authority.
- **Test gap:** No test asserts that a client-supplied coordinate cannot override backend resolution.

**Recommendation.** Add a backend `ADDRESS.RESOLVE` step: accept the human-readable components the client already sends (`addressOne`, `addressTwo`, `postTown`, `country`) plus the client lat/lon as a *hint only*, geocode server-side, and derive `locationId` from the resolved coordinates. Continue to accept and ignore the client-supplied `locationId` so no mobile release is required. Ambiguous or low-confidence results should fail explicitly rather than silently accept the hint.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-040 · Address save shows 'Address saved!' while the coordinate write is fire-and-forget; a failed Mongo write makes the address silently unbookable forever

**P1** · rule §19, §20, §21 · fix in **backend** · protected release: **no**

An address is a two-store write (Postgres row + MongoDB GeoJSON document) with no transaction and no compensating action. If the Mongo leg fails, the customer is told the address was saved, it appears normally in their saved-addresses list, and it is silently unusable: every booking attempt against it dies with an unexplained generic error, and nothing in the app or the API tells the customer or support which address is broken or how to repair it.

- **Client:** servana_client-main/lib/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart:452-454 shows the 'Address saved!' snackbar as soon as `AddressCreated` is returned; lib/common/data/repositories/address_repository.dart:85-118 returns `AddressCreated` purely on the Postgres response
- **Backend:** servana_api-main/src/services/address.service.ts:40-45 — `addLocationInDB(...).catch(e => console.error(...))`: the MongoDB geo write is explicitly fire-and-forget and its failure is swallowed. The Postgres row is returned as a success regardless. At booking time `bookingService.createBooking:58` calls `getLatLonByLocationId`, which throws the bare string `"Location not found"` (address.service.ts:240) when the Mongo document is absent; that propagates to bookingController.ts:52 where `e.message` on a string primitive is `undefined`, so the client receives `{success:false}` with no message and renders 'Something went wrong (400).' (aircon_booking_store.dart:585).
- **Canonical contract:** ADDRESS.CREATE — atomic across both stores, or explicitly reported as incomplete.
- **Test gap:** No test simulates a MongoDB write failure and asserts the API response and the downstream booking behaviour.

**Recommendation.** Make the coordinate write part of the success criterion: await `addLocationInDB` and fail the whole `addUserAddress` (rolling back or marking the Postgres row incomplete) if it errors, so the client's 'Address saved!' is truthful. Separately, normalise the thrown string to `new Error('ADDRESS_LOCATION_UNRESOLVED')` so the booking failure carries an actionable §21 message the app can render.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-041 · Chat messages emit a Socket.IO event but never an FCM push, so a backgrounded customer never learns a provider replied

**P1** · rule §25, §45 · fix in **backend** · protected release: **no**

§25 defines the canonical chain as persisted message → Socket.IO real-time → FCM background. The chat module implements the first two legs and omits the third. The customer socket only exists while the app is foregrounded and connected (chat_socket_service.dart connect path), so any message sent while the customer's app is backgrounded or killed is delivered nowhere and surfaces only if the customer happens to reopen the inbox. This is the single most common real-world messaging path and it is silent.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:554-571 (sendChatMessage); lib/modules/messaging/... socket path via ChatSocketService; lib/modules/notifications/application/fcm_coordinator.dart:112-117 — the app's only inbound-message mechanism while backgrounded is FCM
- **Backend:** servana_api-main/src/chat/chat.service.ts:157-169 — `emitToConversation(conversationId, "message:new", full)` is the only fan-out. A grep for `fcm`/`FCM` across src/chat/ returns zero hits, versus the provider notification path which chains Socket.IO → FCM (notification.service.ts:289-355) and the customer notification path which does the same (notification.service.ts:803).
- **Canonical contract:** MESSAGE.SEND — persist → socket → notification row → FCM, for every non-sender participant.
- **Test gap:** No test asserts a notification row is produced by sendMessage.

**Recommendation.** In `chat.service.sendMessage`, after `emitToConversation`, resolve the other participants from `chat_participants` and call `createCustomerNotification` (type `message_received`, route `{routeKey:'CONVERSATION', resourceId: bookingId}`) for role-3 participants and `createNotification` for role-2 participants, keyed on `notificationKey = 'msg-' + message.id` so it is idempotent. Additive; no client change needed — the app already maps `message_received` and routes it (notification_navigation_coordinator.dart ConversationTarget branch).

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-042 · Customer cancellation does not notify the assigned provider — the provider can travel to a job that was cancelled hours earlier

**P1** · rule §45, §22, §3 · fix in **backend** · protected release: **no**

The cancellation itself persists correctly and is ownership-checked, but the fan-out leg of the chain is missing entirely. The provider whose `booking_workers` row was just set to CANCELED receives no push, no in-app notification and no socket event. Their only signal is a manual refresh of their schedule. For a dispatch product where the provider is already en route, this is an operational-safety gap, not a cosmetic one.

- **Client:** servana_client-main/lib/modules/bookings/presentation/widgets/booking_cancellation_sheet.dart:73-81 (submit → repo.cancelBooking → pop → onCancelled); lib/common/data/backend/servana_api_client.dart:471-486
- **Backend:** servana_api-main/src/services/bookingService.ts:530-581 — `customerCancelBooking` updates `bookings.status='CANCELLED'` (:554-557), flips `booking_workers` to `CANCELED` (:559-563) and inserts a `booking_timeline_events` row (:565-574). It makes no `createNotification` call, no `createCustomerNotification` call and emits no socket event.
- **Other:** ServanaWorker consumes provider notifications produced by `createNotification` (notification.service.ts:289-355); nothing in the cancel path reaches it. The provider's job list is driven by `getWorkerSchedule` (technicianService.ts:698-727), which the provider app must re-poll to notice.
- **Canonical contract:** BOOKING.CANCEL — persist → timeline → notify every active assignee → emit room event.
- **Test gap:** No test asserts a provider notification exists after a customer cancel.

**Recommendation.** After the two UPDATEs in `customerCancelBooking`, look up the affected `worker_uid` and call `createNotification(workerUid, {type:'booking_cancelled', severity:'warning', route:{page:'jobs', bookingId}, notificationKey:'bk<id>-cancelled'})`, plus a matching `createCustomerNotification` for the customer's own record. Emit the existing provider-gateway event to the booking room so a connected provider app updates live.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-043 · Editing a saved address is implemented as delete-then-recreate, so a failure between the two calls destroys the customer's address

**P1** · rule §19, §20 · fix in **backend** · protected release: **yes**

A network drop, a 401 from an expired token (see the token-refresh finding), or a validation rejection between the two awaits leaves the customer with no address at all — the original is already gone. The UI reports failure but cannot restore what it deleted. Because the address also carries `is_primary`, losing it can additionally strand the customer's default selection.

- **Client:** servana_client-main/lib/common/presentation/screens/drawer_placeholder_screens.dart:386-388 — `// Delete the old address, then create the updated one` followed by `await _api.deleteAddress(addressId: addrId);` and `await _api.addUserAddress(payload: {...})`, with no rollback if the second call fails
- **Backend:** servana_api-main/src/routes/user.route.ts exposes `POST /user/adduseraddress` and `DELETE /user/deleteaddress` but no customer-facing address-update route; the `updateUserAddress` branch in user.controller.ts:29-33 is reachable only by supplying `addressId` in the create payload, which the client never does.
- **Other:** PROFILE_BACKEND_GAPS.md GAP-003 already records the missing endpoint; it does not record the data-loss consequence of the workaround.
- **Canonical contract:** ADDRESS.UPDATE — a single ownership-scoped mutation, never delete+create.
- **Test gap:** No test covers the failure window between delete and re-create.

**Recommendation.** Expose a proper `PUT /api/user/addresses/:addressId` backed by the existing `updateUserAddress` service (with the missing `AND uid` predicate added — see the separate P0), then point the client at it. Until the client can be released, an interim backend mitigation is to make `addUserAddress` accept an optional `replacesAddressId` and perform both operations in one transaction, which the client could adopt without changing its call structure.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-044 · In-app email verification is permanently broken: the client posts `{otp}` but the backend requires `{email, otp}`

**P1** · rule §4, §20 · fix in **backend** · protected release: **no**

Every in-app email-verification attempt returns 400 'Missing required parameters'. The profile screen's 'Verify email' action can never succeed. Note the client does attach its bearer token on this call (servana_api_client.dart:221) — the backend simply ignores it because the route is unauthenticated.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:217-225 — `body: jsonEncode({'otp': otp})`, no email. Called from lib/modules/profile/data/profile_repository.dart:53.
- **Backend:** servana_api-main/src/services/auth.service.ts:161-166 — `const { email, otp } = payload; if (!email || !otp) throw "Missing required parameters";`. Controller returns 400 (auth.controller.ts:60-74). The route carries no auth middleware (auth.route.ts:51), so identity comes from the body alone; `requestParityMiddleware` (app.ts:67) aliases field *names*, it does not supply missing values.
- **Canonical contract:** AUTH.EMAIL_OTP.VERIFY — accept identity from the token when present, from the body otherwise.
- **Test gap:** No contract test posts the ServanaClient body shape against the route.

**Recommendation.** Fix backend-side to avoid a protected release: add `verifyAuthOptional` to `POST /auth/verify-email-otp` and, when `req.body.email` is absent but `req.user?.uid` is present, resolve the email from `user_credentials` before calling the service. This is strictly additive — existing callers that do send `email` are unaffected, and ServanaClient starts working with no app change.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-045 · Logout is still purely local — the client never calls POST /api/auth/logout, and the FCM clear that would work fires after the session is deleted

**P1** · rule §11, §58 · fix in **?** · protected release: **yes**

First-pass SC-038 and SC-086, both re-verified unchanged — no lib/ code shipped between the passes. The backend endpoint the client's TODO is waiting for has existed the whole time. A token captured before sign-out stays valid until natural expiry, and the device's FCM token is never cleared server-side because the teardown call is made after the bearer is gone.


**Recommendation.** Replace the no-op with a real `POST /api/auth/logout` call and move both it and `deactivateOnLogout()` above `SessionService.deleteSession()` (authentication_bloc.dart:308), wrapped in try/catch so a network failure still clears local state. Remove the stale TODO and the 401-normalising comment. Client-side; folds into the next scheduled release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-046 · Logout never calls `POST /api/auth/logout`, so the Firebase token is never revoked server-side — the stale credential stays valid after sign-out

**P1** · rule §11, §20 · fix in **client-mobile** · protected release: **yes**

Logout is purely local. The Hive session is deleted and every in-memory store is reset, but the Firebase ID token itself is never revoked, so a copy captured before sign-out (device backup, proxy log, shared device) keeps full account access until natural expiry. The one call that would fix this also clears the server-side FCM token, which would incidentally close the ordering defect reported separately. `MOBILE_BACKEND_COMPATIBILITY_REPORT.md` GAP-001 records this as 'backend must implement' — that half is stale; only the client wiring is missing.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:163-167 — `Future<void> logout() async { /* No backend logout endpoint currently... TODO: when BE adds POST /api/auth/logout, call it here. */ }` — an empty method. Called via lib/modules/authentication/domain/authentication_repo.dart:22-24 from lib/modules/authentication/presentation/bloc/authentication_bloc.dart:304.
- **Backend:** servana_api-main/src/routes/auth.route.ts:62 registers `POST /auth/logout` with `verifyAuth`; src/controllers/auth.controller.ts:327-341 `logoutController` runs `revokeTokenInFirebase(uid)` and `clearFcmToken(uid)`. The endpoint the client's TODO is waiting for already exists.
- **Canonical contract:** AUTH.LOGOUT — revoke server-side, then clear locally; local clear alone is not logout.
- **Test gap:** No test asserts POST /api/auth/logout is invoked during the logout event.

**Recommendation.** Replace the no-op with a real call to `POST /api/auth/logout` issued BEFORE `SessionService.deleteSession()` (authentication_bloc.dart:308) so the bearer token is still attached, wrapped in try/catch so a network failure still clears local state. Delete the stale TODO and correct GAP-001 in MOBILE_BACKEND_COMPATIBILITY_REPORT.md.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-047 · ServanaClient @4868aca cannot be built from a clean checkout — main.dart imports a file that is no longer tracked

**P1** · rule §60, §20 · fix in **?** · protected release: **unknown**

The credential-scrub commits untracked the Firebase CLIENT configuration and left only `.example` templates. Firebase client config is not a secret, so this bought no security — but `lib/main.dart` still imports the deleted file and the Android Gradle Google Services plugin still requires `google-services.json`. A fresh clone, and therefore CI and any release build, fails at compile time.


**Recommendation.** Re-track all three files (`git add -f`), since Firebase client config is public by design — it ships inside every APK/IPA. If a policy of templating them is kept anyway, then CI must materialise them from a secret before `flutter build`, and that step must exist and be proven green before the next release is cut (§60). Right now neither is true.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-048 · The booking OTP step still has no recovery: Resend calls a route that does not exist, and confirmOtp is still non-atomic so an assignment failure is reported as a bad code

**P1** · rule §19, §20, §21 · fix in **?** · protected release: **no**

First-pass SC-024 and SC-028, both re-verified unchanged. Together they make PENDING_OTP a one-way street: if the emailed code goes astray the only escape is broken, and if anything downstream of the status transition throws, the customer is told their correct code is wrong — permanently, because the UPDATE is guarded on a status that no longer matches.


**Recommendation.** Backend-only and unchanged from the first pass: add `POST /api/:id/resend-otp` with verifyAuth + assertBookingAccess, rate-limited and gated on PENDING_OTP (the client's path string already matches, so this closes with no release); wrap the status transition and tracking insert in a transaction and move assignNearestWorker out of the request-failure path; make confirmOtp idempotent so a repeated correct code on an already-CONFIRMED booking returns success; and normalise thrown strings to Error objects so §21 messages survive.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-049 · The bookings list returns guest bookings matched by phone number, but the detail route refuses them — tapping such a booking always 403s

**P1** · rule §7, §8, §9 · fix in **backend** · protected release: **no**

The list and detail endpoints disagree about who owns a guest booking. A customer whose phone number matches an admin-created guest booking sees that booking in My Bookings, then receives 403 BOOKING_ACCESS_DENIED the instant they tap it — and equally cannot cancel it, open its chat, pay it or track it. Separately, the linkage itself is built on raw `phone_number` string equality with no normalisation, which §7 forbids as an identity source and §59 makes fragile given mixed +63/09 formats.

- **Client:** servana_client-main/lib/modules/bookings/data/booking_repository.dart getBookings → lib/common/data/backend/servana_api_client.dart:328-334 (`GET /api/users/:userId/bookings`); tapping a row routes to `/bookings/:bookingId` → lib/common/data/backend/servana_api_client.dart:387-391 (`GET /api/:bookingId`)
- **Backend:** servana_api-main/src/services/bookingService.ts:352-361 — the list query returns rows where `b.user_id = $1` **OR** `b.guest_customer_id` matches a `guest_customers` row whose `phone_number` equals the caller's `user_credentials.phone_number`. But src/services/bookingAccessService.ts:74-91 (`resolveBookingAccess`) checks only `bookings.user_id === actorUid`, an active `booking_workers` row, or admin role — guest linkage is not considered. Its own doc comment at :53-57 states guests 'cannot reach these routes at all'.
- **Canonical contract:** BOOKING.READ — one ownership predicate shared by list and detail; guest linkage is explicit and audited, never inferred from an unnormalised phone string.
- **Test gap:** No test asserts list/detail agreement for a phone-matched guest booking.

**Recommendation.** Decide the linkage once, in one place. Either (a) remove the phone-match OR-branch from `getBookingsByUserId` so the list matches what the detail route will authorise, or (b) — preferable per §8 — introduce an explicit, audited guest→client link record and teach `resolveBookingAccess` to honour it, with normalised PH phone comparison. Do not leave the two queries disagreeing.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-050 · The entire customer notification system has exactly one producer — nothing notifies the customer of assignment, payment, completion or cancellation

**P1** · rule §45, §3 · fix in **backend** · protected release: **no**

ServanaClient ships a complete notification stack — in-app inbox, unread badge, FCM foreground banner, cold-start deep-link routing, 22 typed routes — fed by a single backend event. A customer who books and closes the app is never told that a technician was assigned, that their payment cleared, that the job started or completed, or that a provider messaged them. Every one of those transitions already has an email side effect, so the notification/socket leg of the chain is simply absent, not merely unreliable.

- **Client:** servana_client-main/lib/modules/notifications/domain/notification_type.dart:26-74 (22 notification types the app can render); lib/common/data/backend/servana_api_client.dart:609-639 (full list/unread/mark-read/delete surface); lib/modules/notifications/application/fcm_coordinator.dart:112-153 (foreground handling); lib/main.dart:153-183 (cold-start and background tap handling)
- **Backend:** servana_api-main — a repo-wide grep for `createCustomerNotification` returns exactly two hits: the definition at src/services/notification.service.ts:744 and one call site at src/controllers/bookingController.ts:38 (`type:'booking_created'`). By contrast the provider-side `createNotification` is called from paymentService.ts:97, :133 and elsewhere.
- **Other:** servana_api-main/src/services/technicianService.ts:656-686 notifies the customer of assignment by EMAIL only; src/services/paymentService.ts:493-512 confirms payment by EMAIL only; src/services/bookingService.ts:530-581 (customer cancel) sends nothing at all.
- **Canonical contract:** NOTIFY.CUSTOMER — every persisted booking-state transition emits one idempotent customer notification with a `{routeKey, resourceId}` route.
- **Test gap:** No test asserts a customer notification row exists after assignment/payment/completion.

**Recommendation.** Add `createCustomerNotification` calls alongside the existing email sends, reusing the notification's idempotency key so retries collapse: assignment (technicianService.ts:656, type `booking_assigned`, route `{routeKey:'BOOKING_DETAILS', resourceId}`), payment paid (paymentService.ts:493), job started/completed (technicianService.ts:1139, :1204), customer cancellation (bookingService.ts:554). Pass an explicit `notificationKey` (e.g. `bk<id>-assigned`) so the ON CONFLICT dedupe at notification.service.ts:766-776 engages. Purely additive; the client already renders all of these types.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-051 · The Firebase ID token is stored as the Servana session token and never refreshed — sessions die roughly hourly with no recovery

**P1** · rule §20, §3 · fix in **client-mobile** · protected release: **yes**

Nothing in the client decodes `exp`, watches `idTokenChanges`, or calls `getIdToken(true)`. Expiry is discovered only reactively: the first API call after the hour mark 401s, `onUnauthorized` fires (main_injector.dart wiring), the session is deleted and the router drops the user on /welcome. `AuthStatus.expired` is produced but the router only tests `isAuthenticated` (main_router.dart:145), so the user gets no explanation. Worse, this can land mid-checkout: a booking draft survives, but the create call fails and the user is bounced to sign-in.

- **Client:** servana_client-main/lib/modules/authentication/presentation/bloc/authentication_bloc.dart:133 and :180 — `getIdToken()` is called exactly twice in the whole app, both at initial sign-in. A repo-wide grep for `getIdToken`/`idTokenChanges`/`refreshToken` returns no other hits. lib/common/domain/helpers/session_service.dart stores the token verbatim; lib/common/data/backend/servana_api_client.dart:37-47 replays it forever; :59 turns the eventual 401 into `onUnauthorized`.
- **Backend:** servana_api-main/src/services/firebaseFunctions.service.ts:175-187 — `customerFirebaseLogin` returns `token: idToken`, i.e. it echoes the caller's own Firebase ID token rather than minting a session credential. src/middleware/verifyAuth.ts:36 verifies it with `verifyIdToken`, which rejects it once `exp` passes (Firebase ID tokens live one hour).
- **Canonical contract:** AUTH.SESSION — the bearer credential must be refreshed proactively; expiry must be a distinguishable client state.
- **Test gap:** No test simulates a 401 mid-flow and asserts the recovery UX.

**Recommendation.** Client fix — subscribe to `FirebaseAuth.instance.idTokenChanges()` and rewrite the stored `UserSession.token` on every emission, and/or call `getIdToken(true)` before a request when the cached token is within ~5 minutes of expiry. Also give `AuthStatus.expired` a distinct router branch so the user sees 'Your session expired, please sign in again' rather than a silent bounce. There is no backend-only remedy: the backend cannot lengthen a Firebase ID token's life, and minting a separate long-lived Servana token would be a contract change affecting ServanaWorker too.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-052 · The first-pass remediation record is wrong — five findings are annotated 'FIXED in <commit>' but are demonstrably still open, three of them client-side fixes a backend commit could not have made

**P1** · rule §60, §62 · fix in **?** · protected release: **no**

docs/audit/STITCH_CLIENT.md carries FIXED annotations that do not correspond to code. Two of the P0s (SC-001, SC-002) really were fixed and are correctly marked. But SC-035, SC-040, SC-042, SC-043 and SC-091 are all marked FIXED and none of them are. SC-091 is a Flutter widget attributed to a backend commit, and no lib/ file changed at all between the two passes. Anyone triaging from this document will believe the notification and cancellation chains are closed.


**Recommendation.** Regenerate the FIXED annotations from actual code evidence rather than commit adjacency (docs/audit/_generate.py + _findings.json are the source). A fix marker must cite the line that changed. Until then treat every FIXED marker in these six documents as unverified — SC-001 and SC-002 are the only two I confirmed by reading the code.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-053 · The PayMongo webhook confirms payment in the database but notifies neither the customer nor the provider, unlike the manual `approve` path

**P1** · rule §45, §9 · fix in **backend** · protected release: **no**

The same business event — 'this booking is paid' — produces a provider notification when an operator clicks approve, and produces nothing when the real payment processor confirms it. A customer who completes payment and immediately backgrounds the app gets no confirmation until they reopen it; the assigned provider is never told at all on the PayMongo path. The 30-minute in-screen poll (up to 360 requests per checkout) exists purely to paper over the missing event.

- **Client:** servana_client-main/lib/common/presentation/screens/payment_webview_screen.dart:176-209 — the app compensates by polling `GET /api/:id` every 5 s for up to 30 minutes, and gives up with a manual 'Check Payment Status' button (:388-389). Outside that screen there is no mechanism at all.
- **Backend:** servana_api-main/src/services/paymentService.ts:421-513 — the `checkout_session.payment.paid` branch updates `payments`, updates `bookings.status='PAID'`, writes a `booking_tracking` row and sends one email (:501-508). It calls neither `createCustomerNotification` nor `createNotification`. Contrast paymentService.ts:95-106 and :131-142, where the manual `approve`/`markCashPaid` paths DO notify the provider.
- **Canonical contract:** PAYMENT.CONFIRMED — identical notification fan-out regardless of whether settlement came from the processor or an operator.
- **Test gap:** No test asserts notification rows after a paid webhook.

**Recommendation.** In the webhook's paid branch, after the booking UPDATE, call `createCustomerNotification(customerUid, {type:'payment_paid', notificationKey:'bk<id>-paid', route:{routeKey:'BOOKING_DETAILS', resourceId}})` and `createNotification(workerUid, ...)` using the same idempotency key, so webhook retries collapse. Additive and it lets a future client release drop the aggressive poll.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-054 · The typed booking-error layer is dead code — BookingErrorMapper and BookingSubmissionResult have zero production call sites, so the now-reachable 401 on POST /api/bookings has no categorised recovery

**P1** · rule §20, §21 · fix in **?** · protected release: **yes**

The client ships a complete error taxonomy for booking creation — including an `authenticationRequired` category — and never uses it. The booking stores instead surface the backend's raw `message`, or the raw Dart exception text for anything that is not a ServanaApiException. 52667b3 made 401 a live outcome of booking creation for the first time, and it lands on this unhandled path: the customer sees the backend string while the global 401 hook simultaneously expires their session and the router bounces them to /welcome, with no explanation and no resume.


**Recommendation.** Route the booking stores' catch through `BookingErrorMapper.fromException` and hold the result as a `BookingSubmissionResult`, so `authenticationRequired` gets a distinct 'Please sign in again — your booking details are saved' presentation and `e.toString()` never reaches the UI. Give `AuthStatus.expired` its own router branch (main_router.dart:144) instead of collapsing it into the unauthenticated redirect, and report the mapped category in BookingFailedEvent. Client-side; folds into the next scheduled release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-055 · Two parallel timeline tables: the customer's own cancellation is written to `booking_timeline_events` but the customer app reads `booking_tracking`, so it is invisible to them

**P1** · rule §9, §16 · fix in **backend** · protected release: **no**

One booking has two histories. The customer-visible tracking feed records OTP confirmation, payment, assignment and job start/complete. The admin-visible timeline records cancellations, admin assignment and admin reassignment. Neither is complete. Most visibly: a customer who cancels their own booking, then opens the booking's timeline in the app, sees no cancellation event — the last entry is whatever preceded it. Any admin-side action on the booking is likewise invisible to the customer.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:497-500 (`getBookingTimeline` delegates to `getBookingTracking`) and :415-419 (`GET /api/:id/tracking`); lib/modules/bookings/data/booking_repository.dart getTimeline reads `result['tracking']`
- **Backend:** servana_api-main/src/services/bookingService.ts:370-386 (`getTracking` selects from `booking_tracking` only). Writers of `booking_tracking`: bookingService.ts:158, paymentService.ts:456, :481, technicianService.ts:649, :936, :1074. Writers of `booking_timeline_events`: bookingService.ts:565-574 (customer cancel), plus adminBookingService.ts, adminCreateBookingService.ts, adminDashboardService.ts.
- **Other:** servana_adminportal consumes `booking_timeline_events` via `GET /api/admin/bookings/:id/timeline`; the two audiences therefore see disjoint histories of the same booking.
- **Canonical contract:** BOOKING.TIMELINE — one canonical event store; customer and admin read filtered projections of it, never separate tables.
- **Test gap:** No test asserts that a customer cancellation appears in GET /api/:id/tracking.

**Recommendation.** Pick `booking_timeline_events` as canonical (it carries actor_uid, actor_type, reason and metadata, which `booking_tracking` lacks) and have `getTracking` read from it via a compatibility projection that emits the existing `{status, note, created_at}` shape so the mobile contract is unchanged. Dual-write from the six `booking_tracking` writers during migration. This is entirely backend-side and preserves the wire shape.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-114 · confirmOtp is the one route that got assertBookingAccess without sendBookingAccessError — a 403 collapses to 400 and the OTP screen renders 'You do not have access to this booking' as an OTP error

**P2** · rule §21, §11 · fix in **?** · protected release: **no**

52667b3 added the authorization call to five handlers and the error mapper to four of them. confirmOtp was missed, so an access denial leaves the handler through the generic catch as HTTP 400 with the access message in the body. The client cannot distinguish 'wrong code' from 'not your booking', and shows the authorization text on the code-entry field with no recovery path.


**Recommendation.** Add `if (sendBookingAccessError(res, e)) return;` as the first line of the confirmOtp catch, matching the other six handlers. One line, backend-only.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-115 · Logout deletes the session before calling `DELETE /api/user/fcm-token`, so the request 401s and the device token is never cleared server-side

**P2** · rule §58, §45 · fix in **client-mobile** · protected release: **yes**

Push delivery does stop in practice, because `FirebaseMessaging.instance.deleteToken()` (fcm_coordinator.dart:91) invalidates the token on Firebase's side. But the database row keeps a dead token indefinitely, the backend keeps attempting sends to it, and — until a new sign-in overwrites the column — the last signed-out user's device token remains associated with that account record. Calling the real `POST /api/auth/logout` (which does `clearFcmToken(uid)` server-side, auth.controller.ts:335) would resolve this as a side effect of the separate logout finding.

- **Client:** servana_client-main/lib/modules/authentication/presentation/bloc/authentication_bloc.dart:308 (`await SessionService.deleteSession()`) runs before :359 (`await dpLocator<FcmCoordinator>().deactivateOnLogout()`), which calls lib/modules/notifications/application/fcm_coordinator.dart:86 → lib/common/data/backend/servana_api_client.dart:514-518. With the session already gone, `_headers()` (:37-47) omits the bearer entirely. The comment at authentication_bloc.dart:309-312 shows the resulting 401 was anticipated and suppressed rather than fixed.
- **Backend:** servana_api-main/src/routes/user.route.ts:31 — `DELETE /user/fcm-token` is behind `verifyAuth`, so a request with no Authorization header is rejected at src/middleware/verifyAuth.ts:13-33 before reaching the handler. `user_credentials.fcm_token` therefore retains the signed-out device's token (notification.service.ts:663-668 is never invoked).
- **Canonical contract:** AUTH.LOGOUT — all authenticated teardown calls execute while the credential is still attached.
- **Test gap:** No test asserts DELETE /api/user/fcm-token is sent with a bearer header during logout.

**Recommendation.** Move `deactivateOnLogout()` (and the `POST /api/auth/logout` call) to before `SessionService.deleteSession()` at authentication_bloc.dart:308, keeping the existing try/catch so a failure still clears local state. Remove the comment at :309-312 that normalises the 401.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-116 · Notification deep link for `SettingsTarget` pushes `/settings`, which is not a registered route

**P2** · rule §49, §20 · fix in **client-mobile** · protected release: **yes**

GoRouter has no matching route for `/settings`, so the push resolves to the router's error page. The same string also falls outside the router's case-sensitive `isProtected` guard (main_router.dart:126, which tests `startsWith('/Settings')`), so it would additionally bypass the auth redirect. It is latent only because no backend producer emits a settings-targeted notification today — which will change the moment the notification pipeline gains producers (see the one-producer finding).

- **Client:** servana_client-main/lib/modules/notifications/application/notification_navigation_coordinator.dart — `case SettingsTarget(): context.push('/settings');`. lib/common/presentation/routes/main_router.dart declares `/Settings` (capital S) and six `/settings/<child>` paths (profile-edit, appearance, about, security, privacy, permissions) but no bare `/settings` GoRoute — a grep for `'/settings` in main_router.dart returns no path declarations. Reached from lib/main.dart:153-183 (cold-start and background notification taps) and lib/common/presentation/screens/notifications_screen.dart:125 (in-app tap).
- **Backend:** n/a — the backend does not currently emit any notification with a settings route, so this is latent rather than live.
- **Canonical contract:** NOTIFY.ROUTE — every routeKey the backend can emit must resolve to a declared, guarded route.
- **Test gap:** No test enumerates every NotificationTarget variant and asserts the pushed location resolves.

**Recommendation.** Change the branch to `context.pushNamed(SettingsScreen.routeName)` so it resolves through the named route that the guard actually covers, and add a `/settings` → `/Settings` redirect alias per §49 so old links do not open blank pages. Fix this before adding notification producers.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-117 · Payment settlement is not idempotent — approve and mark-cash-paid re-fire the provider's 'Payment Received' notification and reset paid_at on every retry

**P2** · rule §17, §43 · fix in **?** · protected release: **no**

6d78313 correctly restricted who may settle, but the settle itself has no state guard. A provider double-tapping Mark as paid, or ServanaWorker retrying after a timeout, rewrites paid_at and sends a second earnings notification for money that arrived once. The first pass noted the notification as an impact of the P0; the replay behaviour survives the P0's closure.


**Recommendation.** Add `AND status <> 'PAID'` to both UPDATEs and treat zero rows as a successful no-op returning the existing payment row (replay-safe, not an error). Pass `notificationKey: 'bk<id>-paid'` to both createNotification calls so a duplicate never reaches the provider. Backend-only; ServanaWorker is unaffected because a replay keeps returning success.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-118 · PayMongo verification falls back from `paymentStatus` to booking status, so a null payment status makes a merely-CONFIRMED booking read as paid

**P2** · rule §20, §43 · fix in **client-mobile** · protected release: **yes**

§43 requires payment status, payment method, evidence and verification to be distinct concepts; this fallback conflates 'the booking is confirmed' with 'the money arrived'. In the normal flow a payments row always exists and carries 'PENDING' (which maps to `unknown` and correctly returns false), so this is a narrow rather than routine path — but the failure mode is the worst possible one: the app declares payment complete and stops collecting it. The reachability of a null `payment_status` on a PayMongo booking is UNVERIFIED and is the key evidence needed to grade this higher.

- **Client:** servana_client-main/lib/common/presentation/screens/payment_webview_screen.dart:218-224 — `BookingStatusMapper.fromString(booking['paymentStatus']?.toString() ?? booking['status']?.toString())` then returns true for `paid`, `confirmed`, `awaitingAssignment` or `assigned`. On a true result the screen pops `true` (:197-205), the confirmation screen sets `_paymongoCompleted = true` (aircon_confirmation_screen.dart:80-84) and stops asking for payment.
- **Backend:** servana_api-main/src/services/bookingService.ts:207-238 — `getBookingById` LEFT JOINs `payments`, so `payment_status` is NULL whenever no payments row exists for the booking; `formatBooking` (:483-511) passes the null through as `paymentStatus`. `bookings.status` for an OTP-confirmed unpaid booking is `'CONFIRMED'` (:143), which the client maps to `BookingStatus.confirmed` (booking_status.dart:80-81) — an accepted 'paid' value.
- **Canonical contract:** PAYMENT.VERIFY — only an explicit paid payment status proves settlement; booking status is never a proxy.
- **Test gap:** No test feeds a booking payload with a null paymentStatus into _verifyPayment.

**Recommendation.** Remove the `?? booking['status']` fallback: only an explicit `paymentStatus` of PAID should satisfy payment verification, and `confirmed`/`awaitingAssignment`/`assigned` should be dropped from the accepted set. Backend-side, make `getBookingById` COALESCE a missing payment status to an explicit `'UNPAID'` rather than NULL so the client can never be ambiguous — that half is additive and needs no release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-119 · Submitting a review overwrites `bookings.status` with `REVIEWED`, which can remove a still-active paid job from the provider's list

**P2** · rule §13, §9, §14 · fix in **backend** · protected release: **no**

Review existence is being stored in the booking status column, destroying whatever lifecycle state was there. Because eligibility admits `PAID` — not just `COMPLETED` — a customer can review a paid booking whose service has not yet been performed, which rewrites the status to REVIEWED and removes the job from the provider's active list while the provider is still expected to perform it. It also erases the distinction between a completed job and a paid one for reporting purposes. The rest of the review chain (ownership, one-per-booking, idempotency on clientRequestId, aggregate recalculation) is correctly implemented.

- **Client:** servana_client-main/lib/modules/review/application/review_form_controller.dart:115-148 (submit awaits the backend and only then reports success — the client half of this chain is correct); lib/modules/bookings/presentation/screens/booking_detail_screen.dart:131 treats 'COMPLETED'|'REVIEWED' as completed and :240 derives `_hasReview` from `status == 'REVIEWED'`
- **Backend:** servana_api-main/src/services/customerReviewService.ts:270-272 — eligibility accepts status in `['COMPLETED','REVIEWED','PAID']`; :341-344 then executes `UPDATE bookings SET status='REVIEWED'`. src/services/technicianService.ts:792 documents the provider-side active set as `PENDING_OTP, CONFIRMED, PAID, WORKER_ASSIGNED, ACCEPTED, IN_PROGRESS` — `REVIEWED` is not in it.
- **Other:** ServanaWorker renders the provider job list from this active set; a booking flipped to REVIEWED drops out of it.
- **Canonical contract:** BOOKING.STATUS vs REVIEW.EXISTS — separate concerns; review submission must not mutate the booking lifecycle.
- **Test gap:** No test asserts that reviewing a PAID booking leaves it visible to the assigned provider.

**Recommendation.** Stop writing REVIEWED into `bookings.status`. Derive review existence from the `customer_reviews` table (there is already a per-booking uniqueness rule at customerReviewService.ts:287-291) and expose it as an additive `hasReview` boolean on `formatBooking`, leaving the lifecycle status intact. Tighten eligibility to `COMPLETED` only. Keep accepting 'REVIEWED' in the client's status mapper for backward compatibility with historical rows.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-120 · The authenticated successor routes have zero adopters in either mobile app, so the legacy-retirement gate can never be met and customer tracking still rides an unauthenticated route

**P2** · rule §9, §11 · fix in **?** · protected release: **yes**

a85958e added `GET /worker/schedule` and `GET /booking/:bookingId/provider-location` as authenticated, subject-from-token successors, and documented retirement of the legacy family as gated on legacy traffic reaching zero. Nothing calls the successors. The customer app's live tracking still calls the legacy unauthenticated worker-location route, so legacy traffic can never reach zero without a protected release of both apps.


**Recommendation.** Either sequence the successor adoption into the next scheduled ServanaClient/ServanaWorker releases (no unscheduled release — the legacy routes keep working meanwhile, §2), or accept that `/api/workers/location/:uid` cannot be retired and instead scope it server-side: require a bearer token and return a location only when the caller holds an active booking with that worker, reusing the exact logic in providerLocationAccessController.ts:60-85. The second option needs no client change and closes the hole now.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-121 · The booking OTP screen tells the customer the code was sent by SMS; the backend emails it

**P2** · rule §20 · fix in **client-mobile** · protected release: **yes**

The customer waits for a text message that will never arrive while the code sits in their inbox. Because the Resend button is also broken (separate finding) and the booking cannot progress past PENDING_OTP without the code, this misdirection directly converts into abandoned bookings. It is a one-line copy defect sitting on the critical path of every booking.

- **Client:** servana_client-main/lib/common/presentation/screens/booking_otp_screen.dart:249-250 — 'We sent a 6-digit code to the phone number on your account. Enter it below to confirm your booking.'
- **Backend:** servana_api-main/src/services/bookingService.ts:105-120 — `const email = await getEmailById(userId); ... send(email, "verify_booking_otp", { otp_code: booking.otp_code, ... })`. There is no SMS provider in the repo and no phone-based OTP path for bookings.
- **Canonical contract:** BOOKING.OTP — the delivery channel stated in the UI must match the channel the backend uses.
- **Test gap:** n/a — copy assertion.

**Recommendation.** Change the copy to reference email (and the account's email address if available). Because it is client copy, fold it into the next scheduled release rather than cutting one; the higher-value fixes on this same screen (resend route) are backend-side and can ship immediately.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-122 · The cancellation sheet collapses every backend error into one message, discarding actionable state and authorization errors

**P2** · rule §21, §20 · fix in **client-mobile** · protected release: **yes**

The backend produces exactly the actionable, safe error messages §21 asks for, and the client throws them all away. A customer whose job is already in progress — the single most common legitimate rejection — is told the feature is unavailable and to contact support, rather than that the job has already started. The stale comment will also mislead the next reader into believing the endpoint is still missing.

- **Client:** servana_client-main/lib/modules/bookings/presentation/widgets/booking_cancellation_sheet.dart:80-91 — a bare `catch (e)` sets a fixed string 'Cancellation is not available at this time. Please contact support if you need to cancel.' The comment above it ('BACKEND_GAP-C15-001: no customer-facing cancel endpoint; admin route returns HTTP 403') is stale.
- **Backend:** servana_api-main/src/routes/booking.routes.ts:22 — `POST /bookings/:id/cancel` exists and is customer-facing. src/controllers/bookingController.ts:203-206 returns distinct, useful messages: 400 'reason is required', 400 `Cannot cancel booking with status: IN_PROGRESS` (bookingService.ts:550-552), 403 'Access denied' (:546-548), 400 'Booking not found'.
- **Canonical contract:** ERROR.SURFACE — backend safe-domain messages must reach the user; generic fallbacks only for transport failures.
- **Test gap:** No test asserts that a 400 'Cannot cancel booking with status: IN_PROGRESS' is shown to the user.

**Recommendation.** Decode `ServanaApiException.body` and surface `message` when present (the pattern already used by lib/common/presentation/screens/booking_otp_screen.dart:164-173 and aircon_booking_store.dart:576-588), falling back to the generic string only for network/parse failures. Delete the stale BACKEND_GAP-C15-001 comment.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-123 · The operation journal and the persisted booking idempotency key are written but never read — crash recovery for booking creation does not exist

**P2** · rule §17, §20 · fix in **client-mobile** · protected release: **yes**

The recovery layer is half-built. `aircon_booking_store.dart:417-429` journals the operation 'before the API call so a process kill during the network request leaves a reconcilable record' — but nothing ever reconciles it. `AppLifecycleCoordinator.onResume` (app_lifecycle_coordinator.dart:24-26) documents 'pending-payment reconciliation' as its purpose but is not wired to the journal. Compounding this, the idempotency key lives only in a MobX field, so it does not survive the very process kill the journal was designed for, and the persisted key helper that would fix that is dead code.

- **Client:** servana_client-main/lib/core/recovery/operation_journal.dart:80-94 defines `load()`; a repo-wide grep shows `OperationJournal` is referenced only at lib/common/injectors/main_injector.dart:111 (registration), aircon_booking_store.dart:420 (`record`) and :449 (`resolve`), bw_booking_store.dart:395/:428, and authentication_bloc.dart:349/:352 (clear). `load()` has zero call sites. Likewise lib/core/recovery/draft_repository.dart:88 `getOrCreateIdempotencyKey` and :97 `clearIdempotencyKey` have zero call sites; the stores instead use a volatile in-memory key (aircon_booking_store.dart:29, :391).
- **Backend:** n/a — no backend reconciliation endpoint exists either.
- **Canonical contract:** BOOKING.CREATE.RECOVER — persisted idempotency key + resume-time reconciliation against canonical state.
- **Test gap:** No test kills the process mid-create and asserts a single booking after reconciliation.

**Recommendation.** Two steps, both client-side: (1) switch the booking stores from `_idempotencyKey ??= _uuidV4()` to `DraftRepository.getOrCreateIdempotencyKey(uid, draftId)` so the key survives a restart, clearing it only after backend confirmation; (2) on resume, load the journal and reconcile each unresolved `booking.create` against `GET /api/users/:uid/bookings`. This only becomes genuinely safe once the backend honours `X-Idempotency-Key` (separate P0), so sequence the backend fix first.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-124 · User/address controllers return raw exception text to the client and mutate module-level shared response objects

**P2** · rule §21, §58 · fix in **backend** · protected release: **no**

Two coupled defects on the address/profile path. First, thrown Postgres and driver text is concatenated into the response body, exposing constraint and column names (§21). Second, the response payload is a shared mutable module singleton: it is currently safe only because assignment and `res.send` happen in the same synchronous tick, so introducing any `await` between them would let one request's response body be overwritten by another's — a cross-request disclosure one refactor away. The auth controller already recognised and fixed this pattern locally.

- **Client:** servana_client-main/lib/common/data/repositories/address_repository.dart:120-130 sanitises on the client side (`'Could not save address (${e.statusCode})'`), which masks but does not prevent the leak — the raw text is still transmitted and is still logged verbatim in debug builds at lib/common/data/backend/servana_api_client.dart:52-57
- **Backend:** servana_api-main/src/controllers/user.controller.ts:21 (`errorMessage.error = "" + error`) and :39 (`errorMessage.error = "ERROR: " + error`), repeated across the address and profile handlers, returned with HTTP 500. The `errorMessage`/`successMessage` objects are module-level singletons defined in src/helpers/status.ts and mutated per request (user.controller.ts:18, :37, ...). src/controllers/auth.controller.ts:22-23 and :41-42 document this exact race and deliberately inline their responses instead — the fix was never propagated.
- **Canonical contract:** ERROR.SAFE — safe domain codes on the wire, details in server logs, no shared mutable response state.
- **Test gap:** No test asserts that a DB failure on adduseraddress does not return driver text.

**Recommendation.** Replace the singletons with per-request response literals throughout user.controller.ts (following the auth.controller.ts:22-35 pattern), and map thrown errors to safe domain codes (`ADDRESS_SAVE_FAILED`, `PROFILE_UPDATE_FAILED`) with the detail logged server-side only. Add a global Express error handler — src/app.ts currently has none, so unhandled errors fall through to Express's default handler, which emits a stack trace outside production mode.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

