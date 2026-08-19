# Repo unification — GitHub `main` + `dev` vs the local clone

**Date:** 2026-08-19
**Remote:** `https://github.com/Upupapp/ServanaClientAPP.git`
**Unified working copy:** `C:\Users\paulg\OneDrive\Desktop\servana_client-unified`
**Result:** one branch that contains every commit on GitHub and every local commit.
**Nothing was pushed.**

## What the sweep found

Two bodies of work had been done on `main` in parallel, in two different
working copies, and **neither had ever seen the other**.

| Side | Commits | What it is |
| --- | --- | --- |
| `origin/main` (GitHub) | 31 ahead of the base | Production-launch TABs: integration probe, deep links, version gate, Android R8/signing, iOS release path, dependency pinning, security decisions |
| local `main` | 43 ahead of the base | Front-end SWEEP: SC2-01..09 closures, `dart format`, the DI viewport matrix, canonical identity contract tests |

Common ancestor: `80eff51`. Each side was therefore invisible to the other's
gates, and neither branch alone was the project's real state.

## `dev` contributes nothing — verified, not assumed

`origin/dev` is 9 commits "ahead" of `main` and 50 behind it. Those 9 are seven
merges plus `pods fix` and `fix gradle`.

**Its tree is byte-identical to the merge base `503bc57`**
(`6ec44bde14f22de5cf8046dd075a7dda716598b6` on both). The two real commits had
their content discarded by the earlier *"bring dev up to main, with main's tree
winning outright"*, and both predate the Android release work on `main` that
rewrote the same Gradle files. A stale branch that merges clean is the
dangerous kind, so this was checked by tree OID rather than by reading the log.

`dev` was merged anyway, purely so `main` strictly supersedes every ref on
GitHub and `dev` can later be **fast-forwarded** rather than force-pushed. The
resulting tree OID was unchanged by that merge, which is the proof it changed
no file.

## The two sides overlap in exactly two files

Out of 196 files touched locally and 84 touched remotely:

| File | Local side | Remote side | Resolution |
| --- | --- | --- | --- |
| `.gitignore` | added the Claude Code override rule at the end | rewrote the Firebase section, added signing-material and R8-mapping rules | union — different hunks, both kept |
| `home_screen.dart` | added the composition-cache fill (31 lines) | a 3-line mechanical lint edit | union — different hunks, both kept |

The merge was dry-run with `git merge-tree` first; the tree it predicted
(`42b9874d`) is exactly the tree the real merge produced.

## One defect had to be fixed

`flutter analyze` exited 1 on `unnecessary_type_check` in
`test/search/search_error_honesty_test.dart:21`. `--no-fatal-infos`, which CI
passes, does not spare warnings.

Both connectivity assertions declared the variable with its concrete type, so
`failure is RetryableFailure` was decided by the compiler. The test read as a
classification test and asserted nothing. Both now hold the value as
`ApiFailure`, which is what production does.

**This was pre-existing, not caused by the merge** — measured by analyzing the
pre-merge local tree on its own, where the same warning appears as 1 of 43
issues. That branch would have failed CI on its own. The merge *lowers* the
total to 3 infos, because the other side had already triaged `lib/` to zero.

## Gates on the unified tree

Run as CI runs them (`.github/workflows/flutter-ci.yml`):

| Gate | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | **exit 0** — 728 files, 0 changed |
| `flutter analyze --no-fatal-infos` | **exit 0** — 3 infos, 0 warnings |
| `flutter test --coverage` | **exit 0** — **2139 passed**, 6 skipped |

For comparison, the local branch alone was 2087 tests and analyze exit 1.

## Notes

- `pubspec.lock` is left at its committed pin. A local `flutter pub get`
  downgrades `matcher`, `meta`, `test_api` and `vector_math`, because the
  committed lock was resolved on a newer stable Flutter than the 3.44.0 on this
  machine. That drift is a machine artifact; CI resolves on `channel: stable`.
  The gates above were run against the downgraded lock — all four are
  test-infrastructure packages.
- The 3 remaining infos are pre-existing local-side debt in test files
  (`library_private_types_in_public_api` x1, `prefer_const_constructors` x2).
  They do not fail CI.
- A `localwork` remote points at the previous working copy, recording where the
  43 commits came from. It is local-only.
- **Not pushed.** `.github/workflows/flutter-ci.yml` triggers on `push` to
  `main` and `dev`, and this is a private repository, so any push bills Actions
  minutes.
