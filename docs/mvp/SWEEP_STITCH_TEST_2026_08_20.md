# Customer mobile — SWEEP + STITCH + TEST, 20 August 2026

**Goal:** one customer, end to end, on the features that exist today.

Every figure below was **measured** on 2026-08-20 — against
`api.servana.com.ph`, against the backend commit production runs
(`f8d9b78`, verified byte-equal to `Upupapp/servana_api` main), or by
rendering the app's own screens. Nothing here is inferred from a comment.

---

## The headline

**Two thirds of the catalogue could not be booked, and nobody had noticed
because the failure was a disabled button rather than a crash.**

| | |
| --- | --- |
| Services in the canonical catalogue | **95** |
| Bookable before this sweep | **30** (category 2 only) |
| Bookable after | **94** |
| Still not bookable | **1**, for a backend reason (§B1) |

---

## What was found, in the order a customer meets it

### 1 · The catalogue dead-ended for 65 of 95 services — P0, fixed

Home's "More services" row and Search both route into the canonical catalogue
(`CatalogRoutes.category` / `CatalogRoutes.service`). From a service page,
`startCanonicalBooking` sends category 2 to the aircon checkout and
**everything else** to the Beauty & Wellness one.

The Beauty & Wellness checkout has no branch control, no date control and no
slot control — it *displays* those choices, it does not offer them. They are
made one screen earlier, on `BwBranchSlotScreen`, which the catalogue handoff
skips. And the store submitted with `requiresBranch: true`, unconditionally.

So the customer arrived at a checkout with an address and a payment method,
pressed **Confirm Booking**, and got:

> Complete the service, branch, schedule, address, and payment details.

for ever. Measured, not read — with an address selected, a date set and a
payment method chosen, the store returned that string and
`createdBookingId = null`.

**The client was stricter than the server.** `bookingCreateValidation.ts`
types `branchId?: number` and explicitly maps `undefined | null | ''` to
absent; `bookingService.createBooking` guards every branch read with
`if (payload.branchId !== undefined)`. A booking with no branch is accepted.

And there was nothing to choose anyway:

| legacy family | services | branches | coverage rows |
| --- | ---: | ---: | ---: |
| 1 Aircon 2 (Home Services) | 30 | **0** | 5 |
| 2 Beauty & Wellness (Personal Care) | 54 | 1 | 5 |
| 52 Massage (Personal Care) | 10 | **0** | 1 (Manila, 25 km) |
| 67 Electrical (Home Maintenance) | 1 | **0** | **0** |

`GET /api/services/:id/branches` returns `{"success":true,"branches":[]}` for
**nine of the ten** legacy families. The one branch that exists is a sample
row, "BGC Clinic".

That also means the *legacy* path dead-ended: `BwBranchSlotScreen` auto-selects
the first branch, there is no UI to pick one, `loadSlots()` returns early with
no branch, and `Continue` stays disabled with nothing on screen explaining why.

**Fixed:**

- `branchRequired` is derived from whether branches were actually loaded, so
  the one family that has a branch still requires it.
- `selectedSchedule` / `effectiveSchedule` — a branch slot carries capacity the
  backend locks; a directly-chosen time does not. They are alternatives, never
  both, and `null` still separates *not chosen* from *in the past*.
- The checkout draws a date-and-time picker when there is no branch.
- The branch/slot screen says *"This service is scheduled directly with your
  provider, so there are no branch times to choose from"* and offers a time.
- `beginBranchlessBooking()` clears a branch list left from another category —
  `clearSelectionOnly()` deliberately preserves it for catalogue reuse, which
  would otherwise make a Search booking demand a branch it never showed.
- Refusals name only what is missing.

### 2 · A failed booking told the customer the wrong thing — fixed

Both stores rendered the backend's own sentence for an API error and
`e.toString()` for anything else, so a dropped connection put

> SocketException: Failed host lookup: 'api.servana.com.ph' (OS Error: No
> address associated with hostname, errno = 7)

in a snackbar (§21).

`BookingErrorMapper`, written for exactly this and carrying the rule that raw
API bodies must never be shown, had **zero production callers** — the same
shape as `ErrorMessageMapper.forRegistration` before TAB 02.

Wiring it in as it stood would not have been enough: it classified by keyword,
and the booking route's real refusals contain none of the keywords it searched
for. `createBooking` throws **"Service not available in your area."** for an
out-of-coverage address — no "address", no "coverage" — so it matched nothing
and arrived as *"Something went wrong. Please try again."*, which is advice to
repeat the one action that cannot succeed.

Now status first, then the body's `code`, then prose only to sharpen a category
the status already chose. A 500-class failure can never be reported as a
connectivity problem; 408, minted by the client's own timeout wrapper, is the
only status that can.

### 3 · The Booking Calendar showed a booking the server never sent — fixed

Reachable from the home drawer. Tapping any booking opened
`JobOrderSummaryScreen`, which reads the merchant/job-order surface of
`Backend`. In a release build (`MOCK_BACKEND` defaults to `false`) that surface
is a stub: `getMerchantJoDetails` and `getMerchantDetails` return null,
`getJobOrderItems` and `getJobOrderEmployees` return `[]`, `insertJobOrder`
returns `false`.

Rendered against that composition — **not** against the test container's
`MockBackend`, which is what made this invisible — a real booking produced:

```
ACCEPTED · Schedule: <today, now> · Distance From Office: null km
Services: (none) · Total: ₱0.00 · No assigned personnel
```

Not one field came from the booking. The status was a default, the schedule was
`DateTime.now()`, and `null` reached the screen as a word.

The calendar's own list is real — it comes from `GET /api/users/:id/bookings`
through `HomeStore`. Only the destination was wrong; it now opens
`BookingDetailScreen`, which reads the same booking through
`BookingRepository`.

That was the last edge into the flow from outside it, so the whole
merchant/job-order subgraph is now unreachable. Screens and routes are **kept**,
as Rewards and Favourites were, for the release that builds the surface behind
them; only the affordance is withdrawn. Its "Book Now" called `insertJobOrder`,
which returns `false` every time.

### 4 · A deleted workflow left the gate red — fixed

`27e5793` (a concurrent session, 13:03 today) deleted
`.github/workflows/flutter-ci.yml` and moved its release job into
`scripts/release-android.sh`. Four tests still read the workflow by path. They
did not become lenient, they became **broken** — each threw
`PathNotFoundException`, so `flutter test` exited 1 and
`scripts/hooks/pre-push`, which *is* the deploy step now that there is no CI,
was red for everyone.

Retargeted at the script that now does the releasing, keeping the property each
was written to defend. The freeRASP one is now a property over **every** script
in `scripts/` rather than one named file.

---

## What the app can now do, end to end

`test/e2e/mvp_walkthrough_test.dart` drives the real repositories and
controllers over a transport answering with envelopes captured from production
today:

browse → service detail → handoff → address → schedule → payment method →
**booking created** → My Bookings → booking detail → review eligibility.

The total is asserted at ₱990.00 through a `"990.00"` **string**, which is how
Postgres `numeric` reaches JSON and what once rendered every booking as ₱0.00.

**Four steps are not automated, and are named rather than skipped** — a
walkthrough that quietly omits a step reads as a green light for it:

1. **Email verification** — sign-up mails a 6-digit OTP to a human inbox.
2. **Booking OTP** — `POST /api/bookings` mails an `otpCode`; same out-of-band step.
3. **PayMongo checkout** — a hosted page in a WebView on a real device.
4. **A provider accepting, arriving, completing** — needs the other app.

---

## Backend items — not front-end work

- **B1 · One service cannot be booked anywhere.** Legacy family 67 (Electrical
  Services) has **zero** `service_coverage_geo` rows, and `checkCoverageGeo`
  returns `covered: !!match` — absent configuration fails **closed**. Every
  booking of canonical service **180 "Wiring fuitures"** is refused with
  "Service not available in your area." That is the entire Home Maintenance
  category. It also contradicts §28, which says no explicit restriction means
  all supported cities.
- **B2 · Massage is Metro Manila only.** Family 52's single coverage row is
  25 km around (14.5547, 121.0244). Ten services. Probably intended; recorded
  because nothing in the app says so before the customer submits.
- **B3 · MongoDB is an unlisted dependency of booking creation.**
  `createBooking` resolves the address through `getLatLonByLocationId`, which
  reads the Mongo `addresses` collection and **throws** when the document is
  missing. `/readyz` lists five dependencies and Mongo is not among them, so a
  Mongo outage would make every booking fail while readiness still reported
  `ready:true`.
- **B4 · The one branch in production is a sample row** ("BGC Clinic, Unit 12,
  Sample Building, BGC"). Branch capacity is the only path that exercises
  `SLOT_UNAVAILABLE`/`SLOT_FULL`.

---

## Gates

| gate | result |
| --- | --- |
| `dart format --set-exit-if-changed` | exit 0, 733 files, **0 changed** |
| `flutter analyze --no-fatal-infos` | exit 0, **No issues found** |
| `flutter test` | exit 0, **2,680 pass**, 3 skipped |

Suite 2,647 → 2,680.

**Every new gate was watched to fail before it was believed.** Five mutations:
restoring `requiresBranch: true` (2 fail), making `effectiveSchedule` ignore a
direct schedule (3 fail), removing the 500-class branch from the error mapper
(3 fail), reverting `_money` to the `as num?` chain (2 fail), regenerating the
idempotency key per attempt (1 fail).

**One of them caught a gate that was lying.** The first version of
`no_route_into_stubbed_flow_test.dart` scanned line by line, and `dart format`
puts `context.pushNamed(` and `SomeScreen.routeName` on separate lines — so it
could not see a single navigation edge in the whole repository. It passed, and
it *still passed* when the bad edge was put back. It now scans whole files and
asserts a floor on how many edges the pattern finds at all, so "no offenders"
can never again mean "no matches".

---

## Commits

Local, on `main`. Nothing pushed.

| | |
| --- | --- |
| `ff920c6` | 65 of 95 services could not be booked at all |
| `5810996` | a failed booking told the customer the wrong thing |
| `b2779a0` | walk the journey, and repair the gate a deleted workflow broke |
| `7fed342` | the Booking Calendar opened a summary the server never sent |

`27e5793`, between the second and third, is **not mine** — a concurrent session
committed it mid-sweep.

---

## The lesson worth keeping

All three customer-facing defects were invisible for the same reason: **the
test harness composes `MockBackend`, and production composes `HttpBackend`.**
Seven `Backend` methods return `null`/`[]`/`false` unconditionally in every
release build. Rendered under the harness, `JobOrderSummaryScreen` showed a
plausible booking for "Juan Dela Cruz"; rendered under the production
composition, it showed `null` and ₱0.00.

The branch defect had the same shape one level up — a client rule stricter than
the server it talks to, provable only by reading the handler rather than the
schema, and visible only by driving the flow rather than the unit.

**If the next session must choose where to spend effort on this app: compose it
the way `main.dart` composes it, and drive the flow.**
