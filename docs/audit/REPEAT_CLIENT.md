# REPEAT — Servana Customer Mobile App

Endpoint equivalence and the canonical capability registry — duplicated domain logic and same-entity-different-shape.

| | |
| --- | --- |
| Target | `Heatclift/ServanaClient` @ `bab66e4` |
| Backend | `servana_api` @ `870fd28` (canonical, §3) |
| Also inspected | admin portal `101016d`, provider web `42fbec9`, provider mobile `451eaf6` |
| Customer web | **UNAVAILABLE** — repo has 0 committed files |
| Findings | 26 |

**P0: 2 · P1: 17 · P2: 6 · P3: 1**

## SC-017 · CUSTOMER.BOOKING.LIST joins guest_customers on a column that does not exist (gc.phone_number) — **FIXED** in `880d5bc`

**P0** · rule §0.10 / §7 / §8 / §9 · fix in **backend** · protected release: **no**

GET /api/users/:userId/bookings — the sole endpoint behind the customer app's Bookings tab — runs a subquery on gc.phone_number, a column absent from both DDL definitions of guest_customers. Either the query throws (Postgres 'column gc.phone_number does not exist' → controller returns 500 → the Bookings tab is empty for every customer, since http_backend.dart:357 swallows the exception and returns []), or a legacy production column exists and the backend is silently merging guest bookings into a client account on a raw unnormalised phone string while the canonical link mechanism is ignored. Both branches are P0: the first is a dead primary flow, the second is cross-identity data access.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:342 (getBookings → api.getUserBookings) and lib/modules/bookings/data/booking_repository.dart:25
- **Backend:** servana_api-main/src/services/bookingService.ts:358-359 (gc.phone_number) vs adminGuestService.ts:33 and adminCreateBookingService.ts:84 (phone_normalized is the only phone column; git log --all -S confirms phone_number never existed)
- **Other:** The canonical guest↔client link mechanism is guest_customers.linked_customer_uid, set only by an audited admin action (servana_api-main/src/services/adminGuestService.ts:454-479)
- **Canonical contract:** CUSTOMER.BOOKING.LIST — one canonical ownership predicate: bookings.user_id = :customerUid OR bookings.guest_customer_id IN (SELECT guest_customer_id FROM guest_customers WHERE linked_customer_uid = :customerUid). Guest↔client equivalence is established only by the audited admin link (§8, §0.10), never by string-matching a phone.
- **Test gap:** No test exercises getBookingsByUserId at all; tests/leak-isolation.test.js:91 only asserts the JWT branch in the controller, never the SQL.

**Recommendation.** Replace the phone subquery in bookingService.ts:352-361 with the canonical linked_customer_uid predicate, matching adminGuestService.linkGuestToClient. Add a request-level regression test that a client whose phone equals a guest's phone but who has no link row receives none of that guest's bookings. Backend-only; ServanaClient is unchanged.

## SC-018 · PROVIDER.PROFILE.READ has one unprojected implementation serving provider, admin and customer — customer app pulls the provider's earnings ledger and every other customer's name — **FIXED** in `65b4337`

**P0** · rule §11 / §58 / §0.5 · fix in **backend** · protected release: **no**

Class C violation: one endpoint, one response shape, three audiences. Any unauthenticated caller who knows a provider uid retrieves that provider's email, phone, birthdate, home addresses, compliance documents, complete disbursement/earnings ledger, and the names of every customer they have ever served. The customer app consumes it purely to render a name and avatar on the booking detail screen.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:344 (getWorkerByUid), called from lib/modules/bookings/presentation/screens/booking_detail_screen.dart:287 and lib/common/services/assignment_polling_service.dart:128 — both only need the provider's name and photo
- **Backend:** servana_api-main/src/routes/technician.routes.ts:13 (GET /workers/:uid, no middleware) vs. technician.routes.ts:44-46 (same booking-history/disbursement-history/earnings-history data gated with verifyAuth+verifyOwnership as "financial data"); payload built unprojected at src/services/technicianService.ts:70-215 (email/phone :76-77, birthdate/gender :85-86, addresses :104-112, requirements :123-131, customer_name :146, disbursements :164-192, earnings :195-208, returned :212-239) and passed through without stripping at src/controllers/technicianController.ts:71-79; router mounted with cors() only at src/app.ts:112
- **Other:** ServanaWorker/lib/core/api/servana_api_config.dart:75-78 attaches Authorization: Bearer on every Dio request including /api/workers/:uid (ServanaWorker/lib/core/api/servana_api.dart:313), so the 'Public mobile routes — do NOT add auth' comment at technician.routes.ts:9 is stale for BOTH mobile apps
- **Canonical contract:** PROVIDER.PROFILE.READ splits into three authorised projections over one canonical service: PROVIDER.PROFILE.SELF (uid from token), PROVIDER.PROFILE.ADMIN (role 1), and a new PROVIDER.PROFILE.PUBLIC_CARD returning only {providerUid, displayName, photoUrl, rating, reviewCount} to a customer holding an active booking_workers relationship.
- **Test gap:** tests/leak-isolation.test.js has no case for GET /workers/:uid.

**Recommendation.** Add verifyAuth to technician.routes.ts:13 and return a projection selected by the caller's resolved relationship (reuse bookingAccessService.resolveBookingAccess). Both mobile clients already send a bearer token — verified above — so this closes the hole with zero protected-client change (§2).

## SC-077 · Booking lifecycle status and assignment status are collapsed into one wire field; the customer app maps WORKER_ASSIGNED to 'en route' and never reads workerStatus

**P1** · rule §13 / §9 / §22 · fix in **backend** · protected release: **no**

There is no canonicalisation on the customer path, so the app cannot distinguish §13 'assigned' from 'accepted' — and it actively misreports: the instant an admin or the auto-assigner attaches a provider, the app tells the customer the provider is en route, even though the provider has not accepted and may still decline. Five vocabularies now exist for one concept across backend-admin, backend-customer, ServanaClient, ServanaWorker and the admin portal.

- **Client:** servana_client-main/lib/common/domain/booking/booking_status.dart:82-87 maps WORKER_ASSIGNED to BookingStatus.enRoute alongside EN_ROUTE/IN_TRANSIT; grep across lib for workerStatus/worker_status/assignmentStatus returns zero hits, so the app never reads the assignment status the backend already sends
- **Backend:** servana_api-main/src/services/bookingService.ts:222 selects bw.status AS worker_status and :509 aliases it to assignmentStatus; bookings.status='WORKER_ASSIGNED' is written at services/technicianService.ts:623 and :931 the moment a provider is assigned, before acceptance (booking_workers.status='ASSIGNED'; ACCEPTED only via technicianService.acceptJob). services/adminBookingService.ts:181-200 is the only place the §13 canonical family is produced, and only for admin.
- **Other:** ServanaWorker/lib/features/homepage/data/models/bookingrequest_model.dart:105 resolves the same concept as `workerStatus ?? bookingStatus`, and ServanaWorker/lib/features/homepage/data/job_status.dart:9-14 defines a further disjoint vocabulary; servana_adminportal/src/app/shared/constants/statuses.constants.ts:1-8 defines a fifth
- **Canonical contract:** Two separate canonical status domains: BOOKING.LIFECYCLE.STATUS (new, awaiting_assignment, assigned, accepted, in_progress, completed, cancelled, disputed) and BOOKING.ASSIGNMENT.STATUS (assigned, accepted, declined, in_progress, completed, cancelled), emitted as additive fields alongside the existing raw values.
- **Test gap:** tests/repeat-parity.test.js:209-214 checks only that formatBooking mentions bookingId/scheduledAt/providerUid; nothing asserts status canonicalisation.

**Recommendation.** Add additive canonical fields to formatBooking (canonicalStatus from mapOperationsStatus, canonicalAssignmentStatus from booking_workers.status) so all platforms can converge without any protected client changing today. Do not rename or remove the existing raw fields.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-078 · BOOKING.ADDONS: relational booking_addons rows are written only by the admin path — add-ons the customer paid for are invisible to provider and admin

**P1** · rule §9 / §10 / §30 · fix in **backend** · protected release: **no**

Two representations of the same business fact. A customer books a Beauty & Wellness service with three paid add-ons; booking_addons is empty, so the assigned provider's job card and the Admin Booking 360 both show the base service only while the customer was charged for all four. GET /api/:id returns addons: [] to the very app that created them.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:449-459 reconstructs the service name from pricingBreakdown.addons because the relational add-on list is empty for app bookings; add-ons are selected in lib/modules/bw_booking/data/bw_booking_store.dart:233 and lib/modules/aircon_booking/data/aircon_booking_store.dart:257
- **Backend:** Only writer: servana_api-main/src/services/adminCreateBookingService.ts:720-729. Readers that see nothing for app bookings: src/services/bookingService.ts:242-262 (customer detail), src/controllers/providerController.ts:2186 (provider job detail), src/services/adminBookingService.ts:528 (Admin Booking 360). The customer path stores add-ons only inside pricing_breakdown JSONB (services/pricingService.ts:48-60 → services/bookingService.ts:79,92).
- **Canonical contract:** BOOKING.ADDONS — one canonical relational store (booking_addons) written by every create path; pricing_breakdown remains a priced snapshot, not the system of record.
- **Test gap:** No test asserts booking_addons parity between the two create paths.

**Recommendation.** Write booking_addons rows in bookingService.createBooking from quote.addons (already computed at pricingService.ts:51-59), inside the same transaction as the booking insert. Keep pricing_breakdown unchanged for protected-client compatibility.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-079 · BOOKING.ADDRESS: customer bookings hold a mutable FK instead of a booking-time snapshot, so editing a saved address rewrites past bookings

**P1** · rule §41 / §9 · fix in **backend** · protected release: **no**

Two address realities for one booking entity. Admin-created bookings carry an immutable snapshot; app-created bookings resolve through a live FK, so a customer who edits or deletes that address later sees a wrong or NULL address on every historical booking — and so do the provider and admin views, which COALESCE off the same join.

- **Client:** servana_client-main/lib/common/presentation/screens/drawer_placeholder_screens.dart:387-391 implements 'edit address' as delete-then-recreate (there is no ADDRESS.UPDATE capability), and lib/common/data/repositories/address_repository.dart:85 creates the replacement
- **Backend:** servana_api-main/src/services/bookingService.ts:75-94 stores only user_address_id; reads resolve live (bookingService.ts:218-221, :335-338 COALESCE(ua.address_one, …)). The admin path instead snapshots into bookings.service_address JSONB (adminCreateBookingService.ts:614-617, :698, :712).
- **Canonical contract:** BOOKING.ADDRESS.SNAPSHOT — every create path writes an immutable bookings.service_address JSONB {addressLine, city, lat, lon, locationId} at booking time; user_address_id is retained as lineage only.
- **Test gap:** None.

**Recommendation.** Populate bookings.service_address in bookingService.createBooking from the address row it already reads at :41-53 plus the Mongo lat/lon it fetches at :58. The read paths already COALESCE, so this is additive and invisible to protected clients.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-080 · BOOKING.CREATE: app-originated bookings write no timeline or audit event, so Admin Booking 360 shows two different histories depending on origin

**P1** · rule §15 / §16 / §10 · fix in **backend** · protected release: **no**

Every booking created from the customer app has an empty timeline and no audit record until it is cancelled, while admin-created bookings have both. Admin's Booking 360 therefore presents a different reality per origin, and there is no immutable governance record for the majority of bookings.

- **Client:** servana_client-main/lib/modules/aircon_booking/data/aircon_booking_store.dart:431 and lib/modules/bw_booking/data/bw_booking_store.dart:409 are the only customer booking-create call sites
- **Backend:** servana_api-main/src/services/bookingService.ts:73-132 writes bookings + payments only; the admin equivalent writes booking_timeline_events (adminCreateBookingService.ts:784-796) and booking_audit_events (:799-811). booking_timeline_events is written for customer bookings only on cancel (bookingService.ts:565-574).
- **Other:** servana_adminportal renders the timeline sourced from adminBookingService.ts:145-175
- **Canonical contract:** BOOKING.CREATE emits exactly one canonical timeline event and one audit event regardless of origin, with actor_type ∈ {customer, admin} and sourcePlatform metadata distinguishing them (§14, §19).
- **Test gap:** No test asserts a timeline/audit row exists after a customer-originated create.

**Recommendation.** Extract the timeline+audit emission from adminCreateBookingService into a shared CanonicalBookingService.recordCreated() and call it from bookingService.createBooking with actor_type='customer', actor_uid=customerUid, sourcePlatform='customer_mobile'.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-081 · BOOKING.CREATE: the customer path ignores X-Idempotency-Key while the admin path has a full idempotency table

**P1** · rule §17 / §19 / §0.8 · fix in **backend** · protected release: **no**

One capability, two implementations, only one safe to retry. The customer app already satisfies §17 — stable key, persisted across process death, reused on retry — but the backend discards the header, so a user re-tapping after the client's 30 s timeout (servana_api_client.dart:883-901 synthesises a 408) creates a second booking and a second payments row. The dedupe machinery the fix needs already exists in the same repo for admin bookings.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:372-377 sends X-Idempotency-Key; the key is persisted and deliberately reused across retries (lib/core/recovery/draft_repository.dart:88-96, lib/modules/aircon_booking/data/aircon_booking_store.dart:28 'reused on retry'); lib/core/recovery/retry_policy.dart:62-68 defines a 2-attempt booking-create budget explicitly conditioned on the header being honoured
- **Backend:** grep for 'idempotenc' across servana_api-main/src returns no reader of the X-Idempotency-Key header; the customer path (routes/booking.routes.ts:20 → controllers/bookingController.ts:30 → services/bookingService.ts:73-104) has no dedupe and no transaction, while the admin path (services/adminCreateBookingService.ts:120-129 table, :636-654 advisory lock + pre-read, :765-771 record) is fully idempotent
- **Canonical contract:** BOOKING.CREATE — one canonical mutation guarded by booking_create_idempotency keyed on (idempotency_key, actor_uid), accepted from the X-Idempotency-Key header for customer callers and the body field for admin callers.
- **Test gap:** No backend test replays a create with a repeated idempotency key on the customer route.

**Recommendation.** Read X-Idempotency-Key in bookingController.createBooking and wrap bookingService.createBooking in the same advisory-lock + booking_create_idempotency pattern as adminCreateBookingService.ts:636-771, keyed on (idempotency_key, customerUid). No client change.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-082 · BOOKING.DETAIL.READ has no audience projection — the sibling 65b4337 missed; the assigned provider receives the customer's OTP and GCash payment evidence

**P1** · rule §58 privacy · §43 payment evidence · §9 no duplicate reality · REPEAT Class C · fix in **?** · protected release: **no**

65b4337 fixed PROVIDER.PROFILE.READ by adding projectProviderProfile — one canonical service, three authorised projections. The identical Class C defect on BOOKING.DETAIL.READ was left in place: GET /api/:id selects `b.*` and the formatter spreads every column, so all three audiences (customer, actively-assigned provider, admin) receive one identical, maximal object. That object carries `otpCode` and the customer's GCash reference number and payment-proof URL.


**Recommendation.** Add projectBooking(booking, audience) beside providerProfileProjection.ts and reuse the audience resolver that already exists — assertBookingAccess (bookingAccessService.ts:101) already returns the role, so bookingController.ts:92 can pass it straight through instead of discarding it. Follow the same explicit-list discipline as providerProfileProjection.ts:52-56: withhold by default so a new column added to `b.*` is not silently published. Minimum withheld set for audience 'provider': otpCode, proofUrl, referenceNo. Drop proof_url from the getBookingsByUserId and getTracking SELECTs entirely (bookingService.ts:284, :329) — no caller reads it.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-083 · BOOKING.OWNERSHIP.RESOLVE is implemented twice with different rules — the list endpoint returns bookings the detail endpoint then refuses

**P1** · rule §9 / §10 / §11 · fix in **backend** · protected release: **no**

Two independent answers to 'is this booking this customer's'. The list query deliberately widens ownership to phone-matched guest bookings; assertBookingAccess deliberately narrows it to bookings.user_id and documents guest bookings as out of reach. Any booking satisfying the list rule but not the access rule appears in the customer's Bookings tab and returns 403 on tap, with no recoverable UI state.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:342 lists bookings; tapping one calls lib/common/data/backend/servana_api_client.dart:387 (getBooking) from lib/modules/bookings/presentation/screens/booking_detail_screen.dart:155
- **Backend:** servana_api-main/src/services/bookingService.ts:352-361 (list: user_id OR phone-matched guest) vs src/services/bookingAccessService.ts:59-92 (detail: bookings.user_id only), whose own docstring at :53-57 states guest bookings are deliberately unreachable by any token
- **Canonical contract:** One BOOKING.OWNERSHIP.RESOLVE service consumed by every booking read/write path — list, detail, tracking, cancel, confirm-otp and payment — so a booking is either the customer's everywhere or nowhere.
- **Test gap:** tests/booking-access.test.ts covers the detail path only; nothing asserts list/detail agreement.

**Recommendation.** Have bookingService.getBookingsByUserId derive its WHERE clause from the same predicate bookingAccessService uses (extract resolveOwnedBookingIds), so list membership and detail access cannot diverge. Add a contract test asserting every id returned by the list passes assertBookingAccess for the same actor.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-084 · BOOKING.PROVIDER.ASSIGN has four independent implementations with different guards, different side effects and different prices

**P1** · rule §10 / §14 / §22 / §29 · fix in **backend** · protected release: **no**

Four assignment implementations, each with a different subset of guards and effects. transpo_fee and final_price are recomputed only on the auto-assign path, so the same booking at the same distance costs a different amount depending on who assigned the provider; etaMinutes and workerCode — both read by the customer app — are null for every admin-assigned booking; only two paths write an audit record; only one records who assigned (§14); and each path enforces a different definition of provider eligibility.

- **Client:** servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:54,56 read _etaMinutes and _workerCode; lib/modules/aircon_booking/data/aircon_booking_store.dart:444-446 reads workerCode — all of which exist only on one of the four assignment paths
- **Backend:** (1) services/technicianService.ts:618-651 auto-assign: sets worker_uid, status, eta_minutes, eta_at, worker_code, transpo_fee and rewrites final_price, plus booking_workers + booking_tracking, notifies the customer by email only. (2) services/technicianService.ts:915-951 admin manual: schedule-conflict guard, booking_workers + booking_tracking + provider notification, no eta/worker_code/transpo. (3) services/adminBookingService.ts:773-800 assign and :838-865 reassign: archive + employee_services eligibility guard, timeline + audit, no eta/worker_code/transpo, no schedule-conflict guard. (4) services/adminCreateBookingService.ts:740-745: booking_workers with admin_actor_uid, timeline, audit, provider notification, no eta/transpo.
- **Canonical contract:** BOOKING.PROVIDER.ASSIGN — one canonical service performing eligibility revalidation (§29), transpo/ETA computation, worker_code issuance, booking_workers insert with actor metadata, timeline + audit, and provider notification. Callers differ only in who the actor is.
- **Test gap:** No test compares the post-conditions of the four assignment paths.

**Recommendation.** Consolidate all four into one CanonicalAssignmentService taking {bookingId, providerUid, actorUid, actorRole, reason}. Preserve the existing wire fields exactly so neither mobile app changes.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-085 · legacyRouteTelemetry records no uid on 30 of the 36 legacy routes, and its test injects the field Express cannot supply

**P1** · rule §60 run the checks · §34 observability · REPEAT §35 deprecation · fix in **?** · protected release: **no**

The telemetry added in 65b4337 exists to produce the traffic numbers that gate step 4 of the worker-route migration and to detect uid enumeration. Because it is mounted as router.use() middleware, req.params is empty when it runs, so it can only see a uid on the four routes that pass ?workerUid= in the query string. The two routes the migration doc names as highest-risk — GET /workers/location/:uid and GET /workers/:workerId/job-cards — carry their uid in the path and are therefore logged as claimsUid=no and never counted toward the enumeration threshold.


**Recommendation.** Parse the uid from the URL rather than from req.params, which is the only source available at .use() time — e.g. match `req.path` against /^\/(?:location\/)?([^/]+)/ after the /workers mount, or move the middleware to a router.param('uid') plus router.param('workerId') registration, which does run with params bound. Then close the self-test gap the way the LAGDA probe rule prescribes: mount the real middleware on a real Express router in the test and drive it with supertest against `/api/workers/location/:uid`, so a positive fixture exists for a path-parameterised route and a regression cannot pass. Until this is fixed, treat any 'legacy traffic is low' reading as unmeasured, and do not let it satisfy step 4 of docs/WORKER_ROUTE_MIGRATION.md.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-086 · LOCATION.ID is derived in four places, and the admin path coerces the canonical loc_<lat>_<lon> string to a Number so it is always null

**P1** · rule §38 / §39 / §42 / §0.12 · fix in **backend** · protected release: **no**

Four implementations of one derivation, split across a protected client and the backend, plus two consumers that silently discard the result because they expect a numeric id. §38/§39/§42 place this in the backend, yet the customer app computes coordinates-to-id locally in three files and posts lat/lon the backend writes to Mongo verbatim without validation (services/address.service.ts:41-45, :85-89).

- **Client:** servana_client-main/lib/common/data/repositories/address_repository.dart:70 builds 'loc_${lat.toStringAsFixed(6)}_${lon.toStringAsFixed(6)}' client-side; duplicated at lib/common/data/backend/http_backend.dart:220-221 and again inline at lib/common/presentation/screens/drawer_placeholder_screens.dart:327 and :391
- **Backend:** servana_api-main/src/services/addressSearchService.ts:69-71 buildServanaLocationId returns the same string, surfaced as servanaLocationId at :329; a fourth copy at services/adminCreateBookingService.ts:615. services/adminBookingDraftService.ts:631 then applies Number.isFinite(Number(addr.servanaLocationId)) ? Number(...) : null — 'loc_14.123456_121.123456' is never numeric, so locationId is always null on that path.
- **Other:** servana_adminportal/src/app/pages/job-orders/pages/create-booking/create-booking.component.ts:988 contains the identical always-null coercion, and its own spec pins the wrong behaviour (create-booking.component.spec.ts:692 'locationId is null when servanaLocationId is non-numeric')
- **Canonical contract:** ADDRESS.RESOLVE owns location-id derivation server-side and returns servanaLocationId as the §42 string loc_{lat.toFixed(6)}_{lon.toFixed(6)}. No client computes it; no consumer coerces it to a number.
- **Test gap:** The admin-portal spec asserts the defect as expected behaviour and would need inverting.

**Recommendation.** Make POST /api/user/adduseraddress derive location_id server-side and ignore any client-supplied value (additive — the client keeps sending it harmlessly). Fix the numeric coercion in adminBookingDraftService.ts:631 and the mirrored admin-portal line, treating servanaLocationId as an opaque string.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-087 · NOTIFICATION.CUSTOMER.EMIT: the app understands 21 notification types, the backend produces exactly one, and the two route shapes are incompatible

**P1** · rule §45 / §9 / §10 · fix in **backend** · protected release: **no**

The customer notification capability is implemented on the client and in the notification service but has essentially no producers. Assignment, en route, arrival, service start, completion, payment confirmation, refund and new chat message all notify the provider (or send an email) and never the customer, so the app's notification centre only ever contains 'Booking received'. The two route shapes are also unreconciled: any provider-shaped route reaching a customer resolves to no destination.

- **Client:** servana_client-main/lib/modules/notifications/domain/notification_type.dart:1-23 declares 21 named types plus unknown; lib/modules/notifications/domain/notification_target.dart:34-58 understands only the {routeKey, resourceId} shape
- **Backend:** createCustomerNotification has exactly one call site in the whole backend — controllers/bookingController.ts:38-47, type 'booking_created' — while createNotification (provider) has ten (adminCreateBookingService.ts:817, adminOnboardingService.ts:881/:1087/:1138, paymentService.ts:97/:133, serviceApplicationService.ts:213/:251/:292, technicianService.ts:941). Provider notifications carry route {page, bookingId} (paymentService.ts:103), which targetFromRoute resolves to null. src/chat contains no notification call at all, so a new chat message produces no customer notification.
- **Canonical contract:** NOTIFICATION.EMIT — one canonical emitter keyed on {audience, canonicalEntityType, canonicalEntityId, type} that renders the audience-appropriate route shape from a single canonical target ({routeKey, resourceId}), invoked from every lifecycle transition rather than from the provider branch only.
- **Test gap:** No backend test asserts that a customer notification exists after assignment/completion/payment.

**Recommendation.** Emit the customer-side counterpart at each lifecycle transition using the existing createCustomerNotification, and normalise the route shape in notification.service.ts so {page, bookingId} and {routeKey, resourceId} are two projections of one canonical target. Backend-only; the client already parses everything it needs.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-088 · PAYMENT.RECORD.RESOLVE: the booking↔payment join is scoped by additional_request_id in the provider read model but not in the customer or payment-mutation paths

**P1** · rule §43 / §9 / §18 · fix in **backend** · protected release: **no**

Once an additional-work request exists there are two payments rows sharing one booking_id. The customer read model joins them unfiltered, so the payment status shown for a booking is whichever row Postgres returns first, and approvePayment/markCashPaid/submitGcash/createCheckoutSession each update BOTH rows — settling the additional-work charge as a side effect of settling the booking. The provider read model already gets this right, which is why the divergence went unnoticed.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:343-352 carries a permanent client-side dedupe with the comment 'the BE list endpoint occasionally returns the same booking twice when multiple payment-attempt rows exist server-side' — the customer app has already had to work around this in production
- **Backend:** Correctly scoped: services/technicianService.ts:158 and :1529 (LEFT JOIN payments p ON p.booking_id = b.id AND p.additional_request_id IS NULL). Unscoped: services/bookingService.ts:227-228 (customer detail) and :344-345 (customer list) fan out 1:N and getBookingById returns rows[0] arbitrarily; services/paymentService.ts:61-66, :78-83, :114-119 and :224-231 all mutate WHERE booking_id=$1 with no discriminator. Second rows for the same booking_id are inserted by services/paymentService.ts:358-371 for additional requests.
- **Canonical contract:** PAYMENT.RECORD.RESOLVE — a single resolver returning the booking's primary payment row (additional_request_id IS NULL), used by every read projection and every mutation WHERE clause.
- **Test gap:** No test creates an additional request and then reads the booking.

**Recommendation.** Add AND p.additional_request_id IS NULL to bookingService.ts:227-228 and :344-345 and to every payments UPDATE in paymentService.ts keyed on booking_id.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-089 · PAYMENT.SETTLE has four implementations that leave the system in four different states

**P1** · rule §9 / §10 / §43 / §15 · fix in **backend** · protected release: **no**

Whether a settled booking shows as paid in the customer app, reaches the finance ledger, produces an audit record, or notifies the provider depends entirely on which of four paths settled it. An admin GCash approval leaves bookings.status at CONFIRMED, so the customer app keeps rendering the booking as unpaid (booking_detail_screen.dart:91-93 keys off the payments row while booking_status.dart:69 keys off the booking row) and the provider is never told the money arrived.

- **Client:** servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:91-93 gates the pay CTA on paymentStatus/paymentMethodUsed and :807-810 renders the paid chip; lib/common/domain/booking/booking_status.dart:69-71 separately treats booking status PAID as a lifecycle state
- **Backend:** (1) services/paymentService.ts:75-109 approvePayment — no state guard, no bookings.status update, no ledger, no audit, notifies provider. (2) services/paymentService.ts:111-145 markCashPaid — same, forces method='CASH'. (3) services/paymentService.ts:470-487 webhook — updates payments AND bookings.status='PAID' AND booking_tracking, emails the customer, no ledger, no audit. (4) services/adminFinanceService.ts:347-383 approveGcashPayment — optimistic state guard, createLedgerEntry, auditFire, but no bookings.status update and no provider notification.
- **Canonical contract:** PAYMENT.SETTLE — one canonical service: state guard on payments.status, single UPDATE, bookings.status transition, finance ledger entry, audit event, provider + customer notification. Callers (customer confirm, admin GCash approval, PayMongo webhook, cash collection) are adapters over it.
- **Test gap:** tests/admin-finance.test.js covers only the admin path; no test compares end states across the four.

**Recommendation.** Route all four callers through one settlePayment(paymentId|bookingId, actor, source) performing the guarded update, the bookings.status transition, the ledger entry, the audit event and both notifications in one transaction.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-090 · PROVIDER.LOCATION.READ has three response shapes and ServanaClient parses none — live tracking never shows the provider

**P1** · rule §9 no duplicate reality · §4 additive compatibility · §20 no ghost success · REPEAT Class A/C · fix in **?** · protected release: **no**

One capability, two backend routes, three envelope shapes, and the customer app's parser matches none of them. GeoPositionSnapshot.fromApiMap returns null on every real response, so the live-tracking map silently never renders the provider marker. The unit tests are green because their fixtures were written against a shape the backend does not emit — the same failure mode the options-with-addons fix was written to call out, recurring one module over.


**Recommendation.** Two moves, in this order. (1) Backend, additive, no client release: have the legacy handler also emit the document under the key the client already probes — `res.json({ success: true, location: toCamel(doc), data: toCamel(doc) })` at technicianController.ts:177. tracking_data_source.dart:34 checks `result['data']` first, so this alone restores the marker on the installed base. (2) Converge the two shapes: make the successor return `location: toCamel(doc)` so the family has one projection, then point the client at `GET /booking/:bookingId/provider-location` in the next release. That migration is now nearly free — the client's parser needs a fix either way, and fixing it once against `result['location'] ?? result['data'] ?? result` satisfies both routes. Add a fixture to geo_position_snapshot_test.dart copied verbatim from a real response body of each route, not hand-written.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-091 · SERVICE.OPTIONS.LIST is the one route in service.route.ts registered outside the /services family, and the only live caller 404s

**P1** · rule §0.5 / §4 · fix in **backend** · protected release: **no**

A route-family inconsistency that breaks the capability outright: the customer app's only add-on loader targets the namespaced path the rest of the router uses, and the backend registered the un-namespaced one. The hard-rules protected-route list itself names the two-segment form, so the protected contract as written has no live consumer while the live consumer gets a 404.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:264 requests /api/services/{id}/options-with-addons (three segments) — the sole loader for aircon options, BW add-ons and the Category Experience screen (lib/modules/aircon_booking/data/aircon_booking_store.dart:257, lib/modules/bw_booking/data/bw_booking_store.dart:233, lib/modules/homepage/data/repositories/category_experience_repository.dart:18)
- **Backend:** servana_api-main/src/routes/service.route.ts:12 registers GET /:serviceId/options-with-addons — two segments — while every sibling read route on lines 8-16 is namespaced under /services. No path-rewriting middleware exists (src/app.ts:67,69 alias field names only).
- **Canonical contract:** SERVICE.OPTIONS.LIST — register the canonical /api/services/:serviceId/options-with-addons and keep the legacy two-segment path as a compatibility alias delegating to the same controller (Class B, never delete).
- **Test gap:** No route-registration contract test enumerates the paths the mobile client actually calls.

**Recommendation.** Add router.get('/services/:serviceId/options-with-addons', serviceController.listOptionsWithAddons) alongside the existing line 12. Purely additive, no protected release, and it restores three customer screens.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-092 · The customer app re-parses a human display label as if it were a canonical status code

**P1** · rule §9 / §10 / §13 · fix in **client-mobile** · protected release: **yes**

Two status models inside one app, chained lossily. 'Worker Assigned' → 'WORKER ASSIGNED' (space, not underscore) → BookingStatus.unknown; 'In Progress' → 'IN PROGRESS' → unknown; 'Payment Required' and 'Scheduled' → unknown. bookings_screen.dart:174-176 routes unknown to the Needs-Attention segment, so a booking that is actively in progress or has a provider assigned is filed under 'Needs Attention' instead of Active/Upcoming, and the Bookings tab badge at main_nav_scaffold.dart:40-42 can never count them. Only single-word labels ('Confirmed', 'Paid', 'Completed', 'Cancelled', 'Reviewed', 'Refunded', 'Expired', 'Failed') survive the round trip.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:362-446 converts the raw backend status into a presentation label ('Worker Assigned', 'In Progress', 'Payment Required', 'Scheduled') and stores it in JobOrder.jobOrderStatusToString (:477); lib/modules/bookings/presentation/screens/bookings_screen.dart:135, lib/common/presentation/widgets/main_nav_scaffold.dart:40 and lib/modules/messaging/presentation/screens/messages_inbox_screen.dart:56 then feed that label back into BookingStatusMapper.fromString, which only uppercases and trims (lib/common/domain/booking/booking_status.dart:51-53) and recognises underscore forms only
- **Backend:** servana_api-main/src/services/bookingService.ts:483-511 formatBooking emits only the raw UPPERCASE status plus a naive statusLower; no canonical status is produced on the customer path
- **Canonical contract:** One canonical status value crosses the wire and is interpreted exactly once per platform; presentation labels are derived from it and never re-parsed.
- **Test gap:** No client test asserts BookingStatusMapper.fromString round-trips the labels produced by _mapApiBookingToJobOrder. That unit test would fail today and costs no release.

**Recommendation.** Backend-first: emit an explicit canonical status field from formatBooking (see the WORKER_ASSIGNED finding) so the client can stop inferring. The client-side consolidation — passing the raw status through JobOrder and feeding BookingStatusMapper the raw value — is a protected-repo change and should follow the backend field, not precede it.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-093 · Two complete booking read stacks inside the customer app — the canonical model, mapper and repository are dead code

**P1** · rule §9 / §10 · fix in **client-mobile** · protected release: **yes**

The app carries two full representations of the booking entity. The richer, alias-aware one (CustomerBooking.fromApiMap at customer_booking.dart:163-235, with §7 alias resolution and the 23-value status model) is never rendered; the shipping UI uses the legacy JobOrder built by a mapper that hard-codes latitude/longitude to 0 (http_backend.dart:474-475), invents merchantName 'Servana', and collapses backend status to 7 enum values. This is the root cause of the two preceding findings — the good implementation is disconnected from production.

- **Client:** Live stack: HttpBackend.getBookings (lib/common/data/backend/http_backend.dart:337-360) → _mapApiBookingToJobOrder (:362-489) → JobOrder → bookings_screen.dart / booking_detail_screen.dart. Dead stack: lib/modules/bookings/data/booking_repository.dart:24-35 (getBookings), :46-64 (getBookingById), :94-105 (getTimeline) → CustomerBooking (lib/common/domain/booking/customer_booking.dart). grep shows CustomerBooking is referenced only by its own file and booking_repository.dart, and the only BookingRepository method with a caller is cancelBooking (lib/modules/bookings/presentation/widgets/booking_cancellation_sheet.dart:74).
- **Canonical contract:** One booking domain model per platform, hydrated by one mapper, consumed by every booking screen.
- **Test gap:** Client tests exercise CustomerBooking/BookingStatusMapper directly, so the dead stack looks healthy in CI while the live stack is untested.

**Recommendation.** Client-side consolidation (protected repo — schedule, do not force): retire _mapApiBookingToJobOrder in favour of BookingRepository/CustomerBooking, or delete the dead stack so there is one reality. Until then, treat any status/field fix applied to CustomerBooking as having no production effect. No backend change required.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-139 · ADDRESS.CREATE has three client implementations and one endpoint that silently doubles as ADDRESS.UPDATE

**P2** · rule §10 / §0.12 · fix in **backend** · protected release: **no**

One capability, three client paths (one unauthenticated and therefore always 401), plus a create endpoint that mutates when a body field is present. The absence of a real update capability is why the app implements address editing as delete-then-recreate, which is also what breaks historical booking addresses.

- **Client:** lib/common/data/repositories/address_repository.dart:28 states 'Widgets should never call [ServanaApiClient.addUserAddress] … directly', yet lib/common/presentation/screens/drawer_placeholder_screens.dart:325 and :388 do exactly that; a third implementation with no bearer token exists at lib/common/data/backend/http_backend.dart:213-227
- **Backend:** servana_api-main/src/routes/user.route.ts:16 → src/controllers/user.controller.ts:29-33 branches on req.body.addressId to perform an update instead, calling addressService.updateUserAddress (src/services/address.service.ts:56-60)
- **Canonical contract:** ADDRESS.CREATE and ADDRESS.UPDATE are distinct capabilities over one canonical user_address record: POST /api/user/adduseraddress creates, a new PUT /api/user/addresses/:addressId updates, both scoped by uid from the token. Legacy POST-with-addressId remains as a compatibility adapter.
- **Test gap:** None.

**Recommendation.** Add an explicit ADDRESS.UPDATE route and keep the POST branch as an adapter. The client-side consolidation (route the two direct widget calls through AddressRepository, delete HttpBackend.addUserAddress) is protected-repo cleanup and can wait — the backend change alone makes editing safe.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-140 · AUTH.SIGN_IN returns two different session shapes, reconciled by scattered client-side fallback chains

**P2** · rule §0.12 / §7 · fix in **backend** · protected release: **no**

Two sign-in endpoints for one capability emit disjoint session shapes, and the app absorbs the difference with per-field fallback chains — precisely the pattern §0.12 forbids. A practical consequence: the social path omits role, which is one reason the client performs no role assertion at all and would accept a provider or admin token as a customer session.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:78-86 resolves the session with data['id'] ?? data['customerID'], data['phoneNumber'] ?? data['mobileNumber'], data['email'] ?? data['emailAddress'], data['fullname'] ?? _buildFullName(data); the social path goes through a different client entirely (lib/common/domain/auth/auth_token_exchanger.dart:29 → servana_api_client.dart:115)
- **Backend:** services/auth.service.ts:249-259 returns {token, id, uid, email, role, firstName, lastName, isEmailVerified}; services/firebaseFunctions.service.ts:176-186 returns {token, id, customerID, fullname, phoneNumber, mobileNumber, email, emailAddress} — no role, no first/last name. Both ultimately yield a Firebase ID token, so the bearer contract is at least consistent.
- **Canonical contract:** AUTH.SESSION — one canonical session projection {token, customerUid, email, phoneNumber, firstName, lastName, role, isEmailVerified} emitted by every sign-in adapter, with the current alias fields retained additively.
- **Test gap:** No contract test pins the two sign-in response shapes against each other.

**Recommendation.** Have customerFirebaseLogin return the same field set as the password path (adding role, firstName, lastName) while keeping customerID/emailAddress/mobileNumber as aliases. Purely additive.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-141 · Class F: otp_code and worker_code are produced by one generator but mean two different things, and the app carries both names for one field

**P2** · rule §0.11 (Class F) / §17 · fix in **backend** · protected release: **no**

Same generator, same 6-digit shape, two unrelated business meanings, and the customer app carries an alias chain because the wire name changed under it. Assignment paths also disagree on which code they issue — auto-assign issues worker_code (technicianService.ts:627) while admin manual assign (:915-951) issues neither — so provider start-job verification fails for some assignment paths; the admin create path had to work around this explicitly (adminCreateBookingService.ts:622-626).

- **Client:** servana_client-main/lib/modules/aircon_booking/data/aircon_booking_store.dart:126-130 documents the confusion directly — 'Canonical wire field is workerCode. The legacy otpCode field is being … sends back on Start Job as workerCode' — and reads it defensively at :444-446
- **Backend:** bookings.otp_code is the customer's booking-confirmation OTP (services/bookingService.ts:71,80,145) while bookings.worker_code is the provider's job-start code (services/technicianService.ts:616,627, validated at :1133 and :1146). Both come from helpers/otp.generateOTP. adminCreateBookingService.ts:626,700 sets otp_code NULL and issues only worker_code; services/paymentService.ts:238-245 holds a commented-out third writer of worker_code.
- **Canonical contract:** Two distinct capabilities: BOOKING.CUSTOMER_OTP.VERIFY (bookings.otp_code, consumed by POST /:id/confirm-otp) and BOOKING.START_CODE.VERIFY (bookings.worker_code, consumed by the provider start-job route). Neither may be referred to by the other's name.
- **Test gap:** No test asserts worker_code is non-null after every assignment path.

**Recommendation.** Keep both wire fields (protected) but make issuance canonical: the shared assignment service always issues worker_code. Document the two capabilities separately in the field registry — src/utils/fieldParity.ts:281-282 currently describes worker_code only.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-142 · createBooking returns the plaintext booking OTP to the caller as otpDevOnly, with no environment guard

**P2** · rule §58 privacy · §11 fail closed · fix in **?** · protected release: **no**

The booking-creation response includes the OTP that was just emailed to the customer, under a field name asserting it is development-only. Nothing gates it on NODE_ENV. It defeats the point of mailing the code — possession of the mailbox is no longer required to confirm the booking — and it puts an OTP into every client log, crash report and proxy that captures the response body.


**Recommendation.** Delete `otpDevOnly` from the bookingService.ts:127 return. If a development affordance is genuinely wanted, gate it the way verifyAuth.ts:54-59 gates its bypass — `...(process.env.NODE_ENV !== 'production' ? { otpDevOnly: otp } : {})` — so production cannot emit it regardless of caller.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-143 · JOB_CARD.READ has two independent formatters over one canonical query, and they disagree on address.instructions

**P2** · rule §10 no duplicated domain logic · §9 no duplicate reality · §58 privacy · fix in **?** · protected release: **no**

The legacy and successor job-card endpoints share the canonical read (technicianService.getJobCardsByWorker) but each hand-rolls its own response object. The shapes have drifted: the unauthenticated legacy route publishes the customer's delivery instructions and the authenticated successor does not. The migration doc lists this pair under 'Already available — the app can move today', which is true only because nothing consumes the extra field.


**Recommendation.** Collapse the two formatters into one exported function used by both controllers — the canonical read is already shared, so only the projection needs consolidating (§10). Resolve the field deliberately in one place rather than by omission: since no client reads delivery_instructions, drop it from the legacy shape too. That is the cheapest item on the migration doc's own 'Interim hardening' list, it removes customer access information from an unauthenticated endpoint, and it needs no protected release because the field has no consumer.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-144 · The existing REPEAT parity test suite covers only provider capabilities — no customer capability has a parity test

**P2** · rule §60 / REPEAT §30-32 · fix in **backend** · protected release: **no**

Every finding above concerns a customer capability, and none could have been caught by the current suite: it is entirely provider-scoped and consists of source-text assertions rather than request-level checks. That is why four separate BOOKING.CREATE side-effect divergences and four PAYMENT.SETTLE end states coexist undetected.

- **Client:** Every customer capability traced in this pass (BOOKING.CREATE, BOOKING.LIST, BOOKING.OWNERSHIP.RESOLVE, PAYMENT.SETTLE, ADDRESS.RESOLVE, NOTIFICATION.CUSTOMER.EMIT) is reachable only from servana_client-main/lib/common/data/backend/servana_api_client.dart, and none appears in the backend parity suite
- **Backend:** servana_api-main/tests/repeat-parity.test.js covers WORKER.AVAILABILITY (:26-63), WORKER.TIME_OFF (:69-105), WORKER.SERVICE_AREA (:111-144), mobile contract protection (:150-183) and the parity middleware (:189-215). Its own TODO block at :217-229 lists four live integration tests, all provider-side, none written.
- **Canonical contract:** The parity suite asserts, per capability, that (a) all equivalent routes delegate to one canonical service and (b) data created via one platform is readable via the others' endpoints.
- **Test gap:** Zero customer-capability parity coverage; zero request-level (as opposed to source-text) parity coverage.

**Recommendation.** Extend tests/repeat-parity.test.js with customer-capability cases mirroring the provider ones — assert one writer per canonical table (booking_addons, booking_timeline_events, booking_audit_events), assert the payments join carries the additional_request_id discriminator everywhere, and assert list/detail ownership agreement. Then add the four live integration tests already listed in the TODO plus their customer equivalents.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-163 · Class F confirmed still live at 799b6aa: otp_code and worker_code are one generator behind two business meanings, and the assignment service returns worker_code under the key otpCode

**P3** · rule §0.12 alias conflicts · REPEAT Class F · fix in **?** · protected release: **no**

Carried forward from the first pass (masterlist SC-107). Re-verified rather than re-reported, because the two secrets now travel in the same response object and the collision is one careless fallback away from showing a customer the wrong code. The client has already absorbed the cost in a hand-written warning comment.


**Recommendation.** Rename the return key at technicianService.ts:694 from `otpCode` to `workerCode` so the wire name matches the column and the meaning. Register both names in the field alias registry (src/utils/fieldParity.ts already hosts this kind of entry) with an explicit conflict policy stating they are distinct entities and must never be merged, per §0.12. Then remove `otpCode` from the customer booking projection entirely as part of REP-02, which retires the collision rather than documenting it.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

