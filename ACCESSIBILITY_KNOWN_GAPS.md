# Accessibility Known Gaps — Servana Client

Gaps explicitly deferred from C22 V1 ACCESSCORE+, with rationale and owner.

---

## Color contrast ratios (not audited in C22)

**WCAG**: 1.4.3 Contrast (Minimum) — 4.5:1 for normal text, 3:1 for large text / UI components

**Status**: Design token palette not profiled with a contrast checker in C22.

**Risk**: Low–medium. The palette uses `ColorPalette.primaryColorDark` (dark navy/blue) against white backgrounds, likely meeting 4.5:1, but the light-mode secondary text (`accentText`) on `secondaryBackground` has not been verified.

**Action for C23**: Run `flutter_test_accessibility` or profile `ColorPalette` values against WCAG contrast tables. Fix any failures before public release.

---

## Physical device TalkBack / VoiceOver validation

**WCAG**: 4.1.2 Name, Role, Value

**Status**: All semantic annotations verified via `flutter analyze` and static review. No physical-device screen reader test run exists yet.

**Risk**: Medium. Flutter's `Semantics` tree does not always map 1:1 to what TalkBack/VoiceOver announce — merged nodes, platform quirks, and traversal order can differ from static analysis.

**Action for C23**: Run a TalkBack swipe-through on Android for the auth → home → booking → payment → tracking → messaging critical path. Run a VoiceOver swipe-through on iOS for the same path. Fix any announcement-order or label surprises before launch.

---

## Switch Access / keyboard traversal order

**WCAG**: 2.1.1 Keyboard, 2.4.3 Focus Order

**Status**: `FocusCoordinator` utilities are in place, but no explicit `FocusOrder` or `FocusTraversalGroup` widgets have been added to screens.

**Risk**: Low for sighted-touch; medium for switch access users. Default Flutter traversal (left-to-right, top-to-bottom) is usually correct.

**Action for C23**: Add `FocusTraversalGroup(policy: OrderedTraversalPolicy(), ...)` to any screen where traversal order is non-obvious (booking checkout with a sidebar).

---

## Offline / connectivity error announcements

**WCAG**: 4.1.3 Status Messages

**Status**: The connectivity change is displayed visually; `LiveRegionManager.announceAssertive` exists but is not wired to the `ConnectivityStore` observer.

**Action**: Wire `LiveRegionManager.announceAssertive(SemanticsLabels.offline)` and `LiveRegionManager.announcePolite(SemanticsLabels.reconnected)` to connectivity state changes in `ConnectivityStore`.

---

## Payment WebView accessibility

**WCAG**: 4.1.2 Name, Role, Value

**Status**: The payment flow enters a `WebView` (PayMongo / GCash). The web content inside the WebView is not under app control.

**Risk**: Medium. Users relying on TalkBack/VoiceOver may encounter payment pages that are not screen-reader accessible.

**Action**: Document the payment provider's own accessibility status. If the provider is not accessible, add a fallback that notifies the user before they enter the WebView.

---

## Large text (>200%) layout verification

**WCAG**: 1.4.4 Resize Text

**Status**: `AccessibilityTokens.maxRequiredTextScale = 2.0` is defined and all containers reviewed. No fixed-height `SizedBox` wrappers wrapping text were found in the booking flow. However, a comprehensive 200% screenshot review has not been run on a physical device or emulator.

**Action for C23**: Boot an emulator with "Largest" font size setting and swipe through all critical screens; capture screenshots; verify nothing clips.

---

## Missing analytics `SignInFailedEvent` (pre-existing P1 deferred from C21)

**File**: `lib/modules/authentication/` — 6 social auth failure branches

**Status**: Deferred from C21 ANALYTICSCORE+ analytics gap backlog (ANALYTICS_GAPS.md). Not an accessibility issue but tracked here for completeness as it was raised in the same session.

**Action**: Wire `SignInFailedEvent` to the 6 social auth catch blocks.

---

## AppLifecycleCoordinator.onResume wiring (STITCH-C20-POST-002)

**Status**: Deferred from C20 backend stitch. Not an accessibility issue.

**Action**: Wire `onResume` callback in `AppLifecycleCoordinator`.
