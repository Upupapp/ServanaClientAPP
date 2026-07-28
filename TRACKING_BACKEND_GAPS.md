# TRACKING_BACKEND_GAPS.md — C16 LIVETRACK+

Generated: 2026-07-28  
Scope: Gaps discovered during C16 pre-implementation sweep that require backend changes to reach full-fidelity live tracking.

---

## TRACK-GAP-001 — P0 — No socket event for provider location updates

**Finding:** The backend writes provider GPS coordinates to MongoDB (`worker_locations`) when the provider calls `POST /api/workers/location` or `POST /api/worker/location`, but emits **no Socket.IO event** at that moment. The root namespace emits only `notification` events. The `/chat` namespace emits only messaging events.

**Impact:** The Flutter app cannot receive real-time location pushes. Polling `GET /api/workers/location/:uid` every 10 seconds is required. During the 10-second gap between polls, the map marker does not update, and the displayed location may be up to 10 seconds stale.

**Resolution needed:** When a provider's location is upserted in `technicianService.upsertWorkerLocation()`, emit a Socket.IO event to the relevant booking room:
```
io.to(`booking:${bookingId}`).emit('location:update', {
  uid: workerUid,
  lat: latitude,
  lng: longitude,
  updatedAt: new Date().toISOString(),
})
```
Requires: (a) storing `bookingId` alongside the location upsert or looking it up; (b) customer-side socket room join authorization for `booking:{id}` rooms; (c) customer auth middleware on the root socket namespace.

**Current workaround:** 10-second polling of `GET /api/workers/location/:uid`. Location is labelled "as of HH:MM" with a staleness indicator if > 3 minutes old.

---

## TRACK-GAP-002 — P0 — No tracking snapshot endpoint

**Finding:** There is no single endpoint that returns booking status + provider location + ETA in one response. The Flutter app must make two sequential calls:
1. `GET /api/:bookingId` → booking status, `eta_minutes`, `eta_at`, `worker_uid`
2. `GET /api/workers/location/:uid` → provider GPS coordinates, `updatedAt`

**Impact:** Each poll cycle costs 2 HTTP round-trips instead of 1.

**Resolution needed:** `GET /api/bookings/:id/live-status` returning:
```json
{
  "status": "WORKER_ASSIGNED",
  "etaMinutes": 12,
  "etaAt": "2026-07-28T10:45:00.000Z",
  "provider": {
    "uid": "abc123",
    "isOnline": true,
    "location": { "lat": 14.5547, "lng": 121.0244 },
    "locationUpdatedAt": "2026-07-28T10:33:00.000Z"
  }
}
```

**Current workaround:** Two parallel HTTP calls per poll cycle. `TrackingRepository.fetchSnapshot()` fires both calls with error isolation so a location failure doesn't block status display.

---

## TRACK-GAP-003 — P1 — ETA is static, computed once at assignment

**Finding:** `bookings.eta_minutes` is calculated at worker-assignment time using a Haversine straight-line distance divided by 30 km/h average speed (`technicianService.ts:614-616`). It is never recalculated. `bookings.eta_at` is an absolute timestamp set once as `NOW() + eta_minutes * interval '1 minute'`.

**Impact:** The displayed ETA does not reflect actual travel progress. If the provider is delayed or takes a detour, the ETA stays at the original estimate.

**Resolution needed:** Periodically recalculate ETA using the provider's current GPS coordinates and a routing API (Google Maps Directions or Distance Matrix). Store `eta_minutes_live` and `eta_at_live` updated on each location upsert.

**Current workaround:** The Flutter app displays `etaAt` as "ETA by HH:MM" and marks it expired once `etaAt` has passed. The staleness label ("as of HH:MM") on the ETA card communicates that this is a one-time estimate, not a live countdown.

---

## TRACK-GAP-004 — P1 — No booking status change socket event

**Finding:** When `bookings.status` or `booking_workers.status` changes (accept, start, complete, cancel), no Socket.IO event is emitted to the customer. The only socket emission in the backend is `notification` sent to `provider:{uid}` rooms.

**Impact:** The customer must poll `GET /api/:bookingId` to detect status transitions (e.g., provider arriving, service starting). The 30-second status poll means up to 30 seconds of lag before the UI reflects the new state.

**Resolution needed:** Emit a `booking:status` event to a `booking:{id}` customer room on every status change:
```
io.to(`booking:${bookingId}`).emit('booking:status', { status: 'IN_PROGRESS', ... })
```
Requires customer socket room join authorization (see TRACK-GAP-001 note).

**Current workaround:** 30-second status poll. The tracking screen shows a "Refreshing…" indicator during each poll cycle.

---

## TRACK-GAP-005 — P2 — Worker location schema lacks accuracy, heading, and speed

**Finding:** The MongoDB `worker_locations` document only stores `{ uid, is_online, loc: { type: 'Point', coordinates: [lon, lat] }, updatedAt }`. No accuracy radius, heading, bearing, or speed fields are stored.

**Impact:** The Flutter app cannot show:
- A precision radius circle around the provider marker
- A direction arrow on the map marker
- Speed or bearing-based trajectory estimation

**Resolution needed:** Extend `upsertWorkerLocation()` payload to accept `accuracy`, `heading`, and `speed` from the provider's device GPS, and store them in the MongoDB document.

**Current workaround:** Provider marker shown as a single pin. No precision circle or direction arrow.

---

## TRACK-GAP-006 — P2 — `GET /api/workers/location/:uid` is unauthenticated

**Finding:** `GET /api/workers/location/:uid` (technician.routes.ts:15) has no auth middleware. Any caller with a valid `uid` can retrieve that provider's current location without proving they have an active booking with that provider.

**Impact (BOLA):** A customer can track any provider's location by guessing or enumerating UIDs, even if they have no booking relationship with that provider.

**Note:** Per the mobile parity rule, this route is immutable — it is called by the mobile worker app without a token. Adding `verifyAuthOptional` middleware and a booking relationship check would be additive and non-breaking for unauthenticated callers, but this requires a backend change decision.

**Current workaround:** The Flutter app only calls this endpoint from the tracking screen, which requires an active booking with a non-null `workerUid`. This is UI-level access control only — it does not prevent API-level BOLA.

---

## TRACK-GAP-007 — P2 — Customer socket room authorization not implemented

**Finding:** The root Socket.IO namespace (`provider.gateway.ts`) authorizes `booking:{id}` room joins by checking `WHERE id = $1 AND worker_uid = $2` — this is the **provider's** ownership check. There is no customer-side room join handler and no customer Firebase auth on the root namespace (customers do not currently connect to the root socket).

**Impact:** Even if TRACK-GAP-001 and TRACK-GAP-004 are resolved (backend emits events to `booking:{id}` rooms), the Flutter customer app cannot join those rooms without implementing customer-side socket auth.

**Resolution needed:**
1. Extend root namespace auth middleware to accept customer Firebase tokens (not just provider tokens).
2. Add a `customer:join_booking` event handler that verifies `WHERE id = $1 AND customer_uid = $2` before joining the booking room.

**Current workaround:** No customer socket connection. All tracking is polling-based.

---

## Summary

| ID | Priority | Gap | Workaround |
|---|---|---|---|
| TRACK-GAP-001 | P0 | No socket location events | 10s polling |
| TRACK-GAP-002 | P0 | No snapshot endpoint | 2 sequential calls |
| TRACK-GAP-003 | P1 | Static ETA | Show `etaAt` with staleness label |
| TRACK-GAP-004 | P1 | No status change events | 30s status poll |
| TRACK-GAP-005 | P2 | No accuracy/heading/speed | Single pin, no precision circle |
| TRACK-GAP-006 | P2 | Unauthenticated location read | UI-only gating |
| TRACK-GAP-007 | P2 | No customer socket rooms | All polling, no push |
