# Accessibility Component Guide — Servana Client

Quick reference: how each common widget type should be annotated for WCAG 2.2 AA compliance.

---

## Rules at a glance

| Pattern | Correct approach |
|---------|-----------------|
| `GestureDetector` | Wrap with `Semantics(button: true, label: ..., excludeSemantics: true)` |
| `InkWell` | Same as GestureDetector |
| `IconButton` | Always set `tooltip:` |
| Selectable tile | `Semantics(selected: isSelected, ...)` |
| Live status text | `Semantics(liveRegion: true, child: Text(...))` |
| Decorative image/icon | `ExcludeSemantics(child: ...)` or `Image.asset(semanticLabel: '')` |
| Section heading | `Semantics(header: true, child: Text(...))` |
| `SettingsToggleTile` | Already correct — do not add extra Semantics |

---

## Navigation controls

### Back / close button
```dart
// Preferred: IconButton with tooltip
IconButton(
  tooltip: SemanticsLabels.back,
  onPressed: () => context.pop(),
  icon: const Icon(Icons.chevron_left),
)

// Legacy: plain GestureDetector
Semantics(
  label: SemanticsLabels.back,
  button: true,
  excludeSemantics: true,
  child: GestureDetector(onTap: () => context.pop(), child: Icon(Icons.chevron_left)),
)
```

### Bottom navigation tab with badge
```dart
// In BottomNavigationBarItem:
BottomNavigationBarItem(
  icon: Icon(Icons.message),
  label: unread > 0
      ? SemanticsLabels.tabMessagesWithUnread(unread)
      : SemanticsLabels.tabMessages,
)
```

---

## Interactive tiles

### Booking option tile (single-select)
```dart
Semantics(
  label: option.name,
  button: true,
  selected: isSelected,
  excludeSemantics: true,
  child: InkWell(
    onTap: () => _selectOption(option),
    child: Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.white,
        // color alone is never enough — semantics.selected covers it
      ),
      ...
    ),
  ),
)
```

### Address selection card
```dart
Semantics(
  label: SemanticsLabels.addressCardLabel(
    address.label, address.line1, address.isPrimary, address.isServiceable,
  ),
  button: true,
  selected: isSelected,
  excludeSemantics: true,
  child: InkWell(onTap: ..., child: ...),
)
```

---

## Form fields

### Custom text field (CustomTextField)
The `CustomTextField` widget wraps Flutter `TextField`. Ensure:
1. The `label:` parameter is always set (not just `hintText`).
2. Use `textInputAction` to chain fields (`TextInputAction.next`).
3. Pass `focusNode:` so `FocusCoordinator.focusFirstError` can navigate on validation.

```dart
CustomTextField(
  label: SemanticsLabels.fieldEmail,
  hintText: 'you@example.com',
  focusNode: _emailNode,
  textInputAction: TextInputAction.next,
)
```

### Date / picker fields
```dart
Semantics(
  label: SemanticsLabels.fieldDateOfBirth,
  button: true,
  hint: 'Opens date picker',
  excludeSemantics: true,
  child: GestureDetector(onTap: _openDatePicker, child: ...),
)
```

---

## Modals and bottom sheets

### Focus on open
```dart
@override
void initState() {
  super.initState();
  FocusCoordinator.requestFocusPostFrame(context, node: _firstFieldNode);
}
```

### Focus restore on close
```dart
// Before opening the sheet:
final openerNode = FocusScope.of(context).focusedChild;

// After the sheet closes:
FocusCoordinator.restoreToNode(openerNode as FocusNode?);
```

### Non-dismissible safety modal
```dart
showModalBottomSheet(
  isDismissible: false,
  enableDrag: false,
  context: context,
  builder: (_) => PopScope(
    canPop: false,
    child: MySheet(),
  ),
)
```

---

## Status and live regions

### Tracking status (auto-announces changes)
```dart
Semantics(
  liveRegion: true,
  child: Text(
    SemanticsLabels.trackingStatus(status, eta),
    style: ...,
  ),
)
```

### Search result count (announced once per search)
```dart
// Call after results load:
LiveRegionManager.announceResultCount(results.length);
```

### Error messages
```dart
Semantics(
  liveRegion: true,
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: errorMessage != null
        ? Text(errorMessage!, key: ValueKey(errorMessage))
        : const SizedBox.shrink(),
  ),
)
```

---

## Maps

All `GoogleMap` widgets must have a text alternative accessible to screen readers:

```dart
Semantics(
  label: SemanticsLabels.trackingMapSummary,
  child: GoogleMap(
    onMapCreated: _onMapCreated,
    initialCameraPosition: ...,
  ),
)
```

Additionally, in the same view, show a text summary of the tracked state for users who cannot perceive the map:

```dart
if (AccessibilityTokens.screenReaderActive(context))
  _TrackingTextSummary(status: status, eta: eta, providerName: providerName),
```

---

## Ratings and stars

```dart
// Individual star tap target
for (int i = 0; i < 5; i++)
  Semantics(
    label: SemanticsLabels.ratingLabel(i + 1, 5, SemanticsLabels.ratingMeaning(i + 1)),
    button: true,
    selected: rating == i + 1,
    hint: SemanticsLabels.ratingHint(rating),
    excludeSemantics: true,
    child: GestureDetector(
      onTap: () => onRatingChanged(i + 1),
      child: Icon(
        rating > i ? Icons.star : Icons.star_border,
        size: AccessibilityTokens.minTouchTarget,
      ),
    ),
  )
```

---

## Reduced motion

Wrap any `AnimationController`-driven widget:

```dart
final duration = AccessibilityTokens.reducedMotion(context)
    ? Duration.zero
    : const Duration(milliseconds: 300);
```

Or in a `StatefulWidget`:

```dart
@override
Widget build(BuildContext context) {
  final reduced = AccessibilityTokens.reducedMotion(context);
  return AnimatedOpacity(
    opacity: _visible ? 1.0 : 0.0,
    duration: reduced ? Duration.zero : const Duration(milliseconds: 250),
    child: child,
  );
}
```

---

## Text scaling

Never use fixed heights for containers that hold user-generated or dynamic text:

```dart
// Wrong — clips at 200% text scale
SizedBox(height: 40, child: Text(label))

// Correct — grows with text
Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Text(label),
)
```

For card layouts that must be a fixed height for visual consistency, use `constraints` with a minimum:

```dart
ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 64),
  child: Text(label),
)
```
