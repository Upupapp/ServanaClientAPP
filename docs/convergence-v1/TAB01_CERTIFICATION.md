# TAB 01 certification — exact local repo sweep + backend delta matrix

**Master project** Servana Client Mobile Backend Convergence V1
`servana-client-mobile-backend-convergence-v1-976420d2-a720-416e-b50c-55c2d4dfda4a`
**Date** 2026-08-14 · **Client** `servana_client-main` @ `ce02830` (branch `main`)

---

## 1. Verdict

> ## `CERTIFIED — TAB 01 COMPLETE, CONVERGENCE BLOCKED UPSTREAM`

TAB 01 asked for a sweep, a delta matrix and a set of protected assets. All
three exist and every claim in them is backed by a `file:line` or a git object
in one of the two repositories read.

The sweep's finding is that **Convergence V1 cannot proceed to client
implementation yet**, and the reason is environmental rather than a defect in
either codebase. Certifying TAB 01 complete is therefore not the same as
certifying the project ready for TAB 02 — §6 states exactly what has to change
first, and none of it is this repository's to change.

---

## 2. Deliverables

| # | Deliverable | File | Status |
| --- | --- | --- | --- |
| 1 | **Matrix 1** — client surface inventory: screens, routes, API calls, DTOs, caches | `docs/convergence-v1/TAB01_CLIENT_SURFACE_INVENTORY.md` | complete |
| 2 | **Matrix 2** — backend delta matrix, checked against local route/OpenAPI/contract evidence | `docs/convergence-v1/TAB01_BACKEND_DELTA_MATRIX.md` | complete |
| 3 | **Matrix 3** — business assumptions and convergence risk (18 entries, R-01…R-18) | `docs/convergence-v1/TAB01_CONVERGENCE_RISK_MATRIX.md` | complete |
| 4 | Protected design screens and assets register | `docs/convergence-v1/TAB01_PROTECTED_DESIGN_REGISTER.md` | complete |
| 5 | This certification | `docs/convergence-v1/TAB01_CERTIFICATION.md` | complete |

### Inventory completed

| Item | Count |
| --- | ---: |
| Screen classes catalogued | 67 |
| Router entries catalogued | 64 |
| `ServanaApiClient` public methods traced to call sites | 78 |
| …public methods with no production caller | 13 |
| Distinct legacy endpoints called (verb + path) | 76 |
| DTO-bearing source files | 42 |
| Caches (Hive / secure storage / prefs / in-memory) | 10 |
| Business assumptions registered | 18 |
| Backend routes read as evidence | 235 at HEAD, 232 at `origin/main` |
| Canonical v1 endpoints read as evidence | 99 (95 implemented, 4 planned) |

### Evidence base

Comparison was made **only** against actual local backend artefacts, per the
TAB 01 constraint — no endpoint was assumed to exist from prose:

- mounted Express route tree, `servana_api-main/src/routes/*` + `src/chat/chat.routes.ts` + `src/app.ts`
- canonical contract `src/api/v1/contract.ts` and its composition root `src/api/v1/register.ts`
- generated `docs/api/API_ENDPOINT_REGISTRY.md`, `docs/api/openapi.v1.json` (82 paths / 99 operations)
- generated `docs/api/LEGACY_ENDPOINT_MIGRATION_MATRIX.md` (520 legacy routes classified)
- generated `docs/api/CLIENT_ENDPOINT_PARITY_MATRIX.md`
- `git` object comparison of backend HEAD against `origin/main`

---

## 3. Principal findings

1. **Zero client calls hit a missing backend route.** All 76 resolve to a
   mounted handler at backend HEAD.
2. **Three resolve only at HEAD, not on `origin/main`** — the `/api/catalog*`
   family the current release depends on (a fourth unpushed catalog route is
   not called by the client). The shipped client is ahead of the pushed
   backend.
3. **The canonical namespace is not deployed.** `/api/v1` is absent from
   `origin/main`; the backend's own generated parity matrix reports 0 of 111
   surface × capability cells on canonical.
4. **The client is 100 % legacy** — no `/api/v1` reference anywhere in `lib/`
   or `test/`.
5. **Booking creation has no canonical successor** and none planned.
6. **v1 introduces a third response envelope**, incompatible by design with
   both legacy shapes the client parses.
7. **Four inherited masterlist findings were re-verified and are closed**:
   SC-024, SC-031/048, SC-036/058, SC-037.

---

## 4. Verification

| Check | Command | Result |
| --- | --- | --- |
Run against the final tree, after the arithmetic corrections.

| Check | Command | Result |
| --- | --- | --- |
| Static analysis | `flutter analyze --no-fatal-infos` | **exit 0** — 0 errors, 0 warnings, 39 infos (213.1 s) |
| Test suite | `flutter test` | **exit 0** — `All tests passed!` · 1519 passed, 6 skipped, 0 failed (56 s) |
| Build | `flutter build apk --debug` | **exit 0** — `Built build\app\outputs\flutter-apk\app-debug.apk` (Gradle `assembleDebug` 201.0 s) |
| Matrix self-consistency | row/tally audit of Matrix 2 against `servana_api_client.dart` | 76 numbered rows, ids 1–76, no gaps or duplicates; dispositions sum to 76; verdicts sum to 76 |
| Cited counts re-verified | `find` / `grep` re-run for every figure in §2 | all match |
| Protected assets untouched | `git status --porcelain -- assets assets_src pubspec.yaml` | **empty** |
| Client code untouched by TAB 01 | `git status --porcelain -- lib test` | only the pre-existing `app_theme.dart` modification |

The 39 analyzer infos are all `prefer_const*` in settings screens and two test
files. They pre-date TAB 01 and are unrelated to it. The 6 skipped tests are
likewise pre-existing skips, not skips introduced here. The build emits a
forward-compatibility warning that six plugins still apply the Kotlin Gradle
Plugin (`freerasp`, `in_app_update`, `location`, `package_info_plus`,
`sign_in_with_apple`, `webview_flutter_android`); it does not fail the build
today, is unrelated to TAB 01, and belongs to release engineering rather than
convergence.

TAB 01 is a documentation-only tab: it added five Markdown files under
`docs/convergence-v1/` and changed no Dart, no assets and no build
configuration.

---

## 5. Working tree, commits, and what was *not* done

- **Branch** `main`. Base HEAD at task start `ce02830`. TAB 01 added two local
  commits and nothing else:
  - `d7701c4` — the five deliverables under `docs/convergence-v1/`.
  - `0dc6e87` — corrects the call-set arithmetic in those documents (76
    distinct verb+path pairs, not 74) after an internal-consistency audit
    against `servana_api_client.dart`.
  - a third commit recording the final verification results in §4.
- **Pre-existing unstaged modification preserved.**
  `lib/common/config/app_theme.dart` carries six `const` promotions in
  `buildDarkAppTheme` that were in the tree before this task began. TAB 01 did
  **not** author, stage, commit, revert or otherwise touch them. They remain
  unstaged and identical.
- **Commit scope** — only `docs/convergence-v1/` was staged, by explicit path.
- **Nothing was pushed.** No `git push`, no force-push, no merge, no branch
  deletion, no tag.
- **Nothing was deployed.** No production configuration, data, credential or
  infrastructure was read, written or rotated. No request was made to
  `api.servana.com.ph` or any other environment.
- **The backend repository was read only.** `servana_api-main` was opened for
  route, contract and git-object evidence. No file in it was created, modified
  or staged; its 51 unpushed commits and dirty working tree are exactly as
  found.
- **TAB 02 was not started.** No migration code, no client change, no
  scheduling decision. The sequencing in Matrix 3 §3 is a finding, not a plan.

---

## 6. Environmental and production-only gaps

These cannot be closed from this repository and are the gate on TAB 02.

| Gap | Owner | Why TAB 01 could not close it |
| --- | --- | --- |
| `/api/v1` absent from `origin/main` — 51 unpushed backend commits | backend deploy | Pushing and deploying are outside this task's authorisation and outside this repository. |
| `/api/catalog*` absent from `origin/main` while the shipped client calls it | backend deploy | Same. Flagged previously in `docs/catalog-v2/CLIENT_CATALOG_V2_FINAL_REPORT.md`; still true at `ce02830`. |
| No canonical `POST /api/v1/bookings` | backend contract | Requires a backend contract entry, not a client change. |
| Production ≠ `origin/main` (unverifiable) | ops | Probing production was not authorised. Every availability cell in Matrix 2 is `origin/main`, and Matrix 2 §13 says so. |
| Installed base is `1.0.0+37`; repo is `+38` | release | Adoption is never complete; the backend's mobile-alias retirement rule already requires 90 days of zero hits. |
| Response-shape conformance legacy → v1 not diffed | later TAB | Field-level DTO diffing is out of TAB 01's indexed scope. Recorded as R-18. |
| Authorization equivalence not exercised | later TAB | `SECURITY_AUTHZ_MATRIX.md` was not audited; the v1 `auth` column was read, not tested. |

---

## 7. Memory checkpoint

Saved to the project memory store (outside the repository):

- `convergence-v1-blocked-on-backend-deploy` — the root blocker, with the git
  evidence and the two work items that carry no backend dependency.
- `servana-client-ships-ahead-of-backend` — the repeatable process failure and
  the check that prevents it (`origin/main`, not backend HEAD).
- both indexed in `MEMORY.md`.

---

## 8. Next indexed TAB

**TAB 02.** Not started, and it should not begin as a client migration.

Matrix 3 §3 records what TAB 01 found about ordering: items **R-07** (two
coexisting catalog DTO families) and **R-08** (two transport layers duplicating
six endpoints) are the only Convergence V1 work with no backend dependency.
Everything else waits on the deployment named in §6.
