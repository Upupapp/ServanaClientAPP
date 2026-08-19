# TAB 12 — Change orders and disputes

**Date** 2026-08-16 · **Repo** `servana_client-mobile` @ `main`
**Backend evidence** `servana_api-main`, read directly from source

> **Provenance.** The Master Command text is not stored in this repo. TAB 11's
> subject was chosen by the user; TAB 12's was chosen by me — the four entries
> TAB 10 left behind in `booking-experiences`, which is the one remaining
> candidate needing no decision from the user. Recorded in `state.json`.

---

## 1. Two halves that are not comparable

`booking-experiences` has ten contract entries. TAB 10 took six (tracking, the
three OTP calls, reschedule and its history). The four left:

| Entry | Auth | Legacy relative |
| --- | --- | --- |
| `bookings.additionalWork.list` | authenticated | `GET /api/additional/booking/:id` — live, same service |
| `bookings.additionalWork.create` | **provider** | `POST /api/additional/request/:userId` |
| `bookings.disputes.open` | authenticated | `POST /api/admin/bookings/:id/escalate` — **admin only** |
| `bookings.disputes.list` | authenticated | none |

That asymmetry drove every decision in the tab:

- **Change orders** are a read the app *should already have been making*. The
  legacy route has been live throughout and the canonical one *"differs only in
  living under the booking it belongs to."* Flipping the capability changes a
  URL.
- **Disputes** are a capability the customer app **has never had**. The only
  predecessor is admin-only and *"does not record a category, the opening role
  or the state snapshot."* Flipping that capability turns on a feature.

So they are two capabilities over one repository —
`bookingAdditionalWork` and `bookingDisputes` — because an operator must be
able to take the safe half first. Asserted.

---

## 2. The third kind of gap

Earlier tabs met one shape of absence: the legacy transport lacks something the
canonical one has. Reschedule (TAB 10), customer refunds (TAB 11) and now
disputes are all that shape, and all three are reported through a `supports…`
flag so a UI can ask before offering.

**Raising a change order is not that shape.** Nothing is missing.
`bookings.additionalWork.create` is `implemented`, has a live legacy alias, and
works — for a **provider**. Its contract says `auth: 'provider'` and
`customerMobile: 'n/a'`, and the write *"requires an IN_PROGRESS assignment row
held under FOR UPDATE"*, which a customer does not have.

It is therefore absent from the interface entirely — **no method and no flag**.
A flag would imply a capability that could one day be true for this client, and
it never will be: the customer is not the party who raises a change order, they
are the party who approves one. An endpoint this actor may never call is not a
gap to report; it is a method that should not exist here.

Three kinds of absence now have three different treatments, and the difference
is the point:

| Kind | Example | Treatment |
| --- | --- | --- |
| legacy lacks it | reschedule, refunds, disputes | `supports…` flag on the interface |
| canonical lacks it | `DELETE /api/user/notifications/:key` | absent from the canonical source; repository calls compatibility directly |
| **this actor** may never call it | `additionalWork.create` | absent from the interface altogether |

---

## 3. The vocabulary comes from the server — a contrast worth naming

TAB 10 mirrored `RESCHEDULE_REASONS`. TAB 11 mirrored the customer subset of
`REFUND_TRIGGERS`. Both under the same justification: a reason has to be
pickable before a request exists, and no endpoint hands the list over first.

Disputes are different, and better. `GET /bookings/:id/disputes` returns
`categories: DISPUTE_CATEGORIES` **unconditionally** — verified in
`domains/bookingExperiences.ts:493-501`, which sets it outside any branch, so
it arrives even when the booking has no disputes. The one call a screen makes
to show existing escalations also supplies the vocabulary for opening a new
one.

So `DisputeCategory` is an **extension type over a string**, not an enum. The
backend documents its list as *"a superset of the provider-facing categories,
which must remain a subset"* — a set expected to grow. A closed client enum
would drop a new category silently; this humanises an unknown wire name
(`LATE_ARRIVAL_REPEATED` → "Late arrival repeated") so the server can add one
without a client release.

Where the backend serves its own vocabulary, consume it. Where it does not,
mirroring is the least-bad option and is documented as such.

---

## 4. What the dispute model deliberately cannot read

`reason`, `assigned_team` and `actor_uid` are withheld from **every** caller —
*"free text one party typed about another, internal routing, and a person."*

The customer **writes** `reason` when opening a dispute and can never read it
back, not even their own. `BookingDispute` therefore has no `reason` field;
only the outbound `DisputeDraft` does. A model carrying one would be a parser
waiting for a disclosure bug, and a screen showing it after submission would be
displaying its own local copy while implying the platform echoed it back.

`openedByYou` is the only caller-dependent field in the projection.
`stateSnapshot` is held as an opaque map — it is evidence for an investigation,
not a view model, and typing it would invite a screen to render fields the
backend deliberately kept coarse.

---

## 5. `approvedAmount` is not `totalAmount`

`additionalService.getByBooking` returns `approved_amount` as NULL unless the
status is in `WAITING_FOR_PAYMENT`, `WAITING_WORKER_APPROVAL`, `ACCEPTED`,
`IN_PROGRESS`, `PROCEEDING`, `COMPLETED`.

A change order sitting at `PENDING_ADMIN_APPROVAL` has a price and no approved
amount. Rendering the former where the latter belongs tells a customer they are
being charged for work nobody has agreed to yet.
`AdditionalWorkStatus.carriesApprovedAmount` mirrors that `CASE WHEN` set and
is pinned against it by test — used only to *explain* a null, never to compute
an amount the server declined to send.

A change order is *"a priced child record, never a mutation of the original
service"*, which is why `BookingPayment.breakdown.additionalWork` (TAB 11) is
its own line and can be non-zero while the base price is settled.

---

## 6. No idempotency key on `openDispute`

Its replay guard is a partial unique index — *"two simultaneous reports produce
one record and one `BOOKING_DISPUTE_ALREADY_OPEN`, not two disputes"* — and the
contract lists neither idempotency error code. A uniqueness constraint is
stronger than a client key and operates whether or not one is sent. Asserted.

At most one unresolved escalation exists per booking, so `BookingDisputes`
exposes `openDispute` as a **single**, not a list. Modelling it as a list and
letting callers pick would invite three screens to pick differently.

---

## 7. Runtime state of every shipped build

**Fully legacy**, and for the first time in this convergence work that is not
the same as "no change".

`bookingAdditionalWork` and `bookingDisputes` are both off. Disputes are
therefore unavailable — `canOpenDispute` is false and both methods throw.

But **change orders now work on the legacy transport**, because the route was
always there and the app had simply never called it. That is the one thing in
this tab a shipped build could use today, and it needed no deploy.

---

## 8. Gaps, recorded not fixed

**No UI for either half.** Change orders are readable today and nothing renders
them; disputes are unreachable so a sheet would be dead. Both are surfaces with
real design decisions — a change order needs the approved-vs-requested
distinction on screen, and a dispute needs copy that does not imply the reason
will be visible later.

**`AddAdditionalItemMenuScreen` is still routed.** It is in the MerchantMenu
subtree, picks store items, and is unrelated to `booking_additional_requests`
despite the name. It remains reachable from `job_order_screen.dart:558` and is
covered by the standing "MerchantMenu retirement needs TAB 18 evidence" finding
— this tab confirms it is not the change-order surface, which narrows that
investigation.

**`bookings.supportCases.*` and `bookings.review.*`** appear in TAB 08's
endpoint census but are not in the `booking-experiences` domain and were not in
scope here.

**Upstream, unchanged.** `/api/v1` is still absent from `servana_api`'s
`origin/main`, and there is still no `POST /api/v1/bookings`.

---

## 9. Acceptance gate

```
flutter analyze   → 0 errors, 0 warnings, 39 infos (the unchanged baseline)
flutter test      → 1,874 passed, 6 skipped, 0 failed
```

New tests: 19 in `test/booking_experiences/booking_experiences_test.dart`, plus
1 added to `canonical_availability_test.dart`. **No existing test needed
changing** — the first tab in this run where that is true, because nothing was
migrated off an existing path.

One additive change to `ServanaApiClient`: `getBookingAdditionalWork`. It calls
a route that was already live and adds no new legacy surface area.
