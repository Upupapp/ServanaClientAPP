# Past deployment errors — ServanaClient / servana_api

Every red build and near-miss from this work, with the root cause and the
check that now catches it. Written because the same three failures kept
recurring in different clothes.

---

## 1. Analyze step, exit 1 — the failure in the screenshots

**Run** `Heatclift/ServanaClient` #30730329935, job 91449417458 — *Test &
Build* failed after 3m 6s, at **Analyze** (25s).

```
52 issues found. (ran in 23.2s)
warning • Unused import: '.../home_campaign_controller.dart'
           • lib/modules/homepage/presentation/screens/home_screen.dart:30:8
           • unused_import
warning • The declaration '_CardChip' isn't referenced
           • lib/modules/landing/presentation/widgets/welcome_traveling_overlay.dart:137:7
           • unused_element
Error: Process completed with exit code 1.
```

**Root cause — mine, both of them.** CI runs `flutter analyze
--no-fatal-infos`. Infos are non-fatal; **warnings are still fatal**. The 50
infos were noise. The two warnings were the failure, and both were left
behind by my own edits:

- removing the Home spotlight deleted the only use of
  `home_campaign_controller`, not its import;
- removing the welcome-screen traveling cards (the "distorted text" bug)
  deleted the only uses of `_CardChip`, not the class.

Deleting `_CardChip` then exposed a second one: `ColorPalette` was imported
*only* for that class, so removing the class alone would have produced a
fresh `unused_import` and a second red build. Both had to go together.

**Why I did not catch it.** I checked the analyzer by grepping its output
instead of reading its exit code, and the pattern I used —
`" (error|warning) - "` — does not match GitHub's rendering, which separates
fields with `•` rather than `-`. The grep returned nothing and I read that as
clean. It was matching nothing at all.

**Now caught by:** running the CI command verbatim and asserting
`analyze exit=0`. No grep. The exit code is the contract; any pattern I write
is a second implementation of it that can disagree.

## 2. `firebase_options.dart` untracked — every run failed to compile

I ran `git rm --cached lib/firebase_options.dart` (commit `49acba9`) on the
belief that it held secrets. **Firebase *client* config is not a secret** —
it ships inside every APK. The file stayed on disk, so my machine kept
building; CI checked out a tree without it and could not compile at all.
Restored in `a22ad55`.

**Now caught by:** a clean clone of the exact commit, built and tested in a
separate directory. A local green says nothing when the difference between
local and CI is a file git does not know about.

**This nearly recurred in this very commit.**
`lib/common/constants/app_spacing.dart` — which every Home section imports —
was untracked at the moment all four gates first passed locally. Pushing then
would have failed CI on the first compile, for the second time, for the same
reason.

## 3. Release Build — 21 minutes to report a missing secret

`bundleRelease` failed at the very end with a keystore error naming neither
the secret nor the workflow.

**Root cause:** the build step sets `CM_KEYSTORE_PATH` unconditionally, so
`android/app/build.gradle:63` *always* takes the Codemagic branch. Its comment
claiming "GitHub Actions: no signing config set — release uses debug anyway"
is not true for this workflow. An unset `CM_KEYSTORE_BASE64` therefore does
not fall back to a debug key — it writes an **empty file**, and Gradle only
discovers that after compiling the entire app.

**Now caught by:** a `Require Android signing secrets` preflight that names
every missing secret in seconds, plus a `keytool -list` check that the decoded
bytes really are a keystore the password opens.

**Still outstanding:** the four `production` environment secrets are not set,
so this job will fail on purpose until they are. That is the preflight
working, not a new bug.

## 4. `deploy.yml` ran migrations after restarting the app

The API restarted against a schema that had not been migrated yet — a window
where live traffic hit code expecting columns that did not exist.
Reordered to install → verify → guard → build → **migrations** → restart.

## 5. The deploy pipeline ran no tests at all

The original finding that started this. A green deploy meant "the process
started", not "the code works".

## 6. Status-casing bug armed by a schema fix

The payment retry job excluded `'CANCELED'` while cancellation writes
`'CANCELLED'`. Adding `payments.updated_at` made the retry job reachable and
therefore made a dormant mismatch live. Fixed with `UPPER(b.status) NOT IN
(...)` covering both spellings.

---

## The gate that now runs before any push

Run in the repo, then **again in a clean clone of the commit**:

| # | Command | Must be |
|---|---|---|
| 1 | `dart format --set-exit-if-changed .` | exit 0 |
| 2 | `flutter analyze --no-fatal-infos` | exit 0 |
| 3 | `flutter test --coverage` | exit 0 |
| 4 | `flutter build apk --debug --target-platform android-arm64 --no-tree-shake-icons` | exit 0 |

Three rules the failures above paid for:

1. **Read exit codes, not output.** Every grep over tool output is a second,
   worse implementation of the check.
2. **Verify from a clean clone.** Local state is not what CI receives.
3. **When deleting code, follow the whole reference chain** — the use site,
   the declaration, and the imports that existed only for it.
