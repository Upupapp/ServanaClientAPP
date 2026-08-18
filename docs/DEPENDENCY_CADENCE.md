# Dependency maintenance cadence

A one-off upgrade before launch decays within a quarter. This is what stops it.

---

## Classification

Every **direct** dependency is one of three things, and they move on different
schedules. Batching them is what makes a regression unattributable.

### Security-relevant — upgrade individually, functional pass after each

`freerasp` · `flutter_secure_storage` · `webview_flutter` · the Firebase suite ·
`flutter_facebook_auth` · `google_sign_in` · `sign_in_with_apple` ·
`url_launcher`

**Cadence: monthly**, and immediately on a published advisory. Never batched —
an unattributable regression across a security SDK costs more than the upgrades
saved.

### Functional — quarterly, batched by subsystem

`go_router` · `hive` · `mobx` · `flutter_bloc` · `get_it` · `dio`/`http` ·
`socket_io_client` · `google_maps_flutter` · `package_info_plus` ·
`shared_preferences` · `in_app_update`

### Cosmetic — audited, not upgraded

`ticket_clippers` · `flutter_switch` · `overlay_tooltip` · `easy_stepper` ·
`flutter_spinkit` · `flutter_slidable` · dotted-line/blur/quick-alert helpers

**Cadence: twice a year, and the audit is "should this still be a dependency?"**
Anything unmaintained providing a small widget is a candidate for a few lines of
first-party code. **Fewer dependencies is a feature.** Check last-publish date
and open issues, not just the version number.

---

## Pinning policy

**Pre-1.0 packages are pinned EXACTLY.** pub treats the minor position as
breaking below 1.0, so a caret on a `0.x` package accepts breaking changes
automatically — it is not a loose pin, it is no pin.

Currently pinned exactly: `intl` · `overlay_tooltip` · `ticket_clippers` ·
`flutter_switch` · `firebase_performance` · `easy_stepper` ·
`flutter_launcher_icons`.

**Anything imported must be declared.** `collection` was imported by three files
while only ever transitive — a build that breaks on somebody else's release
note. It is now a pinned direct dependency. `dart fix` will offer `any` for this;
`any` is looser than the caret-on-0.x case this policy already refuses.

**The SDK is pinned too.** `flutter-version: 3.47.0` in all five CI jobs.
`channel: stable` alone is a subscription to whatever Flutter ships next, and it
has already cost this project a working Android build — see below.

**Native dependency ownership stays with the plugin that declares it.** Do not
re-pin a plugin's native version in `android/app/build.gradle`. The Talsec SDK
was once pinned there twelve majors behind what the plugin itself declared;
Gradle's highest-wins hid it, and a dependency lock would have silently resolved
the old one and reintroduced libraries that break 16 KB alignment.

---

## The failure this policy exists to prevent

On 2026-08-18, `flutter build appbundle --release` failed on two version floors
— Gradle 8.13 < 8.14.0 and Kotlin 2.0.0 < 2.2.20 — **with no repository
change**. Flutter stable had moved, and the unpinned CI toolchain moved with it.
The Android build was simply unshippable, and nothing in the repository recorded
why.

Packages were pinned. The SDK that resolves them was not. That is the entire
lesson.

---

## Discontinued packages — the real picture

`flutter pub outdated` reports **five**, and every one is **transitive**:

| package | reached via | note |
| --- | --- | --- |
| `flutter_secure_storage_macos` | `flutter_secure_storage` | **security-relevant parent** |
| `flutter_map_cancellable_tile_provider` | map stack | |
| `js` | several | superseded by `dart:js_interop` |
| `build_resolvers` | `build_runner` | dev-only |
| `build_runner_core` | `build_runner` | dev-only |

**Zero direct dependencies are discontinued.** The correct action is to upgrade
the *parent*, not to try to remove the child — and to re-check after each parent
upgrade. Chasing a transitive package directly is how a dependency override ends
up pinning something nobody understands.

`flutter_secure_storage` has a 10.x and 11.x available across a major boundary.
That is a deliberate migration with a functional pass, not a cadence item —
it holds session and draft state.

---

## Before every release

1. `flutter pub outdated` — read it, do not just run it.
2. Upgrade security-relevant packages individually, tests after each.
3. `flutter pub get` from a clean checkout with **no `.dart_tool`**. A populated
   cache masks a broken resolution, and it then fails first on a colleague's
   machine or in CI.
4. Re-run all three gates **and** the viewport matrix (TAB 17) — a dependency
   bump that changes layout metrics is exactly what that matrix is for.

## Who

Unassigned. **Assign an owner before launch** — a cadence with no name is a
document, not a practice.
