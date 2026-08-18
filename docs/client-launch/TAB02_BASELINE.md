# TAB 02 — Land the local work and prove it builds from a clean clone

**Status:** local scope COMPLETE · **CERTIFIED_WITH_BLOCKED_SCOPE**
**Date:** 2026-08-18 · **HEAD:** `f303122` · **Version:** `1.0.0+40`

---

## What this TAB could not do, and why

The objective as written is to land **43 unreviewed commits**. They are not on
this machine, and no amount of local work produces them.

| | Master Command | Measured here |
| --- | --- | --- |
| Client HEAD | `edda43b`, 43 ahead of `origin/main` | `80eff51`, level with `origin/main` |
| `edda43b` reachable | — | **absent from history** |
| Test files | 149 | 106 |
| `flutter test` | 2090 passed, 6 skipped | 1455 passed, 6 skipped |
| `dart format` | 720 files | 592 files |
| Analyzer infos | 43 | 42 |

Those commits live only at `C:\Users\paulg\OneDrive\Desktop\servana_client-mobile`,
never pushed — correctly, under the standing rule. Tracked as **M1** in
[MASTER_TODO_MANUAL_TASKS.md](../MASTER_TODO_MANUAL_TASKS.md).

Everything else in the TAB is scoped to *this* tree and is done. The baseline
below is real; it is simply a baseline for `origin/main`, not for `edda43b`.

---

## Clean-clone gate transcript

Cloned from local git objects, `flutter pub get`, then the three gates in the
order CI runs them. **Taken from the clean clone, not the working directory.**

```
HEAD     f30312299586e1bc10e9ef3a588a4a672a52eddb
date     2026-08-18T10:05:21Z
flutter  3.47.0 • channel stable
dart     3.13.0

flutter pub get                        exit 0    1s
dart format --set-exit-if-changed .    exit 0    4s     592 files, 0 changed
flutter analyze --no-fatal-infos       exit 0    8s     No issues found!
flutter test                           exit 0   40s     1455 passed, 6 skipped

working tree after all four:  0 modifications
Dart files checked out with CRLF: 0
```

`flutter pub get` leaving **zero** modifications is the point of the working-tree
settlement below. Before it, `pub get` dirtied two files on every clean
checkout, so "clean clone" and "clean tree" could not both be true.

---

## Working tree, decided rather than left to drift

**`analysis_options.yaml`** — kept. Flutter 3.47's `pub get` appends an
`exclude:` block for `build/` and the six platform directories. Measured both
ways: **42 analyzer issues with it and 42 without**, because the only Dart
outside `lib/` and `test/` is in `tool/`, which is not excluded. No effect on
what the gate sees; reverting only invites the tooling to rewrite it.

**`pubspec.lock`** — kept. Four transitive packages moved (`matcher`, `meta`,
`test_api`, `vector_math`), every one pinned by the Flutter SDK rather than by
`pubspec.yaml`. Reverting was *tested and is unavailable*:
`flutter pub get --enforce-lockfile` fails with "Unable to satisfy pubspec.yaml
using pubspec.lock". A lockfile that cannot be honoured is worse than one that
has moved.

**`.gitattributes`** — fixed. Was `* text=auto` alone, which normalises the
stored blob but still hands a Windows working tree CRLF. `dart format
--set-exit-if-changed .` is the CI contract and is line-ending sensitive, so
that configuration turns Validate red for everyone except whoever last touched
the file. This is live, not hypothetical: the repository has shipped 55
unformatted files and reddened Validate once already, and the 43 unlanded
commits were authored on Windows. Now pins `eol=lf` globally and per-extension,
keeps CRLF for `gradlew.bat` and `.ps1`, and marks binaries.
`git add --renormalize .` changed no tracked content.

---

## Analyzer: 42 → 0

Applied per-code. The CI invocation was not touched — the number was fixed, not
the threshold that measures it.

| rule | fixes |
| --- | --- |
| `prefer_const_constructors` | 27 |
| `curly_braces_in_flow_control_structures` | 8 |
| `unnecessary_const` (exposed by the const work) | 6 |
| `prefer_const_declarations` | 4 |
| `use_super_parameters` | 1 |

A bare `dart fix --apply` was deliberately avoided: it also fires
`missing_dependency` and writes `collection: any` into `pubspec.yaml`. See the
TAB 19 handoff below.

`dart fix` left **17 files unformatted**, so the format gate went red the moment
the triage landed — the same failure this repository has already shipped once.
Caught because the gate was run rather than reasoned about.

---

## The 6 skipped tests, each justified

All in `test/bloc/authentication_bloc_test.dart`. An unexplained skip is a hole
in the gate; none of these is unexplained.

| # | Test | Why |
| --- | --- | --- |
| 1 | `AuthLogout` emits Loading then LoggedOut | needs the `flutter_secure_storage` platform channel |
| 2 | `AuthLogout` still emits LoggedOut when `repo.logout()` throws | same |
| 3 | `AuthenticationInit (login)` emits Authenticated on success | same |
| 4 | `AuthGoogleSignIn` happy path | needs injectable `FirebaseAuth` + `ServanaApiClient` |
| 5 | `AuthFacebookSignIn` happy path (TC-003) | same |
| 6 | `AuthCheckSession (F7)` stale-response guard | needs injectable `SessionService` |

Every one is a real `integration_test` boundary — a platform channel or a
non-injectable singleton — not a disabled assertion.

---

## Handoffs

**To TAB 19 — undeclared direct dependency.** `registration_bloc.dart`,
`add_item_bloc.dart` and `store_items_bloc.dart` all import
`package:collection/collection.dart` while `collection` is only transitive.
Relying on an intermediate to keep supplying it is a build that breaks on
somebody else's release note. It wants a **pinned** direct dependency; the
analyzer's own suggestion is `any`, which is looser than the caret-on-0.x case
TAB 19 already treats as effectively unpinned.

**To TAB 19 — the toolchain is unpinned in CI.** All four jobs use
`subosito/flutter-action@v2` with `channel: stable` and no version. The gate
transcript above is reproducible against Flutter 3.47.0 and has no shelf life
beyond the next stable release — which is exactly the property a clean-clone
proof is supposed to provide. `pubspec.lock` pins the packages; nothing pins
the SDK that resolves them.

---

## Acceptance gate

| Requirement | Result |
| --- | --- |
| Working tree clean, named HEAD, version recorded | ✅ `f303122`, `1.0.0+40` |
| Gate transcript from the clean clone | ✅ above |
| `dart format --set-exit-if-changed .` exit 0 | ✅ 592 files |
| `flutter analyze --no-fatal-infos` exit 0 | ✅ No issues found |
| `flutter test` exit 0, pass/skip named | ✅ 1455 / 6 |
| Analyzer count before and after, ending at zero | ✅ 42 → 0 |
| `.gitattributes` line-ending guarantee | ✅ `eol=lf` pinned |
| Justified skip list | ✅ all 6 |
| **Land the 43 commits** | ⛔ **BLOCKED — M1** |
| Nothing pushed | ✅ `origin/main` still `80eff51` |
