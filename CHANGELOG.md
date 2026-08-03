# Changelog — Servana Client

All notable changes to this project are documented here.

---

## [1.0.0+35] — 2026-07-30 (C23 RELEASEFORTRESS+)

### Security
- Firebase iOS bundle identifier corrected in `firebase_options.dart` (`com.servana.client`)
- Android network security config enforces HTTPS-only for api.servana.com.ph
- Android manifest wires `networkSecurityConfig` to production domain
- CI release job added: produces signed AAB on `main` push with keystore injected from secrets

### Accessibility
- All dead C22 accessibility utilities wired: `SemanticsLabels`, `FocusCoordinator.restoreToNode`, `LiveRegionManager.clearCache`
- 7 missing `excludeSemantics: true` added across nav, search, banners, inbox, and bookings
- 7 missing `tooltip:` added to IconButtons
- Nav badge `liveRegion: true` — screen readers announce unread counts
- `ChipContainer` and `MerchantsWidget` now semantically labelled
- Disabled review stars no longer falsely announce `button` role
- `FocusCoordinator` unit test suite added (8 tests)
- Total: 933 tests pass

---

## [1.0.0+34] — C22 ACCESSCORE+

### Accessibility
- WCAG 2.2 Level AA system: `AccessibilityTokens`, `SemanticsLabels`, `FocusCoordinator`, `LiveRegionManager`
- 52 accessibility fixes across 4 core files

---

## [1.0.0+33] — C21 ANALYTICSCORE+

### Analytics
- Firebase Analytics integration with consent gate
- Screen-level event tracking (ScreenAnalyticsObserver)
- Privacy filter: strips PII from analytics events
- Crashlytics: distinguishes fatal vs non-fatal zone errors

---

## [1.0.0+32] — C20 RECOVERYCORE+

### Recovery
- OperationJournal for critical operation persistence
- DraftRepository for form/draft survival across app restart
- ConnectivityMonitor and OfflineBanner
- RetryPolicy with exponential backoff

---

## [1.0.0+31] — C19 REVIEWCORE+

### Reviews
- Review submission flow
- Rating dimensions
- Review history

---

## [1.0.0+30] — C18 SUPPORTCORE+

### Support
- Support ticket creation
- Support ticket detail and thread
- File/image attachment

---

## [1.0.0+29] — C17 PROFILECORE+

### Profile
- Profile viewing and editing
- Address management
- Photo upload

---

## [1.0.0+28] — C16 LIVETRACK+

### Tracking
- Live provider tracking via Google Maps
- Socket.IO room-based tracking updates

---

## [1.0.0+27] — C15 BOOKINGSCORE+

### Bookings
- Booking list with status segments
- Booking detail
- Cancellation flow

---

## [1.0.0+26] — C14 MESSAGECORE+

### Messaging
- Booking conversation inbox
- Real-time chat via Socket.IO
- Unread count badges

---

## [1.0.0+25] — C13 NOTIFYCORE+

### Notifications
- FCM push notification handling
- Foreground notification banner
- Notification navigation coordinator

---

## [1.0.0+24] — C12 SEARCHCORE+

### Search
- Service search with typeahead
- Category browse

---

## [1.0.0+23] — C11 SETTINGSCORE+

### Settings
- Theme preferences
- Notification preferences
- Privacy / legal links
- Analytics consent management
- Logout

---

## [1.0.0+22] — C08-C10 CORETABS / RELEASESWEEP

### Infrastructure
- Bottom navigation shell (CoreTab, MainNavScaffold)
- GoRouter v14 navigation
- PAYFLOW+ payment webview integration

---

## [1.0.0+21] — C01-C07 Baseline

### Foundation
- Authentication (email, Google, Facebook, phone OTP)
- Registration flow
- Home feed with merchant catalog
- Booking creation flow
- Service detail and quote
- Dark mode support
