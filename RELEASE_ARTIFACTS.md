# Release Artifacts — Servana Client v1.0.0+35

Generated: 2026-07-30 | Commit: 1eb2faa (post-RELEASEFORTRESS+ fixes)

---

## Artifact Register

| Artifact | Version | Build | Commit | Status |
|---|---|---|---|---|
| Android Debug APK (arm64) | 1.0.0 | 35 | 1eb2faa | CI-produced on every push |
| Android Release AAB | 1.0.0 | 35 | pending-post-fixes commit | Requires CI secrets populated |
| iOS Archive (.xcarchive) | 1.0.0 | 35 | pending | Requires macOS CI runner + Apple signing |
| iOS IPA | 1.0.0 | 35 | pending | Requires distribution certificate |

---

## Checksum Policy

All release artifacts must have a SHA-256 checksum generated immediately after build:

```bash
sha256sum build/app/outputs/bundle/release/app-release.aab
sha256sum build/app/outputs/flutter-apk/app-release.apk
```

The checksum file must be stored alongside the artifact in CI. The submitted artifact must match the tested artifact exactly. Do not rebuild between test and submit.

---

## Signing Verification

### Android
```bash
# Verify AAB signing (requires build-tools in PATH)
apksigner verify --verbose build/app/outputs/bundle/release/app-release.aab

# Check certificate fingerprint
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Expected signing identity: `upload` key alias from `upload-keystore.jks`
Keystore location: Local only (gitignored) + CI secret `CM_KEYSTORE_BASE64`

### iOS
```bash
# Verify IPA signing (requires codesign in macOS)
codesign --verify --deep --strict --verbose=2 Runner.app
```

Expected identity: Apple Distribution: [Servana Organization]

---

## Symbol Files

Dart obfuscation symbols (when `--obfuscate --split-debug-info` is enabled) must be:
1. Uploaded to Firebase Crashlytics immediately after build
2. Stored in secure storage for the lifetime of the production release
3. Tagged with version + build number + commit SHA

**Current status**: Obfuscation not yet enabled. Add to release build before production submission.

---

## Retention Policy

| Artifact Type | Retention |
|---|---|
| Debug APK | 14 days (CI) |
| Release AAB | 90 days (CI) + permanent in Play Console |
| iOS IPA | Permanent in App Store Connect |
| Debug symbols | Duration of supported release + 12 months |
| Test reports | 90 days |

---

## CI Artifact URLs

Release AABs are uploaded as GitHub Actions artifacts named:
`servana-client-release-aab-{git-sha}`

These are available in the GitHub Actions run for the merge commit to `main`.
