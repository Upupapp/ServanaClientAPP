# Tester builds — Firebase App Distribution

How a signed build reaches testers, and the two things you must set up once.

---

## What the pipeline does

After the release AAB is built **and its signature verified**, the release job
also builds a signed release **APK** and uploads it to Firebase App
Distribution.

Order matters: distribution happens after `Verify signing`, so testers can
only ever receive a build that passed the same certificate check as the
Play bundle. A build that fails signing never reaches anyone.

### Why an APK and not the AAB

App Distribution accepts an AAB only for apps already linked to Play, and a
tester's phone cannot install an AAB directly regardless. A signed release
APK works today with no Play dependency.

The APK is **universal** — it carries every ABI — so it installs on real
devices and emulators alike. It is therefore noticeably larger than what a
user would download from Play, which serves a per-device split. That size
difference is a distribution artifact, not a regression.

### One fidelity gap, stated plainly

The Play bundle is built with `--obfuscate --split-debug-info`. The tester
APK is **not**.

That is a deliberate trade: an obfuscated QA build produces crash reports
that are unreadable without matching symbol files, which defeats the point of
handing builds to testers. The cost is that a bug caused *by* obfuscation —
anything relying on `runtimeType`, class-name strings or reflection — will not
reproduce for testers and will first appear in production.

If that risk matters more than readable traces for a particular release, add
`--obfuscate --split-debug-info=build/tester-debug-info` to the APK build step
and upload that directory alongside the existing symbols.

---

## Setup — do this once

### 1. Create a tester group

Firebase Console → **App Distribution** → **Testers & Groups** → **Add group**.

**A group already exists**: display name **External**, alias **`external`**,
currently holding `carmela@lguids.com.ph` and `jave@lguids.com.ph`. That alias
is the workflow's default.

The distinction matters: Firebase shows the display name in bold and the
alias beside it in monospace, and they are not the same string. The CLI takes
the **alias**; passing "External" fails with "group not found".

Groups are **project-level**, shared by every app in the Firebase project —
only releases are per-app. `external` has been serving `com.servana.worker`
builds, so once customer builds go to the same group its testers receive both
apps. Worth splitting into a dedicated group before the tester list grows;
`Add group` on that page, then read the new alias the same way.

To use a different alias, pass it in the `tester_groups` input when running
the workflow manually, or change the default in
`.github/workflows/flutter-ci.yml`.

### 2. Create a service account and add it as a secret

The Firebase CLI token flow (`firebase login:ci`) is deprecated — use a
service account.

1. Google Cloud Console → **IAM & Admin → Service Accounts** → **Create**
   - Name: `github-app-distribution`
2. Grant it the **Firebase App Distribution Admin** role.
   (`roles/firebaseappdistro.admin` — not Editor. It only needs to publish
   releases, and a broader role on a CI credential is a liability.)
3. Open the account → **Keys → Add key → Create new key → JSON** → download.
4. GitHub → **Settings → Secrets and variables → Actions → New repository
   secret**
   - Name: `FIREBASE_SERVICE_ACCOUNT`
   - Value: the **entire** JSON file contents, braces included
5. Delete the downloaded file. It is a live credential.

The workflow validates the secret parses as JSON before using it, so a partial
paste fails immediately with a clear message rather than at upload time.

---

## Cutting a tester build

**Automatic** — every push to `main` that passes the test job.

**On demand** — GitHub → **Actions → Flutter CI → Run workflow**. Two optional
inputs:

| Input | Default | Purpose |
|---|---|---|
| `tester_groups` | `external` | comma-separated group **aliases** |
| `release_notes` | *(commit subject)* | what testers should look at |

Release notes always carry the version and commit SHA appended, so a tester
report can be traced to an exact build.

---

## If the secret is not set

Distribution is skipped and the job logs a `::warning::` plus a job-summary
note. It does **not** fail the release.

That is deliberate: a missing tester credential must not cost you a signed,
verified, Play-ready bundle. But it is not silent either — "no tester build
appeared and nobody knows why" is the failure mode that choice avoids.

---

## Note on the gating condition

The three distribution steps are gated on `env.FIREBASE_SERVICE_ACCOUNT`,
which is declared at **job** level rather than on the steps themselves.

This is not stylistic. The `secrets` context is not available in a step's
`if:` at all, and a step's own `env:` block is not available to that same
step's `if:`. Gating on either would evaluate `'' != ''`, and the steps would
skip on every run, forever, with no error. Job-level `env` is visible to step
conditionals; that is the documented workaround.
