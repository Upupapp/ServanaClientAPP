# TAB 03 — Repair the successor-version signpost the backend publishes today

**Status:** local scope COMPLETE · **CERTIFIED_PENDING_DEPLOY**
**Date:** 2026-08-18 · **Backend commit:** `d7a2097` (local, unpushed)
**Owner:** Backend · **Blocks:** TAB 05 rollout telemetry

---

## Before — captured from production, not recalled

`curl -D` against `https://api.servana.com.ph`, 2026-08-18:

| path | `Deprecation` | `Link rel="successor-version"` |
| --- | --- | --- |
| `GET /api/catalog` | `true` | `</api/v1/bookings/:bookingId>` ❌ |
| `GET /api/services` | `true` | `</api/v1/bookings/:bookingId>` ❌ |
| `GET /api/bookings` | `true` | `</api/v1/bookings/:bookingId>` ❌ |
| `GET /api/quote` | `true` | `</api/v1/bookings/:bookingId>` ❌ |
| `GET /api/catalog/summary` | `true` | `</api/v1/catalog/summary>` ✅ |
| `GET /api/user/profile` | `true` | `</api/v1/customer/profile>` ✅ |

## The document named the wrong constant

The Master Command attributes the defect to `GET /api/:bookingId`. The contract
has no such entry. The greedy route is **`GET /api/:id`**, superseded by
`bookings.get`. Immaterial to the fix, material to the habit: measure.

It is also the *only* dangerous one. Six other legacy paths carry a parameter
in first position, and every one has a second literal segment
(`/api/:id/timeline`, `/api/:bookingId/paymongo/create`, …) which bounds them.
Blast radius: one route.

## The cause

`toMatcher` compiled every `:param` to `[^/]+`, so `/api/:id` became
`^/api/[^/]+/?$` — one segment under `/api`, which is exactly what
`/api/catalog` is. Two-segment paths were already correct, so the defect was
precisely the wildcard, not the mechanism.

## The fix — three independent constraints

1. **Integer parameters compile to `\d+`.** Read *positionally* off the
   successor's `params[].type`, not hardcoded: the legacy path says `:id`, the
   canonical successor says `bookingId`. Names differ; positions do not.
2. **A parameter may not match a literal another legacy route claims at that
   position.** Derived from the contract array. Kept even where (1) applies,
   because the two fail differently — one on a type change, one on a new route.
3. **Notices ordered literal-first.** `findNotice` takes the first match, so
   order is part of correctness. Sorted by param count, then literal count,
   then path, so the compiled order is stable and diffable.

## After — local

| path | successor |
| --- | --- |
| `GET /api/catalog` | **`/api/v1/catalog`** |
| `GET /api/catalog/summary` | `/api/v1/catalog/summary` *(unchanged)* |
| `GET /api/user/profile` | `/api/v1/customer/profile` *(unchanged)* |
| `GET /api/services` · `/api/bookings` · `/api/quote` | **no notice** |
| `GET /api/123` | `/api/v1/bookings/:bookingId` *(unchanged)* |
| `GET /api/456/timeline` | `/api/v1/bookings/:bookingId/timeline` *(unchanged)* |

### Why silence, and not a service successor

The acceptance gate anticipated "a service successor for service paths". The
contract holds **no `ALIAS_TEMPORARILY` mapping** for `/api/services`,
`/api/bookings` or `/api/quote` — so a header naming one would be inventing a
migration target, which is what production was doing. The contract is the
authority. If these paths should carry successors, that is a contract change
and a separate decision, recorded below rather than smuggled in here.

## Evidence

- **Pinning test** `tests/deprecation-successor-signpost.test.ts`, 22 tests.
  **Watched to fail:** 6 of 13 red against the pre-fix matcher; green after
  restoring it byte-identical.
- **Additive-only proven by measurement, not by reading.** The middleware runs
  against a response recording every method touched; `status`, `send`, `json`,
  `end`, `write`, `redirect` must all go untouched and `next()` always called.
- **Contract consumers still agree** — `tests/v1-contract.test.ts`, 35 passed.
- **Full backend suite** — 6006 passed of 6007. Heap peak 1133.3 MB of
  4288 MB, 73.6% headroom, above the 70% guard.

## Acceptance gate

| Requirement | Result |
| --- | --- |
| Catalog successor for catalog paths | ✅ local |
| No link for a route the contract does not alias | ✅ local |
| Pinning test shown failing pre-fix, passing after | ✅ 6 red → 22 green |
| Backend suite green | ✅ 6006/6007 (see note) |
| No status, body or timing changed | ✅ asserted by measurement |
| **Deploy + re-probe production** | ⛔ **BLOCKED — M2** |

The single failing test is `suite-inventory`, whose count collides with
uncommitted Provider Web work in the same tree (**M5**). `281` is correct for
the committed tree.

## Handoff

**To the contract owner.** 50 of the 70 legacy routes the customer app actually
calls carry no contract legacy mapping — including `/api/services` and
`/api/bookings`, two of the busiest. They therefore have no successor, no
disposition and no migration story, and the deprecation clock cannot see them.
Surfaced by TAB 01's client-derived enumeration; invisible to the
contract-derived one.
