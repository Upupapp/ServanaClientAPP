# Servana Client App — session brief

Last updated 2026-08-10 (second revision). Read this before touching code.

---

## What this is

The **customer** mobile app — Flutter, BLoC, Hive, dependency locator
(`dpLocator`). This is the one Servana product with **real users in the wild**,
which changes the calculus for every decision below.

It is one of five consumers of a single shared backend. The others are the
customer web portal, ServanaWorker (provider mobile), the provider portal and
the admin portal.

| | |
| --- | --- |
| Repo | `Upupapp/ServanaClient` (moved — the old repo hit a CI billing block) |
| Branch | `main`, HEAD `66a15b9`, clean; **2 commits ahead of origin** (both this brief) |
| Version | `1.0.0+38` in `pubspec.yaml` |
| **On Play** | **`1.0.0+37`** — see the warning below |
| +38 artifact | at `Desktop\servana-38-release\` — **rebuilt 2026-08-10 from `bab19da`, verified, ready to upload** (`sha256 c5d20c1c…`). See item 4. |
| Backend | `https://api.servana.com.ph/api` |
| Firebase | `servana-59bee` — the ONLY project, for every platform |
| Tests | 1466, CI green |

---

## The rule that matters most here

**The live app is not the repo.** Play serves **+37**; this tree is **+38**.
Anything reasoned from source describes an app nobody is running yet. When
judging whether a backend or web change is safe, the question is always *"what
does the installed build do?"* — and the answer for anything the customer has
not updated is the +37 behaviour, indefinitely. Adoption is never complete.

---

## Standing rules

- **Never push unless explicitly told to.** Commit locally, stage explicit
  paths. A parallel session commits in this tree.
- **Any change must not break the other four platforms.** Verify by reading the
  other repos, never by reasoning about them.
- **This app's wiring is authoritative for parity.** The web portal follows it,
  not the other way round.
- Exactly one Firebase project. Build **both** iOS and Android. Validate at the
  Flutter level only.
- **Do NOT merge `origin/dev`.**

---

## Open, in priority order

**1. PayMongo return-URL collision — blocks the web launch, not this app.**
The checkout WebView (`lib/common/presentation/screens/payment_webview_screen.dart`)
blocks any host outside a hardcoded allowlist:

```
checkout.paymongo.com · api.paymongo.com · paymongo.com · www.paymongo.com
app.servana.com.ph · servana.com.ph · api.servana.com.ph
```

`client.servana.com.ph` is not there and appears nowhere in this repo. The
backend builds every PayMongo redirect from a single `PAYMONGO_RETURN_URL` —
**now set to `https://app.servana.com.ph`** (2026-08-10), which this allowlist
does accept, so mobile is correct today. The collision is unchanged in kind: the
web portal still cannot get its own return origin without breaking this app.

**Adding the host here is worth doing for +38 but is NOT the fix** — every
installed +37 keeps the old allowlist. The real fix is a per-request origin in
the backend.

Mitigating detail, verified in source: the redirect is treated as a *signal*,
not proof. `_startPolling` polls every 5s for up to 30 minutes and the success
path calls `_verifyAndClose()`. So a blocked success redirect costs seconds, not
the payment. The cancel path has no poll and falls back to the existing
"Cancel payment?" dialog.

**2. ~~Unresolved: is online payment working in production?~~ ANSWERED — it was
not, and it is now fixed (2026-08-10).** It was worse than the suspicion above.
Both were true at once:

- `PAYMONGO_RETURN_URL` and `APP_URL` were **both unset**, so `new URL("")` threw
  and **every** `POST /:bookingId/paymongo/create` returned 503 *"Online payment
  is temporarily unavailable"* — which reads like a PayMongo outage.
- Every call site reads `process.env.PAYMONGO_SECRET_KEY || process.env.PAYMONGO_SK_DEV`.
  `PAYMONGO_SECRET_KEY` was **never set**, so all of them fell through to the
  **test** key. The live key sat in `PAYMONGO_SK`, a name no code reads.
  Production was transacting in test mode with live credentials unused.

Fixed and verified live: `PAYMONGO_RETURN_URL=https://app.servana.com.ph`,
`NODE_ENV=production`, `PAYMONGO_SECRET_KEY=sk_live_…`. Confirmed by running
dotenv inside the app dir: `EXPECT_LIVE_MODE=true`, return URL parses OK.
Backups `*.bak-2026-08-10`.

**All three had to change together.** The live key without `NODE_ENV` makes the
webhook expect `livemode:false` and reject every real payment 401 — money
captured, never recorded. That is the one ordering that loses money.

**There are TWO env files.** `/home/github-runner/env/servana_api.env` (the
deploy source) and the runner workspace `.env` the process actually reads via
`dotenv.config()`. Editing only the source does nothing until the next deploy.
The workspace copy is **not** a verbatim copy — `deploy.yml` appends
`ALLOW_BASELINE_DOCUMENT_SCAN=true` — so append to it, never overwrite.
`pm2 env` shows none of this; it only lists PM2's 21-var launch environment.

**Still unproven:** no real payment has gone through since the fix. One live
low-value transaction is the only thing that closes this, then check for
`environment mismatch` / `Invalid signature` in the PM2 log — both should be
absent.

**3. Superseded checkout session is unrecoverable (backend, untested).**
`createCheckoutSession` reuses a session for 2 h, then mints a new one and
**overwrites** `provider_payment_id` and `raw_response`. The old session is
neither voided at PayMongo (they live ~24 h) nor retained. Pay a superseded
session and the webhook UPDATE matches nothing, the fallback lookup also misses,
and it throws → **500, retried forever, money captured and never recorded**.
Contained fix: keep `prior_session_ids TEXT[]`, append on supersede, widen only
the webhook's not-found branch — leave the primary UPDATE alone.

**4. DONE — 1.0.0+39 SUBMITTED to Play production 2026-08-10, 100% rollout,
awaiting review.** `sha256 de904643…` at `servana-39-release\`, built from
`074ecdf`, all five verifier checks pass, `jar verified` as `CN=Servana Client`,
mapping + native symbols embedded (the AAB is the only upload). Gate: format 0,
analyze 0 (41 infos), 1466 tests / 6 skipped.

**Two beliefs recorded in this brief were wrong, and both were inferences:**

- *"Play serves +37."* It served **+38**, published Aug 7. The +38 upload was
  rejected with *"Version code 38 has already been used."*
- *"versionCode 38 is not burned, so a rebuild at the same version is free."*
  **A version code is consumed by ANY upload to ANY track, including drafts and
  discarded releases.** What Play currently *serves* tells you nothing about
  which codes are spent. Check Latest releases and bundles before choosing one.

The live +38 was a PRE-FIX build, so the four fixes below had reached **nobody**.
It reported **0 installs / 0.0% install base**, which is the only reason that
cost nothing. **Every +38 bundle on this machine is now dead — do not upload
one.** `verify_aab.py` no longer hardcodes the expected code; it reads
`pubspec.yaml` or takes an argument, because a frozen `vc == 38` would have kept
asserting the old version forever.

*Kept below because the reasoning is the reusable part.* The old bundle was
built at `38576a2` and verified properly at the time. **Four fix commits had
landed since**, none of them in it:

| commit | what uploading the stale bundle costs users |
| --- | --- |
| `e5648fa` | booking / payment / signup hardening |
| `7690556` | booking timeline pointed at the wrong route (GAP-C15-002) |
| `5725746` | every booking labelled "Beauty & Wellness" |
| `9d57839` | `WORKER_ASSIGNED` told customers their professional was **on the way** when they had only been assigned; messaging access-revocation; a short client msg-id causing deterministic 422s on send |

The P0 dark-mode signup and status-banner fixes (`eb2b411`) **are** in the built
artifact — verified as an ancestor of `38576a2`, so that much is not at risk.

**Rebuilding is free: versionCode 38 is not burned on Play** (Play serves 37), so
a rebuild at the same version is valid and strictly better than shipping the old
bundle. Use the local recipe and re-run `verify_aab.py` — and self-test the
verifier against the previous AAB first, or a verifier that only ever passes
proves nothing.

**The general rule this is an instance of:** a verified artifact is verified
against the commit it was built from, not against `main`. Re-check
`git log <build-sha>..HEAD` before every upload.

---

## Recently closed — do not re-litigate

- **Backend login-limiter split, verified live in production.**
  `/auth/customer-firebase-login` and `/auth/refresh` were sharing a
  10-per-15-minutes-**per-IP** budget with password sign-in. Under carrier-grade
  NAT that meant unrelated customers on one public address could exhaust it
  between them, and this app's refresh path falls back to a stale token → 401 →
  sign-out. Now `200;w=900` on the token routes, `10;w=900` on password routes.
  Measured on production, not inferred.
- **This app was never the bug** in that investigation. It persists its session
  (`SessionService.saveSession`) and restores it on launch (`_onCheckSession`),
  spending one login call per real sign-in. The web portal was re-exchanging on
  every page load; it has since been fixed to match this behaviour.
- **Booking status parity** — this app already recognised every status; the web
  portal was missing 16 and needed the change. No mobile change was required.

---

## Traps that have cost real time

- **Play re-signs your app.** Google Sign-In, Maps and Facebook need **both** the
  upload and the Play certificate registered. This class of bug is invisible via
  App Distribution and only appears for real Play installs.
- **There is no dark mode.** `ColorPalette` is light-only and is read ~530 times
  bypassing `ThemeData`. Do **not** restore `buildDarkAppTheme`.
- **`late final AnimationController`** must be built in `initState`; a lazy read
  in `dispose()` throws.
- **`padding: null` on a scroll view silently adopts `MediaQuery.padding`.**
- **Postgres timestamps arrive as JS strings** from the backend.
- **`role` conflates authorization with trade.** 0=dev, 1=admin, 3=customer are
  authorization; 2, 4, 5, 6, 7, 8, 9 are trades. A `role === 2` check misses six.
- **Three response envelope shapes are live simultaneously** —
  `{success, ...}`, a bare payload, and `{status, data}`. Confirmed empirically.
- **Branch on `error.recovery`, not HTTP status.**
- **PowerShell 5.1 mangles SSH commands** — it strips embedded double quotes for
  native exes and `\$` is not an escape. Remote commands must contain no `"`,
  `(`, `)`, `$` or `\`. **Better: run them yourself.** `ssh -o BatchMode=yes
  root@192.46.224.126 '<single-quoted command>'` works directly from the agent's
  Bash tool, with no PowerShell in the path at all. Three commands were mangled
  before anyone checked whether that detour was necessary.
- **A config value can be absent from `pm2 env` and still be set.** Anything
  loaded by `dotenv.config()` lives only in the process's memory, never in the
  launch environment. Reading `pm2 env` and concluding "unset" produced a false
  P0 alarm before the `.env` file settled it.

---

## Production reality

**109 bookings · 9 customers · 0 completions ever · 48% stuck at PENDING_OTP ·
64 of 70 providers never assigned · 25 bookings PAID for ~103 days.** One
account holds 65 of the 109. Almost all of that traffic came through this app,
so these numbers are the closest thing to a verdict on it that exists — and
"0 completions ever" is the number to explain before building anything new.

**Read those numbers against open item 2.** Online checkout returned 503 on
every attempt, and when it did not, it was on a test key. That does not explain
everything — `PENDING_OTP` sits *before* payment — but a checkout that could
never succeed is now a known, dated contributor rather than a mystery. The
figures above predate the fix; re-measure before drawing conclusions from them.

Also open on the infrastructure side: **no database backup of any kind**, two
Firebase Admin keys in git history whose IAM deletion is unverified, and 85
provider ID documents readable unauthenticated.
