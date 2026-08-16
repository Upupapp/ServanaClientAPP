# TAB 02 — API client, DTO and compatibility architecture

**Servana Client Mobile Backend Convergence V1**
Client `servana_client-main`, branch `main`. Backend evidence `servana_api-main`.

The local migration manifest the TAB 02 command asks for: what the canonical
boundary is, which endpoints are still served by compatibility sources, and
what has to be true before each one can move.

---

## 1. What was built

| Layer | File | Role |
| --- | --- | --- |
| Failure model | `lib/core/network/api_failure.dart` | Nine sealed cases — the only vocabulary above the boundary |
| Error mapping | `lib/core/network/api_error_mapper.dart` | Every wire shape → one `ApiFailure` |
| Envelope | `lib/core/network/api_envelope.dart` | Reads all three response envelopes; `PageMeta`, `Page<T>` |
| Correlation | `lib/core/network/request_id.dart` | `X-Request-Id` per attempt, `X-Correlation-Id` per intent |
| Endpoints | `lib/core/network/v1_endpoints.dart` | The only place `/api/v1` paths are written |
| Transport | `lib/core/network/v1_api_client.dart` | Auth, timeout, pagination, retry classification |
| Gate | `lib/core/network/canonical_availability.dart` | Deny-by-default capability switch |
| Router | `lib/core/network/compat/canonical_router.dart` | Canonical vs compatibility selection |

Pilot vertical slice — notifications:

| File | Role |
| --- | --- |
| `notifications_data_source.dart` | The interface both transports satisfy |
| `notifications_canonical_data_source.dart` | `/api/v1/notifications*` |
| `notifications_remote_data_source.dart` | `/api/user/notifications*` (compatibility) |
| `notifications_repository.dart` | Selects one, returns `List<ServanaNotification>` either way |

---

## 2. The runtime state of every shipped build

**Fully legacy. No canonical traffic. No behaviour change from TAB 01.**

`CanonicalAvailability` is false unless a build passes *both*
`--dart-define=CANONICAL_V1_ENABLED=true` and a non-empty
`CANONICAL_V1_CAPABILITIES`. No production build passes either, because
`/api/v1` is absent from the backend's `origin/main` — TAB 01 verified
`src/api/v1/contract.ts` is not on the pushed branch and
`origin/main:src/app.ts` mounts zero v1 routers.

Three properties make that a fact about the build rather than a promise:

1. The gate is a **compile-time** define. Nothing on the network can open it,
   and there is no runtime probe that could guess wrong.
2. The router **never falls back**. It does not catch a canonical failure and
   retry on legacy — during a partial rollout that would double-send mutations
   to two backends.
3. A repository handed a canonical source but **no router** pins itself to
   compatibility, so a half-wired injector fails toward legacy.

Asserted by `test/core/network/canonical_availability_test.dart` and
`test/modules/notifications/notifications_compatibility_test.dart`.

---

## 3. Remaining compatibility endpoints

Every call the app makes is still served by a compatibility source today. This
table is what changes that, per domain. "Blocked on" is the condition that must
hold before the capability may be enabled — not a schedule.

> **TAB 03 update (identity).** `V1Capability.identity` was added and the
> authentication/verification domain now uses the same pattern. See §7.

### 3.1 Capabilities defined and ready to switch

Complete canonical surfaces. Enabling them is a define and a test run.

| Capability | Compatibility endpoints today | Canonical successors | Blocked on |
| --- | --- | --- | --- |
| `notifications` | `GET /api/user/notifications`, `…/unread-count`, `PATCH …/:key/read`, `POST …/mark-all-read`, `POST\|DELETE /api/user/fcm-token` | `GET /api/v1/notifications`, `…/unread-count`, `PATCH …/:key/read`, `POST …/read-all`, `POST\|DELETE /api/v1/me/devices` | v1 deploy |
| `catalog` | `GET /api/catalog`, `…/summary`, `…/services/:id` | `GET /api/v1/catalog`, `…/summary`, `…/services/:serviceId` | v1 deploy. **Also unpushed on legacy** — see §5 |
| `customerProfile` | `GET /api/user/profile`, `PUT /api/user/updateprofile`, `GET /api/user/alluseraddresses`, `POST /api/user/adduseraddress`, `PUT /api/user/makeaddressprimary`, `DELETE /api/user/deleteaddress` | `GET\|PATCH /api/v1/customer/profile`, `/api/v1/customer/addresses*` | v1 deploy |
| `conversations` | `GET /api/bookings/:id/conversation`, `GET /api/chat/conversations`, `GET\|POST …/:id/messages`, `POST …/:id/read` | `POST\|GET /api/v1/conversations`, `…/:id/messages`, `…/:id/read` | v1 deploy **and** a semantic decision — see §4 |

### 3.2 Capabilities deliberately NOT defined

`V1Capability` has no value for these. Adding one would let a build claim a
migration it cannot make.

| Domain | Why not | Blocked on |
| --- | --- | --- |
| **bookings** (the domain) | `POST /api/bookings` is classified `KEEP` with **no canonical successor and none planned**. A "migrated" booking domain would still create bookings on a legacy route. Three *slices* have since been named — `bookingReads` (TAB 09), `bookingLifecycle` and `bookingTracking` (TAB 10) — and together they still do not add up to the domain. | A backend contract entry for canonical booking creation |
| **reviews** | 4 of 9 calls have successors. `GET\|PUT\|DELETE /api/reviews/:id`, `GET /api/reviews/me` and `POST …/report` do not. | Canonical review-lifecycle endpoints |
| **support** | The v1 relative is booking-scoped only and documented as narrower, not equivalent: the general contact surface "carries no bookingId". | A canonical non-booking support surface |
| **payments** (the domain) | ~~`paymongo/create` has a successor; `gcash-submit`, `approve`, `mark-cash-paid` do not — though none has a production caller.~~ **Partly superseded by TAB 11 — see §9.** The customer's three booking-scoped finance calls now have a capability, `bookingPayments`. Still without successors: the manual-payment family (`gcash-submit`, `approve`, `mark-cash-paid`), none of which has a production caller. | Contract decision on the manual-payment family |
| **tracking** (the domain) | ~~`GET /api/booking/:id/provider` has no successor; provider-location maps onto `…/tracking`.~~ **Superseded by TAB 10 — see §8.** The *snapshot* now has a capability, `bookingTracking`. What still has no successor is the provider **identity** lookup, which is why the value is named for the tracking read and not for the domain. | Canonical provider identity endpoint |

### 3.3 Calls with no canonical successor inside an otherwise complete domain

The awkward case, and the reason the pattern allows a per-call escape.

| Call | Domain | Handling |
| --- | --- | --- |
| `DELETE /api/user/notifications/:key` | `notifications` | Deliberately **absent** from `NotificationsDataSource`. `NotificationsRepository.dismiss` calls the compatibility source directly, in every configuration, even when the rest of the domain is canonical. Asserted by test. |

Expressing that gap in the type system rather than in a comment is the point:
the canonical implementation cannot invent an endpoint that does not exist, and
cannot throw at runtime on a button the customer can see.

---

## 4. Decisions taken, and why

**The canonical client is a second transport, not a replacement.**
`ServanaApiClient` is untouched and still serves all 76 legacy calls. Collapsing
the two before v1 deploys would mean editing the code path that currently
serves customers, for no user-visible gain.

**Retry is refused by default.** `ApiFailure.isRetryable` is false on the base
class; only `RetryableFailure` and `RateLimitFailure` override it. A mutation is
never retried without an idempotency key — enforced in `V1ApiClient._send`, so a
data source cannot forget it.

**`IDEMPOTENCY_KEY_REUSED` is its own failure case.** It shares HTTP 409 with
every state conflict and means the opposite: a state conflict is "look again, it
may not have happened", this is "it happened, do not send it again". Conflating
them is how a customer ends up with two bookings.

**`markRead` returns a nullable count.** v1 answers with the unread count
recomputed from the store the list was read from; the legacy route returns no
body. Null is "unknown, re-fetch if you need the badge" and never zero — zero
would clear a badge that still has unread items. `NotificationsController` now
takes the reconciled count when present and keeps its optimistic decrement
otherwise, which is the behaviour it has always had on legacy.

**Conversation creation changes meaning under v1.** Legacy
`GET /api/bookings/:id/conversation` lazily creates; canonical is an explicit
`POST /api/v1/conversations`. That is the fix for the finding that a
conversation is created the moment the customer opens the screen with no
assignment gate. It is a semantic change the client cannot make transparently,
so `conversations` is defined as a capability but its migration needs a product
decision about when a conversation should exist, not just a define.

**No new dependency.** Request ids are generated locally. They are random and
must not encode a uid, phone number, booking id or device identifier — a
correlation id travels to server logs, crash reports and support tickets, which
is exactly where a stable personal identifier should not go.

---

## 5. Upstream and environmental gaps

Unchanged from TAB 01 and not closable from this repository.

| Gap | Effect on TAB 02 |
| --- | --- |
| `/api/v1` absent from backend `origin/main` (51 unpushed commits) | The canonical sources cannot be exercised against a real server. They are covered by tests against a mock transport only. |
| Four `/api/catalog*` routes also unpushed | The `catalog` capability is blocked twice over: its canonical successor is undeployed *and* the legacy route it would replace is undeployed. |
| No canonical `POST /api/v1/bookings` | The largest domain cannot be defined as a capability at all. |
| Production ≠ `origin/main`, unverifiable | No request was made to any environment. Availability claims remain `origin/main`-based. |
| Installed base is `1.0.0+37` | Anything the installed base calls must keep working; the backend's own retirement rule requires 90 days of zero hits for a mobile alias. |

---

## 6. Acceptance gate

| Gate condition | Status | Evidence |
| --- | --- | --- |
| No screen contains a new raw endpoint string | **met** | `test/core/network/no_raw_endpoints_in_presentation_test.dart` scans all presentation sources and fails on any path or host literal |
| Canonical and compatibility responses normalise to one mobile model | **met** | `notifications_compatibility_test.dart` asserts field-by-field equivalence of `ServanaNotification` from both transports |
| Production API base configuration unchanged | **met** | `AppConfig.baseUrl` untouched; `git diff` shows no change to `lib/common/config/` |
| Focused tests for touched domains | **met** | 82 new tests across `test/core/network/` and `test/modules/notifications/` |
| Full verification and build | **met** | See the certification section of the TAB 02 report |
| Durable phase checkpoint | **met** | `tab02-canonical-api-boundary` in the project memory store |

One documented exception to the host rule:
`payment_webview_screen.dart` holds `_approvedHosts`, the deny-by-default set
of origins the checkout WebView may navigate to. Those literals are a security
boundary, not a call target — the screen never requests them, it refuses
navigation to anything absent from the set. Sourcing that list from
configuration would make it extendable by whoever controls the build or the
network, so it stays compiled in. The exemption is matched per file, so a new
host literal anywhere else still fails the test.

---

## 7. TAB 03 — authentication, registration, verification and /me

Added `V1Capability.identity`, gated OFF like every other capability.

### 7.1 What moved behind the boundary

| Operation | Compatibility (today) | Canonical successor | In `IdentityDataSource` |
| --- | --- | --- | :---: |
| Who am I | `GET /api/user/profile` (projected) | `GET /api/v1/me` | yes |
| Resend email code | `POST /api/auth/resend-email-otp` | `POST /api/v1/auth/resend-verification` | yes |
| Verify email | `POST /api/auth/verify-email-otp` | `POST /api/v1/auth/verify-email` | yes |
| Verify mobile | **none — no legacy route exists** | `POST /api/v1/auth/verify-mobile` | yes |
| Forgot password | **none — Firebase handles it on this client** | `POST /api/v1/auth/forgot-password` | yes |
| Reset password | **none — Firebase handles it on this client** | `POST /api/v1/auth/reset-password` | yes |
| Logout | `POST /api/auth/logout` | `POST /api/v1/auth/logout` | yes |

The three "none" rows throw a deterministic `UnsupportedTransportOperation`,
which the repository turns into a non-retryable failure. A silent no-op would
report a mobile number as verified when nothing verified it.

### 7.2 What is deliberately NOT in the capability

**Sign-in.** The customer app authenticates via
`POST /api/auth/customer-firebase-login`. The backend's migration matrix
classifies it `ROLE_SPECIFIC` and explicitly does **not** collapse it into
`POST /api/v1/auth/login`: its link-collision contract is a 200 carrying
`status: "failed"` and no token, because the installed app throws on any
non-2xx before reading the body and fires `onUnauthorized` on 401. Either
alternative would show "session expired" to somebody who has no session yet.
Changing that shape is a client release, so sign-in stays on the compatibility
path in **every** configuration — which is why the capability is named
`identity` and not `auth`.

**Account creation.** Registration goes through the multi-step form and
`Backend.registerCustomer`, a different payload from
`POST /api/v1/auth/register`. Entangled with form state; out of scope here.

### 7.3 Session hardening

> **Closed after the first TAB 03 pass.** `SecureSessionStore` originally had
> no production write path — tokens kept being persisted inside the
> `UserSession` Hive record and the secure store was only ever cleared. §7.7
> records the storage lifecycle that closes it.

- `SecureSessionStore` (`lib/core/session/`) keeps the bearer and refresh
  tokens in `flutter_secure_storage` with their own lifetime, instead of only
  inside the general-purpose `UserSession` Hive object. **Additive**: the
  existing `SessionService` and its box are unchanged, because rewriting the
  read path would break every signed-in customer on the installed base, which
  still runs `1.0.0+37`. This is the *expand* half of expand-migrate-contract;
  contract belongs to a later tab once telemetry shows the base has moved.
- It stores the token SUBJECT alongside the credential, so an account switch is
  detectable and account A's token can never be handed to a process that now
  believes it is account B.
- Only credentials live there. No email, phone or name: a credential store is
  not a profile store.
- `SessionCleanupService` holds the customer-scoped teardown that was ~90 lines
  inline in `AuthenticationBloc._onLogout`. Same steps, same order, two new
  properties: each step is isolated (the old code grouped fifteen clears into
  one `try`, so a throw in the second silently skipped thirteen) and the
  outcome is reported rather than silent.

### 7.4 Error and fallback UX

`AuthFailureCopy` maps canonical **codes** to copy plus an `AuthRecovery`,
replacing substring matching on backend prose. All six codes the Master Command
names are handled — `INVALID_CREDENTIALS`, `ACCOUNT_UNVERIFIED`, `OTP_INVALID`,
`OTP_EXPIRED`, `RATE_LIMITED`, `RESET_TOKEN_INVALID` — and crucially
`OTP_INVALID` and `OTP_EXPIRED` now get different recoveries, which
`e.toString().contains('400')` could not do.

`EmailVerificationScreen` gained a resend countdown (fixed cooldown after a
send; the server's `Retry-After` wins when it supplies one), an offline state
via the transport-aware copy, and a "Sign in again" action on the one failure it
cannot recover from in place. Its layout, palette and existing widgets are
unchanged.

### 7.5 Preserved

`SplashScreen`, `WelcomeScreen`, `AuthenticationScreen` and
`CreateAccountScreen` are **byte-identical** — verified by
`git diff -- <those paths>` returning empty. Only data behaviour behind them
changed.

### 7.6 Remaining compatibility gaps after TAB 03

| Gap | Blocked on |
| --- | --- |
| Sign-in stays legacy permanently | A backend decision to give `customer-firebase-login` a canonical successor with a compatible failure shape |
| Registration stays legacy | Canonical registration aligned to the multi-step form |
| Mobile verification unavailable | `/api/v1` deployment — there is no legacy route to fall back to |
| Password reset via API unavailable | Same; the client uses Firebase today |
| `SessionService` Hive box still holds a token copy | The contract phase, once installed-base telemetry allows |

### 7.7 Token storage lifecycle (expand → migrate → contract)

`SessionTokenStore` (`lib/core/session/session_token_store.dart`) is the single
authority for token material. Nothing else reads or writes a bearer or refresh
token.

**Read path**

1. In-memory cache, if warm. `read()` is on the path of every authenticated
   request; secure storage is a platform channel, so hitting it per request
   would add a hop to every call the app makes.
2. `SecureSessionStore` (Keychain / EncryptedSharedPreferences).
3. **Legacy fallback, once.** If secure storage is empty and the Hive
   `UserSession` still carries a token, the store migrates it (below) and
   returns working credentials either way.

**Migration, and why it is ordered this way**

```
write secure  →  READ IT BACK  →  compare  →  only then strip legacy
```

The read-back is the load-bearing step. A corrupt keystore can accept a write
and store nothing; a naive "write then strip" passes that and then loses the
credential. On any failure — throwing write, or a read-back mismatch — the
legacy token is left **exactly as it was**, the customer stays signed in, and
the migration retries next launch. Nothing about the failure is logged, because
anything derived from it could carry the value being protected.

**Write path.** Steady-state writes are secure-storage only, and each one also
strips any legacy copy so a later sign-in cannot resurrect a token in Hive.
`AuthenticationBloc._persistSession` writes the session record with **empty**
token fields for the same reason.

**Clear path.** `clear()` wipes both locations. It runs from the
`sessionTokens` cleanup step on logout, and from the account-switch branch of
`_persistSession` — signing in as somebody else on a device that never signed
out is the same leak as a missed logout and does not go through `_onLogout`.

**What stays in Hive.** Only non-secret session fields — customer id, display
name, email, mobile — which about twenty screens read. Deleting the record
would sign the customer out of screens that have nothing to do with credentials.

**Contract phase, NOT done here.** `UserSession.token` and
`UserSession.refreshToken` remain declared. Removing fields from a persisted
Hive adapter is its own migration, and doing it now would break the record for
every installed customer. `SessionTokenStore.didFallBackToLegacy` is the signal
that phase needs: when no device reports a fallback, the fields can go. It is
exposed as a plain flag and deliberately not reported anywhere automatically —
shipping telemetry for it is a separate, consented decision.

**Guards.** `test/core/session/session_token_store_test.dart` covers migration
success, write failure preserving legacy material, the silently-dropped-write
case, post-migration cleanup, secure reads, caching, clear-both-locations and
account-switch detection. `test/core/session/no_hive_token_writes_test.dart`
fails if any code path writes token material back into the Hive record, and
asserts the read-back-before-strip ordering.

**Environmental gap.** The migration has been exercised against an in-memory
fake of `FlutterSecureStorage`, not against a real Keychain or a real
EncryptedSharedPreferences store, and not against a device that has actually
restored from backup. Those are the conditions the failure branches exist for,
and they can only be confirmed on hardware.

---

## 8. TAB 10 — booking lifecycle actions and tracking

Full record in `docs/convergence-v1/TAB10_CERTIFICATION.md`. What belongs in
this manifest is the vocabulary and the endpoint table.

### 8.1 Two capabilities added

| Capability | Compatibility endpoints today | Canonical successors | Blocked on |
| --- | --- | --- | --- |
| `bookingLifecycle` | `POST /api/bookings/:id/cancel`, `POST /api/:id/confirm-otp`, `POST /api/:id/resend-otp`, **(reschedule: none)** | `POST /api/v1/bookings/:id/cancel`, `…/otp/verify`, `…/otp/request`, `…/reschedule`, `GET …/otp/status` | v1 deploy |
| `bookingTracking` | `GET /api/:id` + `GET /api/booking/:id/provider-location`, stitched | `GET /api/v1/bookings/:id/tracking` | v1 deploy |

Both are named for their slice, not the domain — `POST /api/v1/bookings` still
does not exist. The vocabulary guard was widened accordingly: a *new*
`booking*` capability must now be added to an explicit allow-list in
`canonical_availability_test.dart`, so a rename that widens the claim fails a
test rather than sliding past three hard-coded strings.

Reads, actions and tracking are **independently switchable**, and that is
asserted. Enabling `bookingReads` must not start routing a cancellation over an
undeployed namespace.

### 8.2 A transport defect this tab had to fix first

`V1ApiClient` sent `X-Idempotency-Key`; the canonical routes read
`Idempotency-Key` (`api/v1/envelope.ts`) and nothing else. Every canonical call
built before TAB 10 was a GET, so no key had ever been consulted and no test had
caught it — `v1_api_client_test.dart` pinned the wrong name.

Left unfixed, a retry of a cancel or an OTP verify would have been a **second
action** while the client believed it was protected against exactly that.

### 8.3 Calls with no canonical successor inside an otherwise complete slice

Extends §3.3.

| Call | Slice | Handling |
| --- | --- | --- |
| customer reschedule | `bookingLifecycle` | Has **no legacy relative at all** — the only reschedule route that has ever existed is admin-only. The compatibility source answers `supportsReschedule == false` and throws `UnsupportedLifecycleAction` if called anyway; the UI consults the flag before offering the entry point. |
| `GET …/otp/status` | `bookingLifecycle` | No legacy relative. The compatibility source returns `BookingOtpState.local` with every budget **null** — "unknown", which is distinct from zero and must not disable a button that works. |

The reschedule row is the mirror image of `DELETE /api/user/notifications/:key`
in §3.3: there, the canonical side was missing a call the legacy side had; here,
the legacy side is missing one the canonical side has. Both are expressed in the
type system rather than discovered at runtime — and in this direction that
matters more, because the runtime discovery would be a customer tapping a button
and being refused.

### 8.4 What ships today

Nothing routes canonically. The user-visible changes are the three places the
app stopped holding its own copy of a server rule, all of which apply on the
legacy path:

- a cancellation refusal now says **which** rule refused, instead of one
  "contact support" sentence written for a gap that closed;
- a wrong OTP raises the same typed failure whichever transport answered;
- the tracking verdict is carried rather than flattened, and the legacy guess is
  labelled as a guess.

---

## 9. TAB 11 â€” customer payments and refunds

Full record in `docs/convergence-v1/TAB11_CERTIFICATION.md`.

### 9.1 One capability added

| Capability | Compatibility endpoints today | Canonical successors | Blocked on |
| --- | --- | --- | --- |
| `bookingPayments` | `POST /api/:id/paymongo/create`; payment state by re-reading `GET /api/:id`; **(refund: none)** | `POST /api/v1/bookings/:id/payment-intents`, `GET â€¦/payment`, `POST â€¦/refunds` | v1 deploy |

Named for the slice, and for a second reason beyond the one that governs the
three booking values: the `finance` domain also contains provider earnings,
payouts and admin reconciliation. A capability called `finance` would claim
four surfaces a customer app may never call.

### 9.2 Two of the three have no legacy relative

Extends Â§3.3 and Â§8.3.

| Call | Slice | Handling |
| --- | --- | --- |
| `GET â€¦/payment` | `bookingPayments` | No legacy endpoint â€” TAB 01's R-06, *"payment status is only knowable by re-reading the whole booking."* The compatibility source does exactly that and reports `isBackendDerived: false`, with the breakdown zeroed and the refund position null. Zero here means "this transport cannot tell you", not "the price is nothing". |
| `POST â€¦/refunds` | `bookingPayments` | No customer route exists at all; the canonical entry *"adds the customer-initiated path, which had no route at all."* `supportsRefunds` is false and the call throws `UnsupportedPaymentAction`. |

Both mirror the reschedule row in Â§8.3: the legacy side is missing something
the canonical side has, expressed in the type system rather than discovered by
a customer being refused.

### 9.3 What this replaced

Four independent implementations of "start a checkout" and three of "is it
paid" â€” the shape TAB 08 removed from booking creation, still present in the
payment layer. They disagreed: the inline block in `BookingDetailScreen`
unwrapped the response envelope but read only the root key for the URL, so a
wrapped response the two booking stores handled would have failed there. Fixed
as a consequence of the consolidation.

### 9.4 No idempotency keys here

Deliberate, and the opposite of TAB 10's booking actions. None of the three
operations takes one and none lists the idempotency error codes: checkout is
guarded by an advisory lock plus a processor key derived from the payment row,
refund by a `captured - alreadyRefunded` ceiling, and the payment read is a GET.
`PaymentIntent.reused` is the observable half of the checkout guard â€” the app
already relied on session reuse for crash recovery without being able to see it.

### 9.5 What ships today

Nothing routes canonically. What ships is one payment ceremony in place of
seven call sites, and the `BookingDetailScreen` envelope defect that fell out
of it.
