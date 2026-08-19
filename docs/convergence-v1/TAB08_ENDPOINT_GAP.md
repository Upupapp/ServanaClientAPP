# TAB 08 — booking create has no canonical endpoint

**Date** 2026-08-16 · **Verified against** `servana_api-main` @ `36ca152`

## The finding

There is **no `POST /api/v1/bookings`**.

This was re-verified directly against `src/api/v1/contract.ts` for this tab
rather than inherited from TAB 01. Every entry in the `bookings` domain is one
of two things:

| Kind | Entries |
| --- | --- |
| **Read** | `bookings.listMine`, `bookings.get`, `bookings.timeline`, `bookings.transitions`, `bookings.tracking`, `bookings.otp.status`, `bookings.reschedule.history`, `bookings.additionalWork.list`, `bookings.disputes.list`, `bookings.supportCases.list`, `bookings.payments.get`, `bookings.review.get` |
| **Action on an ALREADY EXISTING `:bookingId`** | `bookings.cancel`, `bookings.reschedule`, `bookings.otp.request`, `bookings.otp.verify`, `bookings.additionalWork.create`, `bookings.disputes.open`, `bookings.supportCases.create`, `bookings.review.create`, `bookings.payments.intent`, `bookings.refunds.create` |

Nothing creates a booking. The legacy `POST /api/bookings` is classified `KEEP`
with no canonical successor and none planned.

## What that means for TAB 08

The Master Command's headline instruction for this tab — *"make them submit
through one canonical Booking create contract"* — has no endpoint behind it.
Fabricating one was not an option, so the tab delivered the half that is real:

| Asked for | Status |
| --- | --- |
| One `BookingDraft`/`BookingCreateRequest` used by all category flows | **DONE** — `BookingCreateRequest` |
| All category flows call the same booking repository contract | **DONE** — `BookingSubmissionService` |
| No duplicate booking state machine per category | **DONE** — one ceremony, category-specific fields only |
| Backend-owned price/state | **DONE** — inputs only, asserted by test |
| Idempotency on create/retry | **DONE** — key minted once per real attempt, reused on retry |
| UI prevents double-tap duplicate creation | **PRESERVED** — `isSubmitting` guard, not reset on success |
| Submit via `POST /api/v1/bookings` | **BLOCKED — endpoint does not exist** |

## Idempotency, precisely

v1 has first-class `Idempotency-Key` semantics with `IDEMPOTENCY_KEY_INVALID`
and `IDEMPOTENCY_KEY_REUSED` — but only on the actions that exist
(`bookings.cancel`, `bookings.reschedule`, and others). Create is not among
them, so the client continues to send `X-Idempotency-Key` on the legacy route.

## A second gap, recorded not fixed

The legacy create takes the customer as a query parameter, `?userId=`. The
submission service resolves it from the **session** and never from screen
state, which is as far as a client can carry the Master Command's *"without
trusting customerId from screen state for authorization"*. It remains a
client-supplied identifier on the wire. Closing it requires the endpoint to
take identity from the token, which is a backend change.

## When the canonical create arrives

One method changes: `BookingSubmissionService.submit`. The stores, the request
model, the validation, the journal and the tests do not.
