# TAB 19 — Dependency currency and supply-chain hygiene

**Status:** COMPLETE · **CERTIFIED** · **Date:** 2026-08-18 · **Commit:** `404dc23`

---

## The finding that mattered most was not a package

`flutter-version: 3.47.0` is now pinned in **all five** CI jobs.

`channel: stable` with no version is not reproducibility — it is a subscription
to whatever Flutter ships next, and it had already cost this project a working
Android build. On 2026-08-18 `flutter build appbundle --release` failed on two
version floors (Gradle 8.13 < 8.14.0, Kotlin 2.0.0 < 2.2.20) **with no
repository change**.

`pubspec.lock` pinned the packages. Nothing pinned the SDK that resolves them.

## The discontinued-package finding was wrong in both directions

The Master Command reports "one discontinued dependency". Measured: **five**,
and **every one is transitive** — so **zero direct dependencies are
discontinued**.

| package | via | note |
| --- | --- | --- |
| `flutter_secure_storage_macos` | `flutter_secure_storage` | security-relevant parent |
| `flutter_map_cancellable_tile_provider` | map stack | |
| `js` | several | superseded by `dart:js_interop` |
| `build_resolvers` | `build_runner` | dev-only |
| `build_runner_core` | `build_runner` | dev-only |

The correct action is to upgrade the **parent** and re-check — chasing the child
directly is how a dependency override ends up pinning something nobody
understands.

## Security-relevant upgrades — individually, pass after each

| package | from → to | result |
| --- | --- | --- |
| `freerasp` | 8.0.0 → **8.2.1** | analyze clean · 1487 pass |
| `flutter_secure_storage` | 9.2.2 → **9.2.4** | analyze clean · 1487 pass |
| `webview_flutter` | 4.13.1 → **4.14.1** | analyze clean · 1487 pass |

Not batched — an unattributable regression across a security SDK costs more than
the upgrades saved. `freerasp` is the RASP SDK itself; `webview_flutter` carries
the PayMongo checkout.

**Deliberately not done here:** the Firebase suite has minors available within
constraints. A five-package Firebase bump landing in the same commit as
everything else is exactly the unattributable batch the standing rule forbids —
it belongs to the first cadence cycle. `flutter_secure_storage` 10.x/11.x cross
a major boundary and are a deliberate migration, not a cadence item; it holds
session and draft state.

## Pre-1.0 pinned exactly

pub treats the minor position as breaking below 1.0, so a caret on `0.x` accepts
breaking changes automatically. **It is not a loose pin, it is no pin.**

`intl 0.19.0` · `overlay_tooltip 0.2.3` · `ticket_clippers 0.0.8` ·
`flutter_switch 0.3.2` · `firebase_performance 0.10.0+10` ·
`easy_stepper 0.8.5+1` · `flutter_launcher_icons 0.14.4`

Versions read from the lock rather than guessed, so each pin records what
already resolved and changes nothing about today's build.

## `collection` declared at last

Imported by `registration_bloc`, `add_item_bloc` and `store_items_bloc` while
only ever transitive — a build that breaks on somebody else's release note. Now
pinned direct at `1.19.1`. **Pinned, not `any`**: `dart fix` offers `any`, and
that is looser than the caret-on-0.x case this project already refuses.

## Acceptance gate

| Requirement | Result |
| --- | --- |
| Zero discontinued packages | ✅ **zero direct**; five transitive, each traced to its parent |
| Security-relevant current, each verified individually | ✅ three upgraded, one pass each |
| Pre-1.0 pinned exactly | ✅ seven |
| `flutter pub get` from a clean checkout, empty cache | ✅ exit 0 |
| All three gates green after upgrades | ✅ format 0 · analyze clean · 1487/6 |
| Written maintenance cadence | ✅ `docs/DEPENDENCY_CADENCE.md` |
| TAB 17 matrix re-run after upgrades | ⛔ **the matrix does not exist in this tree** (M1) |

## Handoff

`docs/DEPENDENCY_CADENCE.md` has **no owner**. A cadence with no name is a
document, not a practice — assign one before launch (**M4.17**).
