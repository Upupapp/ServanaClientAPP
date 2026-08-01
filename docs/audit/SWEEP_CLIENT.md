# SWEEP — Servana Customer Mobile App

Cross-platform field parity — what the client reads and writes versus what the backend actually sends.

| | |
| --- | --- |
| Target | `Heatclift/ServanaClient` @ `bab66e4` |
| Backend | `servana_api` @ `870fd28` (canonical, §3) |
| Also inspected | admin portal `101016d`, provider web `42fbec9`, provider mobile `451eaf6` |
| Customer web | **UNAVAILABLE** — repo has 0 committed files |
| Findings | 21 |

**P1: 10 · P2: 6 · P3: 5**

## SC-021 · 'Pay Now' CTA is unreachable on booking detail — `_needsPayment` can never be true

**P1** · rule §43 / §20 · fix in **backend** · protected release: **no**

A customer with an unpaid GCash/PayMongo booking has no way to complete payment from the booking detail screen: the Pay Now button is gated behind a condition that is structurally unsatisfiable given the backend's value vocabulary.

- **Client:** servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:91-93 `_needsPayment => paymentStatus == 'PENDING' && paymentMethodUsed == 'PAYMONGO'`, where `paymentMethodUsed` is set at :168 from `b['paymentMethod'] ?? b['paymentMethodUsed']`. Gates the payment button at :647, the status label at :807, the amount colour at :598 and assignment polling at :136.
- **Backend:** servana_api-main/src/services/bookingService.ts:21 (`paymentMethod: "CASH" | "GCASH"`) and servana_api-main/src/services/paymentService.ts:362 (PayMongo row inserted with `method` unset) — neither `bookings.payment_method` nor `payments.method` can ever equal 'PAYMONGO', so the guard is dead.
- **Other:** servana_client-main/lib/common/data/backend/http_backend.dart:383 uses the correct broader test (`PAYMONGO || GCASH`) for the PENDING_OTP case, so the bookings LIST does surface 'Payment Required' while the DETAIL screen never does — two screens of the same app disagree about the same booking.
- **Canonical contract:** Payment-required state must be derived from `paymentStatus == 'PENDING'` plus a non-cash method, not from a processor name the backend does not put in that field.
- **Test gap:** No widget/unit test asserts the Pay Now CTA appears for a PENDING GCash booking.

**Recommendation.** Fix at the backend by making the processor visible in a field the client already reads (previous finding). If the client is touched at a future scheduled release, change :93 to `paymentMethodUsed != 'CASH'` so it matches the list mapper's logic at http_backend.dart:383.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-022 · `GET /api/services/:id/options-with-addons` — client path has one more segment than the registered route (404) — **FIXED** in `65b4337`

**P1** · rule §4 (route contract) / §61 · fix in **backend** · protected release: **no**

The aircon add-on picker, the Beauty & Wellness add-on picker and the Category Experience screen all fetch options from a URL that does not match any registered route. The add-on catalog is empty in all three flows.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:262-266 builds `/api/services/$serviceId/options-with-addons`; consumed by aircon_booking_store.dart:257 (`loadOptionsWithAddons`, which sets `errorMessage` and leaves `optionsWithAddons` empty on throw), bw_booking_store.dart:233 and category_experience_repository.dart:18
- **Backend:** servana_api-main/src/routes/service.route.ts:12 registers `router.get("/:serviceId/options-with-addons", …)` on a router mounted at bare `/api` (src/app.ts:103) — i.e. it answers `/api/:serviceId/options-with-addons`, two segments, not three. Grepping the whole backend for `options-with-addons` returns only this one registration (plus a comment at providerCatalog.routes.ts:11). No path-rewriting middleware exists — src/middleware/requestParityMiddleware.ts only aliases field NAMES in body/query, never URLs.
- **Other:** 0 hits for `options-with-addons` in servana_adminportal and Servana.com.ph — ServanaClient is the only caller, so the mismatch has never surfaced elsewhere.
- **Canonical contract:** Catalog read routes are namespaced under `/api/services/:serviceId/...` (as `/services/:serviceId/level2` and `/services/:serviceId/branches` already are). `options-with-addons` is the only sibling missing the `/services` prefix.
- **Test gap:** No route test exercises the exact URL string the mobile client builds. Add a customer-mobile-contract test that asserts 200 for every literal path in servana_api_client.dart.

**Recommendation.** Backend, additive and release-free: register the missing alias `router.get("/services/:serviceId/options-with-addons", serviceController.listOptionsWithAddons)` in servana_api-main/src/routes/service.route.ts alongside line 12. Keep the existing 2-segment route registered — per SEO/protected-endpoint policy it must not be removed until telemetry proves no client uses it.

## SC-023 · `paymentMethod` value vocabulary diverges: 'PAYMONGO' is never written to `payments.method` or `bookings.payment_method`

**P1** · rule §43 (payment status/method/evidence are distinct concepts) / §13 (no per-platform status models) · fix in **backend** · protected release: **no**

Three consumers (customer mobile, provider mobile, admin portal) all branch on `paymentMethod == 'PAYMONGO'`, but the backend stores that value in a different column (`payments.provider`) and never in the field they read. Every PAYMONGO branch on every platform is unreachable, and the admin portal's PAYMONGO payment filter silently returns nothing.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:392, :401 and :487 all branch on `paymentMethod == 'PAYMONGO'` (value read from `b['paymentMethod']`); servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:93 and :795 do the same
- **Backend:** servana_api-main/src/services/bookingService.ts:15-24 types the create payload as `paymentMethod: "CASH" | "GCASH"` and writes that value to `bookings.payment_method` (:71-92). servana_api-main/src/services/paymentService.ts:362 inserts the PayMongo row with `provider='PAYMONGO'` and leaves `method` NULL; `method` is only ever set to 'GCASH' (:62) or 'CASH' (:115). So 'PAYMONGO' exists only in the `provider` column and can never appear in `paymentMethod`.
- **Other:** servana_adminportal/src/app/core/dto/admin-finance.dto.ts:16 declares `PaymentMethod = 'GCASH' | 'CASH' | 'PAYMONGO'` and servana_adminportal/src/app/pages/finance/pages/payments/payments.component.html:13 offers a PAYMONGO filter — but servana_api-main/src/services/adminFinanceService.ts:242 filters on `p.method = ?`, so that filter matches zero rows. ServanaWorker/lib/features/homepage/presentation/screens/pages/job_details.dart:848 has the same dead 'PAYMONGO' case.
- **Canonical contract:** Either (a) `paymentMethod` value set is `{CASH, GCASH}` and the processor is exposed separately as `paymentProvider` ∈ `{PAYMONGO}`, registered as its own parity group; or (b) `payments.method` is populated with 'PAYMONGO' for provider-initiated rows. Pick one and make all four platforms read it.
- **Test gap:** No test asserts the enumerated value set of `paymentMethod` matches what any client switches on. Add a shared value-domain test pinning `{CASH,GCASH}` for `payments.method`/`bookings.payment_method` and `{PAYMONGO}` for `payments.provider`.

**Recommendation.** Backend, additive: add a `paymentProvider` parity group (`payment_provider`, `provider`) and surface `payments.provider` on the payment/booking read models; and populate `payments.method` at servana_api-main/src/services/paymentService.ts:362 so PayMongo rows are not method-NULL (they are currently excluded from every admin method filter, including the GCASH review queue at adminFinanceService.ts:318). Do not rename `paymentMethod` — that would break both live mobile apps (§4).

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-024 · `totalAmount` is not a registered alias of `finalPrice` — customer booking detail renders ₱0.00 for every booking

**P1** · rule §4 (additive compatibility) / §9 (no duplicate reality) · fix in **backend** · protected release: **no**

The customer app reads the booking amount under the name `totalAmount`. No backend response ever contains that key, and `totalAmount` is missing from the `finalPrice` parity group, so the response-parity middleware never synthesises it. Every booking detail screen therefore shows ₱0.00 while the bookings LIST screen shows the correct amount (it reads `finalPrice ?? quotedPrice` at http_backend.dart:464).

- **Client:** servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:216 (`totalAmount: (b['totalAmount'] as num?)?.toDouble() ?? 0`) rendered at :588 (`'₱${booking.totalAmount.toStringAsFixed(2)}'`); same read in servana_client-main/lib/common/domain/booking/customer_booking.dart:219
- **Backend:** servana_api-main/src/utils/fieldParity.ts:198-202 — the `finalPrice` group lists aliases `final_price, quotedPrice, quoted_price, bookingAmount, booking_amount` but NOT `totalAmount`; servana_api-main/src/services/bookingService.ts:483-511 (`formatBooking`) emits only `finalPrice`/`quotedPrice`, and `parityMiddleware` (src/middleware/parityMiddleware.ts:50-65) can only add names present in the registry
- **Other:** ServanaWorker/lib/features/homepage/data/models/bookingrequest_model.dart:166-167 reads the same concept as `_pickNum(json, ['totalAmount','total','finalPrice'])` — provider mobile survives only because it has a `finalPrice` fallback; the customer app has none. Admin uses a third name (`quotedPrice`/`finalPrice`, servana_api-main/src/services/adminBookingService.ts:390-391)
- **Canonical contract:** PARITY_REGISTRY group `finalPrice` → aliases `['final_price','quotedPrice','quoted_price','bookingAmount','booking_amount','totalAmount','total_amount']`. Four platforms already use four names for one concept; the registry must cover all of them.
- **Test gap:** No test asserts that a customer booking response contains a non-null amount under every registry alias. Add a parity contract test that runs `applyContextSafeParity(formatBooking(row))` and asserts `totalAmount`, `finalPrice`, `quotedPrice` and `bookingAmount` are all present and equal.

**Recommendation.** Add `totalAmount` (and `total_amount`) to the `finalPrice` group in servana_api-main/src/utils/fieldParity.ts:198-202, then mirror into servana_adminportal/src/app/shared/utils/servana-field-parity.util.ts and Servana.com.ph/src/app/core/utils/servana-field-parity.util.ts. Purely additive: the response middleware will then emit `totalAmount` alongside `finalPrice` and the customer app starts showing the real amount with no client change.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-025 · Booking response carries no `latitude`/`longitude` — live-tracking destination pin resolves to (0,0)

**P1** · rule §39 (do not fabricate coordinates) / §3 · fix in **backend** · protected release: **no**

The tracking screen reads the service destination coordinates from the booking detail response. The backend never sends them, and the client's fallback chain collapses to 0.0 because the seed value is itself a hard-coded 0. The live-tracking map plots the customer's destination at Null Island in the Gulf of Guinea.

- **Client:** servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:214-215 `latitude: (b['latitude'] as num?)?.toDouble() ?? 0` → :333-334 passes `_booking?.latitude` (= 0.0, not null) as `serviceLatitude` into TrackingArgs; servana_client-main/lib/modules/tracking/data/tracking_repository.dart:76-78 `(b['latitude'] as num?)?.toDouble() ?? seedLatitude ?? 14.5995` — seed is 0.0 so the Manila fallback is dead and the destination becomes (0.0, 0.0). Same invention in servana_client-main/lib/common/data/backend/http_backend.dart:480-481 (`latitude: 0, longitude: 0`).
- **Backend:** servana_api-main/src/services/bookingService.ts:204-236 and :321-352 select no coordinate columns, and no code path anywhere in servana_api-main writes `bookings.latitude`/`bookings.longitude`. Coordinates live in MongoDB keyed by `location_id` (src/services/address.service.ts:235-245 `getLatLonByLocationId`) and, for admin-created bookings, inside `bookings.service_address` JSONB (src/services/adminCreateBookingService.ts:615-616 `{ addressLine, city, lat, lon, locationId }`).
- **Other:** servana_api-main/src/services/technicianService.ts:614-636 already resolves booking coordinates server-side to compute `eta_minutes`, proving the data is reachable from the booking row.
- **Canonical contract:** Customer booking detail returns `latitude` and `longitude` (service destination) alongside `addressOne`/`postTown`, derived server-side from `location_id` or `service_address`.
- **Test gap:** No test covers the tracking destination when the booking response omits coordinates. Add a repository test asserting the destination is null/unavailable rather than (0,0) when no coordinates are supplied.

**Recommendation.** In servana_api-main/src/services/bookingService.ts `getBookingById`, resolve coordinates server-side — `COALESCE((service_address->>'lat')::float8, <mongo lookup by location_id>)` — and return them as `latitude`/`longitude`. The client already reads `b['latitude']`/`b['longitude']`, so this is additive and needs no protected release. Separately consider adding a `latitude`/`longitude` parity group so `lat`/`lon` (the names address.service.ts:270-271 already uses) resolve to the same concept.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-026 · Bookings list invents the service name — every booking without addons is labelled 'Beauty & Wellness'

**P1** · rule §3 (frontend must not establish authoritative business state) · fix in **client-mobile** · protected release: **yes**

An aircon booking with no add-ons is displayed in the customer's Bookings list as 'Beauty & Wellness' — a hard-coded literal, not data. The customer sees a different service name than the admin portal shows for the same booking (§9 duplicate reality), and the value is fabricated rather than backend-confirmed (§3).

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:452 `String serviceName = 'Beauty & Wellness';` — only overwritten at :455-459 when `pricingBreakdown.addons[0].level_3` exists; assigned to `merchantServiceName` at :482
- **Backend:** servana_api-main/src/services/bookingService.ts:483-511 — `formatBooking` returns no service-name field at all, so the client has nothing authoritative to read (see previous finding)
- **Other:** servana_api-main/src/services/adminBookingService.ts:382 returns the true `serviceName`; the admin portal shows the correct name for the same booking that the customer app labels 'Beauty & Wellness'
- **Canonical contract:** Service name is backend-owned (services.name / service_options.level_3). No client may substitute a hard-coded category literal.
- **Test gap:** No test asserts the list mapper prefers a backend-supplied service name over the literal default.

**Recommendation.** Backend: ship the `serviceName` join above (previous finding) so the canonical value is on the wire. Client (next scheduled customer-mobile release, do not cut a release for this alone per §2): change http_backend.dart:452 to read `b['serviceName'] ?? b['merchantServiceName']` first and remove the 'Beauty & Wellness' literal, keeping the pricingBreakdown path only as a fallback.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-027 · Customer booking payload omits `serviceName`/`serviceCategory` — admin and provider get them, customer does not

**P1** · rule §9 (no duplicate reality) / §3 (backend is canonical) · fix in **backend** · protected release: **no**

The backend already resolves the booking's service name for the admin portal and the provider job card, but the two customer booking endpoints never join the catalog tables. The customer app's 'Service' field is therefore always empty on the booking detail screen.

- **Client:** servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:201-205 reads `b['serviceName']` and falls back to `''`, rendered as the 'Service' row at :548; servana_client-main/lib/common/domain/booking/customer_booking.dart:204-213 reads `serviceName|merchantServiceName|service_name` and `serviceCategory|categoryName|merchantName`
- **Backend:** servana_api-main/src/services/bookingService.ts:321-352 (`getBookingsByUserId`) and :204-236 (`getBookingById`) select `b.*` plus payment/branch/address/worker columns but perform NO join to `service_options`/`services`, so no service name is in the row. Contrast servana_api-main/src/services/adminBookingService.ts:307-309 (`s.name AS service_name`, `so.level_3 AS specific_service_name`) surfaced at :382, and servana_api-main/src/controllers/providerController.ts:173-174 (`serviceName`, `categoryName`) for the provider job card.
- **Other:** ServanaWorker/lib/features/homepage/data/models/bookingrequest_model.dart:112-117 successfully resolves the service name from the provider job card because the backend sends it there.
- **Canonical contract:** Every booking read model — customer, provider and admin — returns `serviceName` (services.name) and `specificServiceName`/`serviceType` (service_options.level_3). Registry group `serviceName` already declares aliases `service_name, level2, level_2, name`.
- **Test gap:** No contract test pins the field set of the customer booking read model. Add a customer-mobile-contract test asserting `serviceName` is non-null for a booking with a valid `service_option_id`.

**Recommendation.** Add `LEFT JOIN service_options so ON so.id = b.service_option_id LEFT JOIN services s ON s.id = so.service_id` and select `s.name AS service_name, so.level_3 AS specific_service_name` in servana_api-main/src/services/bookingService.ts:204-236 and :321-352. Additive columns only; `formatBooking` + parity middleware will expose them as `serviceName`/`service_name`/`name`. Fixes the booking detail screen with no client change.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-028 · Customer notification taxonomy: client recognises 22 types, backend emits exactly 1

**P1** · rule §45 (notification canonical pattern) / §9 · fix in **backend** · protected release: **no**

21 of the client's 22 notification types and 7 of its 8 route targets are unreachable. A customer is never notified when a provider is assigned, when the provider is en route, when service starts or completes, when payment is confirmed or fails, or when a message arrives — the client-side handling for all of these already exists and is wired.

- **Client:** servana_client-main/lib/modules/notifications/domain/notification_type.dart:26-74 maps 22 wire strings (`booking_confirmed`, `booking_cancelled`, `provider_assigned`, `provider_en_route`, `service_started`, `service_completed`, `payment_paid`, `payment_failed`, `message_received`, `support_update`, …); servana_client-main/lib/modules/notifications/domain/notification_target.dart:37-59 handles 8 routeKeys (`BOOKING_TRACKING`, `PAYMENT_DETAILS`, `PAYMENT_ACTION`, `CONVERSATION`, `CATEGORY`, `NOTIFICATION_SETTINGS`, `SECURITY_SETTINGS`, `SUPPORT_TICKET`)
- **Backend:** `createCustomerNotification` (servana_api-main/src/services/notification.service.ts:744) has exactly ONE call site in the whole backend: servana_api-main/src/controllers/bookingController.ts:38-46, emitting `type: 'booking_created'` with `routeKey: 'BOOKING_DETAILS'`. By contrast `createNotification` (provider side) has 11 call sites.
- **Other:** servana_api-main/src/services/paymentService.ts:97-105 fires an 'earnings_payout' notification to the assigned PROVIDER on payment approval, but no matching customer notification is created — the two sides of the same event are asymmetric.
- **Canonical contract:** Every canonical booking/payment/assignment/message state transition writes BOTH a provider notification and a customer notification from the same domain service, using the customer type vocabulary already implemented in the client.
- **Test gap:** No test enumerates which customer notification types the backend can actually produce. Add a test asserting each client-recognised type has at least one backend producer, or is explicitly listed as intentionally unimplemented.

**Recommendation.** Backend only: add `createCustomerNotification` calls alongside the existing provider notifications at the assignment (technicianService.ts:624, :931), start (:1139), completion (:1204) and payment (paymentService.ts:97-105, webhook :473) transitions, reusing the client's existing type strings and routeKeys. Entirely additive — the client already parses them.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-029 · Linked guest bookings appear in the customer's list but 403 on tap — 880d5bc fixed the query and left the access check behind — **FIXED** in `a062ef9`

**P1** · rule §8 guest customer / §9 no duplicate reality / §11 fail closed · fix in **?** · protected release: **no**

880d5bc made the bookings list correctly surface admin-linked guest bookings, but resolveBookingAccess still authorises only on bookings.user_id, so every one of those bookings returns 403 the moment the customer taps it.


**Recommendation.** Extend resolveBookingAccess in servana_api-main/src/services/bookingAccessService.ts:66-75 with the same linkage the list query uses: after the user_id check, `SELECT 1 FROM guest_customers gc JOIN bookings b ON b.guest_customer_id = gc.guest_customer_id WHERE b.id = $1 AND gc.linked_customer_uid = $2` and return 'customer' on a hit. Use the audited link column only (linked_customer_uid, set at adminGuestService.ts alongside linked_at/linked_by_admin_uid) — never phone. Backend-only, no protected release. Add an authorization test that a linked guest booking is readable by the linked customer and a non-linked one is not, so list and detail cannot drift apart again.

## SC-030 · Provider live-location response nests the GPS doc under `location`; the client only accepts it at the root or under `data` — the tracking map's provider pin is null on every fetch

**P1** · rule §9 no duplicate reality / §3 backend canonical / §20 no ghost success · fix in **?** · protected release: **no**

GET /api/workers/location/:uid returns the GPS doc under `location`, but GeoPositionSnapshot.fromApiMap only reads `loc` at the root or under `data`, so the client's provider-location parse returns null on every call and the live-tracking map never shows a provider pin.


**Recommendation.** Backend-only and additive, no protected release (§2). In servana_api-main/src/controllers/technicianController.ts:177-180 spread the camel-cased doc alongside the existing wrapper — `res.json({ success: true, location: doc, ...doc })` — so `loc`, `uid`, `isOnline` and `updatedAt` also appear at the root where geo_position_snapshot.dart:47 already looks. Keep the `location` key so any other consumer is unaffected (§4). Then fix servana_client-main/test/modules/tracking/domain/geo_position_snapshot_test.dart to feed the real `{success, location:{...}}` envelope, otherwise the suite will keep certifying the break. Consider registering a parity group `loc → [location, position, geo]` so the two names converge for future readers.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-108 · Booking reference diverges between the app's own two screens: list shows `BK-<id>`, detail shows `SVN-000<id>`

**P2** · rule §9 (no duplicate reality) / §3 · fix in **client-mobile** · protected release: **yes**

The customer sees `BK-123` in their Bookings list and `SVN-000123` on the detail page for the same booking, and support/admin only ever knows the `SVN-` form. The canonical value is already in the list response and is simply ignored.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:471 `jobOrderNumber: 'BK-$id'` — the list mapper fabricates the reference and never reads `bookingCode`, which is present in the same response. The detail screen does it correctly: servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:196-198 reads `b['bookingCode']`.
- **Backend:** servana_api-main/src/services/bookingService.ts:497 — `formatBooking` always sets `bookingCode: c.bookingCode ?? \`SVN-${String(bookingPk).padStart(6,'0')}\``, and servana_api-main/src/controllers/bookingController.ts:140 applies `formatBookings` to the list response too, so `bookingCode` IS on the wire for both endpoints.
- **Other:** servana_api-main/src/utils/fieldParity.ts:193-197 registers `bookingCode` with aliases `booking_code, referenceNo, reference_no` — the admin portal displays `referenceNo` (i.e. `SVN-…`). Nothing anywhere produces the `BK-` prefix.
- **Canonical contract:** One booking → one human-readable reference, `bookingCode` (`SVN-XXXXXX`), identical on every surface.
- **Test gap:** No test asserts the list and detail screens render the same reference for one booking.

**Recommendation.** Backend needs no change. At the next scheduled customer-mobile release (do not cut one for this alone, §2) change http_backend.dart:471 to `jobOrderNumber: b['bookingCode']?.toString() ?? 'SVN-${id.padLeft(6,'0')}'`.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-109 · Customer app reads five booking fields that no backend response anywhere produces

**P2** · rule §9 / §56 · fix in **backend** · protected release: **no**

Five aliases the customer app reads are dead everywhere in the system. The provider-name gap forces a second round-trip: booking_detail_screen.dart:284-304 calls `GET /api/workers/:uid` purely to obtain the assigned provider's name and phone, which the admin booking read model already returns inline as `providerName`/`providerPhone`.

- **Client:** servana_client-main/lib/common/domain/booking/customer_booking.dart:192-193 (`servicePhoto`, `merchantServicePhoto`), :211 (`merchantName`), :228 (`workerPhone`), :218 (`fullAddress`); servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:206-212 (`merchantName`, `servicePhotoUrl`, `servicePhoto`) rendered as the 'Brand' row at :549; servana_client-main/lib/modules/tracking/data/tracking_repository.dart:86-90 (`workerName`, `workerPhone`)
- **Backend:** Grep over all of servana_api-main/src returns 0 occurrences of `servicePhoto`, `merchantServicePhoto`, `merchantName`, `workerPhone` and `fullAddress`. `workerName` exists only as a local variable in servana_api-main/src/services/technicianService.ts:668,984 and servana_api-main/src/services/adminBookingService.ts:1137 (used to build an email/notification body, never returned on a booking).
- **Other:** servana_api-main/src/services/adminBookingService.ts:375-376 returns `providerName`/`providerPhone` on the admin booking read model — the concept exists, under different names, for admin only.
- **Canonical contract:** Assigned-provider display data on a booking is `workerName`/`workerPhone` (aliases `providerName`, `provider_name`, `worker_name`, `providerPhone`, `provider_phone`); service imagery is `servicePhotoUrl` (aliases `servicePhoto`, `service_photo_url`). Neither concept currently has a registry group.
- **Test gap:** No test asserts the booking detail screen renders provider name without a second network call.

**Recommendation.** Backend: (1) join `user_credentials wu ON wu.uid = b.worker_uid` in bookingService.ts:204-236 and return `worker_name`/`worker_phone`; (2) add registry groups `workerName → [worker_name, providerName, provider_name]` and `workerPhone → [worker_phone, providerPhone, provider_phone]` so all four platforms converge; (3) either populate `servicePhotoUrl` from the catalog or record `servicePhoto`/`merchantServicePhoto`/`merchantName`/`fullAddress` as deliberately unimplemented so they are not mistaken for parity gaps later. §58: return only the fields the detail view needs — do not add provider phone to the LIST response.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-110 · Customer mobile generates the canonical `locationId` and supplies raw coordinates the backend persists unvalidated

**P2** · rule §38 / §39 / §42 · fix in **backend** · protected release: **no**

§42 requires `locationId` to be generated canonically in the backend, and §39 forbids trusting client-entered coordinates as authoritative. The customer app computes the ID itself and the backend persists it and the coordinates without any resolution step, so the same canonical identifier has two independent producers with different validation.

- **Client:** servana_client-main/lib/common/data/repositories/address_repository.dart:65-82 — the payload sets `'locationId': 'loc_${lat.toStringAsFixed(6)}_${lon.toStringAsFixed(6)}'` plus `'lat'`/`'lon'` from the device, and hard-codes `'zipCode': ''` and `'country': 'Philippines'`. Duplicated at servana_client-main/lib/common/data/backend/http_backend.dart:220-221.
- **Backend:** servana_api-main/src/services/address.service.ts:9-53 (`addUserAddress`) stores `locationId ?? null` verbatim and writes the client-supplied `lat`/`lon` straight to MongoDB at :39-43 — no geocoding, no validation, no derivation. Contrast servana_api-main/src/services/adminCreateBookingService.ts:615-616 where the backend generates `loc_${lat.toFixed(6)}_${lon.toFixed(6)}` itself from server-side resolved coordinates, and src/routes/location.routes.ts:9-10 which keeps the geocoding credentials server-side for the web portals.
- **Other:** servana_api-main/src/routes/location.routes.ts:8 comments 'web-only (mobile does not call these routes)' — confirming there are two producers of the same canonical ID with different trust levels.
- **Canonical contract:** `locationId` is derived exactly once, in the backend, from a backend-resolved coordinate pair. Clients submit a human-readable address (plus optional device coordinates as a hint) and the backend returns `locationId`, `lat`, `lon`.
- **Test gap:** No test asserts that a client-supplied `locationId` is ignored/recomputed. Add an address test posting a deliberately wrong `locationId` and asserting the stored value is backend-derived.

**Recommendation.** Backend: in `addUserAddress`/`updateUserAddress` (address.service.ts:9,56) geocode `addressOne`+`postTown`+`country` server-side and derive `locationId` from the resolved coordinates, treating any client-supplied `locationId`/`lat`/`lon` as a hint only. The response already returns `locationId`/`lat`/`lon` (formattedAddress, address.service.ts:259-270) which the client reads back, so this is behaviour-compatible and needs no protected release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-111 · Parity registry mirrors are out of sync — `token` and `email` groups exist only in the backend

**P2** · rule SWEEP Registry sync (command_servana_seo.md step 5) / §61 · fix in **admin** · protected release: **no**

The SWEEP procedure requires the two frontend mirrors to stay byte-for-byte in sync with the backend registry. They have drifted by two groups. No customer-mobile impact today (mobile relies on the backend middleware, not the Angular interceptors), but any future registry change made only in one place compounds the drift, and the admin/provider-web interceptors will not normalise `token`/`email` aliases.

- **Client:** servana_client-main/lib/modules/profile/data/profile_repository.dart:62 reads `email|emailAddress|email_address` and servana_client-main/lib/common/data/models/user_session.dart stores `emailAddress` — the customer app depends on the `email→emailAddress` alias the backend middleware injects
- **Backend:** servana_api-main/src/utils/fieldParity.ts:36-40 (`token` group) and :43-47 (`email` group) — 58 groups total in PARITY_REGISTRY
- **Other:** servana_adminportal/src/app/shared/utils/servana-field-parity.util.ts and Servana.com.ph/src/app/core/utils/servana-field-parity.util.ts each contain 56 groups; a canonical-name diff shows both are missing exactly `token` and `email`
- **Canonical contract:** `PARITY_REGISTRY` in the backend and the two Angular mirror files must contain the identical group array.
- **Test gap:** There is no automated check that the three registries match — this drift was silent. The meta-test is the fix.

**Recommendation.** Copy the `token` and `email` groups from servana_api-main/src/utils/fieldParity.ts:36-47 into both mirror files, then run `npx tsc --noEmit` in all three repos. Add a CI meta-test that fails when the three canonical-name lists differ.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-112 · Parity registry mirrors remain two groups behind the backend and there is still no CI check

**P2** · rule SWEEP registry sync (command_servana_seo.md step 5) / §61 · fix in **?** · protected release: **no**

The two Angular parity-registry mirrors still omit the backend's `email` and `token` groups (58 vs 56), and no automated check yet exists to stop the next edit from widening the gap.


**Recommendation.** Copy the `token` and `email` groups from servana_api-main/src/utils/fieldParity.ts:36-47 into both mirror files, then run `npx tsc --noEmit` in all three repos (§60). Fold this into the same edit as the totalAmount alias above. Add a CI meta-test that extracts the canonical-name list from all three files and fails on any difference — the first pass flagged this drift as silent, and it is still silent.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-113 · The authenticated successor route repeats the same `location` wrapper, so the worker-route migration cannot be completed without a protected client release

**P2** · rule §2 protected release / §4 additive compatibility / §61 · fix in **?** · protected release: **yes**

GET /api/booking/:bookingId/provider-location uses the same unparseable `location` wrapper as the legacy route it is meant to replace, so migrating the customer app off the unauthenticated route requires a protected mobile release the migration plan assumes it can avoid.


**Recommendation.** Apply the same root-level spread to providerLocationAccessController.ts:85 that SW2-01 recommends for the legacy handler, so both routes emit an identical, client-parseable body and the client can be repointed by URL alone at a future scheduled release. Keep `assigned` as an additive top-level flag. Until then, record in docs/WORKER_ROUTE_MIGRATION.md that step 4 is blocked on a customer-mobile release, rather than on telemetry.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-156 · `currency` is invented client-side on customer bookings while every other platform receives it from the backend

**P3** · rule §59 (canonical currency) / §3 · fix in **backend** · protected release: **no**

The customer booking model hard-codes PHP because the customer booking payload is the only money-bearing read model in the system that omits `currency`. Harmless today (Servana is PH-only per §59) but it is a frontend-owned business value, and the omission is inconsistent with the provider and admin payloads.

- **Client:** servana_client-main/lib/common/domain/booking/customer_booking.dart:220 `currency: (json['currency'] as String?) ?? 'PHP'` — the fallback is always taken
- **Backend:** servana_api-main/src/services/bookingService.ts:483-511 (`formatBooking`) never emits `currency`; contrast servana_api-main/src/controllers/providerController.ts:184,255,326,380,430,463,498 and src/services/adminBookingService.ts:594 and src/services/adminDashboardService.ts:554, all of which return `currency: 'PHP'` explicitly
- **Other:** servana_api-main/src/services/adminDashboardService.ts:64 types it as the literal `currency: 'PHP'`
- **Canonical contract:** Every money-bearing read model returns `currency`. It should be a parity group (`currency → currency_code, currencyCode`) so the value is never assumed by a client.
- **Test gap:** No test asserts money-bearing read models all carry a currency field.

**Recommendation.** Add `currency: 'PHP'` to `formatBooking` in servana_api-main/src/services/bookingService.ts:494. One line, additive, no release.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-157 · `formatBooking` is applied to booking_tracking rows, fabricating `bookingCode: "SVN-undefined"` on the customer tracking response

**P3** · rule §3 backend canonical / SWEEP formatter rule (command_servana_seo.md step 2) · fix in **?** · protected release: **no**

The customer tracking endpoint runs booking_tracking rows through formatBooking, which unconditionally synthesises a booking code from an undefined primary key and emits the literal string "SVN-undefined" on every tracking event.


**Recommendation.** In servana_api-main/src/controllers/bookingController.ts:161 stop reusing the booking formatter for tracking rows — return `tracking.map(toCamel)`, or add a dedicated `formatTrackingEvent`. Defensively, guard line 508 the same way line 507 is guarded so `bookingCode` is omitted rather than fabricated when there is no PK. Purely additive removal of a bogus field; no client reads it.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-158 · `fullname` is bridged by ad-hoc service code instead of the parity registry, and splits names naively

**P3** · rule SWEEP Registry audit (step 1) · fix in **backend** · protected release: **no**

The `fullname ↔ firstName/lastName` bridge works but lives outside the registry, so it is invisible to the parity middleware, to the two Angular mirrors, and to anyone auditing field coverage. The naive first-space split also mis-assigns multi-word given names ('Maria Clara Santos' → firstName 'Maria', lastName 'Clara Santos'), which the client then reads back as a changed name.

- **Client:** servana_client-main/lib/modules/profile/data/profile_repository.dart:19-32 writes `{'fullname': …, 'mobileNumber': …}`, but reads back `firstName`/`lastName` at :61-62 — the write shape and the read shape are different concepts
- **Backend:** servana_api-main/src/services/user.service.ts:299-311 special-cases `fullname` in the service layer, splitting on the first space (`firstName = slice(0, spaceIdx)`, `lastName = slice(spaceIdx+1)`); servana_api-main/src/types/type.d.ts:79 documents it as 'ServanaClient combined name — split on write'. `fullname` has no group in servana_api-main/src/utils/fieldParity.ts.
- **Other:** servana_api-main/src/services/firebaseFunctions.service.ts:69,123,181 also emit `fullname` (joined from firstName+lastName) in auth responses, so it is a genuine two-way cross-platform concept with three producers. `mobileNumber` by contrast IS registered (fieldParity.ts:72) and is additionally hand-normalised at user.service.ts:296-298 — belt-and-braces on one field, registry-less on the other.
- **Canonical contract:** Register `fullname → [full_name, displayName, display_name]` as a derived group, and keep the split logic in one shared helper rather than inline in `updateUserProfile`.
- **Test gap:** No round-trip test writes `fullname` and asserts `firstName`/`lastName` read back consistently for multi-word names.

**Recommendation.** Add the group to fieldParity.ts and both mirrors, and extract the split into a shared name helper. No client change.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-159 · Provider-profile projection drops `email`, removing the last name fallback on the booking detail screen

**P3** · rule §58 privacy (the removal is correct) / §4 (the client-visible delta is new) · fix in **?** · protected release: **no**

65b4337 correctly withholds the provider's email from customers, which as a side effect kills the third rung of the client's provider-name fallback chain, so a provider with blank name fields now displays as 'Technician'.


**Recommendation.** No backend change; do not re-add email. If a display name is wanted for name-blank providers, the correct fix is the one already recommended under first-pass SC-083: return `worker_name` inline on the booking read model (join user_credentials on bookings.worker_uid in servana_api-main/src/services/bookingService.ts:209-225) and register a `workerName → [worker_name, providerName, provider_name]` parity group. That also removes the extra round-trip booking_detail_screen.dart:287 makes purely to learn a name.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-160 · Three more booking fields fabricated by the customer app: `downPayment`, `numberOfPersonnel`, `distanceFromOffice`

**P3** · rule §3 · fix in **none** · protected release: **no**

Three fields on the legacy `JobOrder` model are pure client-side constants. They are not currently displayed prominently, but they are frontend-owned business values that will silently misinform if ever surfaced.

- **Client:** servana_client-main/lib/common/data/backend/http_backend.dart:483-486 hard-codes `numberOfPersonnel: 1, distanceFromOffice: 0, downPayment: 0`; servana_client-main/lib/modules/bookings/presentation/screens/booking_detail_screen.dart:217-220 reads `b['downPayment']`/`b['numberOfPersonnel']` which no backend response contains, defaulting both to 0
- **Backend:** Grep over servana_api-main/src returns 0 occurrences of `downPayment`, `numberOfPersonnel` and `distanceFromOffice`. The nearest real concepts are `pricing_breakdown.transpo_fee`/`worker_distance` (servana_api-main/src/services/bookingService.ts:66) and `best.distanceKm` (src/services/technicianService.ts:636).
- **Other:** n/a — no other platform reads these names
- **Canonical contract:** Either map these to the real backend concepts (`workerDistanceKm` from `pricing_breakdown.worker_distance`) or drop them from the customer model.

**Recommendation.** Low priority. Either surface `pricing_breakdown.worker_distance` under a registered `workerDistanceKm` group, or mark these as legacy-model dead fields in the client's next cleanup pass so a future reader does not treat them as data.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

