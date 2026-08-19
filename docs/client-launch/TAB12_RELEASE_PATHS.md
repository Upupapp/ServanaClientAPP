# TAB 12 — Android and iOS release paths

**Date:** 2026-08-19 · **Status:** local scope COMPLETE; the rest is device- and
portal-gated

---

## Two corrections to things this programme previously asserted

### 1. The `DEVELOPMENT_TEAM` mismatch does NOT block release

TAB 14 and TAB 16 called it *"the kind of mismatch that costs a day at signing
time"*, and the master command repeats it. **That overstated it.**

Measured from `Runner.xcscheme`:

```
BuildAction    -> Runner.app
ArchiveAction  -> (inherits build)      => Runner.app only
TestAction     -> Runner.app, RunnerTests.xctest
```

The archive never builds `RunnerTests`, so `flutter build ipa` and the TestFlight
upload never touch the target that carries the other team id.

| target | team | in the release path |
| --- | --- | --- |
| `Runner` (`com.servana.client`) | `2K2SF7NRQP` | yes |
| `RunnerTests` | `CAB884NRSN` | **no** |

It is still worth reconciling — it affects running unit tests on a **physical
device** — but it is a developer-experience issue, not a release blocker, and it
should not be triaged as one.

**Not changed here on purpose.** Aligning `RunnerTests` to `2K2SF7NRQP` requires
that `com.servana.client.RunnerTests` exists under that team in the Apple portal.
If it was registered under `CAB884NRSN`, changing the id breaks signing for the
target that currently works. That is portal state this repository cannot see.

### 2. Making the Crashlytics mapping upload explicit is NOT available today

TAB 13 turned R8 on, and an obfuscated build whose mapping never reaches
Crashlytics trades readable crash reports for a smaller binary — silently. The
obvious hardening is to state the intent rather than inherit it:

```groovy
firebaseCrashlytics { mappingFileUploadEnabled true }
```

**It does not compile here.** Verified by running the build rather than reading
docs:

```
Could not find method firebaseCrashlytics() for arguments [...]
  on BuildType$AgpDecorated{name=release, ..., minifyEnabled=true, ...}
```

`firebase-crashlytics-gradle:2.7.1` with AGP 8.11.1 does not expose that
extension on a build type. Reverted; the tree builds clean again.

**Where that leaves it.** The plugin is applied
(`android/app/build.gradle:161`) and uploads the mapping for a minified release
by **default**, so mapping upload is expected to work today. What is missing is
the ability to *assert* it, which is a plugin upgrade — 2.7.1 is several majors
behind — and therefore **TAB 19 work**, not a one-line hardening.

Until then M4.2 stands: verify a release-mode crash actually symbolicates.
Nothing in this repository can prove it.

---

## Portal prerequisites — audited from repository evidence

What the repository can confirm, so the manual list is only what genuinely
cannot be checked here:

| prerequisite | repo evidence | portal action still needed |
| --- | --- | --- |
| Push notifications | `aps-environment` in `Runner.entitlements` (`development`; Xcode rewrites on export) | capability on the App ID |
| Sign in with Apple | `com.apple.developer.applesignin` present | capability on the App ID — **mandatory**, Guideline 4.8, since the app offers Google and Facebook |
| Associated Domains | added by TAB 14, entitlement present | capability on the App ID |
| APNs key in Firebase | not visible from the repo | upload for `servana-59bee` |
| `PrivacyInfo.xcprivacy` | present | — |

Every entitlement the pipeline needs is in the repository. All four remaining
items are portal or console state.

---

## Unchanged from TAB 13, and still the gating facts

- R8 verified on a real artefact: DEX **26.74 MB → 7.07 MB (−73.6%)**, **68.2%**
  of classes renamed — but signed with a **throwaway key** that was deleted.
  Nothing is established about the real upload key (**M4.1**).
- `release-ios` exists and has **never run** (**M4.6**).
- The fail-fast signing guard is verified, including that it does **not** affect
  debug builds — `flutter build apk --debug` exits 0 with the guard's message
  absent.
