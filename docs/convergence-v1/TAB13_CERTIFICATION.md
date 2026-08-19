# TAB 13 — Conversations

**Date** 2026-08-16 · **Repo** `servana_client-mobile` @ `main`
**Backend evidence** `servana_api-main`, read directly from source

> **Provenance.** The Master Command text is not stored in this repo. TAB 11's
> subject was the user's; TABs 12 and 13 were mine. Recorded in `state.json`.

---

## 1. The finding this tab corrected

`V1Capability.conversations` was defined in **TAB 02** and deliberately never
enabled. The manifest recorded it as blocked on *"a semantic decision"*, and
TAB 01's R-10 said why:

> **R-10** Opening a booking chat may create the conversation.
> `getBookingConversation` → `GET /api/bookings/:id/conversation` | v1 replaces
> it with an explicit `POST /api/v1/conversations`; SC-038 records the current
> lazy-create as a defect | **BREAKS**

**That is no longer true, and the fix was upstream.** Measured against
`src/chat/chat.controller.ts`:

```ts
/**
 * GET /bookings/:bookingId/conversation
 *
 * Resolves the booking's conversation. It does NOT create one: a booking
 * conversation is a consequence of a provider being confirmed, created
 * transactionally by `technicianService.acceptJob` and by admin assignment —
 * not of a client opening a screen.
 */
const conversation = await chatService.getExistingConversation(bookingId);
if (!conversation) return res.status(404).json({ … });
```

The handler resolves and 404s. It creates nothing. The backend comment even
names this client as the reason the 404 is the contract:
*"`MessagingRepository.resolveForBooking` maps 404 to null."*

So the semantic hazard that held the capability back for eleven tabs **does not
exist**, and no product decision was needed to proceed. Pinned by test so the
stale finding cannot be re-derived from the document.

---

## 2. What the real hazard turned out to be

Smaller, and running the other way.

| | legacy | canonical |
| --- | --- | --- |
| resolve by booking | `GET /api/bookings/:id/conversation` | `POST /api/v1/conversations` |
| absent | **404** | `CONVERSATION_NOT_AVAILABLE` (409) |

The canonical entry *"opens, **or** resolves"* — one conversation per booking
under a unique constraint and an `ON CONFLICT` insert, so a repeat returns the
same thread. It is gated by `mayOpenConversation`: *"Support may open a
conversation on a booking with no provider; the parties may not."*

So a customer calling it before a provider is confirmed is **refused**, not
given a thread. Both transports mean "not yet" — from different signals — and
both must surface as `null`. Otherwise flipping the capability turns a quiet
empty state into an error banner on a screen that is working correctly.

`CONVERSATION_ACCESS_DENIED` is deliberately **not** swallowed into the same
null: somebody probing another customer's booking must not be told it merely
has no chat yet. Both directions asserted.

---

## 3. The DTOs did not have to change

The canonical `Conversation` names `id`, `bookingId`, `unreadCount`,
`isClosed`, `lastMessageAt` and `lastMessage` — exactly the keys
`ConversationMapper` already reads. `isClosed` is kept canonically as *"the
pre-status compatibility boolean, republished … kept correct for clients that
know nothing about `status`"*, and this client is one of them.

One mapper serves both, so this is a change of URL and envelope rather than of
meaning — the same finding TAB 09 made about bookings, and worth stating for
the same reason: it is why the canonical source is small.

The envelopes do differ. The chat routes carry no envelope and nest under a
top-level `conversations` key — a shape the backend keeps exactly — while v1
returns a bare array in `data`. Both are read.

---

## 4. `reportMessage` never routes

The `conversations` domain has six canonical entries: `create`, `list`, `get`,
`messages.list`, `messages.create`, `read`. **None of them is report, edit or
delete**, and the client calls report.

So `MessagingRepository.reportMessage` calls the compatibility path **directly,
in every configuration**, exactly as `NotificationsRepository.dismiss` does for
`DELETE /api/user/notifications/:key`. That is the second kind of absence in
this codebase's taxonomy — the canonical side missing a call the legacy side
has — and expressing it in the repository is what stops the canonical source
from having to invent an endpoint or throw on a button the customer can see.

Asserted with the capability **on**: reporting must still reach the legacy
client.

---

## 5. Idempotency lives in the body here

`clientMsgId` is the idempotency mechanism for a message and it is a *message
field*, not a transport header — the contract calls a malformed one
`MESSAGE_IDEMPOTENCY_KEY_INVALID` rather than the generic
`IDEMPOTENCY_KEY_INVALID`. So `sendMessage` sends no `Idempotency-Key` header,
and that is asserted rather than left to inference, because TAB 10 established
the header habit three tabs ago.

---

## 6. Runtime state of every shipped build

**Unchanged. Fully legacy.** `conversations` is off, so every call goes to the
chat routes exactly as before. The public surface of `MessagingRepository` is
identical, and `MessagingStore`, `BookingChatScreen` and `MessagesInboxScreen`
were not touched.

---

## 7. Gaps, recorded not fixed

**`ConversationReadState` is discarded.** `POST …/read` returns the
authoritative post-move `unreadCount`, and the repository signature returns
`void` because the store re-reads the list. Wiring it through is a store change
this tab did not need to make.

**`status`, `viewerSeat`, `canSend` and `cannotSendReason` are not modelled.**
The canonical `Conversation` carries a five-value status enum and an explicit
send capability with a reason; `ConversationModel` carries only `isClosed`.
That is sufficient today — `isClosed` is republished precisely for clients like
this one — but `cannotSendReason` is strictly better UX than a bare boolean,
and adopting it is a model-and-screen change.

**Message edit and delete** have no canonical successor either, and no client
caller. Not modelled.

**Upstream, unchanged.** `/api/v1` is still absent from `servana_api`'s
`origin/main`.

---

## 8. Acceptance gate

```
flutter analyze   → 0 errors, 0 warnings, 39 infos (the unchanged baseline)
flutter test      → 1,888 passed, 6 skipped, 0 failed
```

New tests: 14 in `test/messaging/messaging_canonical_test.dart`. No existing
test needed changing — the second tab running where that is true, because the
repository's public surface was preserved exactly.
