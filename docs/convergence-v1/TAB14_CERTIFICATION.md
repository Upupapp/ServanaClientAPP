# TAB 14 — Reviews

**Date** 2026-08-16 · **Repo** `servana_client-mobile` @ `main`
**Backend evidence** `servana_api-main`, read directly from source

> **Provenance.** The Master Command text is not stored in this repo. TAB 11's
> subject was the user's; TABs 12–14 were mine. Recorded in `state.json`.

---

## 1. R-11 was re-measured, and it holds

TAB 13 withdrew R-10 as stale, so R-11 was **measured rather than inherited**
before a tab slot was committed to it. The result is the opposite of TAB 13's:

| Client call | Canonical successor |
| --- | --- |
| `getEligibility` | `bookings.review.get` — **folded in** |
| `getByBooking` | `bookings.review.get` |
| `createReview` | `bookings.review.create` |
| `getProviderAggregate` | `reviews.provider.rating` |
| `getById` | **none** |
| `editReview` | **none** |
| `deleteReview` | **none** |
| `listMyReviews` | **none** |
| `reportReview` | **none** |

Four of nine, exactly as R-11 said — *"5 (`GET/PUT/DELETE /api/reviews/:id`,
`/reviews/me`, `…/report`) are `KEEP`"*.

**So R-11's conclusion stands and its remedy was too blunt.** The manifest
declined to define a `reviews` capability, which is right: the domain cannot be
named. But the four calls that DO migrate are a coherent slice, and the five
that do not are the per-call escape this codebase has used since TAB 02. The
correct move was not "no capability" but "not a *domain* capability" — the same
distinction that produced `bookingReads` in TAB 09.

Two slices, because they are two questions on two screens:

- **`bookingReview`** — the review I leave on my own booking.
- **`providerReputation`** — what other customers said about a provider, read
  from a profile with no booking in sight. Read-only, so an operator can move
  it first.

---

## 2. Two calls become one, and that closes a race

`bookings.review.get` returns `ReviewOrEligibility` — *"the caller's own review
for a booking, or the eligibility verdict when there is none"* — and the
contract names the client's current habit as the reason:

> A SECOND call the client makes to decide whether to show the form. Folded
> into the read above, because **asking twice means a screen that offers a form
> the next call refuses**.

The client's version of that defect is worse than a race. The two calls are
made by **two different controllers, and neither makes both**:

- `ReviewFormController` asks `getEligibility` and never looks for a review;
- `ReviewDetailController` asks `getByBooking` and never asks eligibility.

So the form could open on a booking that already had a review, because it had
no way to know.

`reviewOrEligibility` is now one method. The canonical source gets one
response; the compatibility source issues both legacy calls **in parallel** and
folds them, with an existing review winning. That does not remove the race —
the two verdicts are still computed at two instants — but it puts the
resolution in one place, so both controllers get the same answer instead of
each asking half the question.

`getEligibility` is retained for the existing form controller and now answers
through the fold, synthesising `ALREADY_REVIEWED` when a review exists. The
controller was not touched.

---

## 3. Idempotency is a body field again

`clientRequestId` is the review's own idempotency handle and travels in the
body, so no `Idempotency-Key` header is sent — the same distinction TAB 13 drew
for a message's `clientMsgId`, and asserted for the same reason: the habit
established in TAB 10 would make a header look correct.

---

## 4. Runtime state of every shipped build

**Unchanged. Fully legacy.** Both capabilities are off.

One behavioural improvement does ship, on the legacy path: `getEligibility` now
accounts for an existing review. A customer whose booking was already reviewed
no longer gets the form offered to them if the eligibility route says yes —
previously the form controller never looked.

---

## 5. Gaps, recorded not fixed

**Five calls are permanently legacy.** Reading, editing, deleting, listing and
reporting a review by its own id have no canonical surface. They are called on
`ServanaApiClient` directly from the repository, in every configuration.

**`reviews.provider.list` has no client caller.** The canonical contract has it;
the client reads only the aggregate rating. Not wired, because nothing asks for
it.

**Neither controller was migrated to `reviewOrEligibility`.** Both still call
the narrower methods, which now route through the fold underneath. Collapsing
the two controllers onto one call is a presentation change this tab did not
need to make.

**Upstream, unchanged.** `/api/v1` is still absent from `servana_api`'s
`origin/main`.

---

## 6. Acceptance gate

```
flutter analyze   → 0 errors, 0 warnings, 39 infos (the unchanged baseline)
flutter test      → 1,901 passed, 6 skipped, 0 failed
```

New tests: 12 in `test/review/reviews_canonical_test.dart`, plus 1 in
`canonical_availability_test.dart` pinning that `reviews` is still not a
capability name and why.

One existing test changed: the TAB 10 allow-list guard, which **failed on first
run** because `bookingReview` was not in it. That is the guard doing its job —
it exists so a new `booking*` capability is a visible decision rather than a
quiet addition.
