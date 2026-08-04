# 16 KB page-size alignment — measured

Google Play requires every native library's `PT_LOAD` segments to be aligned
to 16384 bytes for apps targeting Android 15+. This records what Servana
Client actually ships, so the freerasp decision is made on evidence.

## How this was measured

Not from the on-device dialog. That dialog was raised by an **x86_64 debug**
build, and it is misleading in both directions — it flagged `libflutter.so`
and `libdatastore_shared_counter.so`, neither of which is a problem on the
ABI that ships.

Instead: extract `lib/arm64-v8a/*` from the APK and read `p_align` on every
`PT_LOAD` program header directly out of the ELF.

## Result — arm64-v8a, the ABI Play serves

| Library | LOAD `p_align` | Verdict | Comes from |
|---|---|---|---|
| `libflutter.so` | `0x10000` | **OK** | Flutter engine |
| `libdatastore_shared_counter.so` | `0x4000` | **OK** | androidx datastore |
| `libVkLayer_khronos_validation.so` | `0x10000` | OK | debug-only, not in release |
| `libpolarssl.so` | `0x1000` | **NOT 16 KB** | freerasp |
| `libclib.so` | `0x1000` | **NOT 16 KB** | freerasp |
| `libsecurity.so` | `0x1000` | **NOT 16 KB** | freerasp |
| `libtmlib.so` | `0x1000` | **NOT 16 KB** | freerasp |
| `libpbkdf2_native.so` | `0x1000` | **NOT 16 KB** | freerasp |
| `librive_text.so` | `0x1000` | **NOT 16 KB** | rive |

**6 of 9 fail. Five of the six are one package.**

`0x1000` is 4096 — the old 4 KB page assumption.

## What this means for the decision

| Package | Now | Needed | Nature of the bump |
|---|---|---|---|
| `freerasp` | 6.12.0 | **8.0.0** | two majors, on the anti-tampering/RASP SDK |
| `rive` | 0.13.20 | 0.14.10 | transitive; `0.x` minor, which is breaking under pub semver |

Fixing freerasp removes five of the six. Fixing rive removes the last.

Neither is done in this release. `freerasp` is the SDK that decides whether
the app refuses to run on a rooted or hooked device — a two-major jump to it
changes security behaviour, and its API for threat callbacks changed between
6 and 8. That is a deliberate, separately-tested change, not something to
fold into a UI release.

Nothing here blocks the current build: the app still runs on 16 KB devices in
*page-size compatibility mode*. What it blocks is a Play submission once the
16 KB requirement is enforced for the target SDK.

## Reproducing

```bash
unzip -q -o build/app/outputs/flutter-apk/app-debug.apk 'lib/arm64-v8a/*' -d /tmp/elf
# then read p_align of each PT_LOAD; anything below 16384 fails
```
