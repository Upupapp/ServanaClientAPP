# Master TODO — manual tasks only

Items that **cannot** be closed from this machine by writing code. Everything
else is done in-tree and reported per TAB.

Rules in force: nothing is pushed, nothing is deployed, no production data is
touched, no credential is changed. Local commits only.

Last updated: 2026-08-18 (TAB 01).

---

## M1 — The canonical v1 client layer is not on this machine · **BLOCKS TABs 02, 05–12**

**Owner:** repository owner · **Raised:** TAB 01

The Master Command describes the client at HEAD `edda43b`, 43 commits ahead of
`origin/main`, holding a complete canonical v1 layer behind 15 capability
flags. **None of that is here.** Measured on this machine:

| | Master Command | This machine |
| --- | --- | --- |
| Client HEAD | `edda43b` (43 ahead) | `80eff51` (level with `origin/main`) |
| `edda43b` in history | — | **absent** |
| `lib/**/v1_endpoints.dart` | 60 path constants | **file does not exist** |
| `CanonicalAvailability` | 15 capabilities | **no such symbol** |
| `api_error_mapper.dart` | maps 5 of 36 codes | **file does not exist** |
| occurrences of `api/v1` in `lib/` | — | **0** |
| test files | 149 | 106 |

Those 43 commits exist only at `C:\Users\paulg\OneDrive\Desktop\servana_client-mobile`
and were never pushed — correctly, under the standing "nothing is pushed" rule.
The consequence is that the entire Phase C migration is unbuildable here: there
are no capability flags to enable, because the layer they gate is not present.

**To unblock, one of:**

1. Bundle the 43 commits on the Windows machine and transfer them —
   `git bundle create servana-client.bundle origin/main..HEAD`, then
   `git fetch` the bundle here. Keeps the "nothing is pushed" rule intact.
2. Continue the client-side TABs on the Windows machine instead.
3. Authorise a push of the 43 commits to `origin/main` (**explicitly outside
   the current rules** — recorded as an option, not a recommendation).

Until then, TABs that touch only files present in `origin/main` — 13, 14, 15,
17, 18, 19 — remain fully actionable here.

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

Fixes can be written and committed locally; **deploy and re-probe are manual.**

**TAB 03 status (2026-08-18):** fixed and committed locally at backend
`d7a2097`, with a pinning test watched to fail and the full suite green.
**Not deployed** — production still publishes the wrong signpost. The
after-state capture required by the acceptance gate cannot be taken until it
ships.

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

## M6 — 50 of 70 legacy routes the client calls are undeclared by the contract

**Owner:** backend / contract owner · **Raised:** TAB 01, confirmed TAB 03

The customer app constructs **70** legacy routes. Only **20** appear in the v1
contract's `legacy` mappings. The other 50 — including `/api/services` and
`/api/bookings`, two of the busiest — have no successor, no disposition and no
migration story, and the deprecation clock cannot see them.

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
| M4.1 | Play upload-key fingerprint; `apksigner verify --print-certs` on a real bundle | 13 |
| M4.2 | Crashlytics mapping upload + a symbolicated release-mode crash | 13 |
| M4.3 | Hosting `/.well-known/assetlinks.json` and `apple-app-site-association` | 14 |
| M4.4 | Apple portal: Associated Domains, Sign in with Apple, push capability | 14, 16 |
| M4.5 | APNs key uploaded to Firebase console for `servana-59bee` | 16 |
| M4.6 | App Store Connect API key / signing certificates as CI secrets | 16 |
| M4.7 | Remote Config schema published; version-gate propagation rehearsal | 15 |
| M4.8 | Canary customer account on production with real booking history | 05 |
| M4.9 | Security headers (HSTS, nosniff, frame-deny, referrer policy) at the nginx edge — **confirmed absent today** | 18 |
| M4.10 | RASP `watcherMail` moved off a personal Gmail to a team alias | 18 |
| M4.11 | IAM verification that both historical service-account keys are **deleted**, not merely rotated | 18 |
| M4.12 | Play data-safety declaration and Apple privacy nutrition labels | 20 |
