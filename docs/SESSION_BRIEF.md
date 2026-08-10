# Servana Client App — session brief

Last updated 2026-08-10. Read this before touching code.

---

## What this is

The **customer** mobile app — Flutter, BLoC, Hive, dependency locator
(`dpLocator`). This is the one Servana product with **real users in the wild**,
which changes the calculus for every decision below.

It is one of five consumers of a single shared backend. The others are the
customer web portal, ServanaWorker (provider mobile), the provider portal and
the admin portal.

| | |
| --- | --- |
| Repo | `Upupapp/ServanaClient` (moved — the old repo hit a CI billing block) |
| Branch | `main`, HEAD `503bc57`, clean and in sync with origin |
| Version | `1.0.0+38` in `pubspec.yaml` |
| **On Play** | **`1.0.0+37`** — see the warning below |
| +38 artifact | built and verified at `Desktop\servana-38-release\` |
| Backend | `https://api.servana.com.ph/api` |
| Firebase | `servana-59bee` — the ONLY project, for every platform |
| Tests | 1466, CI green |

---

## The rule that matters most here

**The live app is not the repo.** Play serves **+37**; this tree is **+38**.
Anything reasoned from source describes an app nobody is running yet. When
judging whether a backend or web change is safe, the question is always *"what
does the installed build do?"* — and the answer for anything the customer has
not updated is the +37 behaviour, indefinitely. Adoption is never complete.

---

## Standing rules

- **Never push unless explicitly told to.** Commit locally, stage explicit
  paths. A parallel session commits in this tree.
- **Any change must not break the other four platforms.** Verify by reading the
  other repos, never by reasoning about them.
- **This app's wiring is authoritative for parity.** The web portal follows it,
  not the other way round.
- Exactly one Firebase project. Build **both** iOS and Android. Validate at the
  Flutter level only.
- **Do NOT merge `origin/dev`.**

---

## Open, in priority order

**1. PayMongo return-URL collision — blocks the web launch, not this app.**
The checkout WebView (`lib/common/presentation/screens/payment_webview_screen.dart`)
blocks any host outside a hardcoded allowlist:

```
checkout.paymongo.com · api.paymongo.com · paymongo.com · www.paymongo.com
app.servana.com.ph · servana.com.ph · api.servana.com.ph
```

`client.servana.com.ph` is not there and appears nowhere in this repo. The
backend builds every PayMongo redirect from a single `PAYMONGO_RETURN_URL`, so
the web portal cannot get its own return origin without breaking this app's
redirect handling.

**Adding the host here is worth doing for +38 but is NOT the fix** — every
installed +37 keeps the old allowlist. The real fix is a per-request origin in
the backend.

Mitigating detail, verified in source: the redirect is treated as a *signal*,
not proof. `_startPolling` polls every 5s for up to 30 minutes and the success
path calls `_verifyAndClose()`. So a blocked success redirect costs seconds, not
the payment. The cancel path has no poll and falls back to the existing
"Cancel payment?" dialog.

**2. Unresolved: is online payment working at all in production?**
`getReturnUrl` throws 503 when `PAYMONGO_RETURN_URL` and `APP_URL` are both
unset, and two greps against the production env returned nothing — though
without a control, so that is not yet evidence. If it really is unset, checkout
has been failing closed for this app. That would sit uncomfortably close to the
production numbers below and must be ruled in or out before anything else.

**3. Ship +38.** The AAB is built and verified locally.

---

## Recently closed — do not re-litigate

- **Backend login-limiter split, verified live in production.**
  `/auth/customer-firebase-login` and `/auth/refresh` were sharing a
  10-per-15-minutes-**per-IP** budget with password sign-in. Under carrier-grade
  NAT that meant unrelated customers on one public address could exhaust it
  between them, and this app's refresh path falls back to a stale token → 401 →
  sign-out. Now `200;w=900` on the token routes, `10;w=900` on password routes.
  Measured on production, not inferred.
- **This app was never the bug** in that investigation. It persists its session
  (`SessionService.saveSession`) and restores it on launch (`_onCheckSession`),
  spending one login call per real sign-in. The web portal was re-exchanging on
  every page load; it has since been fixed to match this behaviour.
- **Booking status parity** — this app already recognised every status; the web
  portal was missing 16 and needed the change. No mobile change was required.

---

## Traps that have cost real time

- **Play re-signs your app.** Google Sign-In, Maps and Facebook need **both** the
  upload and the Play certificate registered. This class of bug is invisible via
  App Distribution and only appears for real Play installs.
- **There is no dark mode.** `ColorPalette` is light-only and is read ~530 times
  bypassing `ThemeData`. Do **not** restore `buildDarkAppTheme`.
- **`late final AnimationController`** must be built in `initState`; a lazy read
  in `dispose()` throws.
- **`padding: null` on a scroll view silently adopts `MediaQuery.padding`.**
- **Postgres timestamps arrive as JS strings** from the backend.
- **`role` conflates authorization with trade.** 0=dev, 1=admin, 3=customer are
  authorization; 2, 4, 5, 6, 7, 8, 9 are trades. A `role === 2` check misses six.
- **Three response envelope shapes are live simultaneously** —
  `{success, ...}`, a bare payload, and `{status, data}`. Confirmed empirically.
- **Branch on `error.recovery`, not HTTP status.**
- **PowerShell 5.1 mangles SSH commands** — it strips embedded double quotes for
  native exes and `\$` is not an escape. Remote commands must contain no `"`,
  `(`, `)`, `$` or `\`.

---

## Production reality

**109 bookings · 9 customers · 0 completions ever · 48% stuck at PENDING_OTP ·
64 of 70 providers never assigned · 25 bookings PAID for ~103 days.** One
account holds 65 of the 109. Almost all of that traffic came through this app,
so these numbers are the closest thing to a verdict on it that exists — and
"0 completions ever" is the number to explain before building anything new.

Also open on the infrastructure side: **no database backup of any kind**, two
Firebase Admin keys in git history whose IAM deletion is unverified, and 85
provider ID documents readable unauthenticated.
