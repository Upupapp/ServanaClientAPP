"""Generate the six-pass reports and the ServanaClient pending-items masterlist.

Both derive from the same findings file, so the per-pass reports and the
masterlist cannot disagree about severity or status.
"""
import json
import pathlib
import collections

SCRATCH = pathlib.Path(__file__).parent
OUT = pathlib.Path('C:/Users/paulg/OneDrive/Desktop/servana_client-main/docs/audit')

d = json.loads((SCRATCH / '_findings.json').read_text(encoding='utf-8'))
findings = d['findings']
unverified = d.get('unverified', [])
stats = d.get('stats', {})

SEV = {'P0': 0, 'P1': 1, 'P2': 2, 'P3': 3, 'info': 4}
PASSES = ['SWEEP', 'STITCH', 'ALIGN', 'LEAK', 'REPEAT', 'TEST']

PASS_INTENT = {
    'SWEEP':  'Cross-platform field parity — what the client reads and writes '
              'versus what the backend actually sends.',
    'STITCH': 'End-to-end workflow tracing — client to API to persistence to '
              'notification to refresh, and where the chain breaks.',
    'ALIGN':  'Canonical contract alignment — status, catalog, identity, auth, '
              'payment, notification, audit.',
    'LEAK':   'Server-side authorization and cross-user isolation. The backend '
              'was inspectable, so these are verified rather than inferred.',
    'REPEAT': 'Endpoint equivalence and the canonical capability registry — '
              'duplicated domain logic and same-entity-different-shape.',
    'TEST':   'Coverage against the critical paths, and whether the gates that '
              'exist actually gate anything.',
}

# Items closed during this session, keyed by a substring of the finding title.
#
# ORDER MATTERS: the first key that appears in a title wins, so specific keys
# must precede general ones. 'cancel' is broad enough to swallow the round-2
# guest-cancellation findings and misattribute them to bd8c355, which is the
# commit that did NOT fix them.
CLOSED = {
    # 9a07330 — booking lifecycle identity from the token.
    'accept,start,complete,decline': '9a07330',
    'workers/bookings/:id/{accept': '9a07330',

    # a062ef9 — the four P0s the six-pass re-run found.
    'cancel any guest booking': 'a062ef9',
    'cancelled by any authenticated': 'a062ef9',
    'Guest-owned bookings can be cancelled': 'a062ef9',
    'Guest bookings can be cancelled': 'a062ef9',
    'guest booking LIST but not': 'a062ef9',
    'sibling ownership resolver': 'a062ef9',
    '403 on tap': 'a062ef9',
    'workers/role': 'a062ef9',
    'role/3': 'a062ef9',
    'role/:role': 'a062ef9',
    'job-cards': 'a062ef9',
    '/api/additional': 'a062ef9',
    'additional/* family': 'a062ef9',
    "excludes 'CANCELED'": 'a062ef9',
    'payment retry job excludes': 'a062ef9',
    # NOT a bare 'CANCELED' key. It matched "Cancelled bookings still occupy the
    # provider's calendar", a separate defect in providerAvailabilityEngine that
    # a062ef9 does not touch — marking an open bug closed is the one error a
    # masterlist must not make.
    'Residual fail-open ownership shape': 'a062ef9',
    'fail-open ownership': 'a062ef9',

    'approve` and `mark-cash-paid`': '6d78313',
    # Was 'approve' — matched 6 titles including the payment-idempotency and
    # webhook-notification findings, which 6d78313 does not address.
    ':bookingId/approve': '6d78313',
    # Was 'mark-cash-paid' — also matched the payment-idempotency finding and
    # the assertBookingAccess test-coverage gap, neither of which is fixed.
    ':bookingId/mark-cash-paid': '6d78313',
    'addUserAddress': '6d78313',
    'updateUserAddress': '6d78313',
    'leak-isolation.test.js pins three address': '6d78313',
    # Was 'cancel' — which matched 11 titles, of which bd8c355 fixed 2. It
    # closed the provider-calendar bug, the cancellation-notification gap, the
    # duplicate-timeline bug and more, all of which are still open.
    'bookings/:id/cancel': 'bd8c355',
    'users/:userId/bookings': 'bd8c355',
    'user/:userId/addresses': 'bd8c355',
    'gc.phone_number': '880d5bc',
    'guest_customers on a column that does not exist': '880d5bc',
    'Guest bookings are linked to a client account by an unverified': '880d5bc',
    'PROVIDER.PROFILE.READ': '65b4337',
    'contract test pins a URL the backend does not serve': '65b4337',
    'options-with-addons': '65b4337',
}


def n(v):
    return '' if v is None else str(v).replace('\r', ' ').strip()


def esc(v):
    return n(v).replace('|', '\\|').replace('\n', ' ')


def closed_by(f):
    t = n(f.get('title'))
    for key, sha in CLOSED.items():
        if key.lower() in t.lower():
            return sha
    return None


def confirmed(f):
    return 'CONFIRMED' in n(f.get('verification'))


ordered = sorted(findings, key=lambda f: (SEV.get(f.get('severity'), 5),
                                          PASSES.index(f['pass']) if f.get('pass') in PASSES else 9,
                                          n(f.get('title')).lower()))
for i, f in enumerate(ordered, 1):
    f['_id'] = f"SC-{i:03d}"

OUT.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------- per pass --
for p in PASSES:
    sel = [f for f in ordered if f.get('pass') == p]
    L = [f'# {p} — Servana Customer Mobile App', '',
         PASS_INTENT[p], '',
         '| | |', '| --- | --- |',
         '| Target | `Heatclift/ServanaClient` @ `bab66e4` |',
         '| Backend | `servana_api` @ `870fd28` (canonical, §3) |',
         '| Also inspected | admin portal `101016d`, provider web `42fbec9`, provider mobile `451eaf6` |',
         '| Customer web | **UNAVAILABLE** — repo has 0 committed files |',
         f'| Findings | {len(sel)} |', '']

    by_sev = collections.Counter(f.get('severity') for f in sel)
    L += ['**' + ' · '.join(f'{k}: {by_sev[k]}' for k in ('P0', 'P1', 'P2', 'P3', 'info')
                            if by_sev.get(k)) + '**', '']

    for f in sel:
        sha = closed_by(f)
        badge = (f' — **FIXED** in `{sha}`' if sha
                 else (' — **CONFIRMED**' if confirmed(f) else ''))
        L.append(f"## {f['_id']} · {n(f.get('title'))}{badge}")
        L.append('')
        L.append(f"**{f.get('severity')}** · rule {n(f.get('hardRule')) or '—'} · "
                 f"fix in **{n(f.get('fixLocation')) or '?'}** · "
                 f"protected release: **{n(f.get('protectedReleaseRequired')) or '?'}**")
        L.append('')
        if n(f.get('summary')):
            L += [n(f.get('summary')), '']
        for label, key in (('Client', 'clientEvidence'), ('Backend', 'backendEvidence'),
                           ('Other', 'otherEvidence'), ('Canonical contract', 'canonicalContract'),
                           ('Endpoint', 'backendEndpoint'), ('Test gap', 'testGap')):
            if n(f.get(key)) and n(f.get(key)).lower() not in ('n/a', 'none'):
                L.append(f'- **{label}:** {n(f.get(key))}')
        L += ['', f"**Recommendation.** {n(f.get('recommendation'))}", '']
        if not confirmed(f) and not sha:
            L += ['> Agent-reported. Only P0 claims went through adversarial '
                  'verification; re-read the cited files before acting.', '']
    (OUT / f'{p}_CLIENT.md').write_text('\n'.join(L) + '\n', encoding='utf-8')

# --------------------------------------------------------------- masterlist --
open_items = [f for f in ordered if not closed_by(f)]
closed_items = [f for f in ordered if closed_by(f)]

M = ['# Masterlist — Pending Items, Servana Customer Mobile App', '',
     'Every open finding for ServanaClient. Companion to the worker app list at',
     '`ServanaWorker/docs/MASTERLIST_PENDING_ITEMS_SERVANA_WORKER_APP.md`.', '',
     '**Maintenance rule.** Update at the end of every command. Add new findings, '
     'move resolved ones to Closed with the commit that closed them, and move '
     'disproved ones to Corrections. **Never delete a row.**', '',
     '- **Last updated:** 2026-08-01, six-pass RE-RUN (round 2)',
     '- **App:** `Heatclift/ServanaClient` @ `4868aca` — 983 tests, analyzer 0 errors / 46 infos',
     '- **Backend:** `servana_api` @ `9a07330` — 1317 tests, 11 local security commits',
     '- **Per-finding detail:** `docs/audit/<PASS>_CLIENT.md`', '',
     '## Correction to the round-1 numbers', '',
     'The first run of this file reported **95 open / 25 closed**. That closed '
     'count was too high. Closure is matched by substring against the finding '
     'title, and three keys were single words — `cancel`, `approve`, '
     '`mark-cash-paid`. `cancel` alone matched 11 findings when the commit it '
     'pointed at fixed 2, sweeping in the provider-calendar bug, the '
     'cancellation-notification gap and the duplicate-timeline bug, none of '
     'which were touched. Those rows are open again and the keys are now '
     'specific. **A masterlist that reports an open bug as fixed is worse than '
     'no masterlist**, so the number going up here is the file working.', '',
     'Round 2 was scoped to verify the eleven prior fixes rather than re-audit '
     'from scratch: 32 held, 19 partial, 3 unchanged-since-round-1, 6 not '
     'checkable from the repositories. Rows carry `round` and, where the agent '
     'said so, `isNew`. Nine round-2 rows self-declare as pre-existing without '
     'matching a round-1 row automatically — some are restatements, some are '
     'new findings in a known area. They are kept as separate rows rather than '
     'silently merged, because guessing wrong in either direction loses '
     'information.', '',
     '**Three of the five P0s closed in round 2 were introduced or missed by '
     'the round-1 remediation itself** — see `a062ef9` and `9a07330`.', '']

M += ['## At a glance', '',
      '| Severity | Open | Closed this session |', '| --- | ---: | ---: |']
for s in ('P0', 'P1', 'P2', 'P3', 'info'):
    o = sum(1 for f in open_items if f.get('severity') == s)
    c = sum(1 for f in closed_items if f.get('severity') == s)
    if o or c:
        M.append(f'| **{s}** | {o} | {c} |')
M += ['', f'**{len(open_items)} open · {len(closed_items)} closed.**', '']

M += ['> **Verification status.** 18 P0 claims went through adversarial '
      f'verification: **{stats.get("p0Confirmed", "?")} confirmed, '
      f'{stats.get("p0Downgraded", "?")} downgraded**. The other '
      f'{len(findings) - 18} findings are agent-reported and were NOT '
      'independently verified — re-read the cited files before acting on one.', '']

for s in ('P0', 'P1', 'P2', 'P3'):
    sel = [f for f in open_items if f.get('severity') == s]
    if not sel:
        continue
    M += [f'## {s} — open ({len(sel)})', '',
          '| ID | Pass | Finding | Fix in | Release | Verified |',
          '| --- | --- | --- | --- | --- | --- |']
    for f in sel:
        M.append('| ' + ' | '.join([
            f['_id'], n(f.get('pass')), esc(f.get('title'))[:150],
            n(f.get('fixLocation')) or '?',
            n(f.get('protectedReleaseRequired')) or '?',
            '**yes**' if confirmed(f) else 'agent',
        ]) + ' |')
    M.append('')

M += ['## Closed this session', '',
      '| ID | Finding | Commit |', '| --- | --- | --- |']
for f in closed_items:
    M.append(f"| {f['_id']} | {esc(f.get('title'))[:150]} | `{closed_by(f)}` |")
M += ['', '## Carried over from other work', '',
      '| Item | Where |', '| --- | --- |',
      '| Rotate Firebase keys — previously-committed ones remain in git history | ServanaClient |',
      '| 36 unauthenticated legacy worker routes; migration step 2 needs a mobile release | `servana_api` + ServanaWorker |',
      '| 4 backend security commits are local-only and undeployed | `servana_api`, no upstream configured |', '']

if unverified:
    M += ['## Unverified — evidence not obtainable', '']
    for u in sorted(set(n(x) for x in unverified if n(x)))[:60]:
        M.append(f'- {u}')
    M.append('')

(OUT.parent / 'MASTERLIST_PENDING_ITEMS_SERVANA_CLIENT_APP.md').write_text(
    '\n'.join(M) + '\n', encoding='utf-8')

print(f'reports: {len(PASSES)} pass files in docs/audit/')
print(f'masterlist: {len(open_items)} open, {len(closed_items)} closed')
print('by severity (open):',
      dict(collections.Counter(f.get('severity') for f in open_items)))
