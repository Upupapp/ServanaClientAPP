# Deployment policy

**Standing rule, decided 2026-08-19. This is not a preference.**

## Push straight to `main`. No pull requests.

Work lands by committing locally and pushing `main`. There is no PR step, no
review branch, and no merge queue. A change is ready when the gates are green
and it is pushed.

Feature branches are for work in progress, not for landing. If a branch exists
it should be short-lived and merged forward, never left to age — a branch that
falls behind stops being a change to `main` and becomes a re-implementation
against code that has moved on. That is not hypothetical: the backend carries
two branches roughly 600 commits stale whose target files have since been
rewritten four to fourteen times over, and they can no longer simply be merged.

## There is no CI

GitHub Actions is **disabled** on this repository and on `servana_api`
(`enabled: false`, verified). No workflow runs on push.

That means **the gates are local, and running them is the deploy step**. Before
pushing `main`:

```
dart format --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test
```

All three must be clean. This mirrors what `.github/workflows/flutter-ci.yml`
would have run, and it is the only thing standing between a defect and `main`.

**`scripts/hooks/pre-push` now runs all three for you.** Enable it once per
clone — git does not do this itself:

```
git config core.hooksPath scripts/hooks
```

`flutter test` is the heaviest of the three and the least optional: it renders
all 62 screens at three handset sizes and three text scales, and that suite is
what found 46 defects on 2026-08-20 — including two screens that threw outright
in production. See `docs/runbooks/LAYOUT_PATTERNS.md`.

**Never use `--no-verify`.** If a check fails for a reason about the machine
rather than the code, fix the check: three of the backend's gates asserted
Linux-only facts and blocked every push from a Windows machine until repaired.

### Why Actions is off, and what was really protecting us

Actions was not disabled to save minutes. On `servana_api` it was disabled
because the deploy workflow **was destroying production**: it ran on a
self-hosted runner on the production box, its checkout deleted the `dist/` the
live process was executing from, and it then failed before rebuilding. Five
failed runs on 2026-08-19, three of them inside one working session.

On this repository the risk was narrower but the protection was thinner than it
looked. Actions was **enabled** until 2026-08-19; the only reason pushes had not
been billing minutes was `[skip ci]` in commit messages. That is a convention,
not a guard, and the 66 commits waiting to be pushed did not carry it. Anyone
relying on that pattern should know it protects nothing the moment someone
writes an ordinary commit message.

**Do not re-enable Actions on either repository** without a deliberate decision
and a check that no workflow can write into a directory a live process runs
from.

## Releases

Cutting a build is a separate act from pushing. See `docs/runbooks/IOS_RELEASE.md`
and `docs/TESTER_DISTRIBUTION.md`. The version gate
(`docs/runbooks/VERSION_GATE.md`) is what retires a shipped build.

For MVP, all 15 `V1Capability` flags stay **off**, so the shipped app runs
entirely on the legacy transport. `/api/v1` is deployed and healthy, but
enabling a capability puts a surface into production that has never carried
real customer traffic. Migrating is its own command, with its own evidence.

## Backend counterpart

The same push-straight-to-`main` rule applies to `servana_api`, which
additionally has a `pre-push` hook running `npm run verify` on `main`. See that
repository's `docs/DEPLOY_AND_GATE_POLICY.md` for where production lives, how
to deploy it by hand, and why three of its gates had to be fixed before they
could pass on the machine that now runs them.
