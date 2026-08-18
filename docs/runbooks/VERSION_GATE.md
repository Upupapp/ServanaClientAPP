# Runbook — the minimum-version gate

Who can retire a shipped build, how, and what happens when they do.

---

## What this controls, and what it must never control

It gates on **version and nothing else**. No feature may be enabled or disabled
through this channel. The gate may block the app; it may never silently change
its behaviour. Remote toggling of the canonical capability flags is explicitly
out of scope and stays out — a flag a server can flip is a flag an attacker can
flip.

## Why it exists

94 legacy routes are classified `ALIAS_TEMPORARILY` and production already
emits `Deprecation: true` on them. When those aliases retire, every installed
build that has not migrated breaks. Before this gate there was no way to tell
those builds to upgrade and no way to count them.

It is also the honest answer to build-time capability flags: because canonical
traffic cannot be turned off remotely by design, the only way to retire a bad
wave fleet-wide is to require an upgrade.

## Remote Config parameters

Firebase project **`servana-59bee`** — the only project, every platform.

| parameter | type | meaning |
| --- | --- | --- |
| `version_gate_schema_version` | number | `1`. Bump only with a client change; an older build **ignores** a higher schema entirely. |
| `version_gate_minimum_supported_build` | number | Builds **strictly below** this are blocked. `0` disables the gate. |
| `version_gate_recommended_build` | number | Builds below this get a dismissible prompt. |
| `version_gate_message` | string | Shown on the blocking screen. Say *why*. |
| `version_gate_android_store_url` | string | Play listing. |
| `version_gate_ios_store_url` | string | App Store listing. |

**An unconfigured project behaves exactly as if the gate were absent**, because
the in-app default for the minimum is `0` and nothing is below it.

## Publishing a minimum version

1. Confirm the build number you intend to require is **live on both stores** and
   has had time to propagate. Blocking on a build customers cannot yet install
   is a total outage.
2. Set `version_gate_minimum_supported_build` and publish.
3. Watch `build_number` in analytics for the fleet distribution.

**Who may publish:** whoever owns the Firebase console for `servana-59bee`.
This is the single most dangerous parameter in the project — it can brick every
installed app. Treat a change to it like a deploy.

## Rollback

Set the minimum back to its previous value (or `0`) and publish. Propagation is
bounded by Remote Config's fetch interval plus the app reaching a launch or a
resume — **the gate re-evaluates on both**, so a customer sitting in the app
does not need to relaunch.

⚠️ **A cached minimum is still enforced offline.** Lowering the minimum does not
release a device that never fetches again. This is deliberate (see below), but
it means rollback is not instant for a device that is offline.

## The failure policy, precisely

- **Never fetched, nothing cached → allow.** A gate that blocks the app because
  the network is unavailable is worse than the problem it solves.
- **Previously fetched → the cached minimum is enforced, offline included.** A
  published minimum was a real decision, and going offline must not be a way to
  escape it.
- **Unreadable build number → allow.** `PackageInfo` failing must not lock out
  the entire fleet at once.
- **Any throw during evaluation → allow.**
- **A higher `schema_version` than the app understands → ignored entirely**,
  never half-applied. An old build enforcing a rule it has misunderstood is a
  blocking screen the customer cannot argue with.

## Soft prompt

Dismissible, capped at one showing per **3 days** (`softPromptCooldown`). A nag
on every resume teaches customers to dismiss without reading, which costs the
hard block its credibility too. The cap applies **only** to the prompt — a hard
block is never suppressed.

## Android in-app update

The hard block tries Play's **immediate** in-app update first, which keeps the
customer inside the app, and falls back to the store link. `in_app_update` is
Play Core and Android-only; on iOS the store link is the only path, which is
why the application-level gate exists rather than just calling `InAppUpdate` at
startup.

`lib/common/domain/helpers/update_repo.dart` had **zero callers** before this.
It now has exactly one.

## Still manual

- Publishing the parameters in the Firebase console (**M4.7**).
- The staging rehearsal: publish a minimum above the installed build, confirm
  the block appears, restore, confirm it clears, and **record the propagation
  delay**. TAB 05 needs that number — if reverting a bad wave takes more than an
  hour, TAB 15 becomes its prerequisite rather than a parallel workstream.
- Confirming hard block and soft prompt on a **real Android and a real iOS
  device**.
