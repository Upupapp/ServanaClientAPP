# Layout patterns that broke this app

**Written 2026-08-20, after a sweep that found and fixed 34 defects.**

Every one was **silent in a release build**. In debug an overflow paints the
yellow-and-black hatching and throws, which is loud. In release it does
neither: the content is simply clipped. Nobody gets an error report; the
customer just sees less than was written.

Three root causes account for nearly all of them. They are worth recognising by
shape, because the same three keep being written.

---

## 1. A bare `Text` inside a `Row` — about twenty instances

```dart
// WRONG
Row(children: [
  Icon(Icons.calendar_month_rounded),
  const SizedBox(width: 12),
  Text(someLabel),          // demands its full intrinsic width
]),
```

The `Text` asks for whatever width it needs and the `Row` has no way to refuse.
It looks fine on the phone the developer used and clips on a smaller one, or at
a larger text scale.

```dart
// RIGHT
Row(children: [
  Icon(Icons.calendar_month_rounded),
  const SizedBox(width: 12),
  Expanded(child: Text(someLabel)),
]),
```

Use **`Flexible`** rather than `Expanded` when the `Row` is
`mainAxisSize: MainAxisSize.min` — a button, for instance — so a short label
still lets the row hug it.

**Worst instances found:** `"Continue with Facebook"` on the sign-in screen
(122px over **at text scale 1.0**, the default), `"Distance From Office"` in the
booking sheet (386px at 1.3), `"Create your Account"` (90px at 1.0).

---

## 2. Bounding only ONE side of a row — three instances, and the sneakiest

```dart
// WRONG — and it LOOKS fixed
Row(children: [
  Expanded(child: Text(label)),   // bounded ✓
  const Gap(10),
  Text(value),                    // still unbounded ✗
]),
```

This is the one that hides. Someone has already written `Expanded`, so the row
reads as handled — but the value beside it grows too, and the row overflows
anyway. Found in the `Payment:` row of the booking sheet (13px), the shared
`settings_tile` (8.8px **at scale 1.0**), and the welcome screen's top bar.

**If both sides of a row can grow, both have to be able to give.**

---

## 3. A fixed-size box, or a `Column`, around content that scales

```dart
// WRONG
SizedBox(
  width: 180,
  height: 180,                    // the text inside grows; this does not
  child: Column(children: [Icon(...), Text(...), Text(...)]),
),
```

Use a **minimum** instead of a fixed size:

```dart
// RIGHT
ConstrainedBox(
  constraints: const BoxConstraints(minWidth: 180, minHeight: 180),
  child: Column(mainAxisSize: MainAxisSize.min, children: [...]),
),
```

The same applies to grid cells. `SliverGridDelegateWithFixedCrossAxisCount`
defaults to `childAspectRatio: 1.0` — square cells that never grow with the
text inside them. The booking calendar had **every one of its 27+ day cells**
overflowing at scale 1.3. Scale the extent instead:

```dart
mainAxisExtent: MediaQuery.textScalerOf(context).scale(44),
```

---

## When a whole screen does not fit

A `Column` whose fixed children already exceed the viewport overflows no matter
what its flexible children do. Three screens had this: `WelcomeScreen`,
`AccountPendingForApprovalScreen`, `AuthenticationGateScreen`.

**If the Column has NO flex children**, a plain scroll view is enough:

```dart
SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, ...))
```

**If it has `Expanded` or `Spacer` children**, a bare `SingleChildScrollView`
will THROW — those need a bounded height and a scroll view gives them infinity.
Use the scroll-or-fill pattern:

```dart
LayoutBuilder(
  builder: (context, constraints) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: IntrinsicHeight(
        child: Column(...),   // Expanded and Spacer both work here
      ),
    ),
  ),
)
```

Getting this wrong is expensive rather than merely wrong: wrapping a `Column`
containing a `Spacer` took one screen from 3 failing combinations to 9, and a
mis-targeted `Expanded` took another from 6 exceptions to 19.

---

## How these were found, and how to keep finding them

`test/presentation/screen_viewport_matrix_test.dart` renders whole screens at
three real handset sizes and three text scales, including **2.0**, which
`AccessibilityTokens.maxRequiredTextScale` declares supported. Coverage went
from 11 screens to 56 during this sweep.

Two things about it are worth preserving:

- **Add screens with EMPTY data where you can.** The empty state is what a
  customer meets when the backend cannot answer, and on 2026-08-19 that was
  every request for several hours. `ServiceCategoryListScreen`'s defect was in
  its empty state: a fixed 180px illustration above growing text, so the message
  explaining why the list was empty is the part that got clipped.
- **The failure message must name the real exception.** It once reported every
  exception as an overflow, so a missing DI registration read as
  *"overflowed at 390x844 … silent clipping"*. Two screens were briefly believed
  broken that were not. A harness that asserts a cause it does not know wastes
  more time than the bug.

**Where the risk actually is:** every one of the 34 defects came from older
hand-built screens — the booking and job-order flows, the auth funnel, the
settings tiles, the shared buttons. The last thirteen screens added to the
matrix, all repository-backed and newer, produced none.
