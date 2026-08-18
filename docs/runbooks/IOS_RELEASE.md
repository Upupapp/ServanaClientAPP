# Runbook — iOS release to TestFlight

Before this, every TestFlight build was a manual act on somebody's laptop:
unversioned, unreproducible, and impossible to attribute to a commit. CI had
`build-ios` (unsigned) and stopped there.

---

## What runs, and when

`release-ios` runs on **push to `main`**, gated on `validate` and `build-ios`.

Deliberately **not** gated on the Android release, exactly as `release-android`
does not wait on iOS. A Play release must never be blocked by a macOS runner,
and the reverse holds too.

If the signing secrets are absent the job emits a warning and skips the upload
rather than failing. A release job that goes red on every push for want of a
secret trains people to ignore a red iOS build — and then to ignore the real one.

## Secrets (repository secrets, not a named environment)

| secret | where from |
| --- | --- |
| `ASC_KEY_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API |
| `ASC_ISSUER_ID` | same page, above the key list |
| `ASC_KEY_P8` | the downloaded `AuthKey_XXXX.p8`, **entire file contents** |
| `APPLE_TEAM_ID` | optional; only to build for a different team |

**The `.p8` downloads exactly once.** Lose it and you revoke and reissue.

⚠️ **No named GitHub environment, deliberately.** One can only be created by
somebody with repository admin, and that exact choice previously left a release
job permanently unable to go green because the secrets could not be set.

## Why App Store Connect API key, and not match

Both work. **Mixing them is what produces the provisioning-profile mismatches
that consume days.** API-key signing needs no shared certificate repository and
no extra rotation path: three secrets, revocable from App Store Connect, and
Xcode fetches and manages the profile itself.

## Build numbering

Build number = **`github.run_number`**. Monotonic, and every TestFlight build
traces to the run and the commit that produced it. The marketing version stays
in `pubspec.yaml` as the single source.

## Promoting to the App Store

TestFlight and the App Store take the **same** build — `method:
app-store-connect` covers both, so no different build is needed.

1. App Store Connect → your app → **TestFlight**, confirm the build processed.
2. **App Store** tab → new version → select that build.
3. Complete the privacy nutrition labels (**M4.12**) and submit.

Submission is a business decision and belongs to TAB 20, not to this pipeline.

## Portal prerequisites — verify, do not assume

A pipeline that builds an archive the portal will reject wastes the whole cycle.
Confirm on App ID **`com.servana.client`**:

- [ ] **Push Notifications** — `aps-environment` is in the entitlements
- [ ] **Sign in with Apple** — mandatory, not optional: Review Guideline 4.8
      requires a privacy-preserving login option whenever an app offers
      third-party login, and this app offers Google and Facebook
- [ ] **Associated Domains** — added by TAB 14; without it Universal Links
      silently do nothing
- [ ] **APNs key uploaded to Firebase** for `servana-59bee` — Console → Project
      settings → Cloud Messaging

None of these can be done from this repository. Tracked as M4.4 / M4.5.

## Known inconsistency

`DEVELOPMENT_TEAM` is `2K2SF7NRQP` for the Runner target and `CAB884NRSN` for
RunnerTests. Only the app target matters for export, and `ExportOptions.plist`
uses it — but reconcile them (**M4.16**). This is exactly the kind of mismatch
that costs a day at signing time.

## Verifying a release actually works

Install **from TestFlight** on a real device, then confirm:

- [ ] push arrives
- [ ] Sign in with Apple completes
- [ ] a TAB 14 Universal Link opens the app (from **Mail or Notes** — Safari's
      address bar deliberately does not trigger them)
- [ ] re-run the job from a clean state, to prove it does not depend on runner
      or keychain residue
