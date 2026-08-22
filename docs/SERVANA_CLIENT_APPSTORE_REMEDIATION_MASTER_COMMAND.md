# SERVANA CLIENT APP — FRONT-END APP STORE REMEDIATION MASTER COMMAND

| | |
| --- | --- |
| **Repository** | `ServanaClientAPP` — customer app, `com.servana.client` / applicationId `com.servana.serviceclient` |
| **Issued** | 2026-08-22 |
| **Baseline commit** | `26b34eb` — `main`, `origin/main` and `origin/dev` aligned |
| **Scope** | **FRONT-END ONLY.** This programme does not modify `servana_api`. |
| **Trigger** | App Store review rejection covering Guidelines 2.1(a), 5.1.1(v) and 2.3.6 |
| **Phases** | A root cause (01–03) · B guideline 2.1(a) (04–06) · C guideline 5.1.1(v) (07–10) · D metadata and resubmission (11–12) |

---

## 0. WHY THIS DOCUMENT EXISTS

A submission was declined for three separate reasons. Two are code (`2.1(a)`,
`5.1.1(v)`); one is metadata (`2.3.6`) and cannot be fixed from this repository
at all. They are not equally understood, and this document is deliberate about
which is which:

- **5.1.1(v) — account deletion.** Fully understood, and smaller than it looks.
  The backend endpoint already exists and is mounted. The app has a *visible
  dead end* where the feature should be. This is wiring, not invention.
- **2.3.6 — age rating.** Understood and entirely manual. One field in App Store
  Connect. No code change can satisfy it, and none should be attempted.
- **2.1(a) — Sign in with Apple did not log us in.** **NOT yet root-caused.**
  The Dart flow reads correctly and the iOS entitlement is present. Four
  candidate causes survive, three of which are outside this repository. The
  first phase of this programme is built to *discriminate between them*, not to
  start editing the handler.

The single most important instruction in this document: **do not "fix" the Apple
handler before TAB 01 says which of the four causes is real.** The code most
likely to be edited on instinct is the code least likely to be at fault.

---

## 1. MEASURED GROUND TRUTH

Everything in this section was measured on 2026-08-22 at `26b34eb`. It is not
recollection, and it is not from the rejection letter.

### 1.1 Sign in with Apple — what is already correct

| Fact | Location | Status |
| --- | --- | --- |
| Apple handler `_onAppleSignIn` | `authentication_bloc.dart:243–327` | Present |
| Nonce: SHA-256 to Apple, **raw** to Firebase | `authentication_bloc.dart:254`, `:270` | **Correct** |
| First-authorisation-only name/email handled | `authentication_bloc.dart:276–290` | **Correct** |
| Private relay address treated as a real email | `authentication_bloc.dart:302` | **Correct** |
| User cancellation distinguished from failure | `authentication_bloc.dart:306–310` | **Correct** |
| `com.apple.developer.applesignin` = `Default` | `ios/Runner/Runner.entitlements` | **Present** |
| Entitlements wired to all 3 build configs | `project.pbxproj:535, 728, 758` | **Present** |
| `sign_in_with_apple: ^6.1.3` | `pubspec.yaml:129` | Present |

The nonce is the detail that is wrong in most broken Apple integrations, and it
is right here. **Treat the handler as innocent until TAB 01 convicts it.**

### 1.2 Sign in with Apple — the four surviving candidate causes

| # | Candidate | Where it lives | Fixable in this repo? |
| --- | --- | --- | --- |
| C1 | `Sign In with Apple` capability not enabled on App ID `com.servana.client` | Apple Developer portal | **No — manual** |
| C2 | Apple provider not enabled in Firebase for `servana-59bee` | Firebase Console | **No — manual** |
| C3 | Backend rejects the token exchange | `servana_api` | **No — front-end reads only** |
| C4 | iPad-specific presentation/behaviour failure | This repo | **Yes** |

C3 deserves emphasis because it produces *exactly* the symptom the reviewer
described. The exchange posts to **`POST /api/auth/customer-firebase-login`** — a
**legacy** route, not `/api/v1` — via `ServanaApiClient.firebaseLogin`
(`servana_api_client.dart:344–358`). When the response carries an empty or
absent `token`, `AuthTokenExchanger.exchange` returns an error string and the
bloc emits `AuthenticationUnauthenticated` (`authentication_bloc.dart:417–423`).

To a reviewer that is indistinguishable from "the app did not log us in": the
Apple dialog succeeds, Face ID succeeds, and then nothing happens. **A correct
Apple integration and a rejecting backend look identical from the outside.**
This is why TAB 01 exists.

### 1.3 Why 2758 passing tests did not catch it

`FirebaseAuth.instance` is constructed **inline** at
`authentication_bloc.dart:195`, **`:273` (the Apple path)** and `:366`.
Contrast the same file's Google and Facebook dependencies, which *are*
injectable (`_googleSignIn`, `_facebookAuth`, `:84–88`).

The consequence is recorded in the repo already — three tests are skipped at
`test/bloc/authentication_bloc_test.dart:292, :326, :611`:

> *"Full happy path requires injectable FirebaseAuth + ServanaApiClient — use integration_test"*

So the suite reports **2758 passed / 3 skipped**, and the three skips are
precisely the sign-in happy paths. **The gate was never able to see this bug.**
Any fix that does not also close this hole will be equally invisible next time,
which is why TAB 03 comes before TAB 04.

### 1.4 iPad

`TARGETED_DEVICE_FAMILY = "1"` at `project.pbxproj:511, 651, 704` — **iPhone
only**. The app therefore runs on iPad in scaled compatibility mode. That is
permitted, and Apple's letter states the expectation plainly:

> *"apps that may be downloaded onto iPad devices should function as expected for iPad users."*

The review device was an **iPad Air 11-inch (M3), iPadOS 26.6**. No iPad
viewport is present in the screen matrix: `screen_viewport_matrix_test.dart`
covers 320×568, 360×640 and 390×844 — all handsets.

### 1.5 Account deletion — a dead end, not an absence

`lib/modules/settings/presentation/screens/privacy_legal_screen.dart:122–128`
renders a **`SettingsUnavailableTile`**:

> title: `Delete Account` · reason: *"Account deletion will be available in a future update"*

This is worse than having nothing: the reviewer found the exact control they
were looking for and it told them it does not work. A sibling tile, **`Export My
Data`** (*"Data export requires a backend update"*), sits directly above it.

**The backend is not the blocker.** Traced through route registration rather than
by filename (the standing rule for `servana_api`):

| Endpoint | Auth | Source |
| --- | --- | --- |
| `POST /api/account/deletion-request` | public, rate-limited | `routes/accountDeletion.routes.ts:29` |
| `POST /api/account/deletion-request/me` | `verifyAuth` | `routes/accountDeletion.routes.ts:30` |
| `GET /account-deletion` | public HTML page | `app.ts:397` |

Mounted at `/api` in `app.ts:396`. **`/me` is the endpoint this app needs.**
Semantics per `services/accountDeletionService.ts`: the request is recorded
`pending`, then identity columns are anonymised while the financial trail is
retained. Duplicate requests collapse via a unique partial index — pressing the
button twice is safe.

The client currently references **none** of these routes.

### 1.6 Messaging surfaces that force the 2.3.6 answer

The app ships a booking conversation with **photo attachments** (`fe11ca3`,
`booking_chat_screen.dart`, `messaging_store.dart`). Customer-to-provider,
free-text, user-generated images. `Messaging and Chat` = **Yes** is not a
judgement call; it is a description of what shipped.

---

## 2. BOUNDARIES AND WORKING RULES

1. **Front-end only.** Never modify `servana_api` during this programme. Reading
   it to establish contract truth is expected and encouraged.
2. **Auto-advance.** On evidence-backed completion of a TAB, continue to the
   next without waiting to be asked. A distinct 100%-completion report precedes
   any next-TAB reporting.
3. **Push cadence — after every completed TAB**, using the five-step procedure
   in §5. Not once at the end.
4. **Manual-only items** go to `docs/MASTER_TODO_MANUAL_TASKS.md` and nowhere
   else. Items here are pre-numbered `A-1 … A-7` (§4).
5. **No speculative code.** Do not build for a cause that has not been measured.
   This applies hardest to TAB 04.
6. **Evidence over reasoning.** Where a TAB says *capture*, produce the artefact
   — a log, a screenshot, a recording, a captured response body. "It should
   work" closes nothing.
7. **Never `--no-verify`.** If a gate fails for a reason about the machine
   rather than the code, repair the gate.

---

## 3. THE TAB SEQUENCE

### PHASE A — ROOT CAUSE AND TESTABILITY (TAB 01–03)

---

#### TAB 01 — Discriminate the four Apple sign-in causes

**Goal.** Convert "did not log us in" into one named cause from §1.2. Change no
behaviour.

**Do.**
1. Instrument the Apple path end to end so each stage reports distinctly:
   credential returned · identity token non-null · Firebase `signInWithCredential`
   result · Firebase ID token obtained · **backend exchange status and body**.
2. Run on a real iPad and a real iPhone, signed in with a *fresh* Apple ID that
   has never authorised this app (first-authorisation is a different code path —
   §1.1).
3. Capture the exchange independently: `POST /api/auth/customer-firebase-login`
   with a valid Firebase ID token, recording HTTP status and full body.
4. Verify C1 and C2 by inspection (portal + Firebase Console) and record the
   answers as evidence, not assumptions.

**Certify when.** One cause is named, with a captured artefact proving it, and
the other three are positively excluded. If the cause is C1, C2 or C3, **say so
and stop editing Dart** — raise the manual item and proceed to TAB 02.

**Trap.** An expired or reused Apple ID will mask the first-authorisation path.
Deleting the app does **not** reset Apple's "already authorised" state; revoke
it in *Settings → Apple ID → Sign in with Apple*.

---

#### TAB 02 — iPad ground truth

**Goal.** Know what the reviewer actually saw.

**Do.**
1. Run on **iPad Air 11-inch (M3), iPadOS 26.6** — matching the review device.
2. Walk sign-in, browse, booking and chat. Capture screenshots at each step.
3. Record whether the Apple sheet presents, and how the scaled-compatibility
   window behaves in portrait and both landscape orientations.
4. Decide and record, with reasons: does the app stay iPhone-only
   (`TARGETED_DEVICE_FAMILY = "1"`) or adopt iPad? **Do not change it in this
   TAB** — adopting iPad is a large surface with its own review risk.

**Certify when.** iPad behaviour is documented with images, and the
device-family decision is written down with its rationale.

---

#### TAB 03 — Make sign-in testable (the structural fix)

**Goal.** Close the hole in §1.3 so the gate can see sign-in at all.

**Do.**
1. Make `FirebaseAuth` injectable in `AuthenticationBloc`, exactly as
   `_googleSignIn` and `_facebookAuth` already are — constructor parameter
   defaulting to `FirebaseAuth.instance`, so every existing call site is
   unaffected.
2. Do the same for the `ServanaApiClient` used by `_loginWithFirebaseToken`.
3. **Un-skip** the three tests at `authentication_bloc_test.dart:292, :326, :611`
   and make them pass against fakes.
4. Add a test asserting the Apple nonce contract directly: Apple receives the
   SHA-256 hash, Firebase receives the raw string. This is the detail most
   likely to regress silently.

**Certify when.** `flutter test` reports **2761 passed / 0 skipped** (or the
skips that remain are unrelated to sign-in and each carries a written reason).

**Why before TAB 04.** A fix landed before this TAB cannot be proven, and cannot
be defended against the next refactor.

---

### PHASE B — GUIDELINE 2.1(a) (TAB 04–06)

---

#### TAB 04 — Fix the named cause

**Goal.** Repair whatever TAB 01 convicted. **Only that.**

**Do.**
- **If C4 (iPad):** fix presentation/anchor and any iPad-specific layout that
  blocks completion.
- **If C1/C2:** the repo fix is nil. Raise `A-1`/`A-2`, and add a *diagnosable
  failure* so this class of misconfiguration never again presents as silence —
  a distinct, logged, user-visible message.
- **If C3 (backend):** raise `A-3`. Front-end deliverable is honest failure
  reporting: surface the backend's message rather than the generic
  *"Apple sign-in failed. Please try again."*, which currently hides the reason.

**Certify when.** Sign in with Apple completes to an authenticated session on a
physical iPad **and** a physical iPhone, captured on video. If the cause was not
in this repo, the TAB certifies as `CERTIFIED_PENDING_<manual item>` with the
diagnostics landed and the recording still owed.

**Trap.** Do not "improve" the nonce, the name handling or the cancellation
branch while here. §1.1 measured all three correct; changing them adds risk with
no return.

---

#### TAB 05 — iPad correctness for the reviewed journeys

**Goal.** Satisfy *"function as expected for iPad users"* for the flows a
reviewer actually walks.

**Do.**
1. Extend `screen_viewport_matrix_test.dart` with iPad viewports — at minimum
   **820×1180** (iPad Air 11-inch, points) in portrait and landscape.
2. Fix overflow and layout failures the matrix surfaces on the sign-in, booking
   and chat paths **first**; record the rest.
3. Honour the TAB 02 device-family decision.

**Certify when.** The matrix covers iPad, sign-in/booking/chat are clean at
those sizes, and any remaining defects are listed with severity.

---

#### TAB 06 — Regression proof for 2.1(a)

**Goal.** Make this specific rejection impossible to repeat unnoticed.

**Do.**
1. A test that fails if the Apple handler stops reaching the exchange.
2. A test that fails if an empty-token backend response is reported to the user
   as a generic retry message rather than a real reason.
3. A test asserting the entitlement file still declares
   `com.apple.developer.applesignin` — the file is easy to lose in an Xcode
   merge, and losing it fails silently at runtime.

**Certify when.** Each new test is proven to fail when its defect is reintroduced.
An untested test is not evidence.

---

### PHASE C — GUIDELINE 5.1.1(v) ACCOUNT DELETION (TAB 07–10)

---

#### TAB 07 — Wire the deletion endpoint

**Goal.** Give the client a typed call to the endpoint that already exists.

**Do.**
1. Add `requestAccountDeletion()` to `ServanaApiClient` → `POST /api/account/deletion-request/me`,
   authenticated, following the file's existing conventions.
2. Register the route in the endpoint constants alongside its neighbours.
3. Map failures through the existing `error_message_mapper` rather than
   inventing new strings.
4. Handle the duplicate-request case as **success**, not error — §1.5: the
   backend collapses duplicates by design.

**Certify when.** Unit tests cover success, duplicate, unauthenticated, network
failure and 5xx.

---

#### TAB 08 — The deletion flow, replacing the dead end

**Goal.** Remove the tile that says "not available" and put a working flow there.

**Do.**
1. Replace the `SettingsUnavailableTile` at `privacy_legal_screen.dart:122–128`
   with a live entry point.
2. Build the flow: what deletion means in plain language (referencing §1.5 —
   identity anonymised, financial records retained for legal reasons), an
   explicit confirmation step, and a clearly destructive final action.
3. Confirmation must be **deliberate but self-service**. Apple permits
   confirmation steps; it forbids requiring a phone call or an email to support.
   **No route out of this flow may lead to `privacy@servana.com.ph`.**
4. Reachable while signed in, in a place a reviewer will find: Settings →
   Privacy & Legal → Your Data.
5. Accessible at text scale 2.0 and at every supported viewport, iPad included.

**Certify when.** A reviewer can go from signed-in home to confirmed deletion
without leaving the app, and the flow renders correctly across the matrix.

**Trap.** Do not silently repurpose the `Export My Data` tile. It is a separate
obligation with no verified endpoint — leave it, and record it as a watch item.

---

#### TAB 09 — Life after deletion

**Goal.** Leave the device in a defensible state.

**Do.**
1. On confirmed deletion run the customer-scoped teardown — the same
   `SessionCleanupService` path as logout — then return to the unauthenticated
   root.
2. Verify no cached customer state survives: drafts, inbox, search history,
   addresses, tokens in secure storage.
3. Ensure the deleted account cannot be resumed by an app relaunch holding a
   stale session.
4. Confirm the FCM token is released so a deleted account stops receiving push.

**Certify when.** A test proves the post-deletion state is indistinguishable
from a fresh install for that customer's data.

**Trap.** The existing logout cleanup reports partial failure loudly in test logs
(`logout cleanup incomplete: CleanupReport(3 clean, failed: …)`). Confirm
whether that is a test-environment artefact or a real teardown gap **before**
depending on it for deletion.

---

#### TAB 10 — The evidence App Review asked for

**Goal.** Produce exactly what the letter requested.

**Do.**
1. Record on a **physical device**, in one take: creating a new account or
   signing in with the demo account → navigating to deletion → the complete flow
   through to confirmation.
2. Verify the demo account credentials work on a clean install.
3. Draft the App Review Information note, and file the recording location.

**Certify when.** The recording exists, has been watched end to end, and shows
all three required moments. Attaching it in App Store Connect is `A-6`.

---

### PHASE D — METADATA AND RESUBMISSION (TAB 11–12)

---

#### TAB 11 — Age rating (2.3.6)

**Goal.** Make the metadata true.

**Do.**
1. Record in `docs/` the messaging surfaces that force the answer (§1.6) so the
   rating is defensible and re-derivable at the next review.
2. Raise `A-5`: set `Messaging and Chat` = **Yes** in App Store Connect → App
   Information → Age Rating.
3. Re-check the remaining age-rating answers against what actually ships —
   user-generated photo content in chat is easy to overlook a second time.

**Certify when.** The in-repo record exists and `A-5` is raised. **This TAB
cannot certify as complete from the repository** — it closes when the owner
changes the field.

---

#### TAB 12 — Resubmission gate

**Goal.** One deliberate check that all three findings are answered.

**Do.**
1. Verify each rejection point against evidence:
   `2.1(a)` → TAB 04/05 recordings · `5.1.1(v)` → TAB 10 recording ·
   `2.3.6` → `A-5` confirmed done.
2. Full gate run: pin, `--enforce-lockfile`, format, analyze, test.
3. Build the release artefacts; confirm version and build number increment.
4. Write the closing verdict — `CERTIFIED` or `NOT_CERTIFIED` with reasons —
   and list every manual item still open.

**Certify when.** All three points are answered with artefacts, or the verdict
names precisely what is missing and who owns it. **Do not resubmit with an open
`A-5`:** it is one field, and it will cost another full review cycle.

---

## 4. MANUAL-ONLY ITEMS

Cannot be done from this repository. Copy into
`docs/MASTER_TODO_MANUAL_TASKS.md`.

| # | Item | Where | Blocks |
| --- | --- | --- | --- |
| **A-1** | Enable **Sign In with Apple** on App ID `com.servana.client` | Apple Developer portal | TAB 04 if C1 |
| **A-2** | Enable the **Apple provider** for `servana-59bee` | Firebase Console | TAB 04 if C2 |
| **A-3** | Confirm `POST /api/auth/customer-firebase-login` accepts Apple-issued Firebase tokens in production | `servana_api` owner | TAB 04 if C3 |
| **A-4** | Provide a working **demo account** for App Review | App Store Connect | TAB 10 |
| **A-5** | Age Rating → **Messaging and Chat = Yes** | App Store Connect | TAB 11, TAB 12 |
| **A-6** | Attach the deletion **screen recording** to App Review Information | App Store Connect | TAB 12 |
| **A-7** | Decide iPad support: stay iPhone-only, or adopt iPad | Owner | TAB 02, TAB 05 |

**Watch item (not raised, not scoped):** `Export My Data`
(`privacy_legal_screen.dart:119`) is the same dead-end pattern as the deletion
tile was. Apple did not cite it. It is a live obligation in other jurisdictions
and should not be discovered the same way this one was.

---

## 5. THE PUSH PROCEDURE — AFTER EVERY COMPLETED TAB

Binding on every Servana repository. All five steps, in order, every time.

1. **Sweep `origin/main` fully.** Fetch all refs *and* tags. Compare at commit
   **and tree** level — `merge-base --is-ancestor` plus a `git ls-tree` file
   diff. A commit count is not a sweep.
2. **Identify what exists upstream that local lacks, and test it.**
3. **Merge it locally.**
4. **Test again on the merged result.** This is the load-bearing step: step 2
   tests their work, step 4 tests the combination, and only the combination
   ships.
5. **Push straight to `main`.** No branch, no pull request. Then align `dev`.

If the sweep finds the remote strictly behind, **say so and fast-forward** — do
not stage a merge with an empty other side.

**CI must never fire.** The GitHub Actions credit will not be topped up, ever.
This repo carries **zero files under `.github/`** as of `cab362b`, which makes it
structurally CI-free rather than dependent on a marker. Keep `[skip ci]` in the
tip commit subject regardless, and never add a workflow back.

**The local gate is the only gate.** As of `26b34eb` it runs, in order:
toolchain pin → `flutter pub get --enforce-lockfile` → `dart format` →
`flutter analyze` → `flutter test`. Install per clone:

```
git config core.hooksPath scripts/hooks
```

---

## 6. ACCEPTANCE — HOW THIS PROGRAMME ENDS

The programme is complete when:

- Sign in with Apple reaches an authenticated session on a physical **iPad** and
  a physical **iPhone**, on video, with the cause of the original failure named
  and recorded.
- Account deletion is initiated and confirmed entirely in-app, recorded on a
  physical device, with no path that requires contacting support.
- `Messaging and Chat` = Yes is live in App Store Connect.
- The three sign-in tests are un-skipped and passing, so the gate can see this
  class of defect in future.
- The closing verdict is written, with every open manual item named and owned.

**Anything not proven by an artefact is not done.** The submission that produced
this document passed every local gate the repository had.
