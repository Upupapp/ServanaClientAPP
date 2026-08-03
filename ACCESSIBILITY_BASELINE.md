# Accessibility Baseline — Servana Client (C22 V1 ACCESSCORE+)

**Standard**: WCAG 2.2 Level AA  
**Audit date**: 2026-07-30  
**Committed**: HEAD after C22 commit  
**Flutter version**: 3.x (Dart 3.3+, null-safe)

---

## Summary

| Severity | Found | Fixed in C22 | Deferred |
|----------|-------|-------------|----------|
| P0 (launch blocker) | 1 | 1 | 0 |
| P1 (critical) | 21 | 21 | 0 |
| P2 (significant) | 25 | 25 | 0 |
| P3 (minor) | 5 | 5 | 0 |
| **Total** | **52** | **52** | **0** |

---

## P0 Findings (Fixed)

### P0-1: Foreground notification banner close button — no label, tiny target
- **File**: `lib/modules/notifications/` (foreground banner widget)
- **Issue**: `GestureDetector + Icon(Icons.close_rounded)` had no semantic label and a touch target well below 44dp.
- **Fix**: Added `Semantics(label: 'Dismiss notification', button: true, excludeSemantics: true)`, sized to `SizedBox(44×44)`.
- **WCAG**: 2.5.3 Label in Name, 2.5.5 Target Size

---

## P1 Findings (Fixed)

### Auth Screen
- **P1-1**: Password visibility toggle — no semantic label, relied on icon alone.  
  Fix: `Semantics(label: _obscureText ? 'Show password' : 'Hide password', button: true, excludeSemantics: true)`
- **P1-2**: "Forgot password?" GestureDetector — not announced as interactive.  
  Fix: `Semantics(button: true, label: 'Forgot password', excludeSemantics: true)`
- **P1-3**: "Create account" link — same issue.  
  Fix: `Semantics(button: true, label: 'Create an account', excludeSemantics: true)`

### Home
- **P1-4**: Menu icon GestureDetector — no label.  
  Fix: `Semantics(label: 'Open navigation menu', button: true, excludeSemantics: true)`
- **P1-5**: Notification bell — badge count not announced.  
  Fix: Dynamic label: `'View $n notifications'` or `'View notifications'` when count=0.
- **P1-6**: Category tile GestureDetectors — no label or role.  
  Fix: `Semantics(label: cat.label, button: true, hint: 'Browse ${cat.label} services', excludeSemantics: true)`

### Search
- **P1-7**: Back arrow — no label.  
  Fix: `Semantics(label: 'Go back', button: true, excludeSemantics: true)`
- **P1-8**: Notifications icon — no label.  
  Fix: `Semantics(label: 'View notifications', button: true, excludeSemantics: true)`
- **P1-9**: History item remove (×) icon — no label.  
  Fix: Dynamic label: `'Remove "${term}" from history'`
- **P1-10**: Category filter chips — color-only selected state.  
  Fix: `Semantics(selected: isSelected, ...)`
- **P1-11**: Sort button — no label.  
  Fix: `Semantics(label: 'Sort results', button: true, excludeSemantics: true)`

### Booking Flow
- **P1-12**: Aircon/BW option tiles — color-only selection, no semantics.  
  Fix: `Semantics(label: optionName, button: true, selected: isSelected, excludeSemantics: true)`
- **P1-13**: Checkout address tiles — no semantics.  
  Fix: `Semantics(label: 'Select ${label} address', button: true, selected: isSelected, excludeSemantics: true)`
- **P1-14**: Payment method tile — color-only selection.  
  Fix: `Semantics(label: methodName, button: true, selected: isSelected, excludeSemantics: true)`
- **P1-15**: Schedule picker — no label.  
  Fix: `Semantics(label: 'Choose service schedule', button: true, excludeSemantics: true)`

### Notifications
- **P1-16**: Notification card — outer GestureDetector had no semantic label.  
  Fix: Dynamic label from title + body; unread prefix if unread.
- **P1-17**: Mark-read control — no label, small target.  
  Fix: `Semantics(label: 'Mark as read', button: true, excludeSemantics: true)`

### Job Order
- **P1-18**: Multiple `IconButton` widgets without `tooltip`.  
  Fix: Added `tooltip:` to all 5 unlabeled icon buttons.

### Messaging
- **P1-19**: Messages inbox notification bell — no label.  
  Fix: `Semantics(label: 'View notifications', button: true, excludeSemantics: true)`
- **P1-20**: Chat back button — no tooltip.  
  Fix: `tooltip: 'Go back'`

### Tracking
- **P1-21**: Google Map widget — zero text alternative, inaccessible to TalkBack/VoiceOver.  
  Fix: `Semantics(label: 'Live tracking map. Provider location shown visually.')` wrapper + tracking status liveRegion.

---

## P2 Findings (Fixed)

- SettingsToggleTile double-announcement (outer Semantics + inner Switch both fire) → `excludeSemantics: true` + forwarded `onTap`
- Profile photo GestureDetector — no label → `'Change profile photo'`
- Verified email checkmark — decorative announced incorrectly → `Semantics(label: 'Email verified')`
- Date-of-birth GestureDetector — no role or hint → `Semantics(button: true, hint: 'Opens date picker')`
- Gender option InkWell — color-only selected state → `Semantics(selected: isSelected)`
- Review star GestureDetectors — no labels or selected state → labeled per dimension
- Review visibility selector — color-only selection
- Tracking status bar — status changes not announced → `liveRegion: true`
- Tracking staleness dot — decorative noise → `ExcludeSemantics`
- Tracking provider card — map centering button no label → `'Centre map on provider'`
- Bookings segment chip — count not announced → label includes unread count
- Booking detail refresh button — no tooltip → `tooltip: 'Refresh booking'`
- Booking detail dismiss-error icon — no label
- Store items back button — no tooltip → `tooltip: 'Go back'`
- Support home — unread count not in label
- Support ticket detail — error not live region
- Search clear-search icon — no label → `'Clear search'`
- Chat retry-message GestureDetector — no label → `'Retry sending this message'`
- Bookings notifications icon — no label
- (Various others across checkout and details screens)

---

## P3 Findings (Fixed)

- Splash screen petal `Image.asset` widgets — decorative noise → `ExcludeSemantics`
- Drawer item icons — decorative → `semanticsLabel: ''`
- Consent sheet drag handle — decorative → `ExcludeSemantics`
- Consent sheet `_ConsentPoint` icons — decorative (text label suffices) → `ExcludeSemantics`
- Empty state illustration images — decorative → `ExcludeSemantics`

---

## Architecture Changes (C22)

New files under `lib/core/accessibility/`:

| File | Purpose |
|------|---------|
| `accessibility_tokens.dart` | Constants: `minTouchTarget=44`, `maxRequiredTextScale=2.0`; MediaQuery helpers |
| `semantics_labels.dart` | ~110 centralized string constants; dynamic label generators |
| `focus_coordinator.dart` | `requestFocusPostFrame`, `focusFirstError`, `restoreToNode`, `announcePageChange`, `createModalTrap` |
| `live_region_manager.dart` | Throttled `SemanticsService.announce` with per-message dedup; `announceTrackingUpdate` (30s throttle) |

---

## Known Remaining Gaps (Post-C22)

See `ACCESSIBILITY_KNOWN_GAPS.md`.
