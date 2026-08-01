# LEAK — Servana Customer Mobile App

Server-side authorization and cross-user isolation. The backend was inspectable, so these are verified rather than inferred.

| | |
| --- | --- |
| Target | `Heatclift/ServanaClient` @ `bab66e4` |
| Backend | `servana_api` @ `870fd28` (canonical, §3) |
| Also inspected | admin portal `101016d`, provider web `42fbec9`, provider mobile `451eaf6` |
| Customer web | **UNAVAILABLE** — repo has 0 committed files |
| Findings | 16 |

**P0: 7 · P1: 5 · P2: 2 · info: 2**

## SC-005 · ANSWER TO OPEN QUESTION — PUT /api/workers/bookings/:id/{accept,start,complete,decline} has NO auth middleware and the ?workerUid= query param is never validated against any JWT — **CONFIRMED**

**P0** · rule §11, §12, §7, §22 · fix in **backend** · protected release: **no**

Definitive answer: the backend does NOT validate ?workerUid= against the JWT subject — there is no JWT at all on these routes. No auth middleware runs, so `req.user` is undefined and the controller reads the actor identity entirely from the attacker-controlled query string. Any anonymous caller who knows a sequential integer bookingId and any workerUid can decline, accept, start, or complete any job. `completeJob` writes bookings.status='COMPLETED', which is the trigger for disbursement and review eligibility, so this is direct money/booking corruption, not just a read leak. It also destroys §22 assignment integrity (a stranger can decline on a provider's behalf, forcing reassignment).

- **Client:** servana_client-main/lib/common/services/assignment_polling_service.dart:92 — ServanaClient polls GET /api/:bookingId every cycle and renders whatever assignment/status these unauthenticated provider mutations wrote; the customer app has no way to tell a forged transition from a real one
- **Backend:** servana_api-main/src/routes/technician.routes.ts:18-21 (four PUT routes, zero middleware) + src/controllers/technicianController.ts:512 (`const workerUid = req.query.workerUid as string; // or from auth token`) + src/services/technicianService.ts:1220-1224 (completeJob sets bookings.status='COMPLETED' then calls createDisbursement); no global auth gate at src/app.ts:37-90,112
- **Other:** ServanaWorker/lib/core/api/servana_api_config.dart:52 registers `_AuthInterceptor` globally; :74-78 sets `options.headers['Authorization'] = 'Bearer $t'` on EVERY request; ServanaWorker/lib/core/api/servana_api.dart:332,344,355 are the accept/start/complete call sites and go through that same Dio instance
- **Test gap:** No test in servana_api-main/tests covers these four routes. tests/booking-access.test.ts only exercises assertBookingAccess for customer/provider/admin on GET paths. Add request-level tests: (a) no Authorization header → 401; (b) provider B's token + provider A's workerUid → 403; (c) valid provider token whose booking_workers row is DECLINED → 403.

**Recommendation.** Backend-only fix. Add `verifyAuth` to technician.routes.ts:18-21 and change the four controllers to derive `const workerUid = (req as any).user.uid`, keeping the `?workerUid=` param accepted-but-ignored with a non-PII drift warning — exactly the pattern already proven in bookingController.createBooking (bookingController.ts:16-22). Then assert the actor holds an active booking_workers row for the booking, reusing `assertBookingAccess` (bookingAccessService.ts:101) and requiring role 'provider'. Critically: ServanaWorker already sends a bearer token on these exact calls via a global interceptor, so this closes the hole with NO provider-mobile release. The "do NOT add auth" comment at technician.routes.ts:9 is stale and should be deleted so it stops blocking future fixes.

## SC-006 · GET /api/user/:userId/addresses — identical anonymous-bypass; unauthenticated read of any customer's saved home addresses — **FIXED** in `bd8c355`

**P0** · rule §11, §12, §58 · fix in **backend** · protected release: **no**

Same anti-pattern as the bookings route, on more sensitive data. Any anonymous caller who knows a customer uid gets that customer's full saved-address list with coordinates. Customer uids are recoverable from other surfaces, and this route requires nothing else.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:37-47 — `_headers()` attaches the bearer token to every ServanaApiClient call, so the customer app never needs the unauthenticated path. (The app itself reads addresses via the correctly-scoped `/api/user/alluseraddresses`, servana_api_client.dart:163.)
- **Backend:** servana_api-main/src/middleware/verifyAuthOptional.ts:26-27 (`if (!authHeader?.startsWith("Bearer ") && !cookieToken) return next();` — passes through with req.user undefined) + src/controllers/user.controller.ts:168-170 (`if (req.user && req.user.uid !== userId) return 403` — guard short-circuits when req.user is undefined) + src/services/address.service.ts:280-293 (`SELECT * FROM user_address WHERE uid = $1`, scoped only by the attacker-supplied URL param) + src/app.ts:100 (`app.use("/api", cors(corsOptionsDelegate), userRoute)` — no upstream auth middleware)
- **Test gap:** tests/leak-isolation.test.js:227-232 asserts the route USES verifyAuthOptional — it locks in the flaw. Replace with a request-level test asserting 401 when no header is sent.

**Recommendation.** Backend-only. Promote user.route.ts:15 to `verifyAuth` and scope to the token uid (allow role 1 to pass a different userId if the admin portal needs it — verify first). Remove the "mobile may call without token" comment at user.route.ts:14, which is stale for ServanaClient.

## SC-007 · GET /api/users/:userId/bookings — ownership check is skipped entirely when the caller omits the Authorization header — **FIXED** in `bd8c355`

**P0** · rule §11, §12 · fix in **backend** · protected release: **no**

Sending NO token is strictly more privileged than sending a valid one. Any anonymous caller can enumerate any customer's full booking history by uid. The service joins user_address, so the response carries address_one, post_town, country and zip_code alongside worker assignment and payment state — Customer A reads Customer B's home address and entire booking history with a single unauthenticated GET.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:331 builds `/api/users/$userId/bookings` and :332 passes `headers: await _headers()`, which attaches the bearer token from the Hive session (servana_api_client.dart:37-47). The customer app therefore always authenticates on this route — the unauthenticated path exists for nobody.
- **Backend:** servana_api-main/src/controllers/bookingController.ts:133-137 (`const actor = (req as any).user; if (actor?.uid && actor.uid !== userId) return 403` — skipped when actor is undefined), enabled by src/routes/booking.routes.ts:17 (verifyAuthOptional) + src/middleware/verifyAuthOptional.ts:25-28 (pass-through with no token), exploited via src/services/bookingService.ts:352-364 (WHERE b.user_id = $1 bound from req.params) leaking src/services/bookingService.ts:335-338 (address, post_town, country, zip_code from the user_address join at :348-349)
- **Test gap:** tests/leak-isolation.test.js:91-97 asserts only that the string `actor.uid !== userId` appears in the source and that verifyAuthOptional is applied — it pins the vulnerable design in place rather than testing it. Needs a request-level test: no Authorization header → 401, not 200.

**Recommendation.** Backend-only. Change booking.routes.ts:17 to `verifyAuth` and drop the `userId` path segment as an identity source: derive from the token and treat the param as a to-be-ignored legacy alias (same pattern as bookingController.ts:16-22), returning 403 on mismatch for non-admins. ServanaClient already sends the token so no protected release is needed. Delete the stale "unauthenticated mobile calls pass through" comment at booking.routes.ts:15-16.

## SC-008 · POST /api/:bookingId/approve — any authenticated user can mark any booking PAID (no ownership assertion, unlike its sibling payment routes) — **FIXED** in `6d78313`

**P0** · rule §11, §12, §43 · fix in **backend** · protected release: **no**

The route comment at payment.routes.ts:7 claims "the controller asserts the caller owns/serves the booking" — that is true for two of the four routes and false for this one. Any logged-in customer can settle a stranger's booking. paymentService.ts:88-104 then fires an 'earnings_payout' / 'Payment Received' notification to the assigned provider, so the attack also plants a false financial notification in a third party's inbox.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:437 defines `approveGcashPayment` against `/api/$bookingId/approve`. It is currently a dead method (0 call sites in lib/ or test/), so the route exists purely as attack surface from the customer app's perspective — every ServanaClient user holds a token that can call it.
- **Backend:** servana_api-main/src/controllers/paymentController.ts:28-36 (approve — no assertBookingAccess, unlike lines 13 and 51) with servana_api-main/src/routes/payment.routes.ts:9 (verifyAuth only) and servana_api-main/src/services/paymentService.ts:75-84 (UPDATE payments SET status='PAID' WHERE booking_id=$1, no owner predicate)
- **Test gap:** Nothing in tests/ covers payment-route authorization. Add: Customer B's token against Customer A's booking → 403; assert payments.status is unchanged.

**Recommendation.** Backend-only, one line: add `await assertBookingAccess(bookingId, (req as any).user?.uid)` at the top of paymentController.approve (paymentController.ts:30) and `if (sendBookingAccessError(res, e)) return;` in the catch — copying gcashSubmit verbatim. Better still, require role 'admin' here: approving a payment is a staff action, and a customer self-approving their own GCash submission defeats the point of §43's evidence/verification split.

## SC-009 · POST /api/:bookingId/mark-cash-paid — same missing ownership assertion; any authenticated user can force any booking to CASH/PAID — **FIXED** in `6d78313`

**P0** · rule §11, §12, §43 · fix in **backend** · protected release: **no**

Distinct from the approve issue because it also rewrites `method` to CASH, erasing the real payment channel on a booking the caller has nothing to do with, and fires the same false 'Payment Received' provider notification (paymentService.ts:124-141). A booking paid by PayMongo can be silently relabelled as cash-settled by any customer account.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:445 defines `approveCashPayment` against `/api/$bookingId/mark-cash-paid`; also a dead method (0 call sites), but reachable by every ServanaClient token.
- **Backend:** servana_api-main/src/controllers/paymentController.ts:38-46 — `markCashPaid` calls `paymentService.markCashPaid(bookingId)` with no `assertBookingAccess`, unlike `gcashSubmit` (:13) and `createPaymongoPayment` (:51) in the same file; reached via payment.routes.ts:10 (`verifyAuth` only, token-verification only per middleware/verifyAuth.ts:36-38) mounted bare at app.ts:115, executing the unscoped `UPDATE payments SET method='CASH', status='PAID', paid_at=NOW() WHERE booking_id=$1 RETURNING *` at services/paymentService.ts:112-120.
- **Test gap:** Same as the approve route — no coverage. Add an authorization test plus a regression test that a PAID PayMongo payment cannot be downgraded to CASH.

**Recommendation.** Backend-only. Add `assertBookingAccess` + `sendBookingAccessError` to paymentController.markCashPaid (paymentController.ts:40), and gate to role 'admin' or the actively-assigned provider — recording cash receipt is not a customer-initiated action. Also add a state guard so an already-PAID payment cannot have its method rewritten.

## SC-010 · POST /api/bookings/:id/cancel — an anonymous caller can cancel any customer's booking, and the audit row records a NULL actor — **FIXED** in `bd8c355`

**P0** · rule §11, §12, §15, §16 · fix in **backend** · protected release: **no**

Booking-state corruption reachable with no credentials at all. Any anonymous caller can cancel any booking not in NON_CANCELLABLE_STATUSES, which also flips booking_workers rows from ASSIGNED/ACCEPTED to CANCELED — destroying a provider's confirmed job. Because the actor is null, the resulting timeline entry falsely attributes the cancellation to 'customer' with no uid, so the audit trail cannot distinguish a real customer cancellation from an attack (§15/§16).

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:476 builds `/api/bookings/$bookingId/cancel` and sends it with `_headers()` (bearer token attached) — reached from booking_repository.dart:77 ← booking_cancellation_sheet.dart:75. The legitimate client always authenticates.
- **Backend:** servana_api-main/src/services/bookingService.ts:546 — `if (customerUid && ownerId && ownerId !== customerUid) throw Object.assign(new Error('Access denied'), { statusCode: 403 });` reached with customerUid=null via routes/booking.routes.ts:22 (verifyAuthOptional) + middleware/verifyAuthOptional.ts:26-28 (`if (!authHeader?.startsWith("Bearer ") && !cookieToken) return next();`) + controllers/bookingController.ts:197 (`const customerUid = (req as any).user?.uid ?? null`); no global auth at app.ts:109 and TEMP_ID cannot mask it in prod per config.ts:10-12
- **Test gap:** No test covers cancelBooking authorization at all. Add: anonymous → 401; Customer B's token against Customer A's booking → 403; verify the timeline row's actor_uid is non-null.

**Recommendation.** Backend-only. Promote booking.routes.ts:22 to `verifyAuth`, then replace the conditional guard in bookingService.ts:546 with an unconditional `assertBookingAccess(bookingId, actorUid)` (bookingAccessService.ts:101) restricted to role 'customer' or 'admin'. Fail closed: a null actorUid must be rejected, never treated as permission. Persist the real actor_uid on the timeline row.

## SC-011 · POST /api/user/adduseraddress with an addressId performs a cross-user UPDATE — the owner uid is never in the WHERE clause — **FIXED** in `6d78313`

**P0** · rule §11, §12, §41 · fix in **backend** · protected release: **no**

A genuine cross-user WRITE. Any authenticated customer who supplies another customer's addressId overwrites that customer's stored street address, post town, country, label, is_primary flag and location_id — and via updateLocationInDB (address.service.ts:85-89) their MongoDB geo point too. The victim's next booking is then dispatched to an attacker-chosen location. Note the sibling operations were fixed correctly and this one was missed: makeAddressPrimary (address.service.ts:197) and deleteAddress (address.service.ts:224) both carry `AND uid = $2`.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:143 posts to `/api/user/adduseraddress`; called from address_repository.dart:85 and drawer_placeholder_screens.dart:325,388. The client legitimately uses the create branch; the update branch is triggered purely by including `addressId` in the body, which any attacker can do.
- **Backend:** servana_api-main/src/services/address.service.ts:56-59 (`UPDATE ...user_address SET ... updated_by = $8 ... WHERE address_id = $11 returning *` — uid bound only to $8/updated_by, absent from WHERE), reached unguarded via src/controllers/user.controller.ts:25-33 and src/routes/user.route.ts:16 (`verifyAuth` only; src/middleware/verifyAuth.ts:36-37 authenticates without authorizing). Contrast the correctly scoped siblings at address.service.ts:197 and 224.
- **Test gap:** tests/leak-isolation.test.js:48-66 pins the `AND uid = $2` scoping for makeAddressPrimary and deleteAddress but has no equivalent assertion for updateUserAddress — the test file's own pattern would have caught this. Add the matching source assertion plus a DB-level test that Customer B cannot mutate Customer A's address row.

**Recommendation.** Backend-only, one line: change address.service.ts:60 to `WHERE address_id = $11 AND uid = $12` and bind uid, then treat a zero-row result as 403/404 rather than the current generic `throw "Failed to update address"`. Separately, per §41 confirm that editing a profile address does not rewrite the address snapshot on historical bookings.

## SC-055 · All six /api/additional/* customer-and-worker lifecycle routes are completely unauthenticated, including a booking-scoped read

**P1** · rule §11, §12, §43 · fix in **backend** · protected release: **no**

Unauthenticated read of additional-work line items and pricing for any bookingId (sequential integers), plus unauthenticated creation of a chargeable additional-work request against any userId, plus unauthenticated worker-decision/withdraw/confirm-proceed mutations. Rated P1 rather than P0 only because no protected client currently exercises the surface — the exposure itself is cross-user and monetary.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart — grep for 'additional' returns zero hits across the entire file. ServanaClient does not call any of these routes, so nothing in the customer app depends on them staying open.
- **Backend:** servana_api-main/src/routes/additional.routes.ts:9 (`GET /additional/booking/:bookingId`), :12 (`POST /additional/request/:userId`), :13 (`POST /additional/:id/payment`), :14 (`/worker-decision`), :15 (`/withdraw`), :16 (`/confirm-proceed`) — all six registered with no middleware. src/controllers/additional.controller.ts:61-68 (`getByBooking` reads req.params.bookingId with no actor), :4-12 (`createRequest` takes the customer identity from `req.params.userId`, a textbook §7 violation).
- **Test gap:** No coverage whatsoever for /api/additional/*. Add authorization tests for all six routes.

**Recommendation.** Backend-only. Add `verifyAuth` to additional.routes.ts:9-16, derive the customer from the token in createRequest instead of `:userId`, and gate every handler with `assertBookingAccess` (bookingAccessService.ts:101) — customer-role for request/payment, provider-role for worker-decision/withdraw/confirm-proceed. Before shipping, confirm ServanaWorker's usage of these paths; it sends a bearer token globally (ServanaWorker/lib/core/api/servana_api_config.dart:74-78), so a release is very unlikely to be required.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-056 · Client — the 401/session-expiry path deletes the session but does not reset any private-data store, so the next account signing in on the same device sees the previous customer's cached data

**P1** · rule §11 (cached data must clear on logout AND account switch) · fix in **client-mobile** · protected release: **yes**

Cross-account data exposure on a shared device. Sequence: Customer A's token expires → 401 → session deleted, all singletons retain A's bookings, conversations, profile, saved addresses and support tickets → router sends the user to /welcome → Customer B signs in → B's Bookings/Messages/Profile/SavedAddresses screens render A's in-memory data until each store happens to refetch. The logout path shows the team already identified and solved exactly this class of bug (the code is commented LEAKSHIELD); the fix was simply never applied to the expiry path or to sign-in.

- **Client:** servana_client-main/lib/common/injectors/main_injector.dart:150-155 — `onUnauthorized` does only `AuthStateService.update(AuthStatus.expired)` and `SessionService.deleteSession()`. Compare the deliberate logout path at lib/modules/authentication/presentation/bloc/authentication_bloc.dart:325-341, which resets HomeStore, MessagingStore, AirconBookingStore, BwBookingStore, BookingDraftService, ProfileController, AddressController, SearchRepository, three Support controllers and two Review controllers, and :313-321 which deletes the Hive `registration` box, and :345-353 which clears DraftRepository/OperationJournal. None of that runs on the 401 path. Sign-in does not compensate: `_onLogin` (authentication_bloc.dart:76-102) and `_onGoogleSignIn` (:104ff) contain no resetPrivateData calls — grep confirms the only call sites are lines 325-341, inside _onLogout.
- **Backend:** n/a — device-local. Relevant context: the client has no token-refresh logic anywhere, so Firebase ID-token expiry makes the 401 path the ROUTINE session-end path rather than an edge case, while explicit logout is the rare one.
- **Test gap:** The 933-test suite covers logout purging but has no test for the expiry path or for account switching. Add a widget/bloc test: seed HomeStore + ProfileController with account A, fire onUnauthorized, sign in as account B, assert every store is empty.

**Recommendation.** Ideally fix in the client, but §1/§2 make this the one finding here that would force a protected customer-mobile release — so sequence it into the next scheduled ServanaClient release rather than treating it as a hotfix. The minimal change is to extract the reset block at authentication_bloc.dart:325-353 into a `_purgePrivateData(uid)` method and invoke it from (a) the onUnauthorized handler and (b) the top of every sign-in success path, so a purge happens on account switch regardless of how the previous session ended. No backend change is involved.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-057 · POST /api/admin/admin-users/bootstrap-super-admin is callable with any customer's Firebase token and fails OPEN when no active super admin exists

**P1** · rule §11, §12, §6 · fix in **backend** · protected release: **no**

The authorization decision is a mutable DB count, not an identity check. The window re-opens every time the last active super admin is suspended or deactivated — which is a normal admin-lifecycle event, not an exotic failure. Whoever calls first during that window becomes super admin over every customer's bookings, addresses, payments and support tickets. Severity is P1 rather than P0 only because the precondition is state-dependent and unverified in production; if the precondition holds, the impact is unambiguously P0.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:37-47 — every ServanaClient session holds a valid Firebase ID token for the same project, which is the only credential this route requires. The customer app has no admin surface, so any successful call here is by definition an escalation out of the customer role.
- **Backend:** servana_api-main/src/routes/adminPermission.routes.ts:25-26 — `router.post('/admin/admin-users/bootstrap-super-admin', verifyAuth, ctrl.bootstrapSuperAdmin)` — verifyAuth only, no verifyRoles, no requirePermission (every other route in the file uses `...adminOnly` plus a permission or requireSuperAdmin). src/services/adminPermissionService.ts:1032-1053 — the sole guard is `SELECT COUNT(*) ... WHERE is_super_admin = TRUE AND account_status = 'active'`; if that is 0 the caller is INSERTed as super admin and `user_credentials.role` is force-set to 1.
- **Test gap:** tests/admin-permissions.test.js does not cover the bootstrap route's authorization. Add: role-3 token → 403; second call after a super admin exists → 409; and a test that a deactivated super admin does not re-open the window.

**Recommendation.** Backend-only. Remove the self-service route from the HTTP surface entirely and make bootstrap an operator-run script or a one-shot guarded by a `BOOTSTRAP_TOKEN` env secret compared with timingSafeEqual. If it must stay routable, add `verifyRoles([1])` plus an allowlist of bootstrap-eligible emails, and make the guard permanent (a `bootstrap_completed` flag row) rather than a live count that can return to zero.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-058 · Socket.IO root namespace join_room — a client-supplied `type` label bypasses the booking ownership check, allowing any authenticated identity into any private room — **CONFIRMED**

**P1** · rule §11, §26 · fix in **backend** · protected release: **no**

The comment's premise — that non-booking rooms are UUID-keyed and therefore unguessable — is enforced against the attacker-controlled `type` label, not against the actual `roomKey`. Emitting `{ roomKey: 'booking:123', type: 'support' }` walks straight past the ownership SQL at :83-86 and joins the booking room. `{ roomKey: 'provider:<victimUid>', type: 'support' }` joins another provider's private notification channel. Booking IDs are sequential integers, so this is enumerable. Any Servana customer account is sufficient.

- **Client:** servana_client-main/lib/modules/messaging/data/services/chat_socket_service.dart:89-90 shows ServanaClient connects only to the `/chat` namespace (which is correctly authorized). Nothing prevents a customer's Firebase token from being used against the ROOT namespace instead — the root handshake (provider.gateway.ts:43-52) accepts any valid token and defaults an unknown role to 3, i.e. customer.
- **Backend:** servana_api-main/src/provider.gateway.ts:96-97 (unconditional `socket.join(data.roomKey)` for any client-supplied `type` other than 'provider'/'booking', with no validation that roomKey matches the claimed type) — combined with servana_api-main/src/provider.realtime.ts:20-22 (`io.to(providerRoomKey(workerUid)).emit(event, payload)`), the ONLY root-namespace emitter, sole call site servana_api-main/src/services/notification.service.ts:337. This makes `{roomKey:'provider:<victimUid>', type:'support'}` a real cross-tenant subscription. Conversely, no emit to `booking:*` exists anywhere on the root namespace (all 4 `.emit(` sites: chat.realtime.ts:22, chat.gateway.ts:80, chat.gateway.ts:126, provider.realtime.ts:22), so the claim's booking-room enumeration example leaks nothing. Root handshake accepts any authenticated identity with no role gate at provider.gateway.ts:41-53.
- **Test gap:** tests/leak-isolation.test.js:126-142 covers only Socket.IO CORS origins. No test exercises join_room authorization. Add gateway tests: type-mismatch payload must not join; a customer-role socket must never enter a provider: or booking: room.

**Recommendation.** Backend-only. Derive authorization from the roomKey, never from the type label: parse the key prefix and dispatch on that (`provider:` → must equal providerRoomKey(actor.uid); `booking:` → DB check; anything else → verify the UUID exists and that the actor is a member, or reject). Fail closed on an unrecognised prefix rather than joining. Neither mobile app relies on the permissive branch for correctness, so this is release-free.

## SC-059 · verifyAuthOptional silently downgrades an invalid or expired token to anonymous, making "no credentials" the most privileged state on all three routes that use it

**P1** · rule §11 (fail closed) · fix in **backend** · protected release: **no**

This is the shared root cause behind the three anonymous-bypass P0s above, and it is worth fixing as a pattern, not just per-route. Every controller that pairs verifyAuthOptional with an `if (actor?.uid && ...)` ownership guard inverts the privilege model: presenting a bad token is treated as presenting no token, which is treated as being trusted. Additionally, the tempId bypass here lacks the environment assertion its sibling has, so a stray TEMP_ID in a non-production-but-internet-reachable environment authenticates every request as one uid.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:59 — the client treats any 401 as session expiry (`onUnauthorized`). It has no concept of "my token was ignored and I was served as anonymous", so a customer running with a stale token silently receives unscoped data instead of being asked to re-authenticate.
- **Backend:** servana_api-main/src/middleware/verifyAuthOptional.ts:26-28 (`return next()` with req.user undefined when no header) and :39-41 (`catch { }` — an invalid/expired token is swallowed and the request continues unauthenticated). Compare src/middleware/verifyAuth.ts:40-52, which correctly returns 401 TOKEN_EXPIRED / INVALID_TOKEN. Also note verifyAuthOptional.ts:18-21 has the `tempId` dev bypass WITHOUT the `NODE_ENV` fail-closed assertion that verifyAuth.ts:55-59 carries.
- **Test gap:** tests/leak-isolation.test.js:108-124 asserts that verifyAuthOptional calls next() unconditionally when no header is present — i.e. it pins the permissive behaviour as intended. That test should be inverted or deleted alongside the middleware.

**Recommendation.** Backend-only, two parts. (1) Once the three consuming routes are promoted to verifyAuth, delete verifyAuthOptional entirely — grep confirms its only consumers are booking.routes.ts:17, booking.routes.ts:22 and user.route.ts:15. (2) If it must survive for another consumer, make it fail closed on a PRESENT-but-invalid token (401) while still passing through on an ABSENT token, and mirror the NODE_ENV guard from verifyAuth.ts:55-59.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-103 · Booking conversation is created on the customer's first access with no assigned/confirmed state gate (§24)

**P2** · rule §24, §25 · fix in **backend** · protected release: **unknown**

This is NOT a cross-user leak — access is properly gated and the customer is a legitimate participant. It is a §24 violation: a canonical conversation comes into existence for a booking in PENDING_OTP with no assigned provider, which pollutes the conversation inventory and means the admin communication surface shows chats for bookings nobody is servicing. Reported so it is not mistaken for a leak in a later pass.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart:524 calls `GET /api/bookings/:id/conversation` from messaging_repository.dart:28, which the Messages screen invokes whenever the customer opens a booking's chat — including immediately after booking creation, before any provider exists.
- **Backend:** servana_api-main/src/chat/chat.controller.ts:36-52 — `getBookingConversation` correctly calls `resolveAccessForBooking` and 403s when not allowed (:42-45), then unconditionally calls `getOrCreateConversation` (:46). src/chat/chat.service.ts:59-78 creates the conversation row and syncs participants with no check on bookings.status or on whether a provider has confirmed.
- **Test gap:** tests/messaging-group-chat.test.js does not assert that conversation creation is state-gated. Add: booking in PENDING_OTP with no booking_workers row → no chat_conversations row is created.

**Recommendation.** Backend-only. Split the read and the create: return 404 CONVERSATION_NOT_READY when the booking has no confirmed provider, and create only on the confirm transition (technicianService acceptJob) or on the first message send. ServanaClient already tolerates a non-200 here via its standard ServanaApiException path (servana_api_client.dart:60-63), but confirm the Messages screen renders an empty state rather than an error before changing the status code.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-104 · Client router guard is case-sensitive — six /settings/* routes and /HelpSupport fall outside the isProtected prefix list

**P2** · rule §12 (explicitly: this is NOT authorization) · fix in **client-mobile** · protected release: **yes**

Listed for completeness and explicitly de-escalated: per §12, a redirect is not authorization, and the backend does the real gating, so no data leaks. The observable effect is a UX/logic defect — an unauthenticated deep link renders the profile-edit chrome with empty fields instead of bouncing to /welcome. Recording it here so a future pass does not re-report it as a security hole.

- **Client:** servana_client-main/lib/common/presentation/routes/main_router.dart:125-126 — `loc.startsWith(SettingsScreen.route)` where SettingsScreen.route is '/Settings' (capital S). Dart's startsWith is case-sensitive, so the lower-case routes declared at main_router.dart:547 (/settings/profile-edit), :553 (/settings/appearance), :559 (/settings/about), :565 (/settings/security), :571 (/settings/privacy), :577 (/settings/permissions) and :583 (/HelpSupport) never match, and the redirect at :145-150 never fires for them.
- **Backend:** n/a — every screen behind these routes reads through authenticated endpoints (e.g. GET /api/user/profile, user.route.ts:19, which derives the uid from the token at user.controller.ts:81). No data is exposed.
- **Test gap:** No router test asserts that every declared route is either explicitly public or covered by isProtected. Add a meta-test that enumerates the GoRoute paths and fails on any new route that matches neither list — that guardrail is what would keep this from recurring.

**Recommendation.** Client-side only and cosmetic; fold into the next scheduled ServanaClient release alongside the P1 cache-purge fix rather than releasing for it. Normalise the comparison (`loc.toLowerCase().startsWith(...)`) or, better, replace the prefix list with a per-route `redirect:` callback so new routes cannot silently opt out of the guard.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-119 · VERIFIED CLEAN — guest (guestCustomerId) cannot read a booking or become a registered customer through any client-reachable route

**info** · rule §7, §8 · fix in **none** · protected release: **no**

Positive result for the §7/§8 half of this pass. Guests hold no Firebase credential, so they cannot present a token; and even a booking they own is unreachable through the customer routes because ownership is matched on user_id, which is null for guest bookings. No automatic guest-to-client conversion path exists in any client-reachable route — linkage is admin-only.

- **Client:** servana_client-main/lib/common/data/backend/servana_api_client.dart — no method anywhere sends or accepts a guestCustomerId; the customer app has no guest-booking surface. CustomerBooking.fromApiMap (lib/common/domain/booking/customer_booking.dart:200-201) resolves customerId from customerId/userId/customerUid only, so a guest id could never be absorbed into the customerUid slot client-side either.
- **Backend:** servana_api-main/src/services/bookingAccessService.ts:74-75 — `const ownerUid = bookingRes.rows[0].user_id ?? null; if (ownerUid && ownerUid === actorUid) return 'customer'`. Guest bookings carry a NULL user_id (adminCreateBookingService.ts:696-698 inserts guest_customer_id alongside a null user_id), and a null ownerUid can never satisfy the guard. The design intent is documented at bookingAccessService.ts:53-57. Guest identity stays in its own column and its own table throughout: adminCreateBookingService.ts:662-686, adminGuestService.ts:126-159 — it is never written into user_credentials.uid.
- **Test gap:** tests/booking-access.test.ts covers customer/provider/admin resolution but has no guest-booking case. Add one: a booking with user_id NULL and guest_customer_id set must return null access for every non-admin actor, including an actor whose uid equals the guest_customer_id string.

**Recommendation.** No change required. Preserve the null-safe comparison at bookingAccessService.ts:74-75 when refactoring; rewriting it as `ownerUid === actorUid` without the truthiness guard would still be safe, but a change to COALESCE(user_id, guest_customer_id) — a tempting simplification for the admin read models — would immediately create a guest-impersonation path. Worth a comment pinning that.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-120 · VERIFIED CLEAN — push payloads carry no protected content readable pre-auth, and notification/support/review/chat reads are all token-scoped

**info** · rule §45, §58, §11 · fix in **none** · protected release: **no**

Positive result covering four of the pass's checklist items. Lock-screen previews expose only a generic title/body; the data payload is routing metadata, so nothing protected is readable before unlock. Notifications, support tickets, reviews and chat are the best-authorized surfaces in the codebase — every one derives identity from the token and scopes in SQL, with no client-side filtering acting as the only control. Booking deep links also revalidate server-side on open, since GET /api/:id now runs assertBookingAccess (bookingController.ts:92).

- **Client:** servana_client-main/lib/modules/notifications/data/notification_mapper.dart:40-61 (mapFcmDataToNotification) builds only from notificationKey/type/title/body/routeKey/resourceId and returns null without a key; lib/modules/notifications/application/fcm_coordinator.dart:133-152 and lib/main.dart:166,182 refetch canonical state from the backend rather than trusting the payload. lib/common/data/backend/servana_api_client.dart:609-635 (notifications) and :656-761 (support) send no identity parameter at all — the uid comes from the token.
- **Backend:** servana_api-main/src/services/notification.service.ts:793-803 — the FCM data map is exactly {notificationKey, type, schemaVersion, routeKey?, resourceId?}; :578-599 sends notification.title/body from safe_body. The only customer-notification producer in the entire backend is bookingController.ts:38-47, whose safeBody is 'Your booking has been placed…' with no PII. Scoping verified: notification.service.ts:672 (`user_uid = $1`), :691, :702 (`notification_key = $1 AND user_uid = $2`), :722; customerReviewController.ts:24,37,71,85 all read req.user.uid; customerSupport.routes.ts:12-24 is verifyAuth throughout; chat.routes.ts:8 is `router.use(verifyAuth)` with authorization derived from the booking in chat.service.ts:24-39 and applied on every operation.
- **Test gap:** No test asserts that FCM data payloads exclude PII. A cheap source-level guard: assert that the fcmData object literal at notification.service.ts:793 contains only allowlisted keys, so a future field addition has to be deliberate.

**Recommendation.** No change required. Two things to hold onto during future work: keep createCustomerNotification the single choke point for customer pushes so the safe-body discipline cannot be bypassed by a new producer, and keep title/safeBody free of provider names, phone numbers and addresses even as more notification types are added (§58) — the current single-producer state is what makes this easy to guarantee today.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

