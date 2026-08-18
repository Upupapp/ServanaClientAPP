# TAB 18 — Client and transport security hardening

**Status:** local scope COMPLETE · **CERTIFIED_PENDING_DEPLOY**
**Date:** 2026-08-18 · **Owner:** Client + Backend

---

## Decision 1 — certificate pinning is **DECLINED**, and here is why

The TAB permits either: implement pinning, or document it as declined *with
reasons*. It is declined, and this is the reasoning, not a preference.

### The measured facts

```
$ openssl s_client -connect api.servana.com.ph:443 -showcerts
 0 s:/CN=api.servana.com.ph
 1 s:/C=US/O=Let's Encrypt/CN=YE2
 2 s:/C=US/O=ISRG/CN=Root YE
 3 s:/C=US/O=Internet Security Research Group/CN=ISRG Root X2
```

The origin is served by **Let's Encrypt**. That single fact decides it:

- **Leaf certificates rotate every ~60–90 days.** Pinning the leaf brICKS every
  installed app several times a year, by design.
- **The intermediate rotates on ISRG's schedule, not ours.** `YE2` is itself a
  recent ECDSA intermediate; ISRG has changed intermediates before (X1→X2,
  R3→R10/R11) and will again. A pinned intermediate is a bricking event on
  somebody else's calendar.

### Why the usual mitigation is not available here

The standard answer is "pin the intermediate, carry a backup pin, document
rotation." That requires being able to **ship a fix faster than the pin
expires**, and this app cannot:

| capability | state |
| --- | --- |
| Remote un-pin | **impossible by design** — capability flags are build-time, deliberately, because a flag a server can flip is a flag an attacker can flip |
| iOS emergency release | **none** — CI has `build-ios` but no `release-ios` (TAB 16); a fix goes through App Review |
| Force-update propagation delay | **unmeasured** — TAB 15's gate exists, the rehearsal is M4.7 |

The TAB's own guardrail says it plainly: *"Do not enable pinning without a
tested rotation path. A pinned certificate that expires with no backup pin
bricks every installed application simultaneously."* Every precondition for a
tested rotation path is currently missing.

**Pinning today would make this app less available and no more confidential.**
A total outage of a booking platform is not a security improvement.

### What is in place instead

`android/app/src/main/res/xml/network_security_config.xml` pins
`cleartextTrafficPermitted="false"` for `api.servana.com.ph` **including
subdomains**, so the app cannot be downgraded to HTTP even by a misconfiguration.
That is the half that carries no availability risk, and it is already done.

### Revisit when — a real trigger, not "later"

Reconsider pinning when **all three** hold:

1. TAB 16 has landed, so iOS can ship without a manual laptop build.
2. TAB 15's propagation delay is measured and is **shorter than the shortest
   pin lifetime** with margin.
3. The origin moves to a certificate the project controls the rotation of, or a
   pin set covering ISRG's published intermediate roadmap with a tested backup.

Until then this is a decision with a rationale. An unpinned app with a written
rationale is a decision; one with no rationale is an oversight.

---

## Decision 2 — RASP alerts leave the personal mailbox

`free_rasp_service.dart` configured `watcherMail` to a named individual's
personal Gmail address. Tamper, hooking and repackaging alerts for a production
application with real customers went to one person's inbox.

One person on leave, one full mailbox, one spam rule, and nobody learns the app
is being repackaged. **An alert nobody owns is telemetry, not security.**

Now `String.fromEnvironment('RASP_WATCHER_MAIL')`, defaulting to
`security@servana.com.ph` — a domain the organisation controls — following the
`APPLE_TEAM_ID` pattern already in that file. The address is not repeated in
source: it belongs to a person, not the project.

**The alias must exist and be monitored by more than one person** (M4.10), and
`docs/runbooks/RASP_ALERTS.md` states what happens when one fires.

---

## Decision 3 — the Firebase configuration policy, stated once

`.gitignore` carried **two contradictory policies stacked together**: a block
saying the Firebase files "must never be committed… they are now untracked",
directly above one saying client config "is NOT a secret and IS committed,
deliberately."

Measured: all three — `lib/firebase_options.dart`,
`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` — **are
tracked**. The first block was stale from a reversed decision, and the reversal
happened because untracking them broke CI for everyone (`main.dart` imports
`firebase_options.dart`).

Settled on **commit deliberately**, which is both the current state and the
correct one — these files identify the project and authorise nothing; Firebase
Security Rules and `verifyIdToken` are what protect it. The stale block and the
three commented-out ignore lines are **deleted** rather than left as decoration:
a commented ignore rule states no policy and does nothing, but reads as an
unfinished intention, and two contradictory policies in one file is how the next
credential sweep untracks them and breaks the build a second time.

Verified: **no file in this repository contains a `private_key`.** The genuinely
secret Firebase Admin service-account key lives in `servana_api` and is
correctly untracked there.

---

## Finding — the security headers are written, and not deployed

Production serves **no** `Strict-Transport-Security`, `X-Content-Type-Options`,
`X-Frame-Options` or `Referrer-Policy`. Re-measured today.

But they are **already implemented**: `src/middleware/securityHeaders.ts`
(`apiSecurityHeaders`), committed at `f5c4743`, mounted *before* the CORS
delegate — which is load-bearing, because a request from a non-whitelisted
origin is still served and would otherwise carry no `nosniff`. HSTS is one year,
`includeSubDomains`, **deliberately without `preload`** — preload is close to a
one-way door and every origin on the domain inherits it.

That configuration is correct as written and needs no change from this TAB.

**This is the third TAB whose fix is committed-but-undeployed** (TAB 03's
signpost, TAB 04's auth envelope, and now these headers). A single deploy of
`servana_api` closes all three. See **M2**.

---

## Permissions and usage strings — re-audited, no change needed

| permission | justified |
| --- | --- |
| `INTERNET` | ✅ |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | ✅ provider matching and live tracking |
| `POST_NOTIFICATIONS` | ✅ |
| `DETECT_SCREEN_CAPTURE` / `DETECT_SCREEN_RECORDING` | ✅ consumed by freeRASP |

iOS usage strings are specific and say *why* — camera, photo library and both
location keys all name the actual purpose. A vague string is a review rejection;
these are not vague.

---

## Acceptance gate

| Requirement | Result |
| --- | --- |
| Security headers on the production origin | ⛔ **written and correct, NOT DEPLOYED — M2** |
| Pinning decision implemented **or documented with rotation procedure** | ✅ **declined, with evidence and a revisit trigger** |
| RASP alerts to a team-owned address + written response | ✅ code + `docs/runbooks/RASP_ALERTS.md`; alias creation is **M4.10** |
| Firebase configuration policy applied, ignore file consistent | ✅ contradiction removed, policy stated once |
| IAM state of both historical service accounts verified | ⛔ **M4.11** — needs console access |
| Dependency vulnerability scan | → TAB 19 |
