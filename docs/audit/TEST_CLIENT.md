# TEST — Servana Customer Mobile App

Coverage against the critical paths, and whether the gates that exist actually gate anything.

| | |
| --- | --- |
| Target | `Heatclift/ServanaClient` @ `bab66e4` |
| Backend | `servana_api` @ `870fd28` (canonical, §3) |
| Also inspected | admin portal `101016d`, provider web `42fbec9`, provider mobile `451eaf6` |
| Customer web | **UNAVAILABLE** — repo has 0 committed files |
| Findings | 30 |

**P0: 2 · P1: 14 · P2: 11 · P3: 2 · info: 1**

## SC-019 · leak-isolation.test.js pins three address operations but omits updateUserAddress, whose UPDATE has no uid predicate (cross-user address overwrite) — **FIXED** in `6d78313`

**P0** · rule §11, §12, §60 · fix in **backend** · protected release: **no**

The repo has a dedicated cross-user-isolation regression suite that pins every address mutation except the one that is still broken. Any authenticated customer who supplies another customer's addressId to POST /api/user/adduseraddress overwrites that customer's stored street address, location_id and Mongo geo record, and no test in either repo would fail.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/common/data/backend/servana_api_client.dart:140 addUserAddress posts /api/user/adduseraddress; lib/common/data/repositories/address_repository.dart:85 and lib/common/presentation/screens/drawer_placeholder_screens.dart:325,388 are the live callers, and any of them can carry an addressId
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/services/address.service.ts:56-60 (UPDATE ... WHERE address_id = $11, no uid predicate) + src/controllers/user.controller.ts:25-33 (no ownership check before updateUserAddress) + src/routes/user.route.ts:16 (verifyAuth only, no verifyRoles) + tests/leak-isolation.test.js:48-70 (pins makeAddressPrimary and deleteAddress, omits updateUserAddress)
- **Other:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/tests/leak-isolation.test.js:22-232 — 15 assertions covering profile uid source, getAddressByAddressId ownership, makeAddressPrimary, deleteAddress, archive role guard, listUserBookings, socket CORS, PayMongo signature, alluseraddresses role scoping. updateUserAddress appears nowhere in the file.
- **Test gap:** tests/leak-isolation.test.js has no updateUserAddress case; the ServanaClient suite has no address-ownership test either (test/domain/address_repository_test.dart and test/modules/profile/application/address_controller_test.dart both mock the API and never assert server-side scoping).

**Recommendation.** Backend: add `AND uid = $12` to the UPDATE at src/services/address.service.ts:57-60 and bind uid, returning 0 rows -> 403/404 (fail closed, §11). Then add to tests/leak-isolation.test.js a source-text assertion mirroring lines 49-59 that updateUserAddress's WHERE clause contains `uid = $`, plus a dbQuery-mocked unit test (same style as tests/booking-access.test.ts) asserting customer B cannot update customer A's addressId.

## SC-020 · The only ServanaApiClient contract test pins a URL the backend does not serve, certifying a broken booking flow as green — **FIXED** in `65b4337`

**P0** · rule §4, §2, §60 · fix in **backend** · protected release: **no**

servana_api_client_test.dart is the suite's only API-contract test (4 of 990 tests, covering 1 of 78 client methods). It asserts the exact 3-segment path that the backend does not register, so the test suite actively certifies a 404. Two test suites in two repos pin mutually incompatible paths for the same endpoint and both are green — the backend's is green because jest.config.js:5 excludes it from `npm test`.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/test/common/data/backend/servana_api_client_test.dart:87 (also :106) asserts captured.url.path == '/api/services/7/options-with-addons'; lib/common/data/backend/servana_api_client.dart:264 builds that 3-segment path
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/routes/service.route.ts:12 (router.get("/:serviceId/options-with-addons")) mounted at C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/app.ts:103 (app.use("/api", cors(corsOptionsDelegate), serviceRoute)) — yielding /api/:serviceId/options-with-addons, with no other registration anywhere in src/ and no URL rewriting in src/middleware/parityMiddleware.ts or requestParityMiddleware.ts; corroborated by C:/Users/paulg/OneDrive/Desktop/ServanaWorker/lib/core/api/servana_api.dart:305 calling the same 2-segment path in production
- **Other:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/modules/aircon_booking/data/aircon_booking_store.dart:257 loadOptionsWithAddons swallows the exception into errorMessage and leaves optionsWithAddons empty; :142-147 bookableOptions derives entirely from it
- **Canonical contract:** GET /api/services/{serviceId}/options-with-addons AND GET /api/{serviceId}/options-with-addons must both resolve to serviceController.listOptionsWithAddons; a single client-side contract test must assert the request the backend answers, not the request the client happens to build.
- **Test gap:** No contract test in either repo runs in a gate AND asserts the same path. Required: one client test per live ServanaApiClient method pinning verb+path+query+body, and one runnable backend jest test per mobile-called route asserting non-404 with the mobile-shaped URL.

**Recommendation.** Fix on the BACKEND, additively (§4, no protected release): add `router.get("/services/:serviceId/options-with-addons", serviceController.listOptionsWithAddons)` alongside the existing 2-segment route in src/routes/service.route.ts, so both mobile shapes resolve. Then correct the client assertion in test/common/data/backend/servana_api_client_test.dart:87 to pin the shape the backend actually serves, and remove 'catalog-service\\.test\\.ts$' from testPathIgnorePatterns in jest.config.js:5 after rewriting it as real jest tests (see separate finding on its vacuous asserts).

## SC-094 · Backend contract tests catalog-service.test.ts and admin-dedup.test.ts are excluded from jest and pass vacuously when no server is running

**P1** · rule §60 · fix in **backend** · protected release: **no**

Two files named *.test.ts are excluded from the test runner, and the excluded catalog file's assertions are written so that a server that is not running produces a green result — the negative-space assertion 'not 404' is satisfied by every failure mode including total unreachability.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/common/data/backend/servana_api_client.dart:261-267 — listOptionsWithAddons is the exact endpoint catalog-service.test.ts claims to protect for the customer app.
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/jest.config.js:5 — `testPathIgnorePatterns: ['/node_modules/', 'admin-dedup\\.test\\.ts$', 'catalog-service\\.test\\.ts$']`. Inside the excluded file, tests/catalog-service.test.ts:141-146: `const res = await request(...).catch(() => ({ status: 0, body: null })); assert('... is registered (not 404)', res.status !== 404)` — status 0 (connection refused) satisfies `!== 404`. The file is a standalone ts-node IIFE (tests/catalog-service.test.ts:137-152, run-block at the tail), not jest tests.
- **Test gap:** 2 of 24 backend test files never execute. Every assertion in catalog-service.test.ts is of the form 'status !== 404', which cannot distinguish a working route from an unreachable server.

**Recommendation.** Rewrite tests/catalog-service.test.ts as jest tests using supertest against the Express app object (no listening port, deterministic, no environment dependency), assert positive conditions (`expect(res.status).toBe(200)`), remove the `.catch(() => ({status: 0}))` swallow so a connection error fails the test, and delete both entries from jest.config.js:5. Do the same review for admin-dedup.test.ts.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-095 · Backend production deploy runs no tests, no typecheck and no contract guard — 22 jest suites gate nothing

**P1** · rule §60, §62 · fix in **backend** · protected release: **no**

Every push to main deploys straight to PM2 on the production Linode without executing the cross-user isolation suite, the booking-access suite, or even tsc. The tests exist and pass locally but have no gating authority, so the LEAK regressions they were written to prevent can ship unnoticed.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/common/data/backend/servana_api_client.dart — 78 methods, all pointed at the deployed API; a backend regression reaches the customer app with no gate in between.
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/.github/workflows/deploy.yml:8-157 — the single `deploy` job runs migrations, `npm ci`, `npm run build` (deploy.yml:146), then `pm2 start` (deploy.yml:153). There is no `npm test`, no `npm run typecheck`, no `npm run verify`, and no `npm run guard:protected-contracts` step. package.json:11-15 defines all four scripts. `npx jest --listTests` enumerates 22 suites including tests/leak-isolation.test.js and tests/booking-access.test.ts.
- **Test gap:** No CI gate on the backend at all. No PR-triggered workflow exists — deploy.yml:3-6 triggers only on push to main and workflow_dispatch, so nothing runs on pull requests.

**Recommendation.** Insert a gate step into .github/workflows/deploy.yml between 'Install dependencies' (line 143) and 'Build' (line 146): `npm run typecheck && npm run test:ci && npm run guard:protected-contracts`, and fail the job on non-zero exit. Because the runner is self-hosted with the prod .env already copied at deploy.yml:23, run the gate BEFORE the secrets-copy step or use a test-only env so a failing gate cannot touch production.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-096 · CI never runs the test suite — all 1280 tests, including the nine new security regression suites, are unenforced on deploy

**P1** · rule — · fix in **servana_api-main/.github/workflows/deploy.yml:44 (insert before), :161** · protected release: **no**


**Recommendation.** Add a `- name: Test` step running `npm run verify` (typecheck + test:ci) and a `- name: Guard protected contracts` step running `npm run guard:protected-contracts`, both BEFORE `Run pending DB migrations` at deploy.yml:44 — not merely before Build, so a red suite cannot leave the database migrated. `node scripts/guard-protected-contracts.mjs` currently exits 0 in 1s, so neither step is costly.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-097 · createBooking's identity-from-token fix — the core of 52667b3 for the customer app — has no test of any kind

**P1** · rule — · fix in **servana_api-main/tests/create-booking-identity.test.ts (new); covers src/controllers/bookingController.ts:9-52** · protected release: **no**


**Recommendation.** Add to tests/booking-access.test.ts or a new tests/create-booking-identity.test.ts: mock bookingService and notification.service, then assert (a) `bookingService.createBooking` receives the token uid when `?userId=` is absent; (b) it receives the TOKEN uid, not the query uid, when they differ, and a warning is logged containing no uid (§58); (c) it receives the token uid unchanged when `?userId=` matches — the compatibility case ServanaClient exercises; (d) a request with `req.user` undefined returns 401 UNAUTHENTICATED and never calls the service.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-098 · Entire messaging module has 0% test coverage; ConversationMapper's unguarded `as num?` cast on a COUNT(*)-derived field silently empties the Messages inbox

**P1** · rule §20, §25, §60 · fix in **backend** · protected release: **no**

11 messaging source files (~700 executable lines) have zero tests. A String-typed unreadCount fails the `as num?` cast, MessagingStore.loadConversations catches and debugPrints it, and the inbox renders empty with no error state — a silent total failure of a primary flow that no test would catch.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/modules/messaging/data/mappers/conversation_mapper.dart:20-22 — `(json['unreadCount'] as num? ?? json['unread_count'] as num? ?? 0).toInt()`; the exception is swallowed at lib/modules/messaging/presentation/stores/messaging_store.dart:114-115 (`catch (e) { debugPrint(...) }`). coverage/lcov.info records 0.0% for conversation_mapper.dart, message_mapper.dart, message_model.dart, messaging_repository.dart (27 lines), messaging_store.dart (180 lines), chat_socket_service.dart (91 lines), booking_chat_screen.dart (250 lines), messages_inbox_screen.dart (213 lines).
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/chat/chat.repository.ts:261-267 computes `(SELECT COUNT(*) ...) AS unread_count`; src/chat/chat.service.ts:91 returns `rows.map(toCamel)` with no numeric coercion, and no `pg.types.setTypeParser` exists anywhere in src/ (grep: 0 hits). Postgres COUNT(*) is bigint, which node-pg surfaces as a JS string.
- **Canonical contract:** GET /api/chat/conversations -> {success, conversations: [{id:int, bookingId:string, unreadCount:int, isClosed:bool, lastMessageAt:iso|null, lastMessage:obj|null}]} — unreadCount must be JSON number, not string.
- **Test gap:** No test file exists under test/modules/messaging/. No mapper fixture tests, no socket-service tests, no store tests, no clientMsgId send-idempotency test (grep 'clientMsgId' in test/: 0 hits).

**Recommendation.** Backend (preferred, §2 — no protected release): coerce in SQL, `(SELECT COUNT(*) ...)::int AS unread_count`, at src/chat/chat.repository.ts:266. Add a jest test in tests/messaging-group-chat.test.js asserting the listConversations row shape has a numeric unread_count. Client-side, add test/modules/messaging/data/conversation_mapper_test.dart and message_mapper_test.dart with fixtures for: numeric unreadCount, string unreadCount, missing id, string id, snake_case keys, null lastMessage — the mappers must degrade, never throw.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-099 · Five of seven assertBookingAccess call sites have no controller test, and there is no catch-all that would have caught the original approve/mark-cash-paid miss

**P1** · rule — · fix in **servana_api-main/tests/booking-access.test.ts (extend); targets src/controllers/bookingController.ts:71,92,153 and src/controllers/paymentController.ts:14,80** · protected release: **no**


**Recommendation.** Extend tests/booking-access.test.ts (or a new tests/booking-scoped-handlers.test.ts) with two layers. (1) A describe.each over all five handlers, mocking bookingAccessService the way payment-settlement-access.test.ts:17-39 does, asserting each: refuses when the guard rejects, does not call its service when refused, and calls the guard BEFORE the service (the mockImplementation-ordering trick at payment-settlement-access.test.ts:135-138). (2) A source-level catch-all in the spirit of leak-isolation.test.js:75-85: parse src/routes/booking.routes.ts and src/routes/payment.routes.ts, and for every non-webhook handler they name, assert the exported function body in the corresponding controller contains `assertBookingAccess` — so a new booking-scoped route cannot ship unguarded.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-100 · guard-protected-contracts.mjs cannot detect removal of any route ServanaClient actually calls, and is not wired to CI

**P1** · rule §5, §4, §60 · fix in **backend** · protected release: **no**

The only mechanism the backend has for protecting mobile-authoritative contracts is a substring scan so coarse that deleting every customer-mobile route would still pass, and it never executes in CI regardless.

- **Client:** Routes the customer app depends on that the guard does not check: GET /api/{id} and GET /api/{id}/tracking (servana_api_client.dart:388,415), POST /api/{id}/confirm-otp (:396), POST /api/{id}/paymongo/create (:450), POST /api/{id}/gcash-submit (:421), GET /api/services/{id}/level2 (:253), GET /api/branches/{id}/slots (:283), POST /api/quote (:316), all /api/user/notifications/* (:609-635), all /api/support/* (:656-761), all review routes (:765-864).
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/scripts/guard-protected-contracts.mjs:53-56 checks only that the literal substrings '/worker/' and '/workers/' appear somewhere in src; :66 checks '/booking'; :91 checks '/auth/'; :103-105 check '/admin/'. A single surviving occurrence anywhere in 166 source files satisfies each pattern. The script is not referenced in .github/workflows/deploy.yml.
- **Test gap:** No route-inventory test exists in either repo. Nothing asserts that a route the protected mobile apps call still exists with the same verb, path and auth posture.

**Recommendation.** Rewrite scripts/guard-protected-contracts.mjs to assert exact (method, path) pairs, seeded from the actual ServanaClient and ServanaWorker call sites rather than from prose. Feed it a checked-in manifest (e.g. scripts/protected-routes.json) listing every route each protected app calls, and fail if any is absent or has lost its middleware. Wire it into the CI gate from the previous finding.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-101 · leak-isolation.test.js still green-asserts the vulnerability bd8c355 removed, and passes only because of a comment

**P1** · rule — · fix in **servana_api-main/tests/leak-isolation.test.js:117-146; tests/anonymous-bypass.test.ts:89-94** · protected release: **no**


**Recommendation.** Delete tests/leak-isolation.test.js:117-146 (both stale describes) and delete src/middleware/verifyAuthOptional.ts. Replace the two `actor?.uid &&` assertions at leak-isolation.test.js:120 and anonymous-bypass.test.ts:93 with an assertion of the fail-closed shape, and change the controllers to match. Add to tests/anonymous-bypass.test.ts a test that verifyAuthOptional.ts does not exist on disk, replacing the one that asserts it does.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-102 · Logout is entirely untested — all six skipped tests defer to an integration_test harness that does not exist

**P1** · rule §58, §60 · fix in **client-mobile** · protected release: **yes**

The suite reports 983 passing but the six deferred tests are exactly the security-relevant ones: logout emits LoggedOut, logout survives a failing repo call, session save on login, and the session-generation race. The stated destination for them was never created — no directory, no dependency, no CI job — so the deferral is permanent and logout has zero automated verification.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/test/bloc/authentication_bloc_test.dart:123,139,168,283,317,602 — six `skip:` entries, all citing 'Requires flutter_secure_storage platform channel — use integration_test' or 'promote to integration_test'. `flutter test` output confirms '6 skipped tests'. There is no integration_test/ directory in the repo, and `integration_test` appears nowhere in pubspec.yaml:110-125 or pubspec.lock.
- **Other:** The untested logout path at lib/modules/authentication/presentation/bloc/authentication_bloc.dart deletes the session at :308 and only calls FcmCoordinator.deactivateOnLogout() at :359 — after the bearer token is gone — so DELETE /api/user/fcm-token (verifyAuth at servana_api-main/src/routes/user.route.ts:31) always 401s and the FCM row survives server-side. Coverage: authentication_bloc.dart 43.5% of 170 lines; fcm_coordinator.dart 0.0% of 67 lines.
- **Test gap:** 0 executable tests for logout; 0 for login session persistence; 0 for the concurrent-logout race; fcm_coordinator.dart 0% covered.

**Recommendation.** Either (a) add `integration_test:` to dev_dependencies, create integration_test/auth_flow_test.dart, add a CI job, and move the six tests there; or (b) make SessionService injectable so the six become plain unit tests with a fake — the same refactor the comment at authentication_bloc_test.dart:598-601 already identifies. Then add the missing logout-clears-everything assertions: session box deleted, registration box deleted, all 14 stores reset (authentication_bloc.dart:325-341), draft/journal/pending-payment secure-storage keys cleared, notifications SharedPreferences keys cleared, chat socket disconnected, and FCM deactivated BEFORE the session is destroyed.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-103 · No test asserts the Authorization header is sent, and onUnauthorized (which wipes the session globally on any 401) has zero coverage

**P1** · rule §11, §60 · fix in **client-mobile** · protected release: **no**

The backend has just moved every booking and payment route the customer app calls onto verifyAuth. The client's behaviour under a missing/expired token is therefore now safety-critical, and it is completely untested: nothing asserts the bearer header is attached, nothing asserts a 401 wipes the session, and nothing asserts a 403 (booking-access denial) does NOT wipe it. A single spurious 401 from any of ~78 methods force-logs the customer out mid-booking.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/common/data/backend/servana_api_client.dart:37-46 `_headers()` omits Authorization entirely when the token is null/empty; :59 `if (status == 401) onUnauthorized?.call();`. lib/common/injectors/main_injector.dart:150-156 wires onUnauthorized to `AuthStateService.update(AuthStatus.expired)` + `SessionService.deleteSession()`. grep 'onUnauthorized' and 'Authorization'/'Bearer' across test/: 0 hits.
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/routes/booking.routes.ts:20,28,29,30 now apply verifyAuth to POST /api/bookings, POST /api/:id/confirm-otp, GET /api/:id, GET /api/:id/tracking; src/routes/payment.routes.ts:8-11 apply verifyAuth to gcash-submit, approve, mark-cash-paid, paymongo/create. These were unauthenticated at the commit the client docs were written against.
- **Other:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/modules/tracking/... and lib/modules/bookings/presentation/screens/booking_detail_screen.dart:155 poll getBooking on a timer; assignment_polling_service.dart:92 does the same every cycle — each poll is now a 401 candidate that triggers a global session wipe.
- **Test gap:** 0 tests for the auth header, 0 for onUnauthorized, 0 for the 401-vs-403 distinction, 0 for expired-token behaviour during polling.

**Recommendation.** Add test/common/data/backend/servana_api_client_auth_test.dart: (a) with a stubbed Hive session, assert every mutating method's captured request carries `Authorization: Bearer <t>`; (b) assert `_headers()` omits the header when token is empty; (c) assert onUnauthorized fires exactly once on 401 and NOT on 403/404/500; (d) a main_injector-level test that AuthStatus becomes expired and the session is deleted on 401. Use the existing mocktail `mockHttp.send(captureAny())` pattern already proven at servana_api_client_test.dart:68-74.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-104 · No test asserts X-Idempotency-Key is sent, and the backend does not read it for customer booking creation — double-submit creates two bookings

**P1** · rule §17, §19, §60 · fix in **backend** · protected release: **no**

The customer app implements its half of the idempotency contract and the test suite verifies only the local journal. The server half does not exist for POST /api/bookings even though the admin equivalent has a full dedupe table, so a retry or double-tap produces two bookings and two payment rows with nothing to detect it.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/common/data/backend/servana_api_client.dart:374-377 attaches `X-Idempotency-Key` to POST /api/bookings; lib/modules/aircon_booking/data/aircon_booking_store.dart:431-434 and the BW equivalent pass `_idempotencyKey`. No test captures the request headers — grep 'X-Idempotency-Key' in test/: 0 hits.
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main — grep -i idempoten over src/ returns hits only in admin paths: src/controllers/adminBookingController.ts:410-440, src/controllers/adminBookingDraftController.ts:117-124, src/services/adminCreateBookingService.ts:120-128 (table booking_create_idempotency, UNIQUE(idempotency_key, admin_actor_uid)). src/controllers/bookingController.ts:9-52 createBooking never reads req.headers['x-idempotency-key'] and performs no dedupe.
- **Other:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/test/core/recovery/booking_journaling_contract_test.dart:69 tests only that the key is preserved in the LOCAL journal for reconciliation; it never asserts the key crosses the wire or that the server dedupes.
- **Canonical contract:** POST /api/bookings with header X-Idempotency-Key: <uuid> — a replay with the same (key, token subject) returns the original booking, HTTP 200, and creates no second row.
- **Test gap:** No wire-level idempotency test in either repo for the customer booking path; the admin path is tested, the customer path is not.

**Recommendation.** Backend: reuse the existing booking_create_idempotency pattern for the customer path — read `X-Idempotency-Key` in src/controllers/bookingController.ts:9, key on (idempotency_key, user_uid), and return the original booking on replay. Add a jest test mirroring tests/admin-create-booking.js asserting two identical POSTs with the same key yield one row. Client-side, add a case to test/common/data/backend/servana_api_client_test.dart capturing the header on createBooking.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-105 · resolveProviderAudience is untested — the projection tests prove the filter works but never that it is applied to the right callers

**P1** · rule — · fix in **servana_api-main/tests/provider-profile-projection.test.ts:111 (extend); covers src/controllers/technicianController.ts:1022-1038** · protected release: **no**


**Recommendation.** Add a describe block to tests/provider-profile-projection.test.ts mocking ../src/db/dbQuery and ../src/config: (a) undefined actorUid → 'other' with NO query issued; (b) actorUid === subjectUid → 'self' with no query issued; (c) role 1 → 'admin'; (d) role 2 and role 3 → 'other'; (e) zero rows → 'other'; (f) dbQuery.query rejecting → 'other', not 'admin'. Then one integration-shaped test over getByUid itself asserting that a role-2 caller's response body contains none of WITHHELD_FROM_OTHERS.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-106 · The auth-guard test re-implements the router's guard instead of executing it, and explicitly asserts the /settings deep-link gap is correct

**P1** · rule §12, §60 · fix in **client-mobile** · protected release: **yes**

The guard test asserts against a hand-copied duplicate of the guard, so it cannot fail when main_router.dart drifts — which is the only regression it claims to protect against. Worse, its 'public routes' group codifies `/settings` (lowercase) as legitimately unprotected, so the seven unguarded deep-link routes are locked in as intended behaviour rather than flagged.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/test/common/routes/auth_guard_test.dart:21-37 defines a private `_isProtected` copy with the comment 'Mirrors the isProtected logic in MainRouter.router() exactly. Update this if the guard changes'; :205-207 asserts `_isProtected('/settings')` is false. The real guard is lib/common/presentation/routes/main_router.dart:125-143.
- **Other:** Six real routes live under the lowercase prefix: lib/modules/settings/presentation/screens/profile_edit_screen.dart:11 ('/settings/profile-edit'), security_screen.dart:8, privacy_legal_screen.dart:12, permissions_screen.dart:12, appearance_screen.dart:11, about_screen.dart:10 — all registered at main_router.dart:547-583; plus '/HelpSupport' at drawer_placeholder_screens.dart:868. main_router.dart has NO record in coverage/lcov.info at all, i.e. no test ever constructs the router.
- **Test gap:** Zero tests instantiate GoRouter; zero deep-link tests exist; no test enumerates declared routes and asserts each is classified protected or public.

**Recommendation.** Replace the `_isProtected` copy with a widget test that builds `MainRouter.router()` with a stubbed AuthStateService and asserts the resulting location after `router.go('/settings/profile-edit')` etc. — one case per GoRoute path, generated from the route constants so a new route without a guard entry fails the test. Then fix main_router.dart:125 to use a case-insensitive prefix set that includes '/settings' and '/HelpSupport'. Note §12: this is defence-in-depth only — the backend already gates the data, so this is P1 not P0.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-107 · verifyAuth.ts — the single middleware all nine security fixes rest on — has zero behavioural tests, including its production TEMP_ID kill-switch

**P1** · rule — · fix in **servana_api-main/tests/verify-auth.test.ts (new); covers src/middleware/verifyAuth.ts:8-63** · protected release: **no**


**Recommendation.** New file tests/verify-auth.test.ts: mock firebase-admin/auth and ../src/config, then cover — (a) no header, no cookie → 401 UNAUTHENTICATED and next() NOT called; (b) `__session` cookie alone authenticates; (c) `Bearer ` with empty token → 401, not a pass-through; (d) verifyIdToken rejecting with auth/id-token-expired → 401 TOKEN_EXPIRED, any other error → 401 INVALID_TOKEN; (e) tempId set with NODE_ENV='production' → process.exit called (spy on process.exit) and req.user NOT populated; (f) tempId set with NODE_ENV='test' → req.user = {uid: tempId}.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-145 · CI collects coverage but enforces no threshold — measured line coverage is 17.10%, and 149 of 470 lib files have no coverage record at all

**P2** · rule §60, §62 · fix in **client-mobile** · protected release: **no**

The '~983 tests' headline is not a coverage claim. Real line coverage is 17.1% of instrumented code and lower still against the full source tree, concentrated in pure-domain files (analytics, accessibility, status mapping) while every network, navigation, payment and messaging file sits at or near zero. Nothing in CI prevents that number from falling further.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/.github/workflows/flutter-ci.yml:76 runs `flutter test --coverage` and the workflow never reads coverage/lcov.info afterwards — there is no threshold step and no upload. Computed from coverage/lcov.info: 3504/20489 lines hit = 17.10% across 321 instrumented files, while `find lib -name '*.dart'` reports 470 files, so 149 files (including lib/common/presentation/routes/main_router.dart) are never loaded by any test and are absent from the denominator entirely. Verified suite state: `flutter test` = 983 passed, 6 skipped, 0 failed.
- **Test gap:** No coverage threshold, no per-directory floor, no skipped-test budget, no integration_test job, no golden/screenshot job.

**Recommendation.** Add a coverage-gate step to .github/workflows/flutter-ci.yml after line 76 that parses lcov.info and fails below a ratcheted floor (start at the current 17%, raise per merge), and a second check that fails when a lib/ file has no lcov record at all. Also fail the build on skipped tests, or allowlist them explicitly, so the six permanent skips cannot grow silently.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-146 · CustomerBooking.fromApiMap silently substitutes DateTime.now() for a missing schedule and no test pins that fallback

**P2** · rule §3, §60 · fix in **client-mobile** · protected release: **yes**

If the backend ever stops emitting the schedule aliases, or emits an unparseable value, every booking silently renders 'now' as its appointment time rather than failing loudly. The alias tests give the impression this mapping is fully pinned; the degradation path is the one case not covered.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/common/domain/booking/customer_booking.dart:171-176 — `scheduledAt = scheduleRaw != null ? (DateTime.tryParse(scheduleRaw) ?? DateTime.now()) : DateTime.now();`. test/domain/customer_booking_test.dart covers 40+ alias cases (:246-382) including scheduleAt and schedule aliases, but has no case for an absent or unparseable schedule.
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/services/bookingService.ts:499-500 emits scheduleAt and scheduledAt only when `scheduleVal !== null`; a null schedule column therefore reaches the client as no key at all.
- **Test gap:** No negative/degradation cases in the mapper tests; every case supplies well-formed input.

**Recommendation.** Add cases to test/domain/customer_booking_test.dart asserting the behaviour chosen for {no schedule key, empty string, malformed string} — and prefer surfacing a nullable scheduledAt over fabricating one, so the UI can show 'schedule unavailable' instead of a wrong date.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-147 · guard-protected-contracts checks route prefixes, not the specific routes ServanaClient calls — and never runs

**P2** · rule — · fix in **servana_api-main/scripts/guard-protected-contracts.mjs:53-56; .github/workflows/deploy.yml:44** · protected release: **no**


**Recommendation.** Replace the two prefix regexes at scripts/guard-protected-contracts.mjs:53-56 with the explicit route list ServanaClient and ServanaWorker actually call, extracted from servana_client-main/lib/common/data/backend/servana_api_client.dart and ServanaWorker/lib/core/api/servana_api.dart:310-355 — at minimum /workers/role/:role, /workers/:uid, /workers/location/:uid, /workers/location, /workers/:workerId/job-cards, /workers/bookings/:bookingId/{accept,start,complete,decline}. Then add the guard step to deploy.yml so the check is enforced rather than advisory.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-148 · http_backend.dart is 0% covered and holds a second divergent status mapper plus an unauthenticated address write

**P2** · rule §9, §42, §60 · fix in **client-mobile** · protected release: **yes**

An entire parallel HTTP surface and a second booking-status vocabulary exist with no test coverage at all. One of its write paths cannot succeed against the current backend, and neither the duplication (§9) nor the dead path is detectable by the suite.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/coverage/lcov.info records lib/common/data/backend/http_backend.dart at 0.0% of 167 lines. lib/common/data/backend/http_backend.dart:215-227 posts /api/user/adduseraddress with `headers: {'Content-Type': 'application/json'}` only — no bearer token; :220-221 generates locationId client-side. The file also re-maps raw booking status into the legacy JobOrderStatus enum, a second interpretation alongside lib/common/domain/booking/booking_status.dart (which IS tested by test/domain/booking_status_test.dart).
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/routes/user.route.ts:16 — POST /api/user/adduseraddress requires verifyAuth, so this code path can only ever 401.
- **Test gap:** 0% coverage over 167 lines; no test asserts a single canonical status mapper; no test asserts every write path attaches auth.

**Recommendation.** Add a test that fails if any second status-interpretation site exists — e.g. assert BookingStatusMapper is the only symbol converting a raw status string — then delete the duplicate mapper and the unauthenticated addUserAddress path in http_backend.dart, routing everything through ServanaApiClient. Cover whatever of HttpBackend remains live.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-149 · No payment-state tests: PayMongo WebView, pending-payment recovery and the payment chips are all 0% covered

**P2** · rule §20, §43, §60 · fix in **client-mobile** · protected release: **yes**

The money path — create checkout session, hand off to the PayMongo WebView, return, re-read the booking, decide whether payment succeeded — has no test at any layer. Nothing pins the checkoutUrl alias handling (`checkoutUrl ?? checkout_url`), the 2-hour PendingPaymentContext TTL, or the rule that success is only shown when the backend reports PAID (§20).

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/coverage/lcov.info: lib/common/presentation/screens/payment_webview_screen.dart 0.0% of 212 lines; lib/core/recovery/pending_payment_service.dart 0.0% of 13 lines; lib/modules/bookings/presentation/screens/booking_detail_screen.dart 0.0% of 474 lines; lib/modules/job_order/presentation/screens/select_payment_method_screen.dart 0.0% of 61 lines. payment_webview_screen.dart:214 re-fetches the booking after checkout to decide success.
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/routes/payment.routes.ts:11 POST /api/:bookingId/paymongo/create now requires verifyAuth; :12 the webhook is HMAC-verified and is the only authority that writes status PAID.
- **Test gap:** 0 tests referencing paymongo outside analytics event-name validation (test/core/analytics/analytics_event_validator_test.dart); 0 tests for gcash submission; 0 tests asserting no-ghost-success on the payment return path.

**Recommendation.** Add test/modules/payments/payment_recovery_test.dart covering PendingPaymentService set/consume/clear and TTL expiry, and test/common/data/backend/payment_contract_test.dart capturing the createPaymongoSession request and asserting the client reads checkoutUrl from both alias spellings and treats a missing URL as failure, never as success.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-150 · No session-expiry or token-validity test; splash and the auth bloc disagree on what counts as a valid session and neither branch is tested

**P2** · rule §60 · fix in **client-mobile** · protected release: **yes**

Two independent cold-start paths apply different definitions of a valid session and neither is covered. With splash's looser rule, a session whose token was cleared lands the user in the authenticated shell, where the first API call 401s and (via onUnauthorized) tears the session down again — an untested flicker-logout loop.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/modules/landing/presentation/screens/splash_screen.dart:114 `hasSession = session != null;` then :119-121 pushes AuthStatus.authenticated — an empty-token session is treated as signed in. lib/modules/authentication/presentation/bloc/authentication_bloc.dart:266 requires `session != null && session.token.isNotEmpty`. No test exercises splash_screen.dart's session check; the corresponding bloc test at test/bloc/authentication_bloc_test.dart:575-590 only covers the exception path.
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/middleware/verifyAuth.ts verifies the Firebase ID token per request; the client has no exp parsing and no refresh call, so expiry is only ever discovered as a 401.
- **Test gap:** 0 tests for splash session restore; 0 tests for AuthStatus.expired being distinguished from guest at the router (main_router.dart:145 only tests isAuthenticated).

**Recommendation.** Add test/modules/landing/splash_session_test.dart asserting AuthStatus.guest for {null session, session with empty token} and authenticated only for a non-empty token, then align splash_screen.dart:114 with authentication_bloc.dart:266. Add a token-expiry test once an exp check exists.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-151 · No test enforces auth coverage across the route surface — 65 routes register without verifyAuth, 35 of them on the technician router

**P2** · rule — · fix in **servana_api-main/tests/route-auth-inventory.test.ts (new); src/routes/technician.routes.ts:18-19,57; src/routes/additional.routes.ts:11-16** · protected release: **no**


**Recommendation.** Add tests/route-auth-inventory.test.ts: parse every file in src/routes, resolve spread aliases and router.use(), and snapshot the list of routes lacking verifyAuth against an explicit ALLOWED_UNAUTHENTICATED array with a one-line justification per entry. New unauthenticated routes then fail the build until someone writes down why. Seed the allow-list with the current 65 so it is non-blocking on day one, and let the LEAK pass drain technician.routes.ts and additional.routes.ts from it.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-152 · ServanaClient has zero tests for the /workers/:uid contract that 65b4337 reshaped, and the backend test's claim about the client's field list is incomplete

**P2** · rule — · fix in **servana_api-main/tests/provider-profile-projection.test.ts:44-52; servana_client-main/test/modules/bookings/worker_profile_parse_test.dart (new)** · protected release: **no**


**Recommendation.** Two changes. In servana_api-main/tests/provider-profile-projection.test.ts:44-52, add `name` and `email` to the asserted contract explicitly — `name` present, `email` absent — and cite the exact client line for each. In servana_client-main, add test/modules/bookings/worker_profile_parse_test.dart feeding _loadWorkerProfile's parsing the exact projected payload the backend now returns (uid, firstName, lastName, name, phoneNumber, photoUrl, roleName, services) and asserting name and phone resolve and nothing throws on the absent keys.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-153 · ServanaClient's six skipped tests defer to an integration_test/ directory that does not exist, and they cover exactly the token lifecycle this session made load-bearing

**P2** · rule — · fix in **servana_client-main/test/common/data/backend/api_client_headers_test.dart (new); test/bloc/authentication_bloc_test.dart:123,139,168,283,317,602** · protected release: **no**


**Recommendation.** Either create integration_test/ and port the six cases, or — cheaper and sufficient for the risk introduced this session — add test/common/data/backend/api_client_headers_test.dart faking SessionService and asserting: a populated token yields the Authorization header; a null session and an empty-string token both yield NO Authorization header (documenting the state that now 401s); and a 401 response invokes onUnauthorized exactly once. Four tests, no platform channel required.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-154 · The column-does-not-exist defect class hit twice this session; the check that would catch it exists but is scoped to one alias in one function

**P2** · rule — · fix in **servana_api-main/tests/sql-column-contract.test.ts (new); generalizes tests/guest-booking-link.test.ts:50-66** · protected release: **no**


**Recommendation.** New tests/sql-column-contract.test.ts: build a table→columns map by parsing every `CREATE TABLE IF NOT EXISTS ${...}.<table> (...)` and `ADD COLUMN IF NOT EXISTS <col>` in src/, then scan every template-literal SQL string in src/services and src/controllers, resolve `FROM <table> <alias>` / `JOIN <table> <alias>` bindings, and assert each `<alias>.<col>` reference resolves. Start it in report-only mode against a known-offenders allow-list so the existing surface does not block the build, then drive that list to zero. This one test retroactively catches both bugs and is the single highest-leverage addition in this pass after the CI step.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-155 · Two test suites are silently excluded from jest, and they are the only ones that exercise real HTTP routes

**P2** · rule — · fix in **servana_api-main/jest.config.js:5; tests/route-contract.test.ts (new)** · protected release: **no**


**Recommendation.** Add supertest, and create tests/route-contract.test.ts mounting the express app with firebase-admin and the pg pool mocked. Port the assertions from catalog-service.test.ts:137-163 there first (options-with-addons on both the bare and /services-prefixed paths returns non-404), since that is a live protected-client contract. Then move the two ts-node scripts to scripts/smoke/ so their exclusion from jest is explicit rather than a config line nobody reads.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-164 · Canonical §13 statuses `new` and `disputed` are unmapped and untested; unknown statuses are grouped under cancelled

**P3** · rule §13, §60 · fix in **client-mobile** · protected release: **yes**

Latent rather than live: the customer contract still carries PENDING_OTP/WORKER_ASSIGNED, so the missing canonical branches do not bite today. But if the backend ever canonicalises the customer payload, every affected booking would map to unknown and be filed under 'cancelled' in the customer's list, and no test would catch it.

- **Client:** C:/Users/paulg/OneDrive/Desktop/servana_client-main/lib/common/domain/booking/booking_status.dart:51-123 BookingStatusMapper.fromString has no branch for 'new' or 'disputed'; :52,120-121 default to BookingStatus.unknown; :405 groups unknown under the `cancelled` category. grep for 'new'/'disputed'/'awaiting_assignment' in test/domain/booking_status_test.dart and booking_status_c15_test.dart: 0 hits.
- **Backend:** C:/Users/paulg/OneDrive/Desktop/servana_api-main/src/services/bookingService.ts:483-511 formatBooking emits the raw UPPERCASE status plus a naive statusLower; the §13 canonical mapper exists only on the admin path (src/services/adminBookingService.ts mapOperationsStatus), so `new`/`disputed` do not currently reach the customer app.
- **Test gap:** No test asserts the client understands the canonical §13 vocabulary; no test asserts the grouping of an unrecognised status.

**Recommendation.** Add cases to test/domain/booking_status_test.dart for all eight §13 values (new, awaiting_assignment, assigned, accepted, in_progress, completed, cancelled, disputed) asserting each maps to a distinct non-unknown status, and change booking_status.dart:405 so unknown groups under `needsAttention` rather than `cancelled` — surfacing an unrecognised status is safer than hiding it in a terminal bucket.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-165 · No test covers the §21 safe-error boundary, and several hardened controllers return raw exception text

**P3** · rule — · fix in **servana_api-main/tests/booking-access.test.ts:167 (extend); src/controllers/bookingController.ts:51, src/controllers/paymentController.ts:25, src/controllers/technicianController.ts:97** · protected release: **no**


**Recommendation.** Add a describe to tests/booking-access.test.ts, or fold into the tests/booking-scoped-handlers.test.ts proposed above: for each hardened handler, make the mocked service reject with a realistic pg error (`error: column \"foo\" does not exist` with `code: '42703'`) and assert the response body contains neither the driver text nor the code — only a safe domain message. This is the same shape as the BookingAccessError test at :167-181, applied one layer out where the leak actually is.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

## SC-170 · Coverage shape of the nine new suites: strong where the fix is a pure function, thin where it is a wiring decision

**info** · rule — · fix in **servana_api-main/tests/route-contract.test.ts (new)** · protected release: **no**


**Recommendation.** No action on its own; this is the through-line explaining the six findings above. The structural remedy is the supertest harness proposed in the jest-exclusion finding: one mounted app with firebase-admin and pg mocked converts the whole source-regex tier into behavioural tests and closes the comment-satisfies-assertion class permanently.

> Agent-reported. Only P0 claims went through adversarial verification; re-read the cited files before acting.

