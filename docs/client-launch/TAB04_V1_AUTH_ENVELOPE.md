# TAB 04 — Bring v1 authentication failures onto the v1 envelope

**Status:** local scope COMPLETE · **CERTIFIED_PENDING_DEPLOY**
**Date:** 2026-08-18 · **Backend commits:** `086738c`, `fcba273` (local, unpushed)
**Owner:** Backend · **Blocks:** TAB 12

---

## What was already true, and what was not

The translator this TAB asks for **already existed** — `v1AuthEnvelope` in
`src/api/v1/register.ts`, built by the Provider Web programme's TAB 02
(`cbe6828`) against the identical production measurement. It is committed and
**not deployed**, which is exactly why the TAB 01 probe still saw the legacy
envelope on `GET /api/v1/me` today.

So this TAB did not reimplement it. It verified it — and the verification found
a defect.

## The defect: a revoked session escaped translation

`v1AuthEnvelope` decided *"is this already a v1 envelope?"* with `!body.error`.
That predicate is not sufficient. `verifyAuth`'s TOKEN_REVOKED branch writes a
**hybrid**:

```js
{ status: "failed", code: "TOKEN_REVOKED", message: "...",
  error: { code: "TOKEN_REVOKED", recovery: "REAUTHENTICATE", retryable: false } }
```

`body.error` is truthy, so the wrapper passed it through **untouched** — legacy
shape, no `requestId`.

Of the five 401s `verifyAuth` can write, this is the one that matters most.
`TOKEN_EXPIRED` deserves a silent re-authentication; `TOKEN_REVOKED` deserves a
sign-out and an explanation. Collapsed into "something went wrong", the customer
is told nothing and support cannot correlate the refusal to a log line.

**Fix:** every genuine v1 envelope is minted by `fail()`, which always stamps a
string `requestId`. That is now the discriminator, and it cannot be satisfied by
accident — a legacy body carrying an `error` field does not carry
`error.requestId`.

## Why the existing test could not have caught it

`v1-auth-envelope.test.ts` covers the three auth **modes** and passes. A
tokenless request can only ever produce `UNAUTHENTICATED`; it can never reach
the revoked branch. The bug sat behind a case nobody had remembered to write —
precisely why the method demands a **property over the mounted router**, not a
list of cases.

`tests/v1-auth-envelope-conformance.test.ts` asserts, over all **105**
implemented entries:

- every gated entry refuses a tokenless call with `error.code`, `error.message`
  and the real `error.requestId`, never the legacy `status` field;
- every code emitted is one that endpoint's **OpenAPI entry declares** — closing
  the loop between the published document and what runs;
- public entries carry no auth chain at all;
- all **five** bodies `verifyAuth` can write, enumerated from the source end to
  end rather than inferred from the two shapes observed externally;
- no refusal message can distinguish a known account from an unknown one;
- a **population guard**, so a filter bug that empties the list cannot make
  every property above vacuously true.

## Decision — `INVALID_TOKEN` stays out of the vocabulary

`register.ts` explicitly deferred this to TAB 04. `verifyAuth` can emit
`INVALID_TOKEN`, which is absent from `V1_ERROR_STATUS` and from the OpenAPI's
`AUTH_DEFAULT_ERRORS` (`UNAUTHENTICATED | TOKEN_EXPIRED | TOKEN_REVOKED`).

**It stays mapped to `UNAUTHENTICATED`, with the original preserved in
`details.reason`.**

1. The published document is the contract. Anyone generating a client from it
   gets a parser with no case for a fourth code, so adding one is a breaking
   change needing a version story — not a bug fix.
2. Nothing is lost: `details.reason` carries it verbatim for any client wanting
   the distinction.
3. TAB 12 maps the published vocabulary to customer copy. A 37th code appearing
   only nested would be mapped and unreachable — which reads as covered while
   covering nothing.

**The counter-argument, recorded not dismissed:** RFC 6750 §3.1 defines
`invalid_token` as a distinct Bearer error. If the contract owner wants it
published, that is a deliberate vocabulary change. The decision is pinned by
test, so a future change is deliberate rather than drift.

## The legacy tree did not move

Asserted, not assumed: the bare middleware still writes
`{ status, code, message }` with no `error` and no `requestId`. 520 legacy
routes and five clients read that shape. The v1 work is a wrapper applied only
by `authChain`, so nothing outside `/api/v1` can change shape, status or timing.
`legacy-response-envelope.contract.test.ts` and `legacy-authz-parity.test.ts`
both stay green.

## Acceptance gate

| Requirement | Result |
| --- | --- |
| Every v1 entry returns the v1 envelope with a `requestId` | ✅ property over 105 entries |
| Legacy 401 body byte-identical | ✅ asserted by test |
| `TOKEN_REVOKED` / `TOKEN_EXPIRED` distinct, in the v1 envelope | ✅ **and fixed** — revoked was escaping |
| Conformance property shown failing before the change | ✅ found the defect organically |
| No widened disclosure on a 401 | ✅ pinned by test |
| **Deploy + re-probe every gated v1 path** | ⛔ **BLOCKED — M2** |

Demonstrating revoked/expired **against a real token** (gate wording) needs a
live Firebase credential and a deploy — part of M2.

## Verification

- 8 auth suites: **138 passed**
- Full backend suite: **284 suites, 6029 tests, exit 0**
- Heap peak 1164.8 MB of 4288 MB — **72.8% headroom**, above the 70% guard
