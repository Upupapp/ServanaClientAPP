# TAB 10 — Tracking, OTP, cancel and reschedule

**Date** 2026-08-16 · **Repo** `servana_client-mobile` @ `main`
**Backend evidence** `servana_api-main`, read directly from source

---

## 1. What this tab is, in one sentence

The first tab whose canonical calls **change something**, which is why it opens
with a transport defect nobody had been able to notice.

TABs 02–09 built read boundaries. Reading over the wrong transport shows stale
data; acting over the wrong one cancels a customer's booking. Everything below
follows from taking that difference seriously.

---

## 2. The defect that had to be fixed first

`V1ApiClient` sent **`X-Idempotency-Key`**. The canonical routes read
**`Idempotency-Key`**, and no other name:

```ts
// servana_api/src/api/v1/envelope.ts
export const IDEMPOTENCY_HEADER = 'idempotency-key';

export function readIdempotencyKey(req, opts = {}) {
  const raw = req.get(IDEMPOTENCY_HEADER);        // and nothing else
  if (raw === undefined || raw === '') { … }
  if (!/^[A-Za-z0-9_.:-]{8,128}$/.test(raw)) throw IDEMPOTENCY_KEY_INVALID;
}
```

`X-Idempotency-Key` is the **legacy create route's** spelling
(`controllers/bookingController.ts:54`), and `ServanaApiClient` correctly keeps
sending it there.

**What it would have caused.** A canonical mutation carrying an idempotency key
was indistinguishable from one carrying none. `V1ApiClient` also permits a
retry of a mutation *only* when a key was supplied — so the client would have
retried a cancel or an OTP verify believing it was protected, and the server
would have seen two unrelated requests. That is precisely the failure
idempotency exists to prevent.

**Why nothing caught it.** `v1_api_client_test.dart` asserted the header,
and asserted the wrong name. Every canonical call built so far was a GET.

Fixed, plus a client-side shape assertion so a malformed key trips in debug
rather than costing a round trip to be told `IDEMPOTENCY_KEY_INVALID`.
`RequestIds.newIdempotencyKey()` produces keys inside the backend's alphabet,
which is asserted rather than assumed.

**Guard** `test/core/network/idempotency_header_test.dart` — 6 tests, including
an explicit assertion that `x-idempotency-key` is **not** present.

---

## 3. The second defect: two 403s that are not access decisions

`errors.ts` puts four booking codes on 403. Two are access decisions
(`BOOKING_ACCESS_DENIED`, `BOOKING_OTP_ACTOR_NOT_PERMITTED`). Two are not:

| Code | Status | What it means |
| --- | --- | --- |
| `BOOKING_OTP_INVALID` | 403 | *"The booking verification code the customer received did not match."* |
| `BOOKING_WORKER_CODE_INVALID` | 403 | *"The six-digit code the customer reads out did not match."* |

Classified by status alone these became `ForbiddenFailure` — **"You don't have
access to this."** — telling a customer who mistyped one digit that the booking
is not theirs, with no correction affordance. Both now map to `validation`.

**Guard** `test/core/network/booking_action_error_mapping_test.dart` — 11 tests,
including that the 403s which *are* access decisions stay forbidden, so the
override is not a blanket downgrade.

---

## 4. Capabilities added

Two, not one, and not folded into `bookingReads`.

| Value | Covers | Why separate |
| --- | --- | --- |
| `bookingLifecycle` | `cancel`, `reschedule`, `otp/request`, `otp/verify`, `otp/status` | Actions, not reads. Flipping it changes bookings. |
| `bookingTracking` | `GET …/tracking` | A read, but what it moves is a **privacy** boundary. |

Both are named for their slice. The existing guard forbids a value named for
the booking **domain** while `POST /api/v1/bookings` does not exist, and TAB 10
extended it: any *new* `booking*` capability now has to be added to an explicit
list, so a future rename that widens the claim fails the test rather than
sliding past three hard-coded strings.

**Guard** `test/core/network/canonical_availability_test.dart` — now 12 tests,
including that reads, actions and tracking are independently switchable.

---

## 5. What each surface stopped duplicating

This tab removed three client-side copies of server-owned truth and declined to
add a fourth.

### 5.1 The OTP resend cooldown

`BookingOtpScreen` held `static const int _resendCooldownSeconds = 60` and
counted it down locally. Three consequences:

- wrong the moment the policy changes, with nothing failing loudly;
- **reset on dispose** — leaving and returning granted a resend the server then
  refused with `BOOKING_OTP_RESEND_COOLDOWN`;
- could not express the issue ceiling or the attempt budget at all, so the
  customer was told "Resend code" right up to the request that failed.

`GET /api/v1/bookings/:id/otp/status` exists for exactly this. Its contract
says so: *"so a client renders 'resend in 42s' and '2 attempts left' from the
backend rather than from its own copy of the policy."*

The screen now reads that state, honours `Retry-After` on a refusal, and shows
an attempts line **only when the backend supplied the number**. On legacy,
`BookingOtpState.local` supplies the same 60 seconds — now named as a client
assumption and flagged `isBackendDerived: false`, rather than passing for
policy. Null and zero stay distinct: an unknown budget is not an exhausted one.

### 5.2 The cancellation failure message

Every failure rendered as one sentence:

> Cancellation is not available at this time. Please contact support if you
> need to cancel.

Written for GAP-C15-001, when there genuinely was no customer cancel route —
and it outlived the gap. A booking already cancelled, a booking a provider has
started, and a dropped connection all told the customer to contact support, two
of them wrongly. The backend issues one code per distinguishable refusal
precisely so a client can say which rule refused. The sheet now renders
`safeMessage`, and retires the submit button only when the refusal is one no
correction can fix.

### 5.3 A wrong OTP arriving in two different shapes

`POST /api/:id/confirm-otp` answers a wrong code with `{success:false}` at HTTP
200 as often as with a 400. The screen read that flag itself, so the failure
shape depended on which transport answered. The compatibility source now raises
`ValidationFailure` carrying `BOOKING_OTP_INVALID`, so one caller handles both.

### 5.4 The fourth copy, declined

`BookingActionResolver` computes what a customer may do from a status string.
The backend generates `availableActions` from `TRANSITIONS`, the single machine
every surface shares. Rather than extend the resolver with reschedule,
`BookingLifecycleRepository.resolveActions` prefers the backend's list —
**including when that list is empty**, which is the trap: treating empty as
"the server said nothing" reinstates the client's machine at exactly the moment
the server said the machine permits nothing. The resolver is now the labelled
*fallback*, not a rival.

Reschedule is deliberately **not** looked for in `availableActions`. It is not
a state transition — it goes through `bookingRescheduleService` — so it could
never appear there, and a client that looked would offer it never.

---

## 6. Tracking: the privacy boundary moves server-side

The legacy pair is `GET /api/:id` plus `GET /api/booking/:id/provider-location`.
The backend's own note on the second:

> answers in EVERY state — a customer could watch their provider on a booking
> cancelled last week

The canonical route evaluates visibility **before** reading a position, and
reports a withheld one as a **200 with `visibility.reason`**, never a 403,
because the caller is entitled to the booking and simply not to a live location
for it yet.

The client could not express that. `TrackingRepository` reduced every
non-answer to `providerLocation == null`, so four different facts rendered as
one blank map:

| `reason` | What it actually means |
| --- | --- |
| `NO_ASSIGNMENT` | still matching you with a provider |
| `STATE_NOT_TRACKABLE` | shown once your provider is on the way |
| `WINDOW_EXPIRED` | no location update recently |
| `NO_POSITION_REPORTED` | assigned, but has not shared a location |

`TrackingVisibility` now carries the verdict to the screen. Three properties
are asserted rather than assumed:

1. An **unrecognised** verdict withholds. A parser defaulting to `VISIBLE`
   would draw a pin on a value it did not understand.
2. A payload with **no** verdict withholds.
3. A `WITHHELD` verdict **drops an attached position**. The backend already
   nulls it; this is the client refusing to draw a pin on coordinates the
   verdict said to hide, which is the failure a server regression would
   otherwise produce silently.

On legacy the verdict is `TrackingVisibility.inferred` with
`isBackendDerived: false` — a guess, labelled as one.

**Guard** `test/modules/tracking/data/tracking_canonical_test.dart` — 8 tests.
The pre-existing 91-test tracking suite still passes: the two-call stitch moved
into `TrackingCompatibilityDataSource` **verbatim**, and its tests follow it.

---

## 7. Reschedule: the endpoint exists and the client had nothing

`bookings.reschedule` is `implemented`. The client had `BookingAction.reschedule`
in an enum with **zero production callers**, a resolver that never emitted it,
and Help Center copy saying *"Rescheduling must be arranged with Servana
Support."*

Delivered: the full transport, the domain models, the reason vocabulary and a
`BookingRescheduleSheet`.

**The sheet decides nothing.** Not the 24-hour notice window, not the 90-day
lead bound, not `RESCHEDULABLE_STATES`, not the provider-calendar check. Each
has a code of its own and each refusal names the rule. The client owns only the
**vocabulary** — a reason must be pickable before any request exists, and
`RESCHEDULE_REASONS` is closed and append-only, which is what makes mirroring it
safe.

`expectedSchedule` is always sent. It is both the concurrency guard and the
replay guard: the write carries `schedule IS NOT DISTINCT FROM <expected>`, so a
repeat of an applied move is refused with `BOOKING_SCHEDULE_CHANGED` rather than
moving the booking twice. That is why reschedule sends **no** idempotency key —
the guard is already there, and it is armed by `expectedSchedule`.

`PENDING_PROVIDER` is modelled rather than collapsed into accepted, so the day
`RESCHEDULE_REQUIRES_PROVIDER_ACCEPTANCE` flips true the app does not tell a
customer their booking moved when it was only proposed.

**The entry point is gated on the transport, not on a state.** The only
reschedule route that has ever existed is admin-only and answers a customer
token with 403, so `canOfferReschedule` is **false on every shipped build** and
the button does not appear. A capability discovered by making a request and
catching the refusal is a capability the customer discovers by being refused.

The customer reason list excludes `PROVIDER_SUPPLY` and `OPERATIONAL`. Both are
valid on the endpoint and both are an admin's vocabulary; offering them invites
a customer to attribute the move to their provider in a record that is kept.

---

## 8. Idempotency keys are held, not minted at the call site

A key is worth sending only if it survives a retry of the same intent, and a key
generated inside the method that sends it never does. `BookingLifecycleRepository`
keys them by intent and clears the entry once the action resolves:

| Situation | Key |
| --- | --- |
| Retry after a **retryable** failure | **reused** — outcome unknown, replay is the point |
| Retry after a refusal the customer corrects | **fresh** — a new intent |
| A second cancel after a success | **fresh** |
| A different booking | **fresh** |
| A **corrected** OTP code | **fresh** — the key is scoped to the code |

That last row is load-bearing. Keyed on the booking alone, typing a second and
different code would replay the first one's rejection: the customer would enter
the right digits and be told they are wrong.

The repository is registered as a **singleton** for the same reason — a factory
would mint a new key for what the customer performed as one tap.

---

## 9. Runtime state of every shipped build

**Unchanged. Fully legacy.**

`bookingLifecycle` and `bookingTracking` are both off, so:

- cancel goes to `POST /api/bookings/:id/cancel` as it does today;
- OTP verify/resend go to `/api/:id/confirm-otp` and `/api/:id/resend-otp`;
- tracking is the same two calls stitched the same way;
- reschedule is **not offered at all**;
- the OTP screen's cooldown is the same 60 seconds it has always been.

The user-visible changes that DO ship are the three honesty fixes, all of which
apply on the legacy path: cancellation refusals say which rule refused, a wrong
OTP raises the same typed failure either way, and the tracking verdict is
carried rather than flattened.

---

## 10. Gaps, recorded not fixed

**`expectedState` is not passed on cancel from the booking detail screen.**
The sheet accepts it and the canonical route honours it, but the only state that
screen holds is `_bookingStatus` — the *legacy* status string, whose vocabulary
includes `CONFIRMED` and `PAID`, which are not canonical states. Sending one
would not add a concurrency guard; it would manufacture a
`BOOKING_STATE_CONFLICT` on a perfectly cancellable booking. Closing this needs
the canonical state on the read path, which is a booking-**read** concern.

**Three client-side copies of the cancellability rule remain.**
`_isCancellable` on the detail screen and `_cancellable` in
`BookingActionResolver` both duplicate a server rule, and they already disagree
with each other about `paymentProcessing`. TAB 10 built the mechanism to retire
them (`resolveActions` preferring `availableActions`) and did not rewire the
detail screen's rendering, which is a larger UI change than this tab's scope.

**No ETA on the canonical tracking payload.** The legacy stitcher derives one
from booking columns the tracking route does not carry, so the canonical source
returns `eta: null` rather than inventing one. A canonical build would lose the
ETA card until either the payload carries it or the screen fetches it separately.

**`bookings.transitions` is not consumed.** The append-only event log is the
natural source for `availableActions` on a read, and TAB 09 migrated the
*narrative* timeline instead. `resolveActions` accepts the list; nothing fetches
it yet.

**Upstream, unchanged.** `/api/v1` is still absent from `servana_api`'s
`origin/main`, and there is still no `POST /api/v1/bookings`.

---

## 11. Acceptance gate

```
flutter analyze   → 0 errors, 0 warnings, 39 infos (the unchanged baseline)
flutter test      → 1,823 passed, 6 skipped, 0 failed
```

New tests: 54 across four files.

| File | Covers |
| --- | --- |
| `test/core/network/idempotency_header_test.dart` | the header name, the key shape, the malformed-key assertion |
| `test/core/network/booking_action_error_mapping_test.dart` | every booking refusal code → the right recovery |
| `test/bookings/booking_lifecycle_test.dart` | transports, key lifetime, OTP, reschedule, action authority |
| `test/modules/tracking/data/tracking_canonical_test.dart` | the visibility verdict and its three deny-by-default paths |

Five existing tests changed, and each change is a correction rather than an
accommodation:

- **two** in `v1_api_client_test.dart` pinned `X-Idempotency-Key` — they were
  asserting the defect;
- **two** in `tracking_seed_coordinates_test.dart` and **one** in
  `app_store_readiness_test.dart` read `tracking_repository.dart` as source
  text. The code moved to the compatibility source, so the tests follow it. The
  App Store one now reads *both* transports, so the privacy declaration cannot
  become unjustified in its eyes just because the coordinate handling moved.
