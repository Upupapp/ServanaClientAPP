# TAB 13 — Android release build correctness: R8, signing and size

**Status:** local scope COMPLETE · **CERTIFIED_WITH_DEVICE_GAPS**
**Date:** 2026-08-18 · **Commit:** `37c0526` · **Blocks:** TAB 20

---

## The blocker nobody had recorded: the build did not build

Before R8 or signing could be examined, `flutter build appbundle --release`
failed twice on version floors current stable Flutter enforces:

```
Gradle 8.13.0  < Flutter's minimum 8.14.0
Kotlin 2.0.0   < Flutter's minimum 2.2.20
```

**Nobody changed the repository.** All four CI jobs resolve
`subosito/flutter-action@v2` with `channel: stable` and no version, so when
stable moved to 3.47.0 the floors moved with it and the Android build broke on
its own. This is precisely the reproducibility gap TAB 02 recorded as a handoff
to TAB 19 — it arrived sooner than expected, and it is a **launch blocker**:
there is no shippable Android artefact until it is cleared.

Fixed: Gradle → 8.14.3 (pinned by `distributionSha256Sum`, so a substituted
archive fails the build rather than running), Kotlin → 2.2.20. AGP stays 8.11.1,
which supports both. `android/gradlew` gains its executable bit — a
non-executable wrapper is permission-denied on a Linux runner.

## Finding 1 — R8 never ran

`proguardFiles` declared without `minifyEnabled true`. Without that flag neither
the shrinker nor the obfuscator runs, and the 8-line `proguard-rules.pro` was
dead configuration reading as a hardening step that was not happening — while
**freerasp**, a runtime self-protection SDK for detecting tampering and
repackaging, shipped beside fully readable bytecode.

### Measured on real artefacts, not inferred

| | R8 off | R8 on | delta |
| --- | ---: | ---: | ---: |
| **DEX** | 26.74 MB | **7.07 MB** | **−73.6%** |
| AAB total | 90.86 MB | 87.82 MB | −3.3% |
| arm64-v8a download | 65.33 MB | 62.32 MB | −4.6% |
| armeabi-v7a download | 64.61 MB | 61.60 MB | −4.7% |
| x86_64 download | 65.40 MB | 62.39 MB | −4.6% |

Obfuscation: `mapping.txt` 436,937 lines · **5,346 classes renamed**, 2,490
kept — **68.2%**.

The total moves far less than the DEX because **86.7 MB of the bundle is native
libraries**, which R8 does not touch. Both numbers are recorded, because
anyone expecting the headline DEX figure to show up on the download will be
disappointed. Per-ABI figures are compressed — what a device actually fetches.

### No keep rules were added

Deliberately. The method is explicit that a rule added "just in case" defeats
the shrinker it was meant to accommodate. R8 was enabled and the build run
first: Hive, freezed, json_serializable, Firebase, Talsec,
`google_maps_flutter`, `socket_io_client` and the Facebook SDK all ship consumer
rules in their AARs, and the build is clean without help. Rules get added when
something is **observed** to break.

## Finding 2 — release signing degraded silently

`signingConfigs.release` is populated only from the Codemagic env vars or
`key.properties`. With neither it was an **empty config** that
`buildTypes.release` still pointed at — and on AGP 8.x that yields an
**unsigned** artefact. The comment claiming it "uses signingConfigs.debug
anyway" was wrong, and a comment that misdescribes the build is how the next
person ships an unsigned bundle.

Now a task-graph guard refuses the build, naming what is missing.
**Demonstrated: exit 1, no artefact produced.** Debug and profile builds are
untouched, so `flutter run` is unaffected.

## Finding 3 — signing material could be committed

`.gitignore` matched only `/android/key.properties`. Root-level
`key.properties`, `*.jks`, `*.keystore` and `mapping.txt` were all unmatched.
Every path is now verified with `git check-ignore`, and nothing sensitive is
tracked today.

## Acceptance gate

| Requirement | Result |
| --- | --- |
| Release bundle verified **obfuscated** | ✅ 68.2%, 5,346 classes renamed |
| Size before/after recorded **per ABI** | ✅ table above |
| Build with no signing config fails clearly | ✅ exit 1, no artefact |
| Ignore rules cover key.properties / keystore / mapping | ✅ verified via `git check-ignore` |
| Certificate fingerprint matched to the **expected upload key** | ⛔ **M4.1** |
| Release-mode crash symbolicated from an uploaded mapping | ⛔ **M4.2** |
| Full functional pass against the **R8 artefact** | ⛔ **M4.13** |

## What this does NOT establish

The verified artefact was signed with a **throwaway key**, generated for this
measurement and deleted immediately: `CN=TAB13 Local Verification Only,
OU=DO NOT SHIP`, fingerprint `DC:AF:01:60:…`. It proves R8 runs, shrinks and
obfuscates. It proves **nothing** about the real upload key.

The functional pass matters most of the remaining three: R8 failures appear
only in the shrunk artefact, and only at the moment a reflective lookup runs.
A green build is not evidence the app works.

## Verified after the fact — two claims that were assertions

**"Debug and profile builds are unaffected"** was written into the commit
message and never measured. It is now: with no `key.properties` and no `CM_*`
environment — the exact condition that refuses a release build —
`flutter build apk --debug` exits **0**, produces an APK, and the guard's
message appears **zero** times. Had the task regex matched a debug task,
`flutter run` would have broken for every developer.

**Local Android builds need a JDK ≤ 24.** Flutter's default here is Android
Studio's bundled Java 25, and Gradle 8.14.3 accepts up to Java 24, so a debug
build fails on this machine out of the box. CI is unaffected — it pins Java 17.
Recorded in `docs/DEPENDENCY_CADENCE.md`; it fails with a clear message rather
than silently.

## Gates after the change

`dart format` exit 0 · `flutter analyze --no-fatal-infos` **No issues found** ·
`flutter test` **1455 passed, 6 skipped**.
