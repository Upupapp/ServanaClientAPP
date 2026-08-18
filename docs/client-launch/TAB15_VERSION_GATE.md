# TAB 15 — Remote kill-switch and force update on both platforms

**Status:** local scope COMPLETE · **CERTIFIED_WITH_CONSOLE_GAPS**
**Date:** 2026-08-18 · **Commit:** `8d1115f` · **Blocks:** TAB 20

---

## The finding, verified

`lib/common/domain/helpers/update_repo.dart` had **zero callers** anywhere in
`lib/`. Nothing enforced a minimum version. And even called, `in_app_update` is
Play Core and **Android-only** — half the fleet.

This is the structural risk under the whole migration: 94 legacy routes are
`ALIAS_TEMPORARILY` with `Deprecation: true` already in production. When they
retire, every unmigrated installed build breaks, and there was no way to tell
those builds to upgrade or to count them.

## Shape

| file | role |
| --- | --- |
| `version_gate.dart` | pure policy — no Firebase, no Flutter, no I/O |
| `version_gate_repository.dart` | Remote Config + last-known-good cache |
| `version_gate_coordinator.dart` | decision, frequency cap, the `UpdateHelper` call |
| `version_gate_barrier.dart` | outermost wrapper in `MaterialApp.builder` |

The policy is import-free deliberately: it must be certain, so it must be
trivially testable. The barrier sits **above** the router and both banners,
because the gate must run before the first authenticated request.

Remote Config is the transport because it is already a dependency and already
proven here by the Home campaign registry.

## The failure policy — most of the design

| situation | behaviour |
| --- | --- |
| Never fetched, nothing cached | **allow** |
| Previously fetched | **cached minimum enforced, offline included** |
| Unreadable build number | allow |
| Any throw during evaluation | allow |
| `schema_version` newer than this build | **ignored entirely**, never half-applied |
| `recommended` below `minimum` | clamped — the minimum is the safety-critical half |
| Firebase project unconfigured | behaves exactly as if the gate were absent |

Fail-open applies to **never-fetched, not previously-fetched**. A published
minimum was a real decision, and going offline must not be a way to escape it.
That asymmetry is why rollback is not instant for a device that never fetches
again — stated in the runbook rather than discovered during an incident.

## It never nags

Soft prompt capped at one showing per **3 days**. A nag on every resume teaches
customers to dismiss without reading, which costs the hard block its
credibility too. **The cap applies only to the prompt — a hard block is never
suppressed**, and that asymmetry is pinned by test.

The blocking screen states why, offers the store, and **scrolls** — a clipped
"Update now" is a customer with no way forward at all.

## Acceptance gate

| Requirement | Result |
| --- | --- |
| Minimum + recommended gate, both platforms | ✅ |
| Soft prompt and hard block, distinct copy | ✅ |
| Fetch failure fails open | ✅ pinned by test |
| Cached minimum still enforced offline | ✅ by design, documented |
| `update_repo.dart` given a consumer or deleted | ✅ **given exactly one consumer** |
| Build-version telemetry | ✅ `build_number` already flows via `analytics_context_provider` |
| Enforced at launch **and** resume | ✅ own lifecycle observer |
| Runbook written | ✅ `docs/runbooks/VERSION_GATE.md` |
| Hard block + soft prompt on **real devices** | ⛔ **M4.7** |
| Staging rehearsal + **propagation delay recorded** | ⛔ **M4.7** |
| Canonical capability set as a user property | ⛔ **M1** — the layer does not exist here |

## Verification

**18 new tests.** Suite **1455 → 1473 passed**, 6 skipped. `dart format` exit 0,
`flutter analyze --no-fatal-infos` **No issues found**.

The off-by-one is pinned explicitly: a build **equal** to the minimum is
supported. That boundary is the difference between a working fleet and a
fleet-wide outage.

## Why the propagation number matters to TAB 05

TAB 05 rehearses rolling back a bad migration wave by shipping a build. If that
takes more than an hour, **TAB 15 becomes its prerequisite rather than a
parallel workstream.** The rehearsal is the measurement that decides it, and it
needs the console.
