# Master Supervisor — operational memory

**Master Command** Servana Client Mobile — Backend Convergence V1 (20 TABs)
**Repo** `C:\Users\paulg\OneDrive\Desktop\servana_client-mobile` (branch `main`)
**Backend (read-only evidence)** `C:\Users\paulg\OneDrive\Desktop\servana_api-main`

## Path correction

The Master Command names `servana_client-main`. That folder does **not** exist.
The user supplied `servana_client-mobile`, whose `origin` is
`https://github.com/Upupapp/ServanaClientAPP.git` — so this is the same project
the command describes, locally checked out under a different folder name. Local
files are authoritative per TAB 01.

## The one structural fact that governs every TAB

`/api/v1` is **absent from the backend's `origin/main`** — 51 unpushed backend
commits. So every canonical data source in this repo is real, tested, and
**gated off**. `CanonicalAvailability` is deny-by-default and can only be opened
by `--dart-define=CANONICAL_V1_ENABLED=true` plus a per-capability list. It is
deliberately not a runtime probe and not remote-configurable.

This is an upstream deployment gap, not a client defect. It is why the pattern
is *build both transports, ship on legacy*.

## Established architecture (TAB 02, do not re-litigate)

    FeatureRepository
      → <Feature>CanonicalDataSource      when CanonicalRouter says the capability is on
      → <Feature>CompatibilityDataSource  otherwise
      → one domain model returned to BLoC/UI either way

Key files:
- `lib/core/network/canonical_availability.dart` — the gate + `V1Capability` enum
- `lib/core/network/compat/canonical_router.dart` — `select<T>()` / `isCanonical()`
- `lib/core/network/v1_api_client.dart`, `v1_endpoints.dart`, `api_error_mapper.dart`, `api_failure.dart`
- `lib/core/session/session_token_store.dart`, `secure_session_store.dart`, `session_cleanup_service.dart`
- `docs/convergence-v1/TAB02_MIGRATION_MANIFEST.md` — the running manifest

## Completed TABs

| TAB | Subject | Evidence |
| --- | --- | --- |
| 01 | Sweep + delta matrix | `docs/convergence-v1/TAB01_*.md` (5 docs), commits `d7701c4`, `0dc6e87`, `c32fbb3` |
| 02 | API client / DTO / compatibility | `feb05dd` (v1 boundary), `f94d5a5` (notifications pilot + manifest) |
| 03 | Auth / identity / session | `c454325` (identity boundary), `22e3316` (secure token store) |
| 04 | Catalog V2 | `f0da42b` (catalog transport + canonical booking identity) |
| 05 | Home composition | `2148c15`, `TAB05_CERTIFICATION.md` |
| 06 | Search | `5e6fed3` (server-side discovery, qualified refs) |
| 07 | Booking-entry normalization | `8db8cf8` |
| 08 | Booking submission — create BLOCKED | `7aa4f7c`, `TAB08_ENDPOINT_GAP.md` |
| 09 | Booking READ transport | `861e781` (`bookingReads`) |
| 10 | Tracking / OTP / cancel / reschedule | `TAB10_CERTIFICATION.md`, manifest §8 |
| 11 | Payments / refunds | `TAB11_CERTIFICATION.md`, manifest §9 |
| 12 | Change orders / disputes | `TAB12_CERTIFICATION.md`, manifest §10 |
| 13 | Conversations | `TAB13_CERTIFICATION.md`, manifest §11 |

## ⚠ TAB 13 withdrew a TAB 01 finding — go measure, always

`V1Capability.conversations` sat defined-but-disabled for **eleven tabs**
because R-10 recorded *"opening a booking chat may create the conversation …
SC-038 records the current lazy-create as a defect"* and classified it BREAKS.

Measured in TAB 13: `chat.controller.getBookingConversation` calls
`getExistingConversation` and 404s. It creates nothing, and the comment names
this client's 404-to-null mapping as the contract it was written against. The
fix had happened upstream and nobody re-checked.

A recorded finding is a snapshot of a moving system. When one blocks work,
measure it before planning around it.

## The taxonomy TAB 12 named — three kinds of absence

Worth carrying into every later tab, because the treatments differ:

| Kind | Example | Treatment |
| --- | --- | --- |
| legacy lacks it | reschedule, customer refunds, disputes | a `supports…` flag on the interface |
| canonical lacks it | `DELETE /api/user/notifications/:key` | absent from the canonical source; the repository calls compatibility directly |
| **this actor** may never call it | `bookings.additionalWork.create` | absent from the interface **altogether** — no method, no flag |

The third is the subtle one. `additionalWork.create` is `implemented`, has a
live legacy alias, and works — for a **provider**. A `supports…` flag would
advertise a capability that is permanently false for this client and invite the
next reader to ask which deploy turns it on.

## And the vocabulary rule, refined

TABs 10 and 11 mirrored closed lists (`RESCHEDULE_REASONS`, the customer subset
of `REFUND_TRIGGERS`) because no endpoint hands the list over before the
request. Disputes do: `GET …/disputes` returns `categories` **outside any
branch**, so it arrives even for a booking with zero disputes.

**Where the backend serves its own vocabulary, consume it.** `DisputeCategory`
is an extension type over a String, not an enum, because the backend documents
its list as a growing superset — a closed enum turns each backend addition into
a client release.

## ⚠ The Master Command text is NOT in this repo

TAB titles 01–10 came from the original session's prompt. A fresh session sees
only `currentTabIndex` in `state.json`, and `TAB01_CONVERGENCE_RISK_MATRIX.md`
§3 says outright that its sequencing is *"recorded as a finding of TAB 01, not
as a plan."*

TAB 11's subject was therefore **chosen by the user** from an evidence-based
shortlist. **Ask for TAB 12's** rather than inferring it — guessing wrong fills
a numbered slot with another tab's work and writes a false claim into
`completedTabs`, which the next session reads as ground truth.

## TAB 11 — the duplication, and what legacy cannot do

TAB 08 collapsed four per-category booking-create ceremonies into one service.
Payments had the identical shape and were not part of it: **four** copies of
"start a checkout" and **three** of "is it paid". They had diverged —
`BookingDetailScreen._continuePayment` unwrapped the response envelope but read
only the root key for the URL, so a wrapped response the two booking stores
handled would have failed there. Fixed by the consolidation.

The other half is what legacy simply lacks. Two of the three canonical
operations have **no predecessor at all** — no payment-state endpoint (R-06)
and no customer refund route — so `bookingPayments` is the first capability
whose flip adds a question the app could not ask. `hasPaymentDetail` and
`canOfferRefund` let a caller tell which world it is in instead of rendering an
unknowable zero as a price.

Two things to carry forward:

- **A customer REQUESTS; only an admin ISSUES.** A successful customer refund
  call opens a review row and moves no money. `RefundResult.isMoneyMoving` is
  false for it. No refund UI was built partly for this reason — the copy has to
  make that unmistakable.
- **Payment state has six values, not three.** `REJECTED` needs support rather
  than a retry; `REFUNDING`/`REFUNDED` are not `PAID`. An unrecognised value
  maps to `unknown`, never to `pending`, because `pending` is the one state
  that invites a payment.

## TAB 10 — the two capabilities and the defect under them

`bookingLifecycle` (cancel, reschedule, otp request/verify/status) and
`bookingTracking` (the tracking snapshot). Two, not one, and neither folded
into `bookingReads`: a read from the wrong transport shows stale data, an
action from the wrong one changes a customer's booking, and tracking moves a
privacy boundary. All three must be independently switchable, and that is
asserted.

**The defect that gated the tab.** `V1ApiClient` sent `X-Idempotency-Key`. The
canonical routes read `Idempotency-Key` and nothing else
(`api/v1/envelope.ts`, `IDEMPOTENCY_HEADER = 'idempotency-key'`). Every
canonical call before TAB 10 was a GET, so no key had ever been consulted —
and `v1_api_client_test.dart` pinned the wrong name. A retry of a cancel would
have been a second action while the client believed it was protected.

**The rule TAB 10 kept applying.** Find the place the client holds a copy of a
server rule, and delete the copy:

- the OTP screen's `_resendCooldownSeconds = 60` → `GET …/otp/status`;
- the cancel sheet's one-sentence "contact support" → the per-refusal code;
- the legacy `{success:false}` at HTTP 200 → a typed `ValidationFailure`;
- `BookingActionResolver` → demoted to the labelled fallback behind
  `availableActions`, **including when the backend list is empty**.

Reschedule is the one place a vocabulary was mirrored on purpose
(`RESCHEDULE_REASONS` is closed and append-only, and a reason must be pickable
before a request exists). No policy was mirrored: notice window, lead bound,
reschedulable states and the calendar check are all read from the refusal.

## TAB 05 — Home composition (historical)

Uncommitted work found in the tree at session start (5 new files + the `home`
enum value). Architecture is sound. Two **real contract defects** found by
reading the backend, both in the wire layer:

1. **`fetchSection` called the wrong endpoint.** It hit
   `GET /api/v1/home/sections` with `?section=<name>` expecting content. That
   route is a **metadata registry** (`describeSections` — type, audience,
   failureMode, ownedBy, ttlSeconds) and takes no such param. The real
   per-section fetch is `GET /api/v1/home?sections=<name>`.
2. **`HomeComposition.fromJson` could not parse the real payload.** It expected
   `sections` to be a map keyed by type. The backend returns an **array of
   section envelopes**. The parser fell through to the root keys, matched
   nothing, and produced an empty composition → `isUsable == false` → **blank
   Home**.

### Real backend contract (`src/services/home/homeService.ts`, `homePolicy.ts`)

    GET /api/v1/home?sections=a,b,c   → HomeFeed
    {
      "sections": [ { "type", "status": "ok"|"unavailable",
                      "items": [...], "reason", "ttlSeconds" } ],
      "meta": { "requested", "unavailable", "personalized", "generatedAt" }
    }

`reason` values: `EMPTY`, `REQUIRES_AUTH`, `NOT_CONFIGURED`, `UNAVAILABLE`, null.
Seven section types: `categories`, `featuredServices`, `popularServices`,
`recentServices`, `activeBooking`, `notificationSummary`, `banners`.

`banners` is declared but **always empty** with `NOT_CONFIGURED` — the backend
has no promotions source and deliberately refuses to invent one. The client's
own Remote Config campaign/banner system therefore stays as the banner source.
Client enum names it `promotions` and accepts both wire names.

## Next action

TAB 14 — **ask the user for its subject**, per the provenance note above.
Remaining candidates: `reviews` (backend gap R-11 — 5 of 9 legacy calls are
KEEP, so it may still be genuinely blocked; **measure before believing that**,
given TAB 13), and the `account`/`settings` remainder (19 + 2 entries, partly
covered by TAB 03's `identity` and `customerProfile`).

TAB 13 is certified: analyze 0 errors / 39 infos (unchanged baseline), 1,888
tests passing.
