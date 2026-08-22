# Master TODO — manual tasks only

Items that **cannot** be closed from this machine by writing code. Everything
else is done in-tree and reported per TAB.

Rules in force: no deployment, no production data is touched, no credential is
changed. Pushing to `main` IS now in force for this repo — the five-step
procedure (sweep, test, merge, re-test, push) runs after every completed TAB.

Last updated: 2026-08-22 (App Store rejection recorded; A-1..A-7 raised; M8
reopened and re-closed structurally).

---

## M1 — ~~The canonical v1 client layer is not on this machine~~ · **CLOSED 2026-08-20**

**Owner:** repository owner · **Raised:** TAB 01 · **Closed:** sweep of `origin/main`

**It arrived by the option this item did not recommend.** TAB 01 offered three
ways out — bundle the commits, continue on the Windows machine, or authorise a
push — and listed the push third, as an option rather than a recommendation.
The push is what happened. So no bundle was ever needed: this clone was 95
commits behind and 0 ahead, and a plain fast-forward to `d2315ec` landed the
whole layer. Nothing had to be salvaged or reconciled, because nothing local
was ever ahead of the remote.

Re-measured on this machine after the fast-forward:

| | TAB 01 claim | Master Command | Measured at `d2315ec` |
| --- | --- | --- | --- |
| `lib/**/v1_endpoints.dart` | file does not exist | 60 path constants | **61 paths, 62 members** |
| `CanonicalAvailability` | no such symbol | 15 capabilities | **15 capabilities** |
| `api_error_mapper.dart` | file does not exist | maps 5 of 36 codes | **present, 10 codes** |
| occurrences of `api/v1` in `lib/` | 0 | — | **105** |
| test files | 106 | 149 | **159** |

So TABs 02 and 05–12 are no longer blocked by a missing layer. **02 is moot** —
there are no commits to land. 05–12 are now actionable in-tree.

Two things this does NOT close:

- **The capabilities are still all off.** `CanonicalAvailability.enabled` is
  `false` unless built with `--dart-define=CANONICAL_V1_ENABLED=true`, and
  `docs/runbooks/DEPLOY_POLICY.md` keeps all 15 off for MVP deliberately.
  Migrating a capability is its own command with its own evidence.
- **`canonical_availability.dart`'s own doc comment is now stale.** It states
  the `/api/v1` namespace is *absent* from `servana_api`'s `origin/main`.
  `DEPLOY_POLICY.md` states `/api/v1` is deployed and healthy. Both cannot be
  true; the deploy policy is the newer of the two. Left as written rather than
  guessed at — the rationale comment is load-bearing and correcting it needs a
  backend measurement, not an edit. Tracked as **M9**.

The stale second clone at `C:\Users\paulg\OneDrive\Desktop\servana_client-mobile`
is unrelated to this item and remains disabled; see `DEPLOY_POLICY.md`.

---

## M9 — `canonical_availability.dart` contradicts `DEPLOY_POLICY.md` on whether v1 is deployed

**Owner:** backend owner · **Raised:** 2026-08-20 sweep

`lib/core/network/canonical_availability.dart` documents, as the reason the
gate exists, that the entire `/api/v1` namespace is absent from `servana_api`'s
`origin/main`. `docs/runbooks/DEPLOY_POLICY.md` says `/api/v1` is deployed and
healthy and that the flags stay off for a different reason — that the surface
has never carried real customer traffic.

Only one can be current. This is not fixable from the client repository: it
needs a measurement of what `servana_api` actually mounts on production. The
gate's *behaviour* is correct either way (deny by default), so this is a
correctness-of-record defect, not a runtime one.

---

## M2 — Backend contract defects need a deploy · TABs 03, 04

**Owner:** backend owner · **Raised:** TAB 01 (both re-confirmed live)

Both defects are confirmed on production today by direct measurement, and both
are fixable in `/Users/user/servana_api` locally. Neither can be *closed*
without deploying, which is outside the boundary.

- **TAB 03** — `GET /api/catalog` publishes
  `Link: </api/v1/bookings/:bookingId>; rel="successor-version"`. The contract
  declares its successor as `/api/v1/catalog`. Five platforms are mid-migration
  and RFC 8288 successor links are followed automatically.
- **TAB 04** — every v1 `401` returns the legacy envelope
  `{"status":"failed","code":"UNAUTHENTICATED"}` with no `requestId`, while
  every v1 `404`/`400` returns `{"error":{code,message,requestId}}`.

  **Status (2026-08-18):** the translator already existed and is committed but
  undeployed, which is why production still shows the legacy shape. Verifying
  it found a real defect — a **revoked session** was escaping translation
  entirely — fixed at backend `086738c`. Demonstrating `TOKEN_REVOKED` and
  `TOKEN_EXPIRED` against a **real token**, which the acceptance gate requires,
  needs a live Firebase credential and a deploy.

Fixes can be written and committed locally; **deploy and re-probe are manual.**

**One deploy closes three TABs.** TAB 03's successor signpost, TAB 04's v1 auth
envelope and TAB 18's security headers are all implemented, committed and
undeployed in `/Users/user/servana_api`. Production still exhibits all three
defects. Deploying that repository is the single highest-value manual action
outstanding.

**TAB 03 status (2026-08-18):** fixed and committed locally at backend
`d7a2097`, with a pinning test watched to fail and the full suite green.
**Not deployed** — production still publishes the wrong signpost. The
after-state capture required by the acceptance gate cannot be taken until it
ships.

---

## M7 — A parallel session is committing in the backend tree

**Owner:** repository owner · **Raised:** TAB 04

`/Users/user/servana_api` has **two agents committing concurrently**. During
TAB 04 the other session landed `c2c73d2` and `37d9a7f` interleaved with this
programme's `d7a2097` and `086738c`, and both sessions raised
`tests/suite-inventory.test.ts`'s ratchet for their own suite without seeing the
other — leaving the committed count one behind committed reality until
`fcba273` reconciled it.

Nothing was lost and no work was clobbered: every commit here staged explicit
paths and left the other session's files untouched. But the pattern will repeat.
Worth deciding who owns that repository per session, or serialising the two
programmes' backend work.

---

## M4.17 — `docs/DEPENDENCY_CADENCE.md` has no owner

**Owner:** to be assigned · **Raised:** TAB 19

The classification, pinning policy and pre-release checklist are written. Nobody
is named. A cadence with no owner decays within a quarter, which is the exact
failure the document exists to prevent.

---

## M8 — CI pins no Flutter version, and it has already broken the Android build

**Owner:** repository owner · **Raised:** TAB 02 (as a risk), realised in TAB 13

All four CI jobs use `subosito/flutter-action@v2` with `channel: stable` and no
version. When stable moved to **3.47.0**, its minimum Gradle (8.14.0) and Kotlin
(2.2.20) floors rose above what the repository pinned (8.13, 2.0.0) and
**the Android release build stopped building** — with no repository change.

**Closed by TAB 19 (`404dc23`)** — `flutter-version: 3.47.0` pinned in all five
CI jobs.

**REOPENED, silently, by `27e5793`.** That commit deleted `flutter-ci.yml` for
the no-CI policy and took the only pin in the repository with it. Nothing
announced the regression, because the thing that carried the pin was the thing
being deleted on purpose.

The consequence surfaced on 2026-08-22: `pubspec.lock` had been resolved against
an older stable and no longer resolved at all under 3.47.0
(`flutter pub get --enforce-lockfile` exit 65). It stayed invisible because
`flutter test` runs an implicit `pub get` that silently rewrote the lock on every
run — so the only gate this repo has was testing a dependency set other than the
committed one.

**CLOSED STRUCTURALLY 2026-08-22 (`f6082bb`, `26b34eb`)**, and no longer a manual
item. `.flutter-version` now holds the pin, and the pre-push hook checks it
before every push and then runs `--enforce-lockfile`. This is strictly stronger
than the TAB 19 fix: it binds **every clone**, not just a CI runner, and it
cannot be removed by deleting a workflow — there is no workflow left to delete.

---

## M5 — The backend tree carries uncommitted Provider Web work

**Owner:** repository owner · **Raised:** TAB 03

`/Users/user/servana_api` holds unlanded changes from the *Provider Web*
programme's TAB 03 — `tests/deploy-gating.test.ts`,
`docs/audits/TAB03_DEPLOY_GATING.md`, and edits to `deploy.yml`,
`release-gate.yml` and that repo's own manual-task list. They were left
untouched and are **not** in the TAB 03 commit.

Consequence: `tests/suite-inventory.test.ts` pins the suite count, and while
those files sit untracked the local count reads **282** against a committed
value of **281**, so `npm run test:ci` is red on an otherwise green tree. The
committed value is correct; the discrepancy resolves when the Provider Web work
lands or is reverted.

---

## M6 — 30 of 70 legacy routes the client calls are undeclared by the contract

**Owner:** backend / contract owner · **Raised:** TAB 01, confirmed TAB 03

The customer app constructs **70** legacy routes. **30** of them have no entry in
the v1 contract's `legacy` mappings — including `/api/services`, `/api/quote`
and the whole `/api/support` surface. They have no successor, no disposition and
no migration story, and the deprecation clock cannot see them.

The itemised work-list is `docs/integration/M6_UNDECLARED_LEGACY_ROUTES.md`,
grouped by domain and regenerable from the probe.

**Corrected 2026-08-18:** first reported as 50. The probe compared route text
literally, so `/api/:id/timeline` and a concrete `/api/123/timeline` counted as
two different routes. Both sides now normalise parameters before comparing; the
real figure is 30.

This is why `/api/services` now correctly publishes *no* successor rather than a
wrong one: there is nothing in the contract to point at. Whether these routes
should be classified `KEEP`, `ALIAS_TEMPORARILY` or `RETIRE` is a contract
decision, not a client one.

---

## M3 — Backend working tree is not clean

**Owner:** backend owner · **Raised:** TAB 01

`/Users/user/servana_api` is **2 commits ahead of `origin/main`** (`fca1ed1`,
`0aaf89f`) with an untracked `cc.tmp.ts`. Those two commits are the Servana
**Provider Web** programme's TAB 01 work on the shared backend — accounted for,
not unexplained drift. `contract.ts` itself is unmodified, so the snapshot
committed here is sound, but it is stamped `0aaf89f-dirty` and that stamp
should read clean before it is cited as launch evidence.

---

## M4 — Production-only verification carried by later TABs

Recorded now so they are not discovered at the gate. Each needs a real device,
a store account, a console, or a deploy.

| # | Item | TAB |
| --- | --- | --- |
| M4.1 | Play upload-key fingerprint; `apksigner verify --print-certs` on a real bundle. **TAB 13 verified R8 with a throwaway key only** (`CN=TAB13 Local Verification Only`, deleted after) — nothing is established about the real key | 13 |
| M4.2 | Crashlytics mapping upload + a symbolicated release-mode crash. R8 is now on, so an un-uploaded mapping means unreadable crash reports | 13 |
| M4.13 | **Full functional pass against the R8 artefact on a device.** R8 failures appear only in the shrunk build, at the moment a reflective lookup runs — a green build is not evidence the app works | 13 |
| M4.3 | Host `/.well-known/assetlinks.json` and `apple-app-site-association` on all three hosts. **Both files are written and valid** in `docs/deep-links/well-known/`; serve the Apple one as `application/json`, **no extension, no redirect**, and check the well-known path is not shadowed — a wildcard route has eaten a new sibling on this backend before | 14 |
| M4.14 | On-device App Link / Universal Link verification, cold **and** warm. Use `adb shell pm get-app-links com.servana.serviceclient` rather than observing that a tap worked; on iOS open from Mail and Notes, not Safari's address bar (which deliberately does not trigger Universal Links) | 14 |
| M4.15 | **Two** Android fingerprints for `assetlinks.json`: the Play app-signing certificate (what devices see) **and** the upload key (so internal-testing builds verify). Shipping only one is the usual mistake | 14 |
| M4.16 | `DEVELOPMENT_TEAM` differs between targets — Runner `2K2SF7NRQP`, RunnerTests `CAB884NRSN`. The AASA uses the app target's. Reconcile before iOS signing | 16 |
| M4.4 | Apple portal: Associated Domains, Sign in with Apple, push capability | 14, 16 |
| M4.5 | APNs key uploaded to Firebase console for `servana-59bee` | 16 |
| M4.6 | App Store Connect API key / signing certificates as CI secrets | 16 |
| M4.7 | Publish the six `version_gate_*` Remote Config parameters in `servana-59bee`; rehearse a block/restore on real Android **and** iOS devices and **record the propagation delay**. TAB 05 needs that number — over an hour and TAB 15 becomes its prerequisite, not a parallel workstream. Code and runbook are done (`docs/runbooks/VERSION_GATE.md`) | 15 |
| M4.8 | Canary customer account on production with real booking history | 05 |
| M4.9 | Security headers — **already implemented and committed** at backend `f5c4743` (`apiSecurityHeaders`, mounted before CORS, HSTS one year + subdomains, deliberately no `preload`). Production serves none of them. This is a **deploy**, not a code task — see M2 | 18 |
| M4.10 | **Create and staff `security@servana.com.ph`** as a distribution list with at least two people. The code change is done (TAB 18) and now points there; the alias must actually exist and be monitored, and the response procedure is `docs/runbooks/RASP_ALERTS.md`. An alert with no named owner is telemetry, not security | 18 |
| M4.11 | IAM verification that both historical service-account keys are **deleted**, not merely rotated | 18 |
| M4.12 | Play data-safety declaration and Apple privacy nutrition labels | 20 |

---

## A — App Store rejection 2026-08-22 · Guidelines 2.1(a), 5.1.1(v), 2.3.6

Raised by `docs/SERVANA_CLIENT_APPSTORE_REMEDIATION_MASTER_COMMAND.md`. These
are the items that **cannot** be closed by writing code in this repository.

**The rejection, verbatim in substance:**

- **2.1(a) Performance — App Completeness.** *"The app did not log us in when
  using Sign in with Apple."* Review device: **iPad Air 11-inch (M3), iPadOS
  26.6**, active internet connection.
- **5.1.1(v) Data Collection and Storage.** The app supports account creation
  but offers no way to initiate account deletion. Temporary deactivation is
  explicitly insufficient. Requires a screen recording of the full flow.
- **2.3.6 Accurate Metadata.** Age Rating must answer **Yes** to
  **"Messaging and Chat"**, because the app ships chat.

| # | Item | Where | Blocks |
| --- | --- | --- | --- |
| **A-1** | Enable **Sign In with Apple** on App ID `com.servana.client` | Apple Developer portal | TAB 04 if cause C1 |
| **A-2** | Enable the **Apple provider** for Firebase project `servana-59bee` | Firebase Console | TAB 04 if cause C2 |
| **A-3** | Confirm `POST /api/auth/customer-firebase-login` accepts Apple-issued Firebase ID tokens **in production** | `servana_api` owner | TAB 04 if cause C3 |
| **A-4** | Provide a working **demo account** for App Review, verified on a clean install | App Store Connect | TAB 10 |
| **A-5** | Age Rating → **Messaging and Chat = Yes** | App Store Connect → App Information | TAB 11, TAB 12 |
| **A-6** | Attach the account-deletion **screen recording** to App Review Information | App Store Connect | TAB 12 |
| **A-7** | Decide iPad support: stay iPhone-only (`TARGETED_DEVICE_FAMILY = "1"`) or adopt iPad | Owner | TAB 02, TAB 05 |

**A-5 is one field and it will cost a whole review cycle if missed.** It is the
cheapest item on this list and the only one that is certain — the other two
findings still need root-causing, this one does not.

**Note on 2.1(a):** the cause is **not yet known**. The Apple handler and the
iOS entitlement were both measured correct on 2026-08-22. Four candidates
survive (C1–C4 in the Master Command, §1.2), and three of them are A-1, A-2 and
A-3 above — i.e. **most of the likely causes are manual items, not code.** Do
not let TAB 04 start editing Dart before TAB 01 names the cause.
