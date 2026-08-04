# Mobile Release Certification — Servana Client

---

## Release Identification

| Field | Value |
|---|---|
| Release version | 1.0.0 |
| Build number | 35 |
| Commit SHA | 1eb2faa (C23 ACCESSFIX) + RELEASEFORTRESS+ infrastructure fixes |
| Branch | main |
| Release tag | v1.0.0+35 (to apply post-commit) |
| Backend contract | C23-compatible — see MOBILE_BACKEND_COMPATIBILITY_REPORT.md |
| Android artifact | Release AAB — pending CI secrets population |
| iOS artifact | Not yet producible — Apple Developer setup required |
| Certification date | 2026-07-30 |

---

## Gate Summary

### Code Quality
- [x] `dart format --set-exit-if-changed .` — PASS (CI step added)
- [x] `flutter analyze` — PASS (0 errors, 0 warnings, 38 infos — all prefer_const)
- [x] All unit tests — PASS (933/933, 0 fail, 6 skip pre-existing)
- [x] Widget tests — PASS (included in 933)
- [ ] Integration tests — NOT RUN (no integration_test/ suite exists)
- [ ] Physical-device E2E — NOT RUN (requires hardware)

### Security
- [x] Secret scan — PASS (no hardcoded secrets in Dart source)
- [x] `key.properties` not committed — PASS (gitignored)
- [x] MockBackend blocked in release — PASS (`assert(!kReleaseMode)`)
- [x] MOCK_BACKEND default false — PASS
- [x] HTTPS enforced (Android network security config) — PASS (added this command)
- [x] ATS enforced (iOS) — PASS (NSAllowsArbitraryLoads not set)
- [x] Analytics PII filter active — PASS
- [x] Account isolation on logout — PASS (C20 + C23 wiring)
- [ ] POST /api/auth/logout wired — OPEN (server session not invalidated on client logout)
- [ ] Firebase App Check — NOT VERIFIED (requires Firebase Console check)

### Signing
- [x] Android signing configured (Gradle signingConfigs.release) — PASS (local key.properties)
- [x] Android signing CI path (CM_KEYSTORE_PATH env vars) — PASS (Gradle wired)
- [ ] Android CI secrets populated (CM_KEYSTORE_*, GOOGLE_MAPS_API_KEY) — OPEN
- [ ] Android release AAB produced and verified — OPEN (requires secrets)
- [ ] iOS distribution certificate — OPEN (Apple Developer required)
- [ ] iOS provisioning profile — OPEN
- [ ] iOS entitlements file — OPEN

### Accessibility
- [x] C22 ACCESSCORE+ system complete — PASS
- [x] C23 ACCESSFIX — all dead utilities wired, 933 tests pass — PASS
- [x] WCAG 2.2 AA: semantic labels, focus restoration, live regions, touch targets — PASS
- [ ] TalkBack physical device — NOT EXECUTED
- [ ] VoiceOver physical device — NOT EXECUTED
- [ ] 200% font size regression — NOT EXECUTED

### Privacy and Store
- [ ] iOS Privacy Manifest — NOT CREATED
- [ ] Google Play Data Safety declaration — NOT COMPLETED
- [ ] Apple App Privacy declaration — NOT COMPLETED
- [ ] Privacy policy URL — NOT LINKED
- [ ] Terms of Service URL — NOT LINKED
- [ ] Store screenshots — NOT PREPARED
- [ ] App review account — NOT CREATED

### Backend Compatibility
- [x] Production API URL: https://api.servana.com.ph — CONFIGURED
- [x] Firebase project ID consistent — PASS (servana-59bee)
- [x] iOS Firebase bundle ID corrected — FIXED this command
- [ ] POST /api/auth/logout — OPEN

### Release Infrastructure
- [x] CI format check added — PASS
- [x] CI release-android job added (builds signed AAB on main push) — PASS
- [x] Network security config (Android) — PASS
- [ ] Obfuscation + symbol upload — OPEN
- [ ] App Links / Universal Links — OPEN (requires backend hosting)
- [ ] iOS Privacy Manifest — OPEN

---

## Known Issues

| ID | Severity | Summary |
|---|---|---|
| GAP-001 | P1 | POST /api/auth/logout not wired — server sessions persist after logout |
| GAP-002 | P1 | Google Maps key placeholder — maps will fail without CI secret |
| GAP-003 | P1 | Android CI signing secrets not populated |
| GAP-004 | P1 | iOS signing infrastructure absent |
| GAP-005 | P2 | App Links / Universal Links not configured |
| GAP-006 | P2 | iOS entitlements absent |
| GAP-007 | P2 | Obfuscation not enabled |
| GAP-008 | P2 | No integration test suite |
| GAP-009 | P2 | Store listings, metadata, privacy policy, screenshots not prepared |
| GAP-010 | P2 | GET /api/capabilities not implemented on backend |

---

## Rollback Plan

- Google Play: Halt rollout via Managed Publishing
- App Store: Pause phased release
- Remote Config: Kill switches for live tracking, payment webview, experimental features
- Hotfix: Branch from v1.0.0+35, apply minimal fix, increment to v1.0.1+36
- Backend: Maintain backward compatibility with v1.0.0 during rollout window
- See: MOBILE_INCIDENT_RUNBOOK.md

---

## Sign-Off Status

| Role | Status | Notes |
|---|---|---|
| Engineering | PARTIAL — code complete, infra gaps remain | C23 RELEASEFORTRESS+ complete locally |
| QA | PENDING — physical device testing not done | Integration test suite needed |
| Security | PARTIAL — GAP-001 (logout) open | Must be wired before public release |
| Privacy/Legal | PENDING — policies and declarations not prepared | Required for store submission |
| Accessibility | PARTIAL — code complete, physical device not verified | TalkBack/VoiceOver required |
| Product | PENDING | Store assets not prepared |
| Release Manager | PENDING | |

---

## Final Decision

```
DECISION: NO-GO FOR PUBLIC STORE SUBMISSION

REASON: Multiple P1 and P2 operational gaps remain:
  - iOS signing infrastructure not set up
  - Android CI secrets not populated (Maps key, keystore)
  - POST /api/auth/logout not wired (server session leak risk)
  - No store listings, privacy policy, or store metadata
  - Physical-device test matrix not executed
  - iOS Privacy Manifest not created

WHAT IS COMPLETE:
  - All code quality gates pass (933/933 tests, 0 analyzer errors)
  - WCAG 2.2 AA accessibility system complete
  - Security hardening in-code complete (PII filter, safe diagnostics, account isolation)
  - Network security (HTTPS-only Android config added)
  - Firebase iOS bundle ID corrected
  - CI upgraded with format gate and release-android job
  - Signing Gradle configuration correct and tested locally
  - Incident runbook, dependency inventory, compatibility report, all baseline docs created

NEXT STEPS TO REACH GO:
  1. Backend: Wire POST /api/auth/logout
  2. Operator: Populate GitHub Actions secrets (CM_KEYSTORE_*, GOOGLE_MAPS_API_KEY)
  3. Apple Developer: Create app, configure signing, produce distribution certificate
  4. Create Runner.entitlements with aps-environment: production
  5. Enable obfuscation + Crashlytics symbol upload in CI release job
  6. Prepare store listings, screenshots, privacy policy URL, legal links
  7. Create iOS Privacy Manifest
  8. Execute physical-device testing matrix (see MOBILE_RELEASE_REPORT.md)
  9. Re-run flutter test + flutter analyze on final commit
  10. Re-issue certification with GO when all items above are confirmed

ESTIMATED TIME TO GO: Depends on operator infrastructure setup
  - Code: READY
  - Infrastructure: 1–3 days (Apple signing, CI secrets, backend fix)
  - Store assets: 1–2 days
  - Physical testing: 1 day
```

---

*This document was produced by C23 V1 RELEASEFORTRESS+ on 2026-07-30.*
*All code-level gates have been executed and verified locally.*
*Operational gaps are accurately documented and must not be skipped.*
