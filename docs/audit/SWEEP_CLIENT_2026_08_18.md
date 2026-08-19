# SWEEP — Servana Customer Mobile App (front end)

Second sweep. The first (`SWEEP_CLIENT.md`, target `bab66e4`) ran before the
convergence-v1 work. This one targets the tree as it stands after TABs 01–14.

| | |
| --- | --- |
| Target | `Upupapp/ServanaClientAPP` @ `a6cb1e6`, branch `main` |
| Local vs remote | **29 commits ahead of `origin/main`, nothing pushed** |
| Working tree | 1 file dirty — `lib/common/config/app_theme.dart` (const-only edit on dead code) |
| Version | `1.0.0+40` in `pubspec.yaml` |
| Backend evidence | `servana_api-main` @ `270ba86` (14 files dirty there) |
| Also read | admin `b4742b3`, customer web `6f1a510`, worker mobile `5e42679`, worker web `2bed987` |
| Scope | 566 Dart files under `lib/`, 60 screens, 138 test files |
| Gates at audit time | `dart analyze` 39 infos / 0 errors · `flutter test` **1901 pass, 6 skipped** · `dart format` **FAILED, 55 files** |
| Gates after remediation | all three **green** — format 0 of 717 changed, analyze exit 0, **1996 pass, 6 skipped** |
| Findings | 9 (P1: 6 · P2: 3) — **all 9 closed** |

**Repo location note.** The repo has moved since the memory index was written:
it is at `Desktop\servana_client-mobile`, not `servana_client-main`, and the
remote is `ServanaClientAPP`, not `ServanaClient`.

---

## Remediation — nine commits, all local

Nothing pushed. The tree is 39 commits ahead of `origin/main`.

| Commit | Finding | What it did |
| --- | --- | --- |
| `0222e58` | SC2-02 | `dart format` across the 55 files, unblocking the Validate job |
| `2aa4496` | SC2-01, SC2-09 | five canonical identity bodies against the contract; `verifyMobile` refuses in the open; a test that asserts the JSON at the HTTP seam |
| `a84c852` | SC2-07, SC2-08 | Rewards and Favourites made scrollable; a screen viewport matrix, 3 handsets × 3 text scales |
| `c070990` | SC2-06 | password recovery wired to the legacy route the backend has had all along |
| `f0c70e8` | SC2-03, SC2-04 | a detector that fails when a repository is registered with no consumer |
| `960b0c2` | SC2-03 | booking detail reads through `BookingRepository`; the model made lossless first |
| `91a466a` | SC2-05 | Home fills the composition cache logout has always cleared |
| `f905cb2` | SC2-04 | change orders surfaced on booking detail; disputes gated honestly |
| `6778af1` | SC2-01 | `verifyMobile` re-shaped to `{idToken}`, the proof v1 actually asks for |

**Every gate added here was mutation-tested** — the fix reverted, the test
watched to fail, then restored and the control re-run. A green new gate proves
nothing until it has been seen failing. Two of those mutations paid for
themselves immediately: the viewport matrix went red at exactly the two
viewport/scale combinations the original measurement named and stayed green at
the third, and the first version of the repository detector reported a healthy
wire as dark.

**All three unconsumed transports now have callers**, and the detector's
allowlist is empty. Two things found along the way that the audit had not:

- **A blind swap of booking detail onto `BookingRepository` would have
  regressed five behaviours**, one of them the ₱0.00 amount bug an earlier
  sweep had already closed. `CustomerBooking` was lossier than the screen's
  own parsing. The model was made lossless and pinned by
  `test/bookings/customer_booking_fidelity_test.dart` before anything was
  rewired.
- **`(x as num?)` throws on a String rather than yielding null**, so the
  amount chain's own `double.tryParse` fallbacks were unreachable and a
  string-valued price crashed the parse. Postgres numeric reaches JSON as int,
  double or string depending on value and driver.

**Two things deliberately not built**, both for the same reason — the
compatibility transport cannot serve them on any shipped build, so a UI would
fail at the moment of use:

- **A dispute screen.** `canOpenDispute` is false everywhere: the only legacy
  dispute route is admin-only. The controller exposes it and the affordance
  appears the moment a transport can serve one.
- **The Firebase phone-auth flow.** `verifyMobile`'s signature is now correct
  (`{idToken}`), so the canonical source is implementable rather than
  permanently blocked by its own arguments. Acquiring the token belongs with
  the screen that will run it.

---

## SC2-01 · Two of the five canonical identity writes could never have succeeded, and the other three worked only because the backend aliases them — **FIXED** in `2aa4496`

**P1** · fix in **client-mobile** · protected release: **no** (nothing shipped calls it)

`IdentityRepository` is routed by `CanonicalRouter` on `V1Capability.identity`.
Every canonical write it can issue was built against an assumed field
vocabulary rather than against `src/api/v1/openapi.ts`.

**The v1 request schemas are not enforced at runtime.** `src/api/v1/register.ts`
has no validator; `requestSchema` names feed OpenAPI generation only
(`openapi.ts:2364`). So the verdict for each call comes from the **handler**,
not the schema — and the handlers deliberately accept the legacy alias for
three of these fields:

| Client body, before | v1 schema | Handler | Verdict |
| --- | --- | --- | --- |
| `{email, otp}` | `VerifyEmailRequest {identifier*, code*}` | reads `body.identifier ?? body.email`, `body.code ?? body.otp` (`domains/auth.ts:216-217`) | **worked** |
| `{email, channel:'email'}` | `ResendVerificationRequest {identifier*, channel in ['otp','link']}` | reads `identifier ?? email`; `channel === 'link' ? 'link' : 'otp'` | **worked, by accident** — `'email'` is not a member and was silently corrected to `'otp'` by the default |
| `{email}` | `ForgotPasswordRequest {identifier*, platform}` | reads `identifier ?? email` (`:271`) | **worked**; `platform` absent, so the link always used the default |
| `{token, password}` | `ResetPasswordRequest {oobCode*, newPassword*}` | reads `body.oobCode` and `body.newPassword`, **no fallback** (`:299-308`) | **BROKEN** — `VALIDATION_FAILED` on every call |
| `{mobileNumber, otp}` | `VerifyMobileRequest {idToken*}` | requires `idToken`, **no fallback** (`:331-336`) | **BROKEN** — and a different proof entirely |

**Correction to this sweep's first draft.** It reported four of five as rejected
and concluded that enabling `identity` would break email verification for real
customers. That was wrong, and wrong in the direction that matters: `verifyEmail`
and `resendEmailVerification` are the two calls with a live screen behind them
(`email_verification_screen.dart:167,202`) and both would have worked. The two
that could not work — `resetPassword` and `verifyMobile` — have **no caller
anywhere in the app**. The defect was latent, not live. Reading the schema and
stopping there is what produced the overstatement; the handler is the authority.

**Fixed.** All five bodies now match the contract, `verifyMobile` refuses in the
open rather than posting a body v1 cannot accept, and
`test/modules/authentication/identity_canonical_contract_test.dart` asserts each
one at the HTTP seam. See SC2-09 for why nothing caught this before.

---

## SC2-02 · The CI Validate job is red on this tree — `dart format` fails on 55 files, all of them new in the unpushed commits — **FIXED** in `0222e58`

**P1** · fix in **client-mobile** · protected release: **no**

`.github/workflows/flutter-ci.yml:52` runs `dart format --set-exit-if-changed .`
as the **first** gate, before analyze and test. Measured on this tree it exits 1
with 55 files changed, so `build-android`, `build-ios` and `release-android`
never start.

- Verified as genuinely unformatted code, not a formatter-version difference:
  e.g. `lib/core/network/api_error_mapper.dart:179` holds a 92-column boolean
  chain the formatter splits across three lines. Local Dart is 3.12.0; CI pins
  no version (`subosito/flutter-action@v2`, `channel: stable`), so CI resolves
  the same or newer.
- Every sampled file is **absent from `origin/main`** — these are files the
  convergence TABs added. This is a regression introduced by the 29 local
  commits, not a pre-existing condition.
- Heaviest contributors: `425b3a4` (12 files), `c454325` (7), `ada07f6` (7),
  `0035500` (4).

**Recommendation.** `dart format .` and commit, before anything is pushed. It is
a one-command fix and it currently blocks every downstream job.

---

## SC2-03 · `BookingRepository` — TAB 09's canonical booking reads — has zero consumers and zero direct tests; the screens still call legacy transport by hand — **FIXED** in `960b0c2`

**P1** · fix in **client-mobile** · protected release: **no**

The repository is constructed at `lib/common/injectors/main_injector.dart:313`
and **never resolved anywhere**. Grepping `BookingRepository` across `lib/` and
`test/` returns only the injector, the class itself, and doc comments in
neighbouring files.

- `booking_detail_screen.dart:170` calls `api.getBooking(bookingId)` on
  `ServanaApiClient` directly; `:363` calls `api.getBookingProvider`.
- The bookings list is mapped in `lib/common/data/backend/http_backend.dart`.
- Tests reference `BookingsCanonicalDataSource` /
  `BookingsCompatibilityDataSource` (`test/bookings/bookings_canonical_test.dart`),
  never the repository that is supposed to choose between them.

**Consequence.** `V1Capability.bookingReads` is inert. Turning it on moves no
booking traffic, because the object that reads the flag has no callers. The
capability gate is not the only thing holding the app on legacy here — the
presentation layer was never wired to the new seam.

**Recommendation.** Either point `booking_detail_screen` and the list mapper at
`BookingRepository`, or stop registering it — a registered singleton nobody
resolves reads as "migrated" to the next person who greps the injector.

---

## SC2-04 · `BookingExperiencesRepository` — TAB 12's change orders and disputes — has no UI at all — **FIXED** in `f905cb2` (change orders; disputes gated, see below)

**P1** · fix in **client-mobile** · protected release: **no**

Registered at `main_injector.dart:330`, tested in
`test/booking_experiences/booking_experiences_test.dart` (5 constructions), and
referenced by **zero** files under any `presentation/` or `application/`
directory. `additionalWork`, `disputes` and `openDispute` are all unreachable.

Grepping the whole presentation layer for dispute UI returns one string, and it
is a support-ticket category label:
`create_support_ticket_screen.dart:528` — `'Request a refund or dispute a charge'`.

So a customer who wants to dispute a charge today is routed into the generic
support-ticket form, while a typed dispute transport sits behind it with no
screen. Two capabilities (`bookingAdditionalWork`, `bookingDisputes`) are
declared complete against a surface that cannot be entered.

**Recommendation.** Record it as transport-ahead-of-UI in the manifest rather
than leaving the capability enum implying a shipped domain, and decide whether
the dispute screen is in scope before TAB 15.

---

## SC2-05 · `HomeCompositionRepository` never renders Home — its only caller outside its own directory is the logout cache-clear — **FIXED** in `91a466a`

**P1** · fix in **client-mobile** · protected release: **no**

Registered at `main_injector.dart:464`. The single reference from outside
`lib/modules/homepage/data/` is
`lib/modules/authentication/presentation/bloc/authentication_bloc.dart:569-570`,
a `CleanupStep('homeComposition', …)` that calls `.clear()` on sign-out.

`home_screen.dart:66` renders from `dpLocator<HomeStore>()` — the legacy store —
with `bwStore` and `airconStore` alongside it. So the app clears a cache it
never fills, and `V1Capability.home` moves nothing.

**Recommendation.** Same choice as SC2-03: wire Home to it, or unregister it.
The cleanup step is the tell — it is the shape of a wiring that was started at
one end only.

---

## SC2-06 · Password reset does not exist in the customer app, and the code's stated reason for that is factually wrong — **FIXED** in `c070990`

**P1** · fix in **client-mobile** · protected release: **yes** (needs a shipped build)

`authentication_screen.dart:266` renders a "Forgot password?" affordance. Tapping
it calls `_showForgotPasswordInfo()` (`:99`), a snackbar reading *"Password reset
is coming soon. Contact support if needed."* There is no reset flow anywhere in
the app.

The compatibility data source explains the absence
(`identity_compatibility_data_source.dart:71-79`):

> *"The customer app initiates password reset through Firebase, not the legacy API."*

**That is not true.** `sendPasswordResetEmail`, `confirmPasswordReset` and
`verifyPasswordResetCode` return **zero hits** across `lib/` and `test/`. No
Firebase reset is initiated anywhere. The comment describes a mechanism the app
does not have, which is worse than no comment — it closes the question for the
next reader.

Meanwhile the backend has had the route all along:
`src/routes/auth.route.ts:128` — `POST /api/auth/forgot-password`, rate-limited
(`:71`), on the **legacy** surface, deployed today. So this is closable on the
compatibility path without waiting for v1.

**Impact.** A customer who forgets their password has no self-service recovery
in an app with real users. Their only route is support.

**Recommendation.** Implement `forgotPassword` on the compatibility source
against the legacy route, add the reset screen, and delete the false comment. Fix
the canonical body (SC2-01) at the same time so the two paths agree.

---

## SC2-07 · `RewardsScreen` clips 411 px at 320×568 under the text scale the app itself declares supported — **FIXED** in `a84c852`

**P2** · fix in **client-mobile** · protected release: **yes**

Measured, not inferred. Rendered at three viewports × three text scales:

| Viewport | 1.0 | 1.3 | 2.0 |
| --- | --- | --- | --- |
| 320×568 | clean | clean | **overflow 411 px** |
| 360×640 | clean | clean | **overflow 171 px** |
| 390×844 | clean | clean | clean |

`lib/core/accessibility/accessibility_tokens.dart:16` sets
`maxRequiredTextScale = 2.0`, so 2.0 is inside the range this app promises to
support.

Cause: `drawer_placeholder_screens.dart:51-93` — `body: Center( → Padding →
Column(mainAxisSize: .min) )` with no scroll view. The body copy is a long
sentence; at 2.0 it wraps past the viewport and the Column has nowhere to go.
**In a release build this is not an exception, it is silent clipping** — the
explanation text simply disappears for large-text users.

`FavouritesScreen` (`:99`) uses the identical pattern and was probed at the same
nine combinations: **clean**, because its copy is shorter. The pattern is the
hazard; only Rewards has enough text to trip it today.

**Recommendation.** Wrap the body in a `SingleChildScrollView`. Two lines, and it
also protects Favourites from the next copy change.

---

## SC2-08 · 60 screens, and not one of them is rendered at a viewport in any test — **MATRIX ADDED** in `a84c852`

**P2** · fix in **client-mobile** · protected release: **no**

The two files whose names suggest this coverage do not provide it:

- `test/presentation/responsive_test.dart` (205 lines) tests
  `ServanaBreakpoints`, `otpCellWidth`, `chatBubbleMaxWidth`,
  `horizontalPadding` and `minTouchTarget` — pure helper arithmetic. It builds
  no screen.
- `test/core/accessibility/accessibility_tokens_test.dart` asserts token
  constants and `MediaQuery` flag plumbing. It builds no screen.

The only rendered-overflow test in the repo is
`test/homepage/search_result_card_overflow_test.dart`, for one card widget.

This is the gap SC2-07 fell through, and it is measurable: a nine-combination
probe over three screens found the Rewards defect in about a minute. The
provider app runs an eleven-viewport matrix and it found eight overflows across
four screens the same way — this app, which is the one with customers on it, has
none.

**Recommendation.** Port the provider app's matrix. Two traps from that work
apply verbatim: pass a screen **bare** to the renderer (wrapping it in a
`SingleChildScrollView` yields "infinite size during layout", which reads as a
product bug and is the harness's fault), and set `tester.view.physicalSize` —
Flutter's default 800×600 test surface is not a phone.

---

## SC2-09 · The identity tests fake the interface, so no test can see a wrong wire body — **FIXED** in `2aa4496`

**P2** · fix in **client-mobile** · protected release: **no**

`test/modules/authentication/identity_repository_test.dart:55-59` implements
`resetPassword({required String token, required String newPassword})` as a
fake that records the call and returns. The fake satisfies the **client's own**
interface, so it agrees with the client's field names by construction. It cannot
disagree with the backend, because the backend is not in the test.

That is the mechanism behind SC2-01: five wrong request bodies, 1901 passing
tests, and no contradiction anywhere. `test/modules/authentication/` contains no
test that asserts the JSON `IdentityCanonicalDataSource` actually posts.

**Recommendation.** Assert the body at the HTTP seam — capture what
`V1ApiClient.post` is handed and compare the key set against
`src/api/v1/openapi.ts`. A fixture derived from the contract file is the version
that cannot drift; a hand-copied key list is the same failure one layer up.

---

## Prior sweep — what has closed since `bab66e4`

Re-measured against `270ba86`, not inherited.

| ID | Then | Now |
| --- | --- | --- |
| SC-021 | `_needsPayment` unsatisfiable: `paymentMethod` could never be `'PAYMONGO'` | **CLOSED.** `bookingService.ts:33` types it `"CASH" / "GCASH" / "PAYMONGO"`, `bookingCreateValidation.ts:44` accepts it, and the client sends exactly `{'CASH','PAYMONGO'}` (`booking_create_request.dart:49`). The guard is live. |
| SC-023 | `'PAYMONGO'` written only to `payments.provider` | **CLOSED** by the same change. |
| SC-024 | booking detail rendered ₱0.00 from an unaliased `totalAmount` | **CLOSED** — `http_backend.dart:541-564` derives the amount from the priced value. |
| SC-026 | list invented `'Beauty & Wellness'` for every add-on-less booking | **CLOSED** — `http_backend.dart:505` records the literal's removal. |
| SC-027 | customer booking payload had no `serviceName` | **CLOSED** — `getBookingById` now joins `so.level_2 AS service_name` and `s.name AS service_category`. |
| SC-025 | tracking destination resolved to (0, 0), Null Island | **CLOSED ON THE CLIENT.** `booking_detail_screen.dart:426-435` `_nullIfZero` restores the Manila fallback. **Still open on the backend**: `getBookingById` selects no coordinate columns, so the fallback is taken on every booking. |

---

## What was checked and found clean

- **Route reachability.** All 29 screen route constants and all 64 `GoRoute`
  registrations resolve; every route reached by `routeName` or path literal. No
  orphaned or shadowed route. Routes are derived from screen constants rather
  than hand-copied string literals, which is the arrangement that prevented the
  provider app's `NAV-07` class of defect.
- **`dart analyze`** — 0 errors, 0 warnings, 39 infos (`prefer_const_*`,
  `curly_braces_in_flow_control_structures`). CI runs `--no-fatal-infos`, so
  these do not gate.
- **`flutter test`** — 1901 pass, 6 skipped, exit 0.
- **Dark mode.** `main.dart:271` deliberately maps `darkTheme` to the light
  theme, and Settings → Appearance offers only System and Light with Dark shown
  as unavailable. UI and behaviour agree. `buildDarkAppTheme` is dead code, and
  the one dirty file in the tree is a const-only edit inside it.
- **Capability gating.** `CanonicalAvailability` is deny-by-default, build-time
  only, not remote-configurable, and requires master switch AND named
  capability. All 15 capabilities are off in every shipped build.
