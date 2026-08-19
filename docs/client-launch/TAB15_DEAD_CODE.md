# TAB 15 — Front-end integrity: dead code and the route-integrity gate

**Date:** 2026-08-19 · **Status:** dead-code and gate scope COMPLETE;
viewport matrix blocked on **M1**

---

## The gate

`test/common/routing/route_integrity_test.dart` fails when any `goNamed` /
`pushNamed` target is not a name the router declares.

`context.goNamed('X')` on an unknown name throws `GoException: no routes for
name` — at runtime, on tap, with no compile-time warning and no test failure. It
is invisible until a customer finds it.

It reads the source rather than building the real `GoRouter`, which would need
the dependency graph, Firebase and a binding. A test that needs the whole app to
start is a test that gets skipped.

**Watched to fail — for real, not with a synthetic mutation.** Written before the
deletions below, it went red with exactly 2 offenders. After them: green.

## Deleted — 766 lines

### The `job_order` checkout branch — 712 lines

```
CheckoutJobOrderScreen ──"Continue"──┬─→ CashPaymentScreen   (cash)
   (never routed)                    └─→ QRPaymentScreen     (default)
```

Both targets were called with `goNamed` on names **the router does not declare**.
Unreachable, so nobody hit it — but wiring that screen in would have crashed the
**money path** on first tap, on both branches.

Zero external references, zero test coverage. Deleting is the proof: the analyzer
stayed silent, so nothing used them.

### `ProtectScreen` — 54 lines

A bare `Scaffold` placeholder from the original baseline import (2026-07-18),
never touched since.

## Kept, deliberately — 651 lines

Not every orphan should be deleted, and saying which and why is the point.

| screen | lines | why it stays |
| --- | --- | --- |
| `ServiceCategoryListScreen` | 495 | Catalog-shaped, and **catalog-v2 is in flight** — commit `4d2b2a0` deliberately kept four category routes after deleting their screens. Deleting scaffolding while its migration is being written is how a migration loses a piece. |
| `AccountPendingForApprovalScreen` | 156 | Registration-flow. Last touched only by a sweeping legal-links fix, so it is probably dead — but "probably" is not the standard for deleting a signup-flow screen, and an approval gate may be part of the identity work in TAB 09. |

Both are unreachable today. **Neither can crash**, because nothing navigates to
them — which is the difference between these and the checkout branch.

Revisit after TAB 07 lands the canonical layer: the 43 unlanded commits may
reference either.

## Still blocked — the viewport matrix

`test/support/screen_test_container.dart` is in the unlanded commits (**M1**), so
there is no 13-screen matrix here to extend to 62. Building a second harness
would collide with the real one when those commits arrive.

What the existing 13 already found, and why this matters more than it sounds:
a heading clipped at **every** viewport and **every** text scale on the
**safety** screen, and the rewards screen clipping by 411 px at 320×568 at text
scale 2.0. Both found in about a minute, because nothing else in the suite builds
a screen at a viewport. The 49 uncovered screens include booking, checkout,
payment and the address form.

## Unchanged and verified

- **DI graph intact** — 73 registered, 49 resolved, zero missing.
- **Route reachability 55 of 56.** The one exception, `CategoryExperience`, is
  deliberate per `4d2b2a0`.
