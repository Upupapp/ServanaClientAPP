# SERVANA CUSTOMER APP — FRONT-END MASTER COMMAND (WINDOWS)

| | |
| --- | --- |
| **For** | the Flutter developer on the **Windows** machine |
| **Repository** | `ServanaClientAPP` — the customer mobile app |
| **Issued** | 2026-08-23 |
| **Baseline** | `43a885b` · gates green: format 0, analyze 0, **2788 tests pass / 3 skipped** |
| **Scope** | **Front-end Dart/Flutter only.** All Mac/iOS work is **excluded** — it is the Mac agent's and cannot be done from Windows. |
| **Work items** | **51 open**, all doable on Windows |

---

## 0. THE SPLIT — read before you touch anything

This is a two-machine project.

| | You (Windows) | The Mac agent |
| --- | --- | --- |
| **Owns** | Flutter/Dart code, tests, **Android + Google Play** | **iOS + App Store + TestFlight** |
| **Tooling** | `scripts/release-android.sh`, `docs/PLAY_CONSOLE_STATE.md` | Xcode, signing keychain, `flutter build ipa` |

**The collision point is `pubspec.yaml`.** `version: x.y.z+build` is **shared by
both stores**. Currently `1.0.0+44`. Two people bumping it independently produces
a build number already burned on one store and rejected by the other.
**Coordinate the bump — do not assume you own it.**

**Excluded from this document** and not yours:

- Anything under `ios/`, entitlements, `Info.plist`, `ExportOptions.plist`.
- App Store Connect, TestFlight, App Review responses.
- `SC-168` (freeRASP has never started on iOS — `iosConfig` is commented out at
  `free_rasp_service.dart:23-26`). **Left for the Mac agent**, listed here only
  so you know why it is missing.

Cross-platform Dart is yours even when it was found via an iOS symptom.

---

## 1. HOW TO USE THIS LIST — the part that matters most

**The register's status columns are not reliable. Verify before you build.**

That is not a caution, it is a measurement. While assembling this document I
re-checked a sample of the items and found:

| id | recorded as | actually |
| --- | --- | --- |
| `SC-045` / `SC-046` / `SC-128` | "logout never calls `POST /api/auth/logout`" | **STALE — fixed.** `authentication_bloc.dart:508` calls `repo.logout()`, which hits `V1Endpoints.authLogout()`. |
| `SC-026` / `SC-060` | "bookings list hardcodes Beauty & Wellness" | **STALE — fixed.** The only remaining occurrences are in `mock_backend.dart`, a test fixture. |
| `SC-121` | "OTP screen says the code was sent by SMS" | **STALE** — no SMS wording remains on that screen. |
| `SC-047` | "cannot be built from a clean checkout" | **STALE** — a release build ran green on 2026-08-23. |
| `SC-115` / `SC-138` | "FCM deactivation always 401s on logout" | **LIVE.** The code *acknowledges* it: a comment at `authentication_bloc.dart:499` explains it suppresses the resulting session-expired UI. |
| `SC-137` / `SC-116` | six unguarded settings routes | **WAS LIVE — fixed today**, and it was **seven**, not six. See §2. |

So: roughly **a third of what I sampled was already fixed**, one was worse than
recorded, and one was live but disguised by a comment that made it look handled.

**Before starting any item: re-read the cited file.** If it is already fixed,
move it to the closed section of
`docs/MASTERLIST_PENDING_ITEMS_SERVANA_CLIENT_APP.md` and say so in the commit —
that is real work and it stops the next person repeating it.

The register itself carries the same warning: 18 P0 claims were adversarially
verified; **the rest are agent-reported and were never independently checked.**

---

## 2. WHAT WAS JUST FIXED (do not redo)

Closed on 2026-08-23, in `43a885b` and `95b7e52`:

- **`SC-137` + `SC-116` — seven settings routes were reachable with no session.**
  `SettingsScreen.route` is `'/Settings'`; every sub-screen is lower case
  (`/settings/privacy`, `/settings/security`, `/settings/profile-edit`,
  `/settings/delete-account`, …). `String.startsWith` is case-sensitive, so the
  guard protected none of them. Fixed at the class: the location is lower-cased
  once and matched against lower-case prefixes, so the next `/settings/...`
  screen is protected by default.
- **`SC-186` — an account switch left the previous customer's drafts on the
  device.** `customerScopedCleanupSteps('')` made the two account-keyed cleanup
  steps silent no-ops.
- **`SC-187` — Delete Account was a dead-end tile.** Now a real flow.
- **`SC-188` — five administrative endpoints removed** from the customer binary.

---

## 3. START HERE — the highest-value front-end work

### 3.1 · Session lifetime is broken · `SC-051`

**The Firebase ID token is stored as the Servana session token and never
refreshed, so sessions die roughly hourly.** Every customer is silently signed
out about once an hour. Nothing else on this list affects more people more often.

`SC-150` is its test: splash and the auth bloc disagree on what counts as a valid
session, and nothing pins either.

### 3.2 · Logout leaves the device registered for push · `SC-115` / `SC-138`

`DELETE /api/user/fcm-token` is called **after** `SessionService.deleteSession()`,
so it 401s every time and the device keeps receiving that customer's push
notifications. The code knows — there is a comment explaining that the resulting
"session expired" UI is suppressed. Suppressing the symptom is not the fix.

Move the FCM deactivation **before** the session is deleted, or capture the
credential first the way the logout uid is already captured.

### 3.3 · The 401 path does not clear private data · `SC-073`

The session-expiry path deletes the session but resets no private-data store.
Compare it with the deliberate logout teardown (32 cleanup steps) and with the
account-switch path fixed in `SC-186`. **Three paths end a session; only two
clean up.**

### 3.4 · Live tracking never shows the provider · `SC-030` / `SC-090` / `SC-113`

The provider location response nests the GPS document under `location`; the
client accepts it only at the root or under `data`. Three response shapes exist
and the app parses none of them. The tracking map is dead as a result.

Backend cleanup is `SC-113`'s half — **but the client parsing is yours and the
map stays blank until it is done.**

### 3.5 · Dead typed layers — code written and never wired

- **`SC-054`** — `BookingErrorMapper` / `BookingSubmissionResult` had zero
  production callers. **Re-check first**: the 2026-08-20 sweep did work here and
  this may now be stale.
- **`SC-123`** — the operation journal and the persisted booking idempotency key
  are **written but never read**, so crash recovery does not recover anything.
- **`SC-093`** — two complete booking read stacks exist inside the app; the
  canonical model, mapper and repository are unreferenced by the screens.

Each is either a wiring job or a deletion. **Do not leave a third state.** If you
delete, follow the pattern in `test/common/customer_app_api_surface_test.dart` —
unwired code is either wired, deleted, or pinned with a written reason.

---

## 4. CORRECTNESS THE CUSTOMER SEES

| id | finding |
| --- | --- |
| `SC-037` / `SC-129` / `SC-092` | `WORKER_ASSIGNED` maps to `enRoute`, so the customer is told "your professional is on the way" when nobody has set off. The app also re-parses a human display label as if it were a canonical status code. |
| `SC-033` | `AssignmentPollResult.isAssigned` can never be true for a real assignment — both confirmation screens run the full 60 s poll and then report failure. **Re-check: possibly fixed 2026-08-20.** |
| `SC-108` | The booking reference differs between the app's own two screens: list shows `BK-<id>`, detail shows `SVN-000…`. |
| `SC-118` | PayMongo verification falls back from `paymentStatus` to booking status, so a null payment status marks a booking paid. |
| `SC-122` | The cancellation sheet collapses every backend error into one message, discarding actionable state. |
| `SC-146` | `CustomerBooking.fromApiMap` silently substitutes `DateTime.now()` for a missing schedule — and no test pins it. |
| `SC-157` | `formatBooking` applied to tracking rows fabricates `bookingCode: "SVN-undefined"`. |
| `SC-161` | The client resolves customer identity with the canonical `customerUid` **last** in precedence. |
| `SC-164` | Canonical statuses `new` and `disputed` are unmapped and untested. |

---

## 5. TESTS — the gate has holes in exactly the wrong places

Measured line coverage is **17.10%**, and **149 of 470 `lib/` files have no test
at all** (`SC-145`). CI collects coverage and enforces no threshold.

| id | gap |
| --- | --- |
| `SC-102` / `SC-153` | **Logout is entirely untested.** All six skipped tests defer to an `integration_test/` directory **that does not exist**. |
| `SC-103` | No test asserts the `Authorization` header is sent, and `onUnauthorized` — which wipes the session globally — is uncovered. |
| `SC-106` | The auth-guard test **re-implements the router's guard instead of executing it**, so it asserts its own copy is correct. |
| `SC-148` | `http_backend.dart` is 0% covered and holds a second, divergent status mapper. |
| `SC-149` | No payment-state tests at all: PayMongo WebView, pending-payment recovery, payment chips. |
| `SC-150` | No session-expiry or token-validity test. |

**`SC-106` is the one to read first.** A test that re-implements the thing it
guards will pass while the real code is broken — and this repository has already
been bitten twice by tests that could not fail. Before writing any new gate here,
read the four testing rules in `CLAUDE.md`; they were each paid for.

---

## 6. ANDROID — yours, and one item blocks a Play release

**`SC-174` — Google Sign-In cannot work in any build.** The Firebase Android app
`com.servana.serviceclient` has **no SHA-1 certificate fingerprint registered**.
Google Sign-In fails silently on every Android build regardless of the Dart code.

This is a **Firebase Console** action plus a release-signing question, and it is
squarely on your side of the split. Nothing in the app can work around it.

`docs/PLAY_CONSOLE_STATE.md` is your territory — the Mac agent has been told to
read it and not drive it.

---

## 7. THE REST — 51 items indexed

Full text and citations in
`docs/MASTERLIST_PENDING_ITEMS_SERVANA_CLIENT_APP.md`.

| Pass | Count | ids |
| --- | ---: | --- |
| **STITCH** | 17 | SC-033, 037, 045, 046, 047, 048, 051, 052, 054, 114, 115, 117, 118, 120, 121, 122, 123 |
| **TEST** | 9 | SC-102, 103, 106, 145, 146, 148, 149, 150, 164 |
| **REPEAT** | 8 | SC-082, 085, 090, 092, 093, 142, 143, 163 |
| **SWEEP** | 7 | SC-026, 030, 060, 108, 112, 113, 157, 159 |
| **ALIGN** | 4 | SC-128, 129, 135, 161 |
| **LEAK** | 4 | SC-073, 135, 137, 162 |
| **RELEASE** | 2 | SC-169, 174 |

Severity: **23 P1 · 22 P2 · 6 P3.**

`SC-169` (JobOrder submission is a stub) and several others are **blocked on the
backend** — the endpoint does not exist. Those are in the backend command; do not
build a client for a route that is not there.

---

## 8. HOUSE RULES

**Pushing — five steps, every time.** Sweep `origin/main` at commit **and tree**
level → test what is upstream → merge → **re-test the merged result** → push
straight to `main`, then align `dev`. If the remote is strictly behind, say so
and fast-forward; never stage a merge with an empty other side.

**CI must never run.** `.github/` is empty on purpose. Do not add a workflow.
Keep `[skip ci]` in the tip commit subject.

**The pre-push hook is the only gate** — five checks: toolchain pin →
`--enforce-lockfile` → format → analyze → test. Install it per clone:
`git config core.hooksPath scripts/hooks`. Never `--no-verify`.

**The toolchain is pinned** in `.flutter-version` (3.47.0). Upgrading is
deliberate: bump the file, `flutter pub get`, commit the lock.

**Findings go in the register**, not a new list. Highest id in use: **SC-194**.

### The four testing rules, each learned the hard way here

1. **A test that checks a thing *happens* is not a test that checks it happens
   *correctly*.** Two defects fixed this week were already covered by passing
   tests — one asserted a teardown was *called* (it was; the argument was wrong).
2. **Watch every new gate fail before believing it.** Write the mutation.
3. **Then confirm the mutation actually landed.** One reported a pass because
   `dart format` had reflowed the code the patch matched on.
4. **Strip comments before scanning source, and assert a floor.** Two guards here
   have been fooled by a quoted path inside a comment; another passed because its
   pattern matched nothing at all.

---

## 9. ACCEPTANCE

- Sessions survive longer than an hour (`SC-051`).
- Logout leaves the device unregistered for push (`SC-115`/`SC-138`).
- All three session-ending paths clear private data (`SC-073`).
- Live tracking shows the provider (`SC-030`/`SC-090`).
- Every stale item you find is **moved to closed with evidence**, not silently
  skipped.
- No new dead code: wired, deleted, or pinned with a reason.
