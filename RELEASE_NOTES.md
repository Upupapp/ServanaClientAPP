# Release Notes — Servana v1.0.0 (Build 35)

Thank you for using Servana. Here's what's improved in this release.

---

## What's New

### Better Accessibility
- Screen readers now correctly describe booking actions, ratings, and navigation badges
- Improved focus management when dialogs open and close
- Unread message counts are announced to screen readers as they update

### Stability
- Improved reliability when switching between accounts
- Better handling of network timeouts and reconnections
- Offline mode correctly shows cached booking history

### Security
- Network connections to Servana servers now always use encrypted HTTPS
- Analytics data cannot include personal information (filtered at source)

---

## Fixes

- Rating stars no longer incorrectly announce themselves as tappable when disabled
- Fixed an issue where focus could be lost after dismissing a dialog
- Improved accessibility labels on booking and message cards

---

## Known Limitations

- Google Maps in-app requires a device with Google Play Services
- Live provider tracking requires an active internet connection
- In-app update prompt is only available for Play Store installs

---

## Backend Requirements

This release requires Servana backend v1.0+. The following capabilities must be available:
- `POST /api/auth/signin`
- `GET /api/bookings`
- `GET /api/catalog`
- `POST /api/job-orders`
- `GET /api/notifications`
- Socket.IO at production endpoint

---

## Privacy

Servana collects minimal data to operate the service. See our Privacy Policy for details. Analytics are opt-in and can be revoked in Settings → Privacy.
