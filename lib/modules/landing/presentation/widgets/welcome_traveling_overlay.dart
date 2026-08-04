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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListenableBuilder(
        listenable: controller,
        builder: (_, __) {
          final size = MediaQuery.sizeOf(context);
          final t01 = controller.travelProgress(0, 1);
          final t12 = controller.travelProgress(1, 2);

          final ax = _lerp3(_s0.dx, _s1.dx, _s2.dx, t01, t12);
          final ay = _lerp3(_s0.dy, _s1.dy, _s2.dy, t01, t12);
          final sz = _lerp3(_sz0, _sz1, _sz2, t01, t12);
          final op = _lerp3(_op0, _op1, _op2, t01, t12);

          final dim = size.shortestSide * sz;
          final left = ax * size.width - dim / 2;
          final top = ay * size.height - dim / 2;

          return Positioned(
            left: left,
            top: top,
            width: dim,
            height: dim,
            child: Opacity(
              opacity: op,
              child: CustomPaint(painter: _PetalPainter()),
            ),
          );
        },
      ),
    );
  }

  static double _lerp3(double a, double b, double c, double t01, double t12) {
    final ab = a + (b - a) * t01;
    return ab + (c - ab) * t12;
  }
}

/// Draws a simplified Servana-blue petal shape using a cubic Bézier.
class _PetalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF2D56CC)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w * 0.50, 0)
      ..cubicTo(w * 0.95, h * 0.05, w, h * 0.55, w * 0.50, h)
      ..cubicTo(0, h * 0.55, w * 0.05, h * 0.05, w * 0.50, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PetalPainter old) => false;
}
