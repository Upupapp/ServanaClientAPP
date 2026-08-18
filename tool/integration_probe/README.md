# Integration probe

Ground truth about the backend the client is migrating onto, measured on the
day it is acted on rather than remembered from the day it was written.

## Why

A recorded position was wrong. Memory held that `/api/v1` was unreachable and
that `GET /api/catalog` returned 401. Both were false — v1 was deployed and
complete, and a migration was very nearly cancelled off the stale reading.
Nothing in either repository was watching that claim, so nothing corrected it.

Three separate findings in the same sweep had that shape: accurate when
written, false once the other side moved, with no detector in between. This
probe is the detector.

## Run it

```bash
dart run tool/integration_probe/integration_probe.dart \
  --origin https://api.servana.com.ph
```

Exits non-zero on a hard failure. Roughly 90 seconds against production.

| flag | default | meaning |
| --- | --- | --- |
| `--origin` | `https://api.servana.com.ph` | origin to probe |
| `--contract` | `docs/integration/contract_snapshot.json` | backend contract snapshot |
| `--out-dir` | `docs/integration` | where `BASELINE.md` / `baseline.json` land |
| `--api-client` | `lib/common/data/backend/servana_api_client.dart` | source for legacy call sites |
| `--client-endpoints` | *(none)* | canonical `V1Endpoints` source, when present |
| `--strict` | off | also fail on a wrong successor signpost |

## What counts as failure

**Hard (exit 1):**

- an implemented contract path answering a **router** 404 — it is not mounted
- a legacy path the shipped client constructs answering a router 404 — a live
  field outage, not a migration concern
- an entry marked `planned` that answers — the contract says it is not mounted
- any transport failure — the run measured nothing and says so

**Advisory:** a published `Link rel="successor-version"` that disagrees with the
contract (TAB 03). Real, but it does not stop a client migrating. `--strict`
promotes it.

## The two 404s

A 404 is ambiguous — the *router* may not have the route, or the *handler* may
not have the record — and conflating them is how a probe invents an outage.
`/api/v1/catalog/services/999999999` returns 404 with
`{"error":{"code":"CATALOG_SERVICE_NOT_FOUND",...}}`: the route is mounted, the
id is not real. The router answers an unmounted path with a distinctive
`No v1 endpoint for …` envelope instead, so the two are separated on evidence.
Five catalog routes land in this bucket on every run. A naive probe reports
five hard failures and declares the deploy broken.

`429` is likewise positive evidence of mounting — a limiter in front of a route
that exists. Probing the auth surface trips it by design.

## Where the path lists come from

Neither list is written by hand, because a hand-maintained list is the failure
this probe exists to catch.

- **v1 paths** — `docs/integration/contract_snapshot.json`, produced by
  *executing* `src/api/v1/contract.ts`, the same array `register.ts` mounts
  from and `openapi.ts` generates from. The snapshot cannot name a route the
  backend does not mount, because it never gets to say what the routes are.
- **legacy paths** — twice over, because the two sets differ:
  1. the contract's own `legacy` mappings, and
  2. every `_uri('/api/…')` call site in `servana_api_client.dart`, paired with
     the `_client.<verb>` that consumes it.

  Pairing the verb matters: probing a POST-only route with GET draws a router
  404 and would report a healthy route as a P0 outage.

  Comparison is on route SHAPE: the contract writes `:bookingId` and a call site
  yields a concrete id, so both normalise to `:id` before diffing. Comparing the
  literal text counted those as different routes and inflated this figure from
  30 to 50.

  As of the committed baseline, **30 of the 70 routes the client actually calls
  are not declared as legacy by the contract at all** — so probing either list
  alone leaves a hole precisely where field breakage would appear.

## Refreshing the contract snapshot

Needs the backend repository checked out alongside this one.

```bash
cd ../servana_api
./node_modules/.bin/ts-node \
  --compiler-options '{"module":"CommonJS","moduleResolution":"node"}' \
  ../ServanaClientAPP/tool/integration_probe/extract_contract.ts \
  ../ServanaClientAPP/docs/integration/contract_snapshot.json
```

The snapshot records the backend commit it came from, and `BASELINE.md` prints
it. A snapshot that cannot say where it came from is a rumour.

## Proving it can fail

A green gate proves nothing until it has been watched to fail.

```bash
# 1. rename a contract path -> must exit 1 with a NOT MOUNTED hard failure
python3 -c "import json;s=json.load(open('docs/integration/contract_snapshot.json'));\
[e.__setitem__('path','/api/v1/renamed-by-mutation') for e in s['v1'] if e['id']=='catalog.browse'];\
json.dump(s,open('/tmp/mut.json','w'))"
dart run tool/integration_probe/integration_probe.dart --contract /tmp/mut.json --out-dir /tmp/mut

# 2. point at an origin that does not exist -> must fail loudly, and must NOT
#    report an empty diff as agreement
dart run tool/integration_probe/integration_probe.dart \
  --origin https://api.servana-does-not-exist-xyz.invalid --out-dir /tmp/mut2
```

Mutation 2 earned its keep: it first failed for the *wrong reason*, reporting
"4 planned entries are answering" when the origin was simply unreachable. A
probe that cannot reach the origin knows nothing about the contract, and now
says exactly that instead of dressing a dead DNS lookup up as contract drift.
