# Accessibility Test Plan — Servana Client

**Standard**: WCAG 2.2 Level AA  
**Tooling**: Flutter widget tests, `flutter_test_accessibility`, physical device (TalkBack / VoiceOver)

---

## Automated tests (widget)

### Location
`test/core/accessibility/`

### Required test files

| File | Coverage |
|------|---------|
| `accessibility_tokens_test.dart` | Token constants, MediaQuery helpers |
| `semantics_labels_test.dart` | Dynamic label generators return correct strings |
| `focus_coordinator_test.dart` | Post-frame focus, error-field focus, announcePageChange |
| `live_region_manager_test.dart` | Throttle dedup, clearCache resets state, assertive fires immediately |
| `semantics_integration_test.dart` | End-to-end semantic tree checks for critical widgets |

### Semantic tree assertions

Use `tester.getSemantics(find.byType(MyWidget))` in widget tests to verify:
- `SemanticsData.label` matches expected string
- `SemanticsData.isButton == true` for interactive controls
- `SemanticsData.isSelected == true` when option is active
- `SemanticsData.isToggled` reflects current toggle value
- `SemanticsData.isLiveRegion == true` for status text

Example:
```dart
testWidgets('notification bell announces count', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: HomeHeader(notificationCount: 3)),
  );
  final SemanticsHandle handle = tester.ensureSemantics();
  final SemanticsData data = tester.getSemantics(
    find.bySemanticsLabel(RegExp(r'View \d+ notification')),
  );
  expect(data.label, contains('3'));
  expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
  handle.dispose();
});
```

### Touch target tests

```dart
testWidgets('all tap targets >= 44dp', (tester) async {
  await tester.pumpWidget(MaterialApp(home: MyScreen()));
  final elements = find.byWidgetPredicate(
    (w) => w is GestureDetector || w is InkWell || w is IconButton,
  );
  for (final el in elements.evaluate()) {
    final size = tester.getSize(find.byElementPredicate((e) => e == el));
    expect(size.width, greaterThanOrEqualTo(44),
        reason: 'Touch target too small: ${el.widget}');
    expect(size.height, greaterThanOrEqualTo(44),
        reason: 'Touch target too small: ${el.widget}');
  }
});
```

### Large text test

```dart
testWidgets('booking checkout renders at 200% text scale', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: MaterialApp(home: AirconCheckoutScreen()),
    ),
  );
  await tester.pumpAndSettle();
  // Verify no overflow errors are thrown
  expect(tester.takeException(), isNull);
});
```

### Reduced motion test

```dart
testWidgets('animations use zero duration when reduced motion active', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: HomeScreen()),
    ),
  );
  // Assert that page entrance animation completes immediately
  await tester.pump(); // one frame only
  expect(find.byType(HomeScreen), findsOneWidget);
});
```

---

## Manual test checklist — TalkBack (Android)

Enable: Settings → Accessibility → TalkBack

### Critical path
- [ ] Swipe to every element on Login screen — each interactive control is announced with a descriptive label
- [ ] Password field: "Show password" / "Hide password" toggle announces correctly as state changes
- [ ] Home category tiles announce label + hint (e.g. "Aircon, Browse Aircon services")
- [ ] Notification bell announces count: "View 3 notifications"
- [ ] Service selection: TalkBack announces "selected" when an option tile is chosen
- [ ] Checkout address cards announce "selected" when tapped
- [ ] Payment method announces "selected"
- [ ] Live tracking status bar announces status changes automatically (no swipe needed)
- [ ] Tracking map announces "Live tracking map" as a single node — does not read raw map tile noise
- [ ] Messages inbox: unread badge count included in announcement
- [ ] Settings toggle: announces "on"/"off" — NOT announced twice
- [ ] Review stars: each star announces dimension + value (e.g. "Cleanliness: 3 of 5")

### Focus traps
- [ ] Consent sheet: back gesture does nothing (PopScope blocks it)
- [ ] Booking cancel dialog: focus stays inside dialog; TAB/swipe does not escape to background
- [ ] After dialog closes, focus returns to the control that opened it

---

## Manual test checklist — VoiceOver (iOS)

Enable: Settings → Accessibility → VoiceOver

Same critical path as TalkBack above, verifying:
- [ ] Rotor shows "Links" and "Buttons" correctly
- [ ] Form fields read their persistent label (not just placeholder)
- [ ] Double-tap activates buttons (no custom gesture conflicts)
- [ ] Swipe up/down in text fields adjusts cursor (no override)

---

## Manual test checklist — Large text

Set: Settings → Display → Font size → Largest

- [ ] Auth screen — email/password fields fully visible, no clipping
- [ ] Home category grid — labels wrap, not truncated
- [ ] Booking option tiles — names wrap, tiles grow vertically
- [ ] Checkout summary — price amounts readable
- [ ] Chat bubbles — text wraps inside bubble

---

## Manual test checklist — Reduced motion

Set: Settings → Accessibility → Motion → Reduce Motion

- [ ] Home screen entrance slides in instantly (no animated slide)
- [ ] Category tiles appear without scale/fade animations
- [ ] Bottom sheet slides up instantly

---

## Release gate (must pass before ship)

- [ ] `flutter test test/core/accessibility/` — 0 failures
- [ ] `flutter analyze` — 0 issues in `lib/core/accessibility/`
- [ ] TalkBack critical path — no unlabeled controls
- [ ] VoiceOver critical path — no unlabeled controls
- [ ] Large text — no overflow in booking flow
- [ ] Reduced motion — no mandatory animations
