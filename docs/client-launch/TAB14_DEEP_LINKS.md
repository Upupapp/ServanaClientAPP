# TAB 14 — Deep links: App Links and Universal Links

**Status:** client scope COMPLETE · **CERTIFIED_PENDING_HOSTING**
**Date:** 2026-08-18 · **Commit:** `e2a4bb1` · **Blocks:** TAB 07 completion, TAB 20

---

## Verified before building

| claim | measured |
| --- | --- |
| No `android:autoVerify` | ✅ zero occurrences in the manifest |
| Only browsable filter is Facebook login | ✅ confirmed |
| No `associated-domains` in entitlements | ✅ confirmed — push and Sign in with Apple only |
| Internal routing already exists | ✅ **60 GoRoutes**, derived from screen constants |

The app knew how to route. It could not be reached.

## The resolver is pure, because it handles untrusted input

`DeepLinkResolver` has no Flutter, no router, no I/O. Three properties, each
pinned by test:

- **No destination mutates.** Every claimed path is a read. A URL that mutates
  is a URL that mutates when a mail client prefetches it.
- **No credential is forwarded.** `/reset-password?token=…` resolves to the
  reset *screen* and **drops the token** — a one-time code in a path or query
  reaches the nginx access log on every request, and survives in history and
  referrer headers.
- **No segment can retarget the request.** `/bookings/1%2F..%2Fadmin` and
  `/bookings/1%3Ffoo%3Dbar` are refused, not decoded into a route. Ids are
  validated as digits *and* encoded — a filter and an encoder fail differently.

An unknown path resolves to **null, never Home**. "Open in the browser" and
"open the app on the wrong screen" are different answers.

## Signed-out arrival reuses `AuthReturnIntent`

It already carries a destination through the auth gate and already validates
against an allow-list to prevent open redirects. Deep links populate it rather
than adding a second mechanism.

## A repo test corrected the first draft

The hosts were hardcoded in the resolver, and `servana_urls_test.dart` failed
it — this repository already shipped 13 wrong URL literals across 5 files and
now forbids the pattern. They moved to `ServanaUrls.deepLinkHosts`, which is the
better home: the intent filters, the association file and the resolver must name
the same set. **An exact set, never a suffix match** — otherwise
`servana.com.ph.evil.com` is a valid link.

## Acceptance gate

| Requirement | Result |
| --- | --- |
| Route table derived from route constants, not literals | ✅ |
| Percent-encoding of every link-derived segment | ✅ pinned by test |
| Signed-out arrival holds the destination | ✅ via `AuthReturnIntent` |
| A link cannot trigger a mutation or carry a token | ✅ pinned by test |
| `autoVerify` intent filters + `associated-domains` | ✅ both added, both parse |
| Association files authored | ✅ valid JSON, `docs/deep-links/well-known/` |
| Files **hosted** | ⛔ **M4.3** |
| Android verification confirmed **on device** | ⛔ **M4.14** |
| Real signing fingerprints | ⛔ **M4.15** |
| Password reset completing in-app (closes TAB 07) | ⛔ needs M4.3 **and** the TAB 07 reset flow (blocked by M1) |

## Nothing breaks before the files are hosted

Android verification fails, iOS does not claim the domain, links open in the
browser. **The failure direction is safe**, which is why the client half ships
first.

## Verification

14 new resolver tests. Suite **1473 → 1487 passed**, 6 skipped. `dart format`
exit 0 · `flutter analyze` **No issues found**. Manifest parses as XML,
entitlements as a plist, both association files as JSON.

**Flagged for TAB 16:** `DEVELOPMENT_TEAM` is `2K2SF7NRQP` for Runner but
`CAB884NRSN` for RunnerTests. The AASA uses the app target's; the mismatch is
the kind of thing that consumes days at signing time (M4.16).
