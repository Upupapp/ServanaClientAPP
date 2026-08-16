# TAB 11 — Payments, refunds and the four copies

**Date** 2026-08-16 · **Repo** `servana_client-mobile` @ `main`
**Backend evidence** `servana_api-main`, read directly from source

---

## 1. What this tab found

TAB 08 collapsed four per-category booking-create ceremonies into one
`BookingSubmissionService`. Payments had grown the identical shape and were not
part of that work:

| Operation | Copies before this tab |
| --- | --- |
| start a checkout | **4** — `AirconBookingStore`, `BwBookingStore`, an inline block in `BookingDetailScreen`, plus the raw API method |
| is it paid | **3** — both booking stores, and `PaymentWebViewScreen._verifyPayment` |

They did not agree. Two of the checkout copies unwrapped the envelope and then
checked both `checkoutUrl` and `checkout_url`; the inline block in
`BookingDetailScreen` unwrapped the envelope **and then only ever read the
root key**, so a wrapped response the two stores handled correctly would have
produced *"Payment session could not be started"* there. That is a live defect,
not a stylistic one, and it is the kind that only shows up on one of four
screens.

---

## 2. Two of the three operations have no legacy relative at all

This is what makes `bookingPayments` an unusual capability: enabling it does
not merely move traffic, it adds a question the app could not ask and an action
it could not take.

| Operation | Legacy | Canonical |
| --- | --- | --- |
| start checkout | `POST /api/:id/paymongo/create` | `POST /api/v1/bookings/:id/payment-intents` |
| read payment state | **no endpoint** | `GET /api/v1/bookings/:id/payment` |
| request a refund | **no endpoint** | `POST /api/v1/bookings/:id/refunds` |

**Payment state.** TAB 01 recorded this as R-06: *"Payment status is only
knowable by re-reading the whole booking."* The consequence is visible on the
checkout screen, which polls `GET /api/:id` every five seconds for up to thirty
minutes to read one field.

**Refunds.** The contract is explicit that the canonical entry *"adds the
customer-initiated path, which had no route at all."* The only refund route
today is the admin portal's, which answers a customer token with 403.

Both are reported through the interface — `hasPaymentEndpoint` and
`supportsRefunds` — rather than discovered by making a request and catching the
refusal. A capability discovered that way is one the customer discovers by
being refused.

---

## 3. A customer REQUESTS; only an admin ISSUES

The highest-stakes distinction in this tab. From `bookingPaymentService.ts`:

> One rule, two outcomes. A customer REQUESTS (a review row, no processor call)
> and an admin ISSUES (money moves). Both run `evaluateRefundEligibility`
> first, so a request can never be accepted for a booking an issue would refuse.

So a **successful** customer refund call means *an admin will look at this*. It
does not mean money has moved. `RefundResult.isMoneyMoving` is false for
`outcome: 'requested'` and exists so that wording a request as a completed
refund is hard to do by accident — that error would leave a customer waiting
for money that is not coming until somebody approves it.

**Which triggers a customer may cite** is narrower than an admin's and is
enforced server-side by `REFUND_TRIGGERS[…].initiators`:

| Trigger | Customer may cite |
| --- | --- |
| `CUSTOMER_CANCELLED`, `PROVIDER_CANCELLED`, `SERVICE_NOT_DELIVERED`, `DUPLICATE_PAYMENT` | **yes** |
| `ADMIN_CANCELLED`, `DISPUTE_UPHELD`, `ADMIN_DISCRETION` | no |

The admin-only three are **modelled but never offered**: an admin may have
issued a refund the customer is now reading about, so the result has to parse.
Offering one would produce `REFUND_OUTCOME_NOT_REFUNDABLE` — a refusal the
customer can do nothing about, on a screen about their money.

No eligibility rule is mirrored. Capture state, the refundable ceiling and
double-refund prevention stay on the server, where *"a second full refund
computes a ceiling of zero and is refused by arithmetic rather than by anyone
remembering to check."*

---

## 4. Payment state is not booking state, and it has six values

`PaymentStatusParser` — the string helper this replaces — knew three: `PAID`,
`PENDING`, `FAILED`. The backend enumerates six, and the three it did not know
are the interesting ones:

- `REJECTED` — a GCash proof declined on review. Needs support, **not** another
  payment attempt. `PaymentState.rejected.invitesPayment` is false, and a
  canonical intent for one would be refused with `PAYMENT_STATE_CONFLICT`.
- `REFUNDING`, `REFUNDED` — money went out. Neither is `PAID`.

A seventh value, `unknown`, is deliberately distinct from `pending`. Mapping an
unrecognised state onto a known one is how a client offers "Pay now" for a
booking the server considers settled.

`state` is *"Settlement truth. SEPARATE from the booking lifecycle state and
linked to it."* TAB 09 pinned the other half of that for `CustomerBooking`; this
type completes it.

---

## 5. What the client deliberately does not model

**`returnOrigin`.** `PaymentIntentRequest`'s only property, and *"matched
against a SERVER-SIDE allowlist. Never used as a URL — a caller-supplied return
target would let a payer be returned to another application."* This client
sends an **empty body**. A mobile app has no origin worth nominating, and the
request that cannot be wrong is the one that expresses no preference. Asserted.

**`earning`, `payout`, `provider`, `servana`.** `GET …/payment` serves three
seats and discloses different fields to each — the provider never sees the
refund position, the customer never sees the provider share. This is the
customer's client, so those four have no parser. A field a customer app cannot
receive is a field it must not have a parser for: the parser would be the thing
that made a disclosure bug invisible.

**Any arithmetic on the breakdown.** *"Backend-computed. Clients display it and
never recompute it."* There is no `basePrice + additionalWork` in
`PaymentBreakdown`, which would be a second opinion on a total the server
already sent.

---

## 6. No idempotency keys, and why that is not an oversight

TAB 10 established the opposite habit for booking actions, so this is worth
stating. None of the three payment operations takes a key, and none of them
lists `IDEMPOTENCY_KEY_INVALID` or `IDEMPOTENCY_KEY_REUSED` among its errors.
Each has a stronger guard of its own:

- **checkout** — an advisory transaction lock on the booking, reuse of a live
  session for the same return origin, and a processor `Idempotency-Key` derived
  from the payment row and its attempt counter. The replay protection is
  *inside* the processor call, where a client-supplied key could not reach.
- **refund** — the ceiling is `captured - alreadyRefunded`; a customer repeat
  returns the SAME open review row rather than opening a second.
- **payment read** — a GET.

Adding key plumbing here would imply a protection that is not the one actually
operating.

`PaymentIntent.reused` is the observable half: *"true when an existing live
session was returned instead of a new one."* The app already depends on that
behaviour — both stores persist the checkout URL to `DraftRepository` for
crash recovery and call the endpoint again on retry — but had no way to see it.
A regression would have handed a customer two payable sessions for one booking
with nothing in the client noticing.

---

## 7. The error mapper needed no change, and that was checked

Every `PAYMENT_` and `REFUND_` code was read out of `errors.ts` before the
mapper was touched, and the status-driven classification is already correct for
all of them. That absence is now pinned by test rather than left silent — the
TAB 10 OTP codes looked equally fine until their statuses were actually read,
and two of them were wrong.

| Code | Status | Kind | Recovery |
| --- | --- | --- | --- |
| `PAYMENT_STATE_CONFLICT` | 409 | stateConflict | refresh and look again |
| `PAYMENT_PROCESSOR_UNAVAILABLE` | 502 | retryable | try again shortly |
| `PAYMENT_ACTOR_NOT_PERMITTED` | 403 | forbidden | genuinely an access decision |
| `PAYMENT_NOT_FOUND` | 404 | notFound | — |
| `REFUND_PAYMENT_NOT_CAPTURED`, `REFUND_ALREADY_SETTLED`, `REFUND_IN_PROGRESS`, `REFUND_OUTCOME_NOT_REFUNDABLE` | 409 | stateConflict | the world moved |
| `REFUND_EXCEEDS_CAPTURED`, `REFUND_TRIGGER_INVALID` | 422 | validation | ask for less / pick another reason |

---

## 8. Runtime state of every shipped build

**Unchanged. Fully legacy.**

`bookingPayments` is off, so checkout still goes to
`POST /api/:id/paymongo/create`, payment state is still read by re-fetching the
whole booking, and no refund action is offered anywhere.

What ships is the consolidation: one checkout call and one payment read, in
place of four and three. The `BookingDetailScreen` envelope defect is fixed as
a consequence — that path now reads both URL spellings, as the two stores
always did.

---

## 9. Gaps, recorded not fixed

**No refund UI.** The transport, the domain models and the customer trigger
vocabulary are built and tested; there is no sheet. `canOfferRefund` is false
on every build, so a sheet would be unreachable — the same situation as TAB
10's reschedule, where a surface was built because the endpoint existed and the
gate kept it hidden. Refund is a money conversation and the copy needs a
decision this tab did not have: the difference between "requested" and
"refunded" has to be unmistakable on screen.

**The checkout poll is unchanged.** Still five seconds, still up to thirty
minutes, still a whole booking per tick on legacy. Under `bookingPayments` it
becomes `GET …/payment`, but the interval and timeout are client constants that
no backend policy governs, so they were left alone.

**`PaymentStatusParser` still has three callers** — `http_backend.dart`,
`CustomerBooking` and `BookingDetailScreen` — all reading a booking payload
rather than a payment. They are booking-read concerns and not this tab's to
move; `BookingPayment.fromBookingMap` now carries the same fallback chain with
the reasoning attached.

**Upstream, unchanged.** `/api/v1` is still absent from `servana_api`'s
`origin/main`, and there is still no `POST /api/v1/bookings`.

---

## 10. Acceptance gate

```
flutter analyze   → 0 errors, 0 warnings, 39 infos (the unchanged baseline)
flutter test      → 1,854 passed, 6 skipped, 0 failed
```

New tests: 23 in `test/payments/payments_boundary_test.dart`, plus 7 added to
`booking_action_error_mapping_test.dart` and 2 to
`canonical_availability_test.dart`.

Three existing tests changed, each a correction rather than an accommodation:

- **two** source-introspection tests
  (`booking_ux_alignment_test.dart`, `paymongo_flow_test.dart`) asserted the
  literal `PaymentStatusParser.isPaid(booking)` in the checkout screen and both
  stores. The rule they protect — only the payment record may close checkout as
  paid — is unchanged; the code moved. They now assert the call goes through
  the repository **and** that none of the three re-derives the answer itself,
  which is a stronger claim than the string match was.
- **one** new test was added alongside them pinning that payment truth is
  decided in exactly one place, which is what the string match used to imply
  and could no longer prove.
