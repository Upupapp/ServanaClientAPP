import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/presentation/navigation/servana_book_action.dart';
import 'package:client/common/presentation/navigation/servana_curved_nav_painter.dart';
import 'package:client/common/presentation/navigation/servana_nav_item.dart';
import 'package:client/common/presentation/navigation/servana_nav_motion.dart';
import 'package:client/common/presentation/shell/core_tab.dart';

/// Servana's curved main navigation.
///
/// MoveUp contributes the *character* — a curved surface, a raised circular
/// selection, floating depth. It contributes none of the implementation: no
/// `curved_navigation_bar`, no pink, no icon-only tabs, no one-second
/// transition (§1, §2, §30). Everything here is Flutter primitives:
/// `CustomPaint`, `AnimatedPositioned`, `AnimatedScale`, `AnimatedSwitcher`.
///
/// ## Why the active bubble lives here and not in the item
///
/// One bubble travels across the bar. If each [ServanaNavItem] owned its own,
/// four bubbles would cross-fade in place and the cradle beneath would have no
/// continuous target to follow — the surface would appear to blink between
/// shapes rather than yield and release. The bubble and the cradle share one
/// interpolated x, which is what makes the surface look like it is carrying the
/// selection.
///
/// ## Layout
///
/// Five slots, fixed: Home, Bookings, [gap for the Book action], Messages,
/// Profile. The gap is a real slot rather than an overlay so the four tabs
/// cannot drift under the central button as the bar width changes (§28,
/// compact phones).
///
/// This widget renders chrome only. It owns no navigation state, holds no
/// store, and starts no route change — [onTabSelected] and [onBookPressed] are
/// the only ways out, which keeps branch handling in the scaffold where
/// GoRouter can see it (§1, §21).
class ServanaCurvedMainNavigation extends StatelessWidget {
  const ServanaCurvedMainNavigation({
    super.key,
    required this.currentIndex,
    required this.bookingsBadge,
    required this.messagesBadge,
    required this.onTabSelected,
    required this.onBookPressed,
  });

  /// Branch index from `StatefulNavigationShell.currentIndex`. Maps through
  /// [CoreTab] — never a magic integer (§6).
  final int currentIndex;

  final int bookingsBadge;
  final int messagesBadge;

  final ValueChanged<CoreTab> onTabSelected;
  final VoidCallback onBookPressed;

  /// Visual slot for each branch, skipping the centre (§6):
  /// Home 0, Bookings 1, [Book 2], Messages 3, Profile 4.
  static int slotOf(CoreTab tab) {
    switch (tab) {
      case CoreTab.home:
        return 0;
      case CoreTab.bookings:
        return 1;
      case CoreTab.messages:
        return 3;
      case CoreTab.profile:
        return 4;
    }
  }

  static const int _slotCount = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Never pure white in dark mode (§20).
    final surface = isDark ? theme.colorScheme.surface : Colors.white;
    final border =
        isDark ? theme.colorScheme.outlineVariant : ColorPalette.navBorder;
    final shadow = isDark
        ? Colors.black.withOpacity(0.45)
        : const Color(0xFF0B1B4A).withOpacity(0.10);
    final activeColor =
        isDark ? theme.colorScheme.primary : ColorPalette.navActive;

    final activeTab = CoreTab.values.firstWhere(
      (t) => t.index == currentIndex,
      // Cold start or an out-of-range restore lands on Home rather than
      // animating from an uninitialised slot (§22).
      orElse: () => CoreTab.home,
    );

    final reduced = ServanaNavMotion.reduced(context);
    final duration = ServanaNavMotion.selectionFor(context);

    // Bottom inset read once here and applied once, so it is never
    // double-counted by an inner SafeArea (§15).
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return RepaintBoundary(
      child: SizedBox(
        // Reserves the BAR only — not the headroom the raised bubble and Book
        // action occupy. Scaffold reserves exactly this height for page
        // content, so reserving the headroom too left a ~40pt dead band above
        // the bar where nothing was drawn and nothing could scroll.
        //
        // The bubble and Book action overflow upward out of these bounds via
        // the Stack's Clip.none, so they still float above the surface without
        // pushing the page away from it.
        height: ServanaNavMotion.barHeight + bottomInset,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final slotWidth = width / _slotCount;

            // Clamped away from both edges (§5: "do not allow the bubble to
            // clip against the screen edge").
            //
            // Five equal slots put the Home and Profile centres at 10% and 90%
            // of the width. On a 390pt phone that leaves the 52pt bubble
            // straddling the bar's own 24pt corner radius — it does not run
            // off-screen, but it sits ON the corner, and the cradle beneath it
            // has no flat edge left to dip into. Verified on a 390x844
            // emulator: the Home bubble overlapped the rounded corner.
            //
            // The minimum keeps a bubble radius plus the corner radius clear of
            // each end, so the surface always has straight edge to curve from.
            final minCentre = (ServanaNavMotion.bubbleDiameter / 2) +
                ServanaNavMotion.surfaceRadius * 0.5;
            final rawCentreX = (slotOf(activeTab) + 0.5) * slotWidth;
            final activeCentreX =
                rawCentreX.clamp(minCentre, width - minCentre).toDouble();
            // The surface starts at the widget's own top edge now; raised
            // elements sit at negative offsets and overflow upward.
            const topPad = 0.0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Surface ────────────────────────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  top: topPad,
                  bottom: 0,
                  // TweenAnimationBuilder interpolates from its CURRENT value
                  // to each new `end`, so the cradle follows the bubble on
                  // every change. `begin` only matters on the first build,
                  // where matching `end` means the bar paints in place rather
                  // than sliding in from the left on cold start (§22).
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: activeCentreX, end: activeCentreX),
                    duration: duration,
                    curve: ServanaNavMotion.selectionCurve,
                    builder: (context, x, _) => CustomPaint(
                      painter: ServanaCurvedNavPainter(
                        cradleCentreX: x,
                        surfaceColor: surface,
                        shadowColor: shadow,
                        borderColor: border,
                        showCradle: !reduced,
                      ),
                    ),
                  ),
                ),

                // ── Tab cells ──────────────────────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  top: topPad,
                  bottom: bottomInset,
                  child: Row(
                    children: [
                      ServanaNavItem(
                        tab: CoreTab.home,
                        isActive: activeTab == CoreTab.home,
                        badge: 0,
                        onTap: () => onTabSelected(CoreTab.home),
                      ),
                      ServanaNavItem(
                        tab: CoreTab.bookings,
                        isActive: activeTab == CoreTab.bookings,
                        badge: bookingsBadge,
                        onTap: () => onTabSelected(CoreTab.bookings),
                      ),
                      // Centre slot: reserved, never a destination.
                      Expanded(child: Container()),
                      ServanaNavItem(
                        tab: CoreTab.messages,
                        isActive: activeTab == CoreTab.messages,
                        badge: messagesBadge,
                        onTap: () => onTabSelected(CoreTab.messages),
                      ),
                      ServanaNavItem(
                        tab: CoreTab.profile,
                        isActive: activeTab == CoreTab.profile,
                        badge: 0,
                        onTap: () => onTabSelected(CoreTab.profile),
                      ),
                    ],
                  ),
                ),

                // ── Travelling active bubble ───────────────────────────────
                AnimatedPositioned(
                  duration: duration,
                  curve: ServanaNavMotion.selectionCurve,
                  left: activeCentreX - (ServanaNavMotion.bubbleDiameter / 2),
                  top: -ServanaNavMotion.bubbleLift,
                  child: IgnorePointer(
                    // The cell underneath handles the tap, so the bubble must
                    // not become a second hit target or a duplicate semantic
                    // node (§17).
                    child: _ActiveBubble(
                      tab: activeTab,
                      color: activeColor,
                      surface: surface,
                      reduced: reduced,
                      badge: switch (activeTab) {
                        CoreTab.bookings => bookingsBadge,
                        CoreTab.messages => messagesBadge,
                        _ => 0,
                      },
                    ),
                  ),
                ),

                // ── Central Book action ────────────────────────────────────
                Positioned(
                  left: (width / 2) - (ServanaNavMotion.bookDiameter / 2),
                  // Half above the bar, half on it — the classic raised
                  // centre action.
                  top: -(ServanaNavMotion.bookDiameter / 2),
                  child: ServanaBookAction(onPressed: onBookPressed),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The raised circle carrying the selected destination's filled icon.
class _ActiveBubble extends StatelessWidget {
  const _ActiveBubble({
    required this.tab,
    required this.color,
    required this.surface,
    required this.reduced,
    required this.badge,
  });

  final CoreTab tab;
  final Color color;
  final Color surface;
  final bool reduced;

  /// Count for the SELECTED destination.
  ///
  /// The badge rides on the bubble rather than disappearing while its tab is
  /// active. §13 forbids drawing it behind the raised bubble; simply not
  /// drawing it would satisfy that wording and still lose the information —
  /// a customer on the Bookings tab with two payments outstanding would see no
  /// count at all. It moves with the bubble instead.
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ServanaNavMotion.bubbleDiameter,
      height: ServanaNavMotion.bubbleDiameter,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: AnimatedSwitcher(
              // Cross-fade the glyph as the bubble arrives, so the icon changes
              // during the travel rather than snapping on landing (§8).
              duration: reduced
                  ? const Duration(milliseconds: 1)
                  : ServanaNavMotion.selection,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Icon(
                tab.activeIcon,
                key: ValueKey(tab),
                color: Colors.white,
                size: ServanaNavMotion.iconSize *
                    ServanaNavMotion.activeIconScale,
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: ServanaNavBadge(count: badge),
            ),
        ],
      ),
    );
  }
}
