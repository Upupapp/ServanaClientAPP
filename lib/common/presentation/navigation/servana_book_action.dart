import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/presentation/navigation/servana_nav_motion.dart';

/// The central Book action.
///
/// Deliberately NOT a navigation destination (§7): it opens a sheet, never
/// changes `navigationShell.currentIndex`, and never renders as selected. It is
/// orange where the tabs are blue precisely so it does not read as a fifth tab.
///
/// The press sequence is 1.00 → 0.94 → 1.03 → 1.00 across ~160ms, inside the
/// 120–180ms the spec allows. Short enough to feel like a button acknowledging
/// a press rather than an animation playing.
class ServanaBookAction extends StatefulWidget {
  const ServanaBookAction({super.key, required this.onPressed});

  /// Invoked after the press animation begins, not after it completes — the
  /// sheet should start opening while the button is still settling.
  final VoidCallback onPressed;

  @override
  State<ServanaBookAction> createState() => _ServanaBookActionState();
}

class _ServanaBookActionState extends State<ServanaBookAction> {
  double _scale = 1;

  Future<void> _run() async {
    final reduced = ServanaNavMotion.reduced(context);

    if (!reduced) {
      setState(() => _scale = ServanaNavMotion.pressScale);
      await Future<void>.delayed(ServanaNavMotion.press);
      if (!mounted) return;
      setState(() => _scale = ServanaNavMotion.releaseScale);
      await Future<void>.delayed(ServanaNavMotion.pressRelease);
      if (!mounted) return;
      setState(() => _scale = 1);
    }

    // Guarded: the widget may have been disposed during the animation above.
    // §7 is explicit that the haptic must not fire when the sheet cannot open,
    // and the haptic lives inside QuickBookSheet.show — so the guard has to be
    // here, on the call itself.
    if (!mounted) return;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ColorPalette.navBookAction;

    return Semantics(
      button: true,
      label: 'Book a service',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _run,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _scale,
          duration: ServanaNavMotion.press,
          curve: Curves.easeOut,
          child: Container(
            width: ServanaNavMotion.bookDiameter,
            height: ServanaNavMotion.bookDiameter,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(
                // Separates the button from the bar beneath it. In dark mode
                // the surface is near the accent's value, so without this the
                // circle loses its edge (§20).
                color: isDark
                    ? Theme.of(context).colorScheme.surface
                    : Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(isDark ? 0.28 : 0.34),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
