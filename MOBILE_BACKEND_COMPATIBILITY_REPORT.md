# Mobile–Backend Compatibility Report — Servana Client v1.0.0+35

Generated: 2026-07-30 | Backend: https://api.servana.com.ph

---

## Mobile Routes Declared

| Route | Method | Used By | Status |
|---|---|---|---|
| `/api/auth/signin` | POST | AuthBloc email login | Required |
| `/api/auth/register` | POST | RegistrationBloc | Required |
| `/api/auth/logout` | POST | AuthBloc logout | TODO comment in http_backend.dart — not yet called |
| `/api/auth/refresh` | POST | Token refresh | Required |
| `/api/auth/verify-email` | POST | Email verification | Required |
| `/api/users/me` | GET | Profile | Required |
| `/api/users/me` | PUT/PATCH | Profile update | Required |
| `/api/bookings` | GET | Bookings screen | Required |
| `/api/job-orders` | POST | Booking creation | Required |
| `/api/job-orders/:id` | GET | Booking detail | Required |
| `/api/job-orders/:id/cancel` | POST | Cancellation | Required |
| `/api/merchants` | GET | Category / home | Required |
| `/api/merchants/:id` | GET | Merchant detail | Required |
| `/api/merchants/:id/services` | GET | Service list | Required |
| `/api/search` | GET | Search | Required |
| `/api/notifications` | GET | Notification list | Required |
| `/api/notifications/:id/read` | POST | Mark read | Required |
| `/api/messages/:bookingId` | GET | Conversation history | Required |
| `/api/messages/:bookingId` | POST | Send message | Required |
| `/api/payments/checkout` | POST | Payment checkout | Required |
| `/api/payments/:id/status` | GET | Payment polling | Required |
| `/api/support/tickets` | POST | Create ticket | Required |
| `/api/support/tickets` | GET | Ticket list | Required |
| `/api/support/tickets/:id` | GET | Ticket detail | Required |
| `/api/support/tickets/:id/reply` | POST | Reply | Required |
| `/api/reviews` | POST | Submit review | Required |
| `/api/addresses` | GET/POST | Address management | Required |
| `/api/capabilities` | GET | Backend capability check | RECOMMENDED — not yet implemented |

---

## Known Backend Gaps

### GAP-001: POST /api/auth/logout not called
- **File**: `lib/common/data/backend/http_backend.dart:156`
- **Comment**: `// TODO: when BE adds POST /api/auth/logout, call it here.`
- **Impact**: Server-side session is not invalidated on logout. Only local state and FCM token are cleared.
- **Risk**: If the bearer token is captured, it remains valid server-side until natural expiry.
- **Action Required**: Backend team must implement `POST /api/auth/logout` and mobile team must wire it.
- **Severity**: P1 — security gap

### GAP-002: Worker status enum rename pending
- **File**: `lib/common/data/backend/http_backend.dart:385`
- **Comment**: `// TODO: when the BE renames this status to PENDING_WORKER_CODE`
- **Impact**: Code contains a defensive enum mapping that may need updating when backend renames status
- **Action**: Backend and mobile must coordinate enum rename simultaneously
- **Severity**: P2 — coordination required

### GAP-003: GET /api/capabilities not implemented
- **Impact**: The app cannot gracefully degrade when backend features are unavailable. It relies on 404/500 responses to infer missing capabilities.
- **Action**: Backend team should implement a capabilities or health endpoint
- **Severity**: P2 — observability gap

---

## Socket.IO Contract

| Event | Direction | Purpose |
|---|---|---|
| `join_booking_room` | Client→Server | Join booking-specific room |
| `leave_booking_room` | Client→Server | Leave room on navigate away |
| `new_message` | Server→Client | Incoming chat message |
| `booking_status_update` | Server→Client | Booking lifecycle change |
| `tracking_update` | Server→Client | Provider location update |
| `disconnect` | Server→Client | Clean disconnect on logout |

**Authorization**: Socket connections must present a valid bearer token. The server must validate room membership against the authenticated user's bookings. Customer A must not receive Customer B's events.

---

## Minimum Backend Version

This mobile release requires:
- Backend commit supporting all routes in the table above
- Socket.IO server v2.x compatible events
- Firebase project `servana-1d13b` for push notifications

---

## Event Schema Versions

| Analytics Event | Schema Version | Status |
|---|---|---|
| `registration_started` | C21 | Active |
| `booking_initiated` | C21 | Active |
| `payment_initiated` | C21 | Active |
| `screen_view` | C21 | Active |
| `messages_opened` | C21 | Active |
| `notification_opened` | C21 | Active |

---

## Recommendation

Before releasing to production users:
1. Wire `POST /api/auth/logout` on both backend and mobile
2. Implement `GET /api/capabilities` on backend
3. Verify Firebase App Check is enabled for both Android and iOS apps in Firebase Console
