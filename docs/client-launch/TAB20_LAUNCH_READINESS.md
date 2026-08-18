# TAB 20 — Launch readiness: interim assessment

**Status:** PARTIAL — a go/no-go cannot be taken yet · **Date:** 2026-08-18

> **This document is not evidence.** Every figure was measured on 2026-08-18 and
> must be re-measured on the day a decision is taken. That instruction exists
> because the last recorded position was wrong: the integration was believed
> blocked on an undeployed backend, and v1 had been live and complete for some
> time.

---

## Verdict: **NO-GO**, on two blockers, neither of them code quality

### Blocker 1 — the canonical v1 layer is not on this machine (**M1**)

Phase C is the integration. TABs **05–12** cannot start: the capability flags
they switch gate a layer that does not exist in `origin/main`. `grep -r "api/v1" lib/`
returns **0 hits**. The 43 commits holding it were never pushed, correctly, under
the standing rule.

**The app in customers' hands is 100% legacy and will stay that way** until
those commits are landed and shipped.

### Blocker 2 — three fixes are committed and undeployed (**M2**)

| TAB | defect | state |
| --- | --- | --- |
| 03 | `/api/catalog` signposts the wrong successor | fixed locally, **not deployed** |
| 04 | v1 401s answer in the legacy envelope | fixed locally, **not deployed** |
| 18 | no security headers on the origin | written earlier, **not deployed** |

**One deploy of `servana_api` closes all three.** `scripts/verify-deploy.sh`
proves it did — before/after capture, a verdict, and an additive-only guard that
fails if any status code moved.

---

## Measured today

### Integration surface — re-probed against production

```
implemented v1 contract paths mounted     105 / 105    zero 404
legacy routes (contract-derived)          115 / 115    zero 404
legacy routes the shipped client calls     70 /  70    zero 404
planned entries wrongly answering                 0
successor signpost wrong                          1    (TAB 03, undeployed)
client routes undeclared by the contract          30 / 70   ← M6
```

**The integration is blocked on neither side.** v1 is deployed and complete; the
client layer that would use it is on another machine.

### Client gates

```
dart format --set-exit-if-changed .   exit 0
flutter analyze --no-fatal-infos      exit 0   No issues found
flutter test                          exit 0   1487 passed, 6 skipped
```

Analyzer infos: **42 → 0**. Tests: **1455 → 1487** (+32 added by this work).

### Android release artefact

Was **unbuildable** on 2026-08-18 (Gradle and Kotlin below current stable
Flutter's floors). Now builds, and R8 verified on a real artefact: **DEX
26.74 MB → 7.07 MB (−73.6%)**, **68.2% of classes obfuscated**. Signed with a
**throwaway key** — the real upload key is unverified (**M4.1**).

---

## Store compliance

| item | state |
| --- | --- |
| iOS `PrivacyInfo.xcprivacy` | ✅ present |
| iOS usage strings specific | ✅ each names the purpose |
| Sign in with Apple entitled | ✅ mandatory under Guideline 4.8 |
| Android permissions minimal and justified | ✅ re-audited |
| Play data safety declaration | ⛔ **M4.12** |
| Apple privacy nutrition labels | ⛔ **M4.12** |
| Reviewer account | ⛔ — state plainly this is the **customer** app; the sibling worker app was rejected because a reviewer got a customer account |

## Operational readiness

| item | state |
| --- | --- |
| Crash symbolication from an uploaded mapping | ⛔ **M4.2** — R8 is now on, so an un-uploaded mapping means unreadable crashes |
| Transport diagnostics (TAB 05) | ⛔ blocked on **M1** |
| RASP alerts to a team alias | ⚠️ code points at `security@servana.com.ph`; the alias must exist (**M4.10**) |
| Version-gate rollback rehearsed and timed | ⛔ **M4.7** |
| Support runbook for refunds/disputes/reports | ⛔ blocked on **M1** — those surfaces do not exist here |

**The platform has 109 bookings and zero completions ever recorded.** Any launch
plan should say plainly that this is a first real production load, and
instrument accordingly rather than assume the shipped paths have been exercised.

---

## What this programme completed

| TAB | verdict |
| --- | --- |
| 01 Ground-truth probe | CERTIFIED_WITH_NONBLOCKING_GAPS |
| 02 Clean-clone baseline | CERTIFIED_WITH_BLOCKED_SCOPE |
| 03 Successor signpost | CERTIFIED_PENDING_DEPLOY |
| 04 v1 auth envelope | CERTIFIED_PENDING_DEPLOY |
| 13 Android release build | CERTIFIED_WITH_DEVICE_GAPS |
| 14 Deep links | CERTIFIED_PENDING_HOSTING |
| 15 Version gate | CERTIFIED_WITH_CONSOLE_GAPS |
| 16 iOS release pipeline | CERTIFIED_UNVERIFIABLE_LOCALLY |
| 18 Security hardening | CERTIFIED_PENDING_DEPLOY |
| 19 Dependency hygiene | CERTIFIED |

**Blocked:** 05–12 and 17 (**M1**). TAB 17's harness
(`test/support/screen_test_container.dart`) is itself in the unlanded commits —
there is no 13-screen matrix here to extend to 62.

### Defects found that the Master Command did not contain

1. **A revoked session escaped the v1 envelope untranslated** (TAB 04). Of the
   five 401s `verifyAuth` writes, the most security-relevant one bypassed the
   translator because its body already carried a nested `error` key.
2. **The Android release build did not build at all** (TAB 13). Two version
   floors, no repository change — the unpinned CI toolchain moved underneath it.
3. **30 of the 70 legacy routes the client calls have no contract mapping**
   (TAB 01). The deprecation clock cannot see them.
4. **`.gitignore` stated two contradictory Firebase policies** (TAB 18), and
   root-level `key.properties`, `*.jks` and `mapping.txt` were unignored (TAB 13).
5. **Five discontinued packages, not one** — all transitive (TAB 19).

---

## The shortest path to a go

1. **Land the 43 commits** (M1) — `git bundle` from the Windows machine.
   Unblocks 05–12 and 17.
2. **Deploy `servana_api`** (M2) — closes TABs 03, 04 and 18's headers. Verify
   with `scripts/verify-deploy.sh`.
3. **Host the association files** (M4.3) — completes TAB 14 and unblocks TAB 07's
   password reset.
4. **Verify the real upload key and upload a mapping** (M4.1, M4.2).
5. **Publish and rehearse the version gate** (M4.7) — TAB 05 needs that
   propagation number.

Items 1 and 2 are the only two that block *other work*. The rest are parallel.
