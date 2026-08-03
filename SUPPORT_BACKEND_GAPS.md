# C18 SUPPORTCORE+ — Backend Gaps

Documented gaps between the C18 Flutter implementation and the backend as shipped.
These are not bugs in the current implementation — they are deferred P1/P2 features.

---

## P0 — None. All blocking requirements are met.

---

## P1 — No FCM push on admin reply

**Gap**: When a Servana admin posts a reply to a customer support ticket via the admin
portal, no FCM notification is sent to the customer's device. The customer sees the
new reply only the next time they open the ticket detail screen (pull-to-refresh or
re-navigation).

**Fix path**: Backend `addAdminReply` handler should call `FcmService.sendToCustomer`
with `routeKey: 'SUPPORT_TICKET'` and `resourceId: ticketKey`. Flutter
`NotificationNavigationCoordinator` already handles `SupportTicketTarget` navigation.

**Impact**: Customers may not know they received a reply until they open the app.

---

## P1 — No file/photo attachment endpoints

**Gap**: C18 spec §65 mentions attachment support. No `/support/tickets/:ticketKey/attachments`
endpoint exists on the backend. The Flutter UI does not surface an attachment button
(correctly omitted until backend is ready).

**Fix path**: Add multipart POST `/api/support/tickets/:ticketKey/attachments`,
returning `{ url, filename, mimeType }`. Add attachment display to `SupportReplyBubble`.

---

## P2 — No pagination on ticket list

**Gap**: `GET /api/support/tickets` returns all tickets for the customer. For most
customers this is fine (< 20 tickets), but no `page`/`cursor` parameter exists.

**Fix path**: Add `?cursor=` or `?page=` to the endpoint and implement infinite-scroll
in `SupportTicketsScreen`.

---

## P2 — No admin reply UI in current admin portal scope

**Gap**: The Servana admin portal (`servana_adminportal`) does not yet have a Support
Inbox tab for answering customer tickets. Tickets will accumulate without admin-side
tooling to respond.

**Fix path**: Add Support Inbox to admin portal (separate command — admin scope).
Backend ticket APIs already support admin role via `req.user` Firebase UID check in
`customerSupportController.ts`.

---

## P3 — Safety incident attachments not implemented

**Gap**: Customers cannot attach photos to safety incident reports. Useful for evidence.

**Fix path**: Same as P1 attachments, applied to `/api/support/safety/incidents/:caseKey/attachments`.

---

*Last updated: C18 SUPPORTCORE+ implementation (local only, not deployed to prod)*
