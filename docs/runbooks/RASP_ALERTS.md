# Runbook — freeRASP threat alerts

## Where alerts go

`security@servana.com.ph`, set by `RASP_WATCHER_MAIL` at build time and
defaulting to that alias in `free_rasp_service.dart`.

**It must be a distribution list with at least two people on it.** It previously
went to one individual's personal Gmail, which is a single point of failure for
the one signal you cannot afford to miss.

Override per build:
`--dart-define=RASP_WATCHER_MAIL=security-staging@servana.com.ph`

## What can fire

freeRASP 8.0.0 exposes 21 callbacks and all 21 are wired. The ones that mean
something is actively wrong:

| threat | reading | action |
| --- | --- | --- |
| `appIntegrity` | the APK/IPA was modified after signing | **treat as a repackaged build in the wild.** Check Play/App Store for clones; consider a forced minimum version (TAB 15) |
| `obfuscationIssues` | shipped without R8 | a build-pipeline regression — TAB 13 turned R8 on; this firing means it came back off |
| `hooks` | Frida/Xposed attached | instrumentation against a real session |
| `privilegedAccess` | root / jailbreak | common and often benign |
| `deviceBinding` | credentials moved between devices | possible session theft |
| `malware` | suspicious packages present | **the package list is deliberately not forwarded** — it describes other apps on the customer's device and is not ours to collect |

## Responding

1. **Correlate before reacting.** A single `privilegedAccess` on one device is a
   developer or an enthusiast. A spike in `appIntegrity` across many devices is
   a repackaged build being distributed.
2. **Never lock a customer out on a single signal.** Rooted-but-benign devices
   are common in this market. No threat response may leave a legitimate customer
   with no recourse.
3. **`appIntegrity` at volume is the escalation.** The response is a minimum
   version publish (`docs/runbooks/VERSION_GATE.md`), not a silent behaviour
   change.

## Owner

Whoever holds `security@servana.com.ph`. An alert with no named owner is
telemetry, not security — assign one before launch.
