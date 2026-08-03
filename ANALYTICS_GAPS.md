# Analytics Coverage Gaps — Servana Customer App

Status as of C21 ANALYTICSCORE+ + post-audit fixes · 2026-07-30

---

## P0 — Consent Infrastructure (BLOCKER)

### GAP-CON-001: No consent dialog UI
**Impact**: Analytics are **completely dark** on first install. After the PDPA/GDPR fix (`defaultConsent()` now returns `essential`-only), all `analytics`-category events are blocked until the user explicitly grants consent. The `fullConsent()` static method is ready; it just needs a UI to call it.

**Required**: A consent dialog (shown on first launch or onboarding) that calls `dpLocator<AnalyticsCoordinator>().setConsent(AnalyticsConsent.fullConsent())` on user approval.

**Files**: `lib/core/analytics/domain/analytics_consent.dart`, `lib/common/injectors/main_injector.dart`

---

## P1 — Funnel Gaps (Business-Critical)

### GAP-FUNNEL-001: Registration step tracking not wired
**Events defined**: `RegistrationStepCompletedEvent` exists in `auth_events.dart`
**Wired**: `RegistrationStartedEvent` ✓, `RegistrationSucceededEvent` ✓, `RegistrationFailedEvent` ✓
**Missing**: Step-by-step completion events. The RegistrationBloc currently has only step 1 (`onSubmitRegistrationForm` with `event.step == 1`). Multi-step completion tracking (e.g. per field group) is not fired.
**Effort**: Low — fire `RegistrationStepCompletedEvent(step: event.step)` in `onSaveRegistrationFormToCache` on success.

### GAP-FUNNEL-002: Checkout abandonment not tracked
**Events defined**: `BookingAbandonedEvent` has `step` property.
**Missing**: No call sites for `BookingAbandonedEvent` exist. Users who back out of checkout without completing payment are invisible.
**Effort**: Medium — wire at `WillPopScope`/`onDetach` in checkout screens.

### GAP-FUNNEL-003: Payment flow step-level gaps
**Missing**:
- No event when payment method is auto-selected (vs user-selected)
- `checkout_returned` is defined but verify it is called in the webview return handler
**Effort**: Low

---

## P2 — Security / Privacy Hardening (Deferred)

### GAP-SEC-001: deriveAnalyticsId uses XOR-fold instead of HMAC-SHA256
**File**: `lib/core/analytics/domain/analytics_user_context.dart`
**Issue**: XOR-fold of a UUID has weak collision resistance. An analytics ID collision across users could (in theory) merge Firebase user profiles.
**Fix**: Replace with `HMAC-SHA256(uid, perEnvironmentSecret)`. The secret should come from `AppConfig` so dev/staging/production can't collide.
**Risk**: Low in practice (Firebase User Properties are scoped by Firebase user anyway), but the HMAC approach is correct by design.

---

## P2 — Coverage Gaps by Domain

### GAP-MSG-001: Conversation load error not tracked
The `loadMessages` in `MessagingStore` has a `debugPrint` on error but no analytics event.
Define `MessageLoadFailedEvent` and fire it in the `catch` block.

### GAP-MSG-002: Socket connection state transitions not fully tracked
`RecoverySocketReconnectedEvent` fires on reconnect ✓, but initial socket connect success and deliberate disconnect are not tracked. Add `SocketConnectedEvent` and `SocketDisconnectedEvent` if the messaging team needs funnel data.

### GAP-NOTIF-001: In-app notification list interactions
User opening the notifications list, marking all read, and clearing all are not tracked. Low priority.

### GAP-PROFILE-001: Address update (edit/replace) not tracked
`AddressCreatedEvent` ✓, `AddressDeletedEvent` ✓, `AddressSetPrimaryEvent` ✓ — but updating an existing address has no event. Add `AddressUpdatedEvent`.

### GAP-PROFILE-002: Profile load error not tracked
`loadProfile()` in `ProfileController` has no analytics event on error path. Add `ProfileLoadFailedEvent`.

### GAP-SEARCH-001: Search history interactions not tracked
Users tapping a history suggestion fires `SearchSuggestionSelectedEvent` ✓, but clearing history is not tracked.

### GAP-TRACK-001: Tracking map interaction not tracked
Pan/zoom/re-center actions on the live tracking map are not tracked. Not high priority.

### GAP-BOOK-001: Quote failure not tracked
`BookingQuoteLoadedEvent` covers quote success with `quoteResult` prop, but there is no dedicated error event when the quote API throws. Currently falls through to `BookingFailedEvent` — consider a separate `BookingQuoteFailedEvent` for clarity.

---

## P3 — Observability Traces (Performance)

### TRACE-001: appStartup trace never started
`TraceNames.appStartup` is registered but no call site exists. Wire it in `main.dart` around `WidgetsFlutterBinding.ensureInitialized()` → first frame callback.

### TRACE-002: bookingSubmit trace never started
`TraceNames.bookingSubmit` is registered but not wired in the booking flow. Wire it around the `repo.submitBooking()` call in the booking BLoC/controller.

### TRACE-003: checkoutCreate trace never started
`TraceNames.checkoutCreate` is registered but not wired. Wire it around the checkout session creation API call.

### TRACE-004: supportTicketLoad trace never started
`TraceNames.supportTicketLoad` is registered but not wired in `SupportTicketController.load()`.

### TRACE-005: notificationListLoad trace never started
`TraceNames.notificationListLoad` is registered but not wired in `NotificationsController.load()`.

### TRACE-006: reviewEligibilityCheck trace never started
`TraceNames.reviewEligibilityCheck` is registered but not wired in `ReviewDetailController`.

### TRACE-007: bookingDetailLoad trace never started
`TraceNames.bookingDetailLoad` is registered but not wired in the booking detail fetch.

---

## Already Fixed (this session)

| ID | Description |
|---|---|
| FIX-CON-001 | `defaultConsent()` now returns `essential`-only (PDPA/GDPR compliance) |
| FIX-CON-002 | `fullConsent()` static method added |
| FIX-KEY-001 | All 4 unregistered string literal keys in `auth_events.dart` replaced with `AnalyticsKeys` constants |
| FIX-KEY-002 | `launchType`, `hasSession`, `otpContext`, `logoutTrigger` added to `AnalyticsKeys` |
| FIX-PIPE-001 | Analytics pipeline reordered: PII filter now runs before validator |
| FIX-DEDUP-001 | `dedupKey` added to `RecoveryConnectionRestoredEvent`, `RecoverySocketReconnectedEvent`, `HomeViewedEvent`, `MessagesOpenedEvent` |
| FIX-BUCKET-001 | `CountBucketValues.forCount`: `'10+'` → `'11+'` (≥11 was mislabeled) |
| FIX-AUTH-001 | `SignInFailedEvent` wired at all 6 social auth failure branches (Google + Facebook) |
| FIX-STITCH-002 | `AppLifecycleCoordinator.onResume` wired to `MessagingStore.initForSession()` |
| FIX-STITCH-003 | `SessionGenerationCoordinator.isValid()` guard wired in `_onCheckSession` |
| FIX-SAFETY-001 | Safety analytics events wired in `SafetySupportScreen` and `_SafetyReportForm` |
| FIX-REG-001 | Registration analytics wired: `RegistrationStartedEvent`, `RegistrationSucceededEvent`, `RegistrationFailedEvent` |
| TRACE-WIRE-001 | `homeLoad` trace wired in `HomeStore.loadBookings()` |
| TRACE-WIRE-002 | `searchRequest` trace wired in `SearchController._loadCatalog()` |
| TRACE-WIRE-003 | `conversationLoad` trace wired in `MessagingStore.loadMessages()` |
| TRACE-WIRE-004 | `profileLoad` trace wired in `ProfileController.loadProfile()` |
