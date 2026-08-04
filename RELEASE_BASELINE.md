# Release Baseline — Servana Client v1.0.0+35

Generated: 2026-07-30 | Sweep HEAD: 1eb2faa (post-C23 RELEASEFORTRESS+ fixes applied)

---

## Repository State

| Item | Value |
|---|---|
| Repository | Heatclift/ServanaClient |
| Branch | main |
| HEAD (pre-RELEASEFORTRESS+) | 1eb2faa |
| Dart SDK constraint | >=3.3.0 <4.0.0 |
| Flutter channel | stable |
| Android app ID | com.servana.serviceclient |
| iOS bundle ID | com.servana.client |
| Firebase project | servana-59bee |
| Production API | https://api.servana.com.ph |
| Version | 1.0.0+35 |

---

## Sweep Findings

### FIXED During This Command

#### P1: iOS Firebase bundle ID mismatch
- **File**: `lib/firebase_options.dart`
- **Was**: `iosBundleId: 'com.servana.serviceclient'`
- **Now**: `iosBundleId: 'com.servana.client'`
- **Risk**: Firebase iOS SDK would not match the correct app record in the console, causing authentication and analytics misattribution.
- **Status**: FIXED

#### P2: No Android network security config
- **Files added**: `android/app/src/main/res/xml/network_security_config.xml`
- **Manifest updated**: `android:networkSecurityConfig="@xml/network_security_config"`
- **Policy**: Explicit HTTPS-only for api.servana.com.ph
- **Status**: FIXED

#### P2: CI pipeline lacked release build stage
- **File updated**: `.github/workflows/flutter-ci.yml`
- **Added**: `release-android` job — runs on main push, requires `production` environment approval, builds signed AAB using keystore injected via GitHub Actions secrets, produces SHA-256 checksum
- **Added**: `dart format --set-exit-if-changed .` to format gate
- **Status**: FIXED

---

### OPEN — Must Resolve Before Store Submission

#### P1: Google Maps API key not configured
- **Files**: `android/app/src/main/res/values/strings.xml`, `ios/Runner/Info.plist`
- **Value**: `REPLACE_WITH_GOOGLE_MAPS_API_KEY` (placeholder)
- **Required**: Inject production Maps key via CI secret (`GOOGLE_MAPS_API_KEY`) before release build. The CI `release-android` job now does `sed` substitution. iOS requires a Xcode pre-build phase or xcconfig injection.
- **Status**: OPEN — requires Google Maps console setup + CI secret population

#### P1: Android signing infrastructure — local only
- **Key file**: `android/key.properties` — correctly gitignored, exists locally only
- **Upload keystore**: `upload-keystore.jks` — local only
- **CI**: Requires `CM_KEYSTORE_BASE64`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD` GitHub Actions secrets set before `release-android` job can run
- **Status**: OPEN — operator must populate GitHub Actions secrets

#### P1: iOS signing not configured for CI
- **Situation**: No entitlements file, no provisioning profile, no distribution certificate in repository
- **Required**: Apple Developer account, iOS App ID `com.servana.client`, distribution certificate, provisioning profile, App Store Connect app record
- **CI**: No iOS release job yet — macOS runner required
- **Status**: OPEN — requires Apple Developer setup and macOS CI runner

#### P1: Firebase config files committed to source
- **Files**: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
- **Assessment**: Firebase client API keys are public by design and restricted by Firebase Security Rules + app attestation. Committing them is common practice and accepted by Firebase. However, these files represent the production Firebase project. They must remain consistent with production signing.
- **Action**: Verify Firebase Security Rules enforce authenticated-only access. Verify Android App Check and iOS App Attest are configured in Firebase Console.
- **Status**: ACCEPTABLE with App Check — OPEN for App Check verification

#### P2: App Links (Android) not configured
- **Situation**: No `<intent-filter android:autoVerify="true">` in `AndroidManifest.xml`
- **Impact**: Deep links from notifications and payment returns use custom scheme fallback only; autoVerified App Links (HTTPS-based) are not active
- **Required**: Configure `assetlinks.json` on `api.servana.com.ph` + intent-filter in manifest
- **Status**: OPEN — requires backend team to host `assetlinks.json`

#### P2: Universal Links (iOS) not configured
- **Situation**: No `com.apple.developer.associated-domains` entitlement, no `apple-app-site-association` file
- **Impact**: iOS deep links use custom scheme only
- **Required**: Create Runner.entitlements with `applinks:api.servana.com.ph`, host AASA file
- **Status**: OPEN — requires backend team + Apple Developer setup

#### P2: iOS provisioning entitlements absent
- **Situation**: No `Runner.entitlements` file exists
- **Minimum entitlements needed**: push notifications (`aps-environment: production`), associated domains if Universal Links are used
- **Status**: OPEN

#### P2: Obfuscation not applied to release builds
- **CI release job does not include** `--obfuscate --split-debug-info`
- **Impact**: Dart symbols are readable in release builds, aiding reverse engineering
- **Required**: Add flags + configure Crashlytics symbol upload before first production release
- **Status**: OPEN — add `--obfuscate --split-debug-info=/tmp/symbols` and upload symbols to Crashlytics

#### P3: CI action versions not SHA-pinned
- **Situation**: `actions/checkout@v4`, `actions/setup-java@v4`, etc. pinned to tags, not SHAs
- **Risk**: Tag mutation (low risk for official GitHub actions, but a supply-chain hygiene gap)
- **Status**: ACCEPTABLE for current maturity; upgrade to SHA pins when CI hardens

#### P3: `mock_` prefix on optimistic booking placeholder
- **File**: `lib/modules/job_order/presentation/blocs/job_order_bloc.dart:303`
- **Assessment**: This is an optimistic UI pattern — a placeholder booking with `id='mock_...'` is added to HomeStore immediately after submit and replaced by the real backend response on next `loadBookings()`. It is NOT a fake-data production leak because: (a) the `MockBackend` class has `assert(!kReleaseMode)` which would crash a production build if somehow enabled, (b) `AppConfig.fromEnv()` defaults `MOCK_BACKEND=false`, and (c) `HttpBackend` is the actual production path.
- **Action**: The comment text is misleading. Rename variable to `optimisticBooking` and update comments for clarity.
- **Status**: P3 — not blocking, cosmetic/clarity improvement

---

### CONFIRMED CLEAN

| Check | Result |
|---|---|
| `key.properties` in git history | NOT committed — gitignored, local only |
| Cleartext traffic exemption | None — HTTPS-only via network_security_config |
| `NSAllowsArbitraryLoads` | Not set — ATS enforced by default |
| `MOCK_BACKEND` production default | `false` — safe |
| `MockBackend` release guard | `assert(!kReleaseMode)` — crash if somehow enabled |
| Production API URL default | `https://api.servana.com.ph` |
| Analytics PII filter | Active — strips password/token/auth_token/secret keys |
| Crashlytics PII in keys | `safe_diagnostics.dart` strips URLs and long tokens |
| `flutter analyze` | 38 infos (prefer_const only) — 0 warnings, 0 errors |
| `flutter test` | 933/933 pass, 6 skip, 0 fail |
| Firebase project ID | servana-59bee (consistent across Android + iOS) |

---

## Production Mock Elimination Status

| Mock | Status | Evidence |
|---|---|---|
| `MockBackend` in production path | BLOCKED by `assert(!kReleaseMode)` | `mock_backend.dart:27` |
| `MOCK_BACKEND` dart-define default | `false` | `app_config.dart:39` |
| Optimistic booking placeholder | Cosmetic only — real data replaces on next load | `job_order_bloc.dart:347-349` |
| Mock token in MockBackend | Never reached in production | `mock_backend.dart:1104` |

---

## Tests

| Suite | Count | Result |
|---|---|---|
| Unit + Widget | 933 | ALL PASS |
| Skipped | 6 | Pre-existing (pre-C22) |
| Failed | 0 | — |
| Analyzer errors | 0 | — |
| Analyzer warnings | 0 | — |
| Analyzer infos | 38 | All `prefer_const_*` in settings/support screens |
