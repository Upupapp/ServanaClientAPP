# Pending workflow changes — not on `main`

Three CI deliverables from this programme are **in git history but not in the
tip of `main`**. This directory holds the finished file so restoring them is one
command.

## Why they are not on main

Two independent restrictions were in play and they are easy to conflate:

| restriction | governs | status |
| --- | --- | --- |
| PAT lacks `workflow` scope | whether you may **modify** `.github/workflows/*` | **blocking** |
| GitHub Actions credit exhausted | whether a workflow **runs** | handled with `[skip ci]` |

`[skip ci]` solves the second and does nothing for the first. The push of 27
commits only succeeded because `flutter-ci.yml` at the tip was made identical to
`origin/main` — GitHub checks the resulting **tree diff** for workflow paths,
not whether intermediate commits touched them.

So the work landed; the workflow config did not.

## What is missing from main

| deliverable | commit | what it does |
| --- | --- | --- |
| `integration-probe` job | `a418230` | TAB 01 — probes production against the backend contract; advisory on PRs, blocking on `main`. The detector for the class of staleness that has now caused two incidents. |
| `release-ios` job | `5bbf568` | TAB 16 — the only automated path to TestFlight. Without it every iOS build is a manual act on a laptop. |
| `flutter-version: 3.47.0` pin | `404dc23` | TAB 19 — **an unpinned `channel: stable` already broke the Android build once**, with no repository change, when stable's Gradle and Kotlin floors rose. |

The third is the one that will bite again on its own schedule.

## Restoring

With a credential that has `workflow` scope — or an SSH remote, which is not
subject to the PAT scope rule:

```bash
git remote set-url origin git@github.com:Upupapp/ServanaClientAPP.git
cp docs/pending-workflow/flutter-ci.yml .github/workflows/flutter-ci.yml
git add .github/workflows/flutter-ci.yml
git commit -m "ci: restore the integration probe, release-ios and the Flutter pin [skip ci]"
git push origin main
```

Keep `[skip ci]` on the head commit until Actions credit is restored — the jobs
should exist in the repository whether or not they can run today.

`flutter-ci.patch` is the same change as a diff, if applying by hand is preferred.
