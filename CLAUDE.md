# ServanaClientAPP — agent brief

The **customer** mobile app (Flutter). `com.servana.client`, applicationId
`com.servana.serviceclient`. One of five clients on one backend.

Read this before changing anything. It is short on purpose; everything else is a
pointer.

---

## Which machine does what — read this before any release work

**This is a two-machine project, split by platform. The split is not a
preference; iOS release work is physically impossible off a Mac.**

| Platform | Owner | Tooling |
| --- | --- | --- |
| **iOS / App Store / TestFlight** | the **Mac** agent | Xcode, signing keychain, `flutter build ipa`, `ios/ExportOptions.plist` |
| **Android / Google Play** | the **Windows** agent | `scripts/release-android.sh`, `docs/PLAY_CONSOLE_STATE.md` |

**The collision point is `pubspec.yaml`.** `version: x.y.z+build` is **shared by
both stores**. Two agents bumping it independently is how you get a build number
already used on one store and rejected on the other. **Coordinate the bump; do
not assume you own it.**

If you are on the Mac: do not run `release-android.sh`, do not produce a release
AAB/APK, and do not drive Play Console items — read `PLAY_CONSOLE_STATE.md`,
don't edit it. If you are on Windows: the reverse, and note that nothing in
`ios/` can be verified from there at all.

Cross-platform code, and backend work that **blocks** a store submission, belong
to whoever is blocked. The Sign in with Apple refusal, for instance, lives in
`servana_api` and blocks iOS — so it is the Mac agent's to chase even though it
is not Flutter code.

Findings for the other platform are **recorded** (`SC-###`), not fixed.

## Where the findings live

**Do not start a new list.** Three registers exist and each has a job:

| File | What belongs there |
| --- | --- |
| `docs/MASTERLIST_PENDING_ITEMS_SERVANA_CLIENT_APP.md` | **Every finding**, open and closed, with an `SC-###` id. Highest id in use: **SC-194**. |
| `docs/MASTER_TODO_MANUAL_TASKS.md` | Only items that **cannot** be closed by writing code here — portal settings, console fields, owner decisions. `M-##` and `A-#`. |
| `docs/mvp/SWEEP_*.md` | The narrative report of each sweep — what was found, in the order a customer meets it. |

Counts in the masterlist have drifted twice. **Count the rows** — `grep -c '^| SC-'`
per section — rather than trusting a header or the at-a-glance table.

## Current programmes

- `docs/SERVANA_CLIENT_APPSTORE_REMEDIATION_MASTER_COMMAND.md` — 12 TABs
  answering the 2026-08-22 App Store rejection (2.1(a) Sign in with Apple,
  5.1.1(v) account deletion, 2.3.6 age rating). **TAB 03 comes before TAB 04
  deliberately**: sign-in cannot be tested until `FirebaseAuth` is injectable.
- Backend work this app depends on:
  `servana_api/docs/SERVANA_CUSTOMER_SWEEP_BACKEND_MASTER_COMMAND.md` and
  `.../SERVANA_CLIENT_APP_BACKEND_MASTER_COMMAND.md`.

## The open items most likely to bite you

- **Sign in with Apple is broken and the cause is almost certainly in the
  backend**, not here. `findLinkCollision` refuses any first-sight Firebase uid
  whose email already exists, and Apple always produces a first-sight uid. The
  Dart handler and the iOS entitlement were both measured correct. **Do not
  "fix" the Apple handler.**
- **Account deletion ships from this app now** but the backend records the
  request `pending` and no fulfilment code was found (SC-191).
- **`Export My Data` is deliberately still a dead tile** (SC-192 — no customer
  endpoint exists). Making it look live would repeat exactly the mistake App
  Review rejected. Leave it until the backend lands.

---

## Hard rules

**Pushing — all five steps, every time, in order.** Applies to every Servana repo.

1. Sweep `origin/main` fully — all refs and tags, compared at commit **and tree**
   level (`merge-base --is-ancestor` plus a `git ls-tree` file diff). A commit
   count is not a sweep.
2. Identify what exists upstream that local lacks, and **test it**.
3. Merge it locally.
4. **Test again on the merged result.** Step 2 tests their work; step 4 tests the
   combination, and only the combination ships.
5. Push straight to `main`. No branch, no PR. Then align `dev`.

If the remote is strictly behind, **say so and fast-forward** — never stage a
merge with an empty other side; it records work that did not happen.

**CI must never run.** The GitHub Actions credit will not be topped up, ever.
This repo carries **zero files under `.github/`** and that is deliberate — do not
add a workflow back. Keep `[skip ci]` in the tip commit subject anyway.

**The pre-push hook is the only gate.** It runs five checks in this order:
toolchain pin → `flutter pub get --enforce-lockfile` → `dart format` →
`flutter analyze` → `flutter test`. Install it per clone — git will not:

```
git config core.hooksPath scripts/hooks
```

Never `--no-verify`. If a check fails for a reason about the **machine** rather
than the code, repair the check.

**The toolchain is pinned.** `.flutter-version` holds it (3.47.0). Upgrading is
allowed and meant to be deliberate: bump the file, `flutter pub get`, commit the
lock it produces. The lock rotted once because nothing pinned the toolchain.

**Surface parity.** Customer web and customer mobile are one product; provider
web and provider mobile are another. Before closing anything, ask whether the
mirror surface has the same defect — two backend fixes have already been applied
to the provider side and not the customer side.

---

## Testing rules learned the hard way

**A test that checks a thing *happens* is not a test that checks it happens
*correctly*.** Both defects found in the 2026-08-23 sweep were already covered by
a passing test: one asserted a teardown was *called* (it was — the argument was
wrong), the other never asserted the widget type of the tile it guarded.

**Watch every new gate fail before believing it.** Write the mutation that
reproduces the defect and confirm the gate goes red.

**Then confirm the mutation actually landed.** One mutation reported a pass
because `dart format` had reflowed the code the patch matched on, so the edit
silently applied nothing. Assert the file changed.

**Assert a floor on any scan.** A guard here once passed because its pattern
matched nothing at all, and kept passing when the defect was restored. If a scan
finds zero offenders, prove it can still see the file.

**Strip comments before scanning source for behaviour.** A guard failed on the
very doc comment written to explain the rule it enforces — which invites the
worst possible fix, deleting the explanation to go green.
