# Customer mobile — SWEEP + STITCH + LEAK + REPEAT + TEST, 23 August 2026

**Baseline:** `0b0a23b` · **Result:** `95b7e52` · gates green throughout.

Follows `SWEEP_STITCH_TEST_2026_08_20.md`, which closed the catalogue dead end.
That pass added STITCH; this one adds **LEAK** and **REPEAT**, and those two
passes are where everything new was found.

---

## The headline

**An account switch cleared everything except the two things actually keyed by
customer.**

The teardown that runs when somebody signs in as a different person on a device
that never signed out was calling `customerScopedCleanupSteps('')`. Two of those
steps — the ones that clear `DraftRepository` and `OperationJournal` — are
guarded by `if (logoutUid.isNotEmpty)`, because those are the two stores keyed
per account. With an empty string both were **silent no-ops**.

So the block whose own doc comment says *"their drafts and inbox leak into the
new session"* left exactly the drafts and the journal on disk.

The logout path had been given the uid for this precise reason (`C20 LEAKSHIELD`).
The switch path never got the same fix.

---

## What was found, by pass

### LEAK 1 · An account switch left the previous customer's drafts — **fixed**

| | |
| --- | --- |
| Where | `authentication_bloc.dart`, `_persistSession` |
| Was | `customerScopedCleanupSteps('')` |
| Now | reads the outgoing subject from the token store first |
| Blast radius | booking drafts and the operation journal of the previous account, retained indefinitely on a device that account no longer uses |

**The existing test passed for as long as the defect was live.** `an account
switch clears the previous customer state` asserted that
`customerScopedCleanupSteps(` appeared near `isDifferentSubjectFrom(` — and it
did. Checking that a call is present cannot see a wrong argument. It now asserts
the argument, and a third test pins the `logoutUid.isNotEmpty` guard that makes
an empty string a defect in the first place — so if that guard is ever removed,
the reasoning behind the new test is re-examined rather than silently voided.

### STITCH 1 · Delete Account was a dead end — **fixed**

`privacy_legal_screen.dart` rendered a `SettingsUnavailableTile`:
*"Account deletion will be available in a future update."*

That is worse than nothing: App Review found the exact control they were looking
for and it told them it did not work. Rejected 2026-08-22 under Guideline
5.1.1(v). **`POST /api/account/deletion-request/me` had existed the whole time.**

Now shipped: `requestAccountDeletion()`, a routed `DeleteAccountScreen` stating
what is removed and what is kept, an acknowledgement checkbox, a confirmation
dialog, and a sign-out on success — the logout teardown is what clears the
account's data off the device. **No path out of the flow reaches support**, which
the guideline forbids outside highly-regulated industries.

Added to the viewport matrix: **9 of 9** viewport × text-scale combinations
render clean, including 2.0.

The neighbouring *Export My Data* tile was deliberately **left alone**. It has no
backend (§ backend S5), and making it look live would repeat the mistake that
caused the rejection.

### SWEEP 1 · Five administrative endpoints in a customer binary — **removed**

**11 of 82** public API-client methods had no caller anywhere in `lib/` or
`test/`. Five were not customer operations at all:

| Method | Endpoint |
| --- | --- |
| `approveGcashPayment` | `POST /api/:bookingId/approve` |
| `approveCashPayment` | `POST /api/:bookingId/mark-cash-paid` |
| `createGeoCoverage` | `POST /api/services/:id/coverage-geo` |
| `createBranchSlot` | `POST /api/branches/slots` |
| `getRegisteredUsers` | `GET /api/user/registereduser` |

Approving payments, configuring coverage and listing registered users are
provider or admin capabilities. Shipping the call sites also ships the endpoint
paths to anyone who unpacks the binary. Deleted.

The other six are legitimate customer operations with no caller yet —
`submitGcashProof` looks like a half-finished payment path — so they are **pinned
with a written reason each** rather than destroyed. Deleting a half-finished
feature is a different decision from deleting a privileged one.

The new guard is a ratchet: new dead surface fails the build unless someone
writes down why it is there.

### REPEAT · The write surface, measured

**5 of 35** mutating operations carry a replay key: `createBooking`,
`sendChatMessage`, `createSupportTicket`, `createReview`, and
`submitSafetyIncident` — the last of which sends a key **the server does not
enforce**.

Ten unprotected operations have a real duplication consequence. All of them need
a backend change first; a client that sends a key the server ignores is theatre.
They are listed in the backend work order, §3.

**No front-end fix was made here on purpose.** This is the one pass whose
findings are almost entirely somebody else's to close.

### What LEAK cleared

- **No token or PII reaches a log.** No `debugPrint`/`print` of tokens,
  passwords, OTPs, emails or phone numbers anywhere in `lib/`.
- **Tokens are in `flutter_secure_storage`, not Hive**, and the Hive session is
  written with empty token fields. The other two `saveSession` call sites
  preserve that rather than re-introducing a credential.
- **32 cleanup steps** cover every customer-scoped store found. The defect was
  never coverage; it was one argument.

---

## Backend items — not front-end work

Seven, written up as a work order for the backend developer:
`servana_api/docs/SERVANA_CUSTOMER_SWEEP_BACKEND_MASTER_COMMAND.md`.

The thread running through the two biggest:

> **A fix was applied to the provider surface and not to the customer surface
> that mirrors it. Twice.**

- **S1 · Customer safety incidents can still duplicate.** `providerSafetyService`
  carries the definitive analysis of why `findOne`-then-`insertOne` is not
  idempotent, and was fixed with an atomic upsert **plus a unique index**.
  `customerSupportService` still does `findOne` then `insertOne`. `createIndex`
  appears in exactly one file in the whole backend — the provider one. The client
  already sends `clientIncidentId`.
- **S2 · Chat attachments accept no replay key.** `uploadAttachment` reads only
  `{file, name, conversationId}`. Migration `043` gave provider booking evidence
  exactly this protection days earlier.
- **S4 · Deletion requests are recorded and apparently never fulfilled** —
  `recordDeletionRequest` only inserts a `pending` row and no fulfilment code was
  found. **Now urgent: this app started sending those requests today.**
- **S5 · Customers cannot export their data; providers can.**
- **S6 · No active-sessions endpoint** — an honest dead end, product decision.
- **S3 · The remaining ten unprotected writes.**
- **S7 · B1–B4 carried forward**, unchanged. B1 still blocks the entire Home
  Maintenance category from being booked anywhere.

---

## Gates

| gate | result |
| --- | --- |
| `dart format --set-exit-if-changed` | exit 0, 749 files, **0 changed** |
| `flutter analyze --no-fatal-infos` | exit 0, **No issues found** |
| `flutter test` | exit 0, **2,782 pass**, 3 skipped |

Suite 2,758 → 2,782.

**Every new gate was watched to fail.** Five mutations: restoring
`approveGcashPayment` (1 fail), adding unexplained dead surface (1), reverting
the empty-uid call (1), restoring the unavailable Delete Account tile (1), and
adding a support escape hatch to the deletion flow (1).

**One mutation reported a pass and was wrong.** Restoring the dead-end tile
appeared to leave the suite green — because `dart format` had reflowed the code
the patch matched on, so the edit silently applied nothing. The mutation, not the
gate, was broken. Mutations now assert that the file actually changed before the
result is believed.

**A second gate had to be corrected mid-flight for the opposite reason.** The
first version of the deletion test scanned raw source for the support address,
and failed on the screen's own doc comment explaining that the address must not
appear there. Scanning raw text would have invited the worst possible fix —
deleting the explanation to make the gate green. It strips comments now, and a
floor test proves the stripper removes comments **and** keeps the code.

---

## The lesson worth keeping

Both of this pass's real defects were **already covered by a test that passed**.

The account-switch leak had a test asserting the teardown was called. The call
was there; the argument was wrong. The Delete Account dead end was rendered by a
tile whose widget type was never asserted.

A test that checks a thing *happens* is not a test that checks it happens
*correctly*. When a guard is written for a defect, write the mutation that
reproduces the defect and watch the guard fail — and check the mutation actually
landed before believing what it tells you.
