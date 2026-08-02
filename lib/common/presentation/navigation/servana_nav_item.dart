import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/navigation/servana_nav_motion.dart';
import 'package:client/common/presentation/shell/core_tab.dart';

/// One destination in the curved navigation.
///
/// Renders the label and badge only. The raised bubble and its icon are drawn
/// by the parent as a single travelling widget — if each item drew its own
/// bubble, four of them would cross-fade past each other instead of one moving,
/// and the cradle would have nothing continuous to follow.
///
/// Semantics: exactly one node per destination (§17). `excludeSemantics` stops
/// the icon and label announcing separately, and the badge is folded into the
/// label by `CoreTab.semanticLabel` rather than being a node of its own.
class ServanaNavItem extends StatelessWidget {
  const ServanaNavItem({
    super.key,
    required this.tab,
    required this.isActive,
    required this.badge,
    required this.onTap,
  });

  final CoreTab tab;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = isDark ? scheme.primary : ColorPalette.navActive;
    final inactiveColor =
        isDark ? scheme.onSurfaceVariant : ColorPalette.navInactive;
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: Semantics(
        label: tab.semanticLabel(badge: badge),
        button: true,
        selected: isActive,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          // Whole cell is tappable, not just the icon (§16).
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          radius: 40,
          child: SizedBox(
            // Comfortably past the 48px minimum even before the bar's own
            // height is counted (§16).
            height: ServanaNavMotion.barHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Reserved space for the travelling bubble. Fixed, so the label
                // never moves when selection changes — motion in the label
                // makes the whole bar feel unstable.
                SizedBox(
                  height: ServanaNavMotion.bubbleDiameter * 0.62,
                  child: isActive
                      ? const SizedBox.shrink()
                      : Center(
                          child: _InactiveIcon(
                              tab: tab, color: color, badge: badge)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // Labels stay visible at every size (§12). Capped scaling
                    // rather than hidden text: shrinking below this is not
                    // accessible, and hiding is explicitly disallowed (§30).
                    textScaler: TextScaler.linear(
                      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
                    ),
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 10.5,
                      height: 1.1,
                      color: color,
                      letterSpacing: -0.3,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon shown when the destination is not selected, with its badge.
class _InactiveIcon extends StatelessWidget {
  const _InactiveIcon({
    required this.tab,
    required this.color,
    required this.badge,
  });

  final CoreTab tab;
  final Color color;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(tab.icon, color: color, size: ServanaNavMotion.iconSize),
        if (badge > 0)
          Positioned(
            right: -6,
            top: -4,
            child: ServanaNavBadge(count: badge),
          ),
      ],
    );
  }
}

/// Count badge.
///
/// Positioned absolutely so its appearance and its digit count never move the
/// icon or label (§13). It animates in once on appearance; it does not re-run
/// on every increment, which would turn an unread counter into a twitch.
class ServanaNavBadge extends StatelessWidget {
  const ServanaNavBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Keyed on presence, not on value: an increment from 2 to 3 must not
      // replay the entrance.
      key: const ValueKey('servana-nav-badge'),
      tween: Tween(begin: 0, end: 1),
      duration: ServanaNavMotion.badge,
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(
        scale: 0.6 + (0.4 * t),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: ColorPalette.danger,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : Colors.white,
            width: 1.5,
          ),
        ),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        child: Text(
          // §13: exact count to 9, then a compact form.
          count > 9 ? '9+' : '$count',
          textAlign: TextAlign.center,
          // Not scaled: the badge is a fixed-size dot and its number is
          // already announced in the tab's semantic label, so growing it only
          // risks clipping (§13 — badges must stay in bounds).
          textScaler: TextScaler.noScaling,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
