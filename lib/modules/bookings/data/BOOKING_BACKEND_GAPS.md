# Booking Backend Gaps — C15 V1 BOOKINGSCORE+

Documented gaps between what `BookingRepository` needs and what the Servana API
currently provides to mobile/customer callers.  Each gap has an ID that is also
present as a comment in `ServanaApiClient` and `BookingRepository` so the fix is
easy to locate when the backend route is added.

---

## GAP-C15-001 — Customer Cancel Booking

| Field | Value |
|---|---|
| Gap ID | BACKEND_GAP-C15-001 |
| Capability | Customer self-cancels a booking |
| Status | UNAVAILABLE |
| Required endpoint | POST /api/bookings/:id/cancel  *(does not exist)* |
| Existing endpoint | POST /api/admin/bookings/:id/cancel *(admin-only, 403 for customers)* |
| Priority | HIGH — blocks self-serve cancellation in the app |

**Current behaviour:** `ServanaApiClient.cancelBooking()` calls the admin
endpoint.  Any non-admin Firebase token receives HTTP 403, which is re-thrown
as `ServanaApiException(statusCode: 403)`.  `BookingRepository.cancelBooking()`
propagates this exception.  The store/BLoC layer must catch it and surface a
user-friendly message ("Cancellation is not available yet, please contact
support.").

**Fix required on backend:** Add a customer-facing route in `booking.routes.ts`:
```
POST /api/bookings/:id/cancel
Auth: verifyAuthOptional (or verifyAuth once customer tokens are enforced)
Body: { reason: string, reasonCode?: string }
Response: { success: true, booking: <formatted booking> }
```
Once live, update `ServanaApiClient.cancelBooking()` to point to the new path
and remove the admin fallback.

---

## GAP-C15-002 — Customer Booking Timeline

| Field | Value |
|---|---|
| Gap ID | BACKEND_GAP-C15-002 |
| Capability | Rich per-event timeline visible to the customer |
| Status | PARTIAL |
| Required endpoint | GET /api/bookings/:id/timeline  *(does not exist)* |
| Existing admin endpoint | GET /api/admin/bookings/:id/timeline *(admin-only, 403 for customers)* |
| Existing customer fallback | GET /api/:id/tracking → `booking_tracking` rows |
| Priority | MEDIUM — tracking rows cover key lifecycle milestones |

**Current behaviour:** `ServanaApiClient.getBookingTimeline()` delegates to
`getBookingTracking()` (GET /api/:id/tracking).  The response envelope is
`{ success: true, tracking: [...] }`.  `BookingRepository.getTimeline()` parses
this and returns the rows as `List<Map<String, dynamic>>`.

The customer tracking data is a subset of the admin timeline (no internal notes,
no admin-action events).  It is sufficient for progress indicators and status
history but not for a full audit view.

**Fix required on backend:** Add a customer-facing route in `booking.routes.ts`:
```
GET /api/bookings/:id/timeline
Auth: verifyAuthOptional (ownership check on userId if token present)
Response: { success: true, timeline: [<event objects>] }
```
Once live, update `ServanaApiClient.getBookingTimeline()` to call the new path
and update `BookingRepository.getTimeline()` to read `result['timeline']`.

---

## No Gap — Booking Detail Path

The correct customer/mobile detail endpoint is `GET /api/:id` (bare numeric ID,
no "bookings" segment).  The existing `ServanaApiClient.getBooking(int)` already
uses this path.  `ServanaApiClient.getBookingDetail(String)` is a convenience
alias only — no backend work needed.

Note: `GET /api/bookings/:id` does **not** exist.  `GET /api/bookings/all` is a
separate route (list all, admin-only).  Do not confuse the two.

---

*Last updated: C15 V1 BOOKINGSCORE+ implementation pass.*
