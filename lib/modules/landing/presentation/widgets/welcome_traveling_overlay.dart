import 'package:client/modules/landing/presentation/controllers/welcome_experience_controller.dart';
import 'package:client/modules/landing/presentation/widgets/servana_orange_ribbon.dart';
import 'package:flutter/material.dart';

/// Full-screen overlay positioned above the background [PageView] and below
/// the text/CTA layer. Contains:
///
///   1. [ServanaOrangeRibbon] — the continuous narrative ribbon from §24.
///   2. [_TravelingPetal]    — one Servana-blue petal that shifts depth + position
///                             across the three scenes (§25).
///   (The two labelled traveling cards were removed — their viewport-
///   fractional anchors put one on top of the real chip grid, where its label
///   drew over itself and read as corrupted text.)
///                             forward (§17 / §27).
///
/// All elements respond continuously to [WelcomeExperienceController.pageProgress]
/// without per-frame widget rebuilds (RepaintBoundary + ListenableBuilder pattern).
class WelcomeTravelingOverlay extends StatelessWidget {
  const WelcomeTravelingOverlay({super.key, required this.controller});

  final WelcomeExperienceController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.motionMode.isStatic) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Orange ribbon — deepest traveling element
          ServanaOrangeRibbon(controller: controller),

          // Traveling blue petal
          _TravelingPetal(controller: controller),

          // The two labelled traveling cards ("Aircon" and "Beauty") were
          // removed. Their anchors are fractions of the viewport, so on a tall
          // narrow screen the Beauty card landed underneath the real chip grid
          // and drew its label on top of itself — the text read as corrupted
          // rather than as a second element. It was decoration duplicating
          // labels the grid already shows, so there is nothing to replace it
          // with; the ribbon and petal above carry the motion without text.
        ],
      ),
    );
  }
}

// ── Traveling blue petal ──────────────────────────────────────────────────────

class _TravelingPetal extends StatelessWidget {
  const _TravelingPetal({required this.controller});
  final WelcomeExperienceController controller;

  // Petal anchor positions (fractional: dx=x/w, dy=y/h) per scene.
  static const _s0 = FractionalOffset(0.78, 0.18);
  static const _s1 = FractionalOffset(0.10, 0.28);
  static const _s2 = FractionalOffset(0.82, 0.70);

  // Petal size (fraction of screen min-dimension) per scene.
  static const _sz0 = 0.32;
  static const _sz1 = 0.26;
  static const _sz2 = 0.40;

  // Opacity per scene.
  static const _op0 = 0.18;
  static const _op1 = 0.14;
  static const _op2 = 0.22;

  /// The petal is placed by the PAINTER, not by a [Positioned].
  ///
  /// It used to return `RepaintBoundary(ListenableBuilder(... Positioned ...))`.
  /// `Positioned` only takes effect as a DIRECT child of a [Stack]; buried
  /// under the RepaintBoundary its `left`/`top`/`width`/`height` were inert.
  /// The parent `Stack` is `StackFit.expand`, so this widget was treated as a
  /// non-positioned child and stretched to the whole screen — and
  /// [_PetalPainter] fills whatever canvas it is given. The result was a
  /// screen-sized petal at 14–22% opacity: the grey-blue veil over all three
  /// onboarding photos, on every release build since the effect landed.
  ///
  /// Keeping the geometry in the painter means there is no ParentData
  /// relationship to get wrong, and the RepaintBoundary still isolates the
  /// per-frame repaint.
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: controller,
          builder: (_, __) {
            final t01 = controller.travelProgress(0, 1);
            final t12 = controller.travelProgress(1, 2);

            return CustomPaint(
              size: Size.infinite,
              painter: _PetalPainter(
                anchor: FractionalOffset(
                  _lerp3(_s0.dx, _s1.dx, _s2.dx, t01, t12),
                  _lerp3(_s0.dy, _s1.dy, _s2.dy, t01, t12),
                ),
                sizeFactor: _lerp3(_sz0, _sz1, _sz2, t01, t12),
                opacity: _lerp3(_op0, _op1, _op2, t01, t12),
              ),
            );
          },
        ),
      ),
    );
  }

  static double _lerp3(double a, double b, double c, double t01, double t12) {
    final ab = a + (b - a) * t01;
    return ab + (c - ab) * t12;
  }
}

/// Draws a simplified Servana-blue petal shape using a cubic Bézier.
///
/// The petal is drawn into a sub-rectangle of the canvas rather than filling
/// it. This painter is handed the FULL screen, and filling it is exactly the
/// bug this replaced — see [WelcomeTravelingOverlay.build].
class _PetalPainter extends CustomPainter {
  const _PetalPainter({
    required this.anchor,
    required this.sizeFactor,
    required this.opacity,
  });

  /// Petal centre as a fraction of the canvas.
  final FractionalOffset anchor;

  /// Petal edge length as a fraction of the canvas's shortest side.
  final double sizeFactor;

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = size.shortestSide * sizeFactor;
    final left = anchor.dx * size.width - dim / 2;
    final top = anchor.dy * size.height - dim / 2;

    final paint = Paint()
      ..color = const Color(0xFF2D56CC).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Geometry is expressed in petal-local coordinates and translated, so the
    // shape stays identical to the original — only its extent changed.
    final w = dim;
    final h = dim;
    final path = Path()
      ..moveTo(w * 0.50, 0)
      ..cubicTo(w * 0.95, h * 0.05, w, h * 0.55, w * 0.50, h)
      ..cubicTo(0, h * 0.55, w * 0.05, h * 0.05, w * 0.50, 0)
      ..close();

    canvas.save();
    canvas.translate(left, top);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PetalPainter old) =>
      old.anchor != anchor ||
      old.sizeFactor != sizeFactor ||
      old.opacity != opacity;
}
