# Accessibility Architecture — Servana Client

## Overview

Accessibility support in the Servana Client is provided by four coordinated files under `lib/core/accessibility/`. Together they form a single layer that all presentation widgets reference instead of importing Flutter semantics primitives directly.

```
lib/core/accessibility/
├── accessibility_tokens.dart   — constants + MediaQuery helpers
├── semantics_labels.dart       — all label strings (centralised, l10n-ready)
├── focus_coordinator.dart      — focus lifecycle management
└── live_region_manager.dart    — throttled SemanticsService.announce
```

---

## `AccessibilityTokens`

**Import**: `package:client/core/accessibility/accessibility_tokens.dart`

Provides:
- `minTouchTarget = 44.0` — WCAG 2.5.5 minimum (dp)
- `maxRequiredTextScale = 2.0` — all critical journeys must work at 200% (WCAG 1.4.4)
- `largeTextThreshold = 1.3` — switch to stacked/wrapped layouts above this scale

Static helpers (read from `MediaQuery`):
```dart
AccessibilityTokens.reducedMotion(context)      // MediaQuery.disableAnimations
AccessibilityTokens.screenReaderActive(context)  // MediaQuery.accessibleNavigation
AccessibilityTokens.boldText(context)            // MediaQuery.boldText
AccessibilityTokens.isLargeText(context)         // textScaler.scale(1) >= 1.3
```

Use these instead of reading `MediaQuery` directly in widgets, so thresholds can be adjusted in one place.

---

## `SemanticsLabels`

**Import**: `package:client/core/accessibility/semantics_labels.dart`

All human-readable strings for the semantics tree live here: ~110 constants covering every module. Do not hardcode label strings inside widgets.

Usage:
```dart
// Constant label
Semantics(label: SemanticsLabels.back, button: true, ...)

// Dynamic label
Semantics(
  label: SemanticsLabels.tabMessagesWithUnread(unreadCount),
  ...
)
```

Dynamic generators:
- `SemanticsLabels.tabMessagesWithUnread(int count)`
- `SemanticsLabels.addressCardLabel(label, address, isPrimary, isServiceable)`
- `SemanticsLabels.ratingLabel(int rating, int max, String meaning)`
- `SemanticsLabels.trackingStatus(String status, String? eta)`
- `SemanticsLabels.bookingStep(int step, int total)`

---

## `FocusCoordinator`

**Import**: `package:client/core/accessibility/focus_coordinator.dart`

Use for focus management at screen transitions, dialogs, and form validation.

```dart
// Move focus to a specific node after the next frame
FocusCoordinator.requestFocusPostFrame(context, node: _headingNode);

// Announce a screen change for screen readers (call in initState)
FocusCoordinator.announcePageChange(context, 'Booking details');

// After dialog closes, return focus to the control that opened it
FocusCoordinator.restoreToNode(_openButtonNode);

// After form validation failure, focus the first invalid field
FocusCoordinator.focusFirstError(context, fieldsInOrder: [_emailNode, _passwordNode]);

// Prevent focus leaking across logout
FocusCoordinator.clearStaleFocus(context); // call in dispose()

// Create a focus trap node for modals
final trap = FocusCoordinator.createModalTrap();
```

---

## `LiveRegionManager`

**Import**: `package:client/core/accessibility/live_region_manager.dart`

Wraps `SemanticsService.announce()` with per-message throttling so dynamic content updates (tracking status, unread counts, search result counts) don't overwhelm screen-reader users.

```dart
// Non-urgent updates (default 3 s dedup)
LiveRegionManager.announcePolite('3 services found');

// Urgent — fires immediately regardless of interval
LiveRegionManager.announceAssertive('Session expired. Please sign in again.');

// Convenience helpers
LiveRegionManager.announceResultCount(42);         // "42 services found"
LiveRegionManager.announceTrackingUpdate('En route'); // throttled to 30 s

// Clear throttle state on screen change
LiveRegionManager.clearCache();
```

Note: `SemanticsService.announce()` has no `assertive:` parameter in Flutter — assertive behavior is simulated by sending with no throttle delay.

---

## Widget Patterns

### Interactive control without built-in semantics (GestureDetector / InkWell)

```dart
Semantics(
  label: SemanticsLabels.openMenu,
  button: true,
  excludeSemantics: true,
  child: GestureDetector(
    onTap: _handleTap,
    child: Icon(Icons.menu),
  ),
)
```

### Selectable option tile (color-only state must be supplemented)

```dart
Semantics(
  label: option.name,
  button: true,
  selected: isSelected,
  excludeSemantics: true,
  child: InkWell(onTap: ..., child: ...),
)
```

### IconButton (use tooltip, not Semantics directly)

```dart
IconButton(
  tooltip: SemanticsLabels.back,
  onPressed: () => context.pop(),
  icon: const Icon(Icons.chevron_left),
)
```

### Decorative image or icon

```dart
ExcludeSemantics(child: Image.asset('assets/petal.png'))
// OR: Image.asset('...', semanticLabel: '')
```

### Settings toggle (prevent double-announcement)

Use `SettingsToggleTile` from `settings_tile.dart` — it already applies `excludeSemantics: true` on the outer `Semantics` node and forwards `onTap` to prevent the inner `Switch` from generating a duplicate node.

### Dynamic status that must be auto-announced

```dart
Semantics(
  liveRegion: true,
  child: Text(currentStatus),
)
```

---

## Compliance Target

**WCAG 2.2 Level AA** across all critical journeys:
- 1.3.1 Info and Relationships
- 1.3.3 Sensory Characteristics (no color-only meaning)
- 1.4.1 Use of Color
- 1.4.3 Contrast (minimum 4.5:1)
- 1.4.4 Resize Text (200%)
- 2.1.1 Keyboard / Switch Access
- 2.4.3 Focus Order
- 2.5.3 Label in Name
- 2.5.5 Target Size (44dp)
- 4.1.2 Name, Role, Value
- 4.1.3 Status Messages (live regions)
