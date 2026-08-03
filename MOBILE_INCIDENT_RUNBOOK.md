# Mobile Incident Runbook — Servana Client

Last Updated: 2026-07-30 | Version: 1.0.0+35

---

## Severity Definitions

| Severity | Definition | Response Time |
|---|---|---|
| SEV-0 | Active security breach or confirmed customer data leak | Immediate — wake on-call |
| SEV-1 | Payment corruption, widespread booking failure, startup crash, severe availability outage | < 30 minutes |
| SEV-2 | Major feature degraded with safe workaround available | < 2 hours |
| SEV-3 | Limited issue, minor regression, cosmetic | Next business day |

---

## SEV-0: Cross-Customer Data Leak

**Signals**: Customer reports seeing another person's bookings, messages, or payment data. Firebase Crashlytics keys contain foreign user IDs. Socket room receives wrong events.

**Immediate actions**:
1. Pause staged rollout (Google Play Console → Managed publishing → Halt)
2. Notify engineering lead and security lead immediately
3. Isolate affected accounts in backend (disable socket rooms, revoke sessions)
4. Determine scope: API response leak vs Socket room leak vs local cache leak
5. Backend: verify room authorization is enforced server-side
6. Mobile: verify `LiveRegionManager.clearCache()` and secure storage wipe run on logout
7. Do NOT publish incident details publicly until scope is confirmed
8. Document all affected accounts and timeline

**Resolution paths**:
- Socket leak → backend fix room authorization, force-disconnect all clients, redeploy
- API leak → backend fix authorization guard, no mobile change needed
- Cache leak → mobile hotfix to clear storage on logout, emergency store submission

---

## SEV-1: Payment Corruption / Duplicate Charge

**Signals**: Customer reports double charge. Payment status shows `success` but booking was cancelled. `PaymentInitiatedEvent` fires twice.

**Immediate actions**:
1. Do NOT disable the payment flow — customers mid-payment must complete
2. Backend: identify duplicate webhook deliveries or double checkout creation
3. Backend: verify idempotency key is enforced on checkout creation
4. Mobile: check for duplicate `PaymentInitiatedEvent` firing from `BookingDetailBloc`
5. Coordinate with payment provider to identify affected transactions
6. Issue refunds through payment provider admin panel for confirmed duplicates
7. Document each affected transaction

**Resolution paths**:
- Duplicate webhook → backend idempotency fix + webhook signature verification
- Client-side double tap → mobile hotfix with button debounce
- Optimistic booking + real booking duplicate → verify `mock_` prefix cleanup in `job_order_bloc.dart`

---

## SEV-1: Startup Crash

**Signals**: Crashlytics shows crash rate spike on app launch. `FirebaseCrashlytics.recordFlutterFatalError` fires within first 3 seconds.

**Immediate actions**:
1. Check Crashlytics for the stack trace
2. Identify if crash is in: Firebase init, Hive init, GetIt registration, Router init
3. If Firebase init: verify `google-services.json` / `GoogleService-Info.plist` match project
4. If Hive: check for schema migration issue after upgrade
5. If GetIt: check for circular dependency or missing registration
6. Use Remote Config kill switch to disable new feature if applicable
7. If no kill switch available: halt rollout and prepare hotfix

**Recovery priority**: Startup crash = P0. Halt rollout immediately.

---

## SEV-1: Authentication Failure Spike

**Signals**: `AuthenticationFailedEvent` rate spikes. `GET /api/auth/signin` returns 401 or 500. Firebase ID token exchange fails.

**Immediate actions**:
1. Check backend logs for auth endpoint errors
2. Verify Firebase project is operational (status.firebase.google.com)
3. Verify backend token validation logic is unchanged
4. Check if a recent backend deployment changed the JWT validation
5. Backend rollback if deployment caused it
6. Mobile cannot fix backend auth failures — escalate to backend team

---

## SEV-1: FCM / Push Notification Outage

**Signals**: Booking status changes not delivered. Support tickets not notified. Message notifications missing.

**Immediate actions**:
1. Check Firebase Console → Cloud Messaging for delivery failures
2. Verify `servana-1d13b` FCM project is active
3. Check backend FCM send code for token errors
4. Verify production `google-services.json` sender ID matches backend FCM credentials
5. Test with a controlled test device using Firebase Console direct send

---

## SEV-2: Booking Creation Failure

**Signals**: Customers cannot complete bookings. `DoneJOState("")` not reached. Backend returns error on `POST /api/job-orders`.

**Actions**:
1. Check backend `POST /api/job-orders` endpoint health
2. Verify request payload from mobile matches backend contract
3. Check for enum mismatch in `job_order_status`
4. If backend unavailable: offline state is shown — no action needed, wait for recovery
5. If mobile sends malformed payload: hotfix required

---

## Rollback Procedures

### Halt Staged Rollout
- Google Play Console → App → Production → Managed Publishing → Halt
- App Store Connect → Version → Remove from Review / Pause Phased Release

### Remote Config Kill Switch
- Firebase Console → Remote Config
- Set `feature_live_tracking_enabled: false` to disable map tracking
- Set `feature_webview_payment_enabled: false` to disable hosted checkout (show alternative flow)
- Changes propagate within 1 hour (12-hour server-side cache)

### Emergency Hotfix Process
1. Branch from exact production tag: `git checkout -b hotfix/v1.0.1 v1.0.0+35`
2. Apply minimal fix only — no unrelated changes
3. Increment version: `1.0.1+36`
4. Run full test suite
5. Build and sign new artifact
6. Submit for expedited App Review (flag as security/crash fix)
7. Release to 100% immediately (not staged) for crash/security fixes
8. Merge hotfix back to `main`

### Previous Version Support
- Google Play: previous version users continue with old binary until they update
- App Store: previous version users continue until they update
- Ensure backend remains backward compatible with v1.0.0 during hotfix window
- Do NOT deploy backend changes that break v1.0.0 until v1.0.1 is at 80%+ rollout

---

## Monitoring Checklist

Check during rollout window:
- [ ] Firebase Crashlytics: crash-free users > 99.5%
- [ ] Firebase Crashlytics: no new fatal crash types
- [ ] Backend: `/api/auth/signin` 2xx rate > 95%
- [ ] Backend: `/api/job-orders` POST 2xx rate > 95%
- [ ] Backend: `/api/payments/checkout` POST 2xx rate > 90%
- [ ] Backend: Socket.IO connection errors < 1%
- [ ] FCM: delivery success rate > 95%
- [ ] Google Play: ANR rate < 0.5%

---

## Escalation

| Situation | Contact |
|---|---|
| Security / data breach | Engineering Lead + Security Lead (immediate) |
| Payment corruption | Engineering Lead + Finance Lead |
| Startup crash | On-call Engineer |
| Backend outage | Backend Lead |
| Store review rejection | Product Lead + Release Manager |
| FCM outage | Engineering Lead (Firebase Console access) |
