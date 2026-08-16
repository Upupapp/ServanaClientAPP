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

TAB 11. TAB 10 is certified: analyze 0 errors / 39 infos (unchanged baseline),
1,823 tests passing.
