# Google Play Console — what is already DONE

**Read this before asking anyone to open Play Console, Google Cloud, Firebase or
Meta.** Everything under "Settled" was completed and verified on the dates given.
Do not ask for it again. Only the "Still open" list at the bottom is outstanding.

App: `com.servana.serviceclient` · Play developer `5143238911617930399` ·
app id `4973002056186399953` · Firebase/GCP project `servana-59bee`

---

## Settled — Data safety form (completed 2026-08-21)

All five steps green. Declared exactly as follows, and this matches what the
built AAB actually carries:

| Section | Declared |
|---|---|
| Data **shared** | Device or other IDs |
| Personal info | Name, Email address, User IDs, Address, Phone number |
| Financial info | Purchase history |
| Location | Approximate **and** Precise — App functionality |
| Messages | Other in-app messages — App functionality |
| Photos and videos | Photos — **Optional** — App functionality |
| App info and performance | Crash logs (App functionality, Analytics); Diagnostics (App functionality) |
| App activity | App interactions (Analytics); Other user-generated content — Optional |
| Device or other IDs | **Analytics, Advertising or marketing** |
| Security | Encrypted in transit: **Yes** |
| Account creation methods | **Username and password** + **OAuth** — both ticked, and both are true: `POST /api/auth/signup` takes email + password, and Google / Facebook / Apple are all live sign-in buttons |
| Data deletion | Delete app account → `https://api.servana.com.ph/account-deletion` |
| Privacy policy | `https://servana.com.ph/privacy-policy` |

**Device or other IDs is declared, including "Advertising or marketing."** That is
the one people miss: the merged manifest carries `ACCESS_ADSERVICES_AD_ID` via
`firebase_analytics`, and an undeclared advertising ID is a policy violation on
its own even with no ads in the app. It is declared. Leave it declared.

Photos and "Other user-generated content" are marked **Optional**, which is
correct — the app shows a consent sheet on first launch offering *Accept &
Continue* or *Essential Only*.

## Settled — App content questionnaires (completed 2026-08-21)

| Section | State |
|---|---|
| **Data safety** | Complete — full declaration in the table above |
| **Target audience and content** | Complete — **18 and over**, with *"Restrict users that Google has determined to be minors"* ticked. That is a deliberate reach restriction, appropriate for a marketplace taking payments and sending workers to homes. Do not untick it without a reason. |
| **Content rating** | Complete |

Confirmed by the user 2026-08-21. Do not ask for these again.

## Settled — Play review account WORKS (2026-08-21)

```
email  play.review.customer@servana.com.ph
pass   Servana2026x
uid    slrGwnQ8wwPhQozlPjURfg09bcE2
role 3 (customer) · account_status active · is_email_verified t · is_archive f
```

**Do not ask anyone to create or repair this account again.** Signup through the
app succeeds, but sign-in is gated on email verification — and a Google reviewer
cannot open a mailbox at servana.com.ph, which is exactly how ServanaWorker was
rejected ("login credentials are incorrect" when the real cause was an account
gate). Cleared with a one-row UPDATE on production; the assertion printed
*"Play review account is ready."*

Two schema facts, both measured, both counter to the obvious assumption:
- **`user_credentials.role` is VARCHAR** — `role = 3` throws
  `operator does not exist: character varying = integer`. Use `role = '3'`.
- **`account_status` is lowercase**, only two values exist in production:
  `pending` (121) and `active` (3).

Access route: `ssh root@192.46.224.126` then
`su postgres -c "psql -d servana -P pager=off -f /tmp/x.sql"`. Always pass
`-P pager=off` — without it psql opens `less`, and anything typed then goes into
the pager rather than the shell. `scp` from the dev machine is sandbox-blocked;
write the SQL with a quoted heredoc (`<<'SQL'`) at the server prompt.

## Settled — Internal testing

`41 (1.0.0)` uploaded and **Available to internal testers**, released
2026-08-21 01:31. Track active.

## Settled — signing certificates

Play App Signing is enrolled and the key is in the **Quantum-ready (beta)**
programme, so the console shows FOUR fingerprints. Only the **Classical** pair
works with Firebase, Maps and Facebook; the post-quantum pair authenticates
nothing. Never register it.

| | SHA-1 |
|---|---|
| **Play app signing** (what devices see) | `EA:3D:E8:C6:C9:E3:98:FF:C6:30:EC:C4:22:27:A7:F8:C0:C8:EF:E0` |
| Upload key (what local builds use) | `38:40:B7:9D:CC:E9:E0:89:C9:08:AC:E3:F3:48:9B:B9:46:7F:25:FF` |
| Local debug keystore | `92:6E:B8:BE:48:C2:61:CB:F4:F0:63:A8:1A:5E:58:1B:FE:4A:91:33` |

Play app signing SHA-256:
`79:D9:1D:63:A5:2C:70:58:C7:D2:97:F6:9D:DD:9B:D7:C3:FC:9E:EA:BD:6D:82:BA:4B:57:C9:42:98:29:1D:B1`

All three SHA-1s are already registered in `android/app/google-services.json`.
Fingerprints are also pinned in `RELEASE_MANIFEST.json` — read that before asking
anyone for one.

## Settled — every certificate-keyed integration (2026-08-20)

Play App Signing re-signs the bundle, so anything that authenticates by signing
certificate needs BOTH the upload cert and the Play cert. All four are done:

| Integration | Where the Play cert goes | State |
|---|---|---|
| Firebase phone auth | `google-services.json` SHA-1 | registered |
| Google Sign-In | same | registered |
| Google Maps | Maps key Android restriction | added + saved |
| Facebook Login | FB app Android key hashes | added + saved |

Facebook key hashes (`base64(sha1_bytes)`, **not** the hex SHA-1) — both present
on app `2048115409245680`:
`6j3oxsnjmP/GMOzEIien+MDI7+A=` (Play) and `OEC3nczp4InJCKzj80ibuUZ/Jf8=` (upload).

Sign in with Apple is **not** certificate-keyed on Android and needs nothing.

## Settled — Google Cloud Maps keys (project `servana-59bee`)

- **Servana Client Android — Maps SDK** — restricted to *Android apps*, 1 API
  (Maps SDK for Android). Its restriction list holds BOTH
  `com.servana.serviceclient` + upload SHA-1 and + Play SHA-1.
- **Servana Client iOS — Maps SDK** — restricted to *iOS apps*, 1 API.

One key cannot restrict to both platforms, which is why there are two. The client
makes **zero** direct HTTP calls to any Google API (`geocoding` uses Android's
native `Geocoder`, `geolocator` uses platform location), so "1 API" is correctly
scoped. **Do not widen it.**

Keys are injected at build time by `tool/inject_maps_key.dart`; `strings.xml` and
`Info.plist` keep the literal placeholder `REPLACE_WITH_GOOGLE_MAPS_API_KEY` in
git. Restore both files after any release build.

---

## Still open

1. **Store listing** — icon 512×512 and feature graphic 1024×500 need design.
   Copy drafts and 5 phone screenshots (1080×2160, cropped to Play's 2:1 limit)
   are ready at `Desktop\servana-play-screenshots`.
3. **Sign in details** (this is what Play calls **App access** on this console —
   there is no row named "App access"). Last edited **Jul 27 2026**, three weeks
   before the review account existed, so it cannot be describing working
   credentials. Set it to "All or some functionality is restricted" and paste the
   reviewer instructions. This is the category that got ServanaWorker rejected.
4. **Meta required actions** — the Facebook app showed "Required actions 2" and
   "Alert Inbox 1". Meta can disable Login on apps with lapsed required actions,
   and Facebook Login is a live button in this app.
