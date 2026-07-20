import 'dart:ui' as ui;
import 'package:client/modules/landing/presentation/controllers/welcome_experience_controller.dart';
import 'package:flutter/material.dart';

/// Draws the Servana orange ribbon — the narrative element that travels from
/// the logo chevron trail through all three onboarding scenes.
///
/// The ribbon follows a cubic Bézier curve whose anchor points shift with
/// [pageProgress]. It responds continuously to swipe, never uses a shader
/// that redraws the full screen, and disappears under reduced-motion.
class ServanaOrangeRibbon extends StatelessWidget {
  const ServanaOrangeRibbon({
    super.key,
    required this.controller,
    this.opacity = 0.72,
  });

  final WelcomeExperienceController controller;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (controller.motionMode.isStatic) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: controller,
          builder: (_, __) {
            return CustomPaint(
              painter: _RibbonPainter(
                pageProgress: controller.pageProgress,
                opacity: opacity,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.pageProgress, required this.opacity});

  final double pageProgress;
  final double opacity;

  // ── Brand colors ────────────────────────────────────────────────────────────
  static const Color _orange = Color(0xFFF89040);
  static const Color _orangeFade = Color(0x00F89040);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ribbon has three anchor positions — one per onboarding scene.
    // Each anchor is expressed as a fraction of (w, h).
    // As [pageProgress] advances 0→1→2 the ribbon morphs between them.

    final t01 = pageProgress.clamp(0.0, 1.0); // 0→1 crossing
    final t12 = (pageProgress - 1.0).clamp(0.0, 1.0); // 1→2 crossing

    // Scene 0 anchor layout: orbit the service-chip cluster (lower-left arc)
    final p0Start = Offset(w * 0.05, h * 0.62);
    final p0C1 = Offset(w * 0.22, h * 0.52);
    final p0C2 = Offset(w * 0.62, h * 0.54);
    final p0End = Offset(w * 0.92, h * 0.44);

    // Scene 1 anchor layout: sweep through service cards (horizontal arc)
    final p1Start = Offset(w * 0.04, h * 0.50);
    final p1C1 = Offset(w * 0.30, h * 0.40);
    final p1C2 = Offset(w * 0.68, h * 0.60);
    final p1End = Offset(w * 0.96, h * 0.46);

    // Scene 2 anchor layout: booking progress path (diagonal from cards to CTA)
    final p2Start = Offset(w * 0.08, h * 0.56);
    final p2C1 = Offset(w * 0.28, h * 0.62);
    final p2C2 = Offset(w * 0.60, h * 0.72);
    final p2End = Offset(w * 0.92, h * 0.78);

    // Interpolate anchor points between scenes
    final start = _lerp3(p0Start, p1Start, p2Start, t01, t12);
    final c1 = _lerp3(p0C1, p1C1, p2C1, t01, t12);
    final c2 = _lerp3(p0C2, p1C2, p2C2, t01, t12);
    final end = _lerp3(p0End, p1End, p2End, t01, t12);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);

    // Gradient along the ribbon — fades in from start, fades out at tail.
    final gradient = ui.Gradient.linear(
      start,
      end,
      [_orangeFade, _orange, _orange, _orangeFade],
      [0.0, 0.15, 0.85, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..shader = gradient;

    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white.withOpacity(opacity));
    canvas.drawPath(path, paint);
    canvas.restore();

    // Secondary glow pass — slightly wider, low opacity
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..shader = gradient
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Colors.white.withOpacity(opacity * 0.35),
    );
    canvas.drawPath(path, glowPaint);
    canvas.restore();
  }

  /// Three-point interpolation: lerp A→B over t01 then B→C over t12.
  static Offset _lerp3(Offset a, Offset b, Offset c, double t01, double t12) {
    final ab = Offset.lerp(a, b, t01)!;
    return Offset.lerp(ab, c, t12)!;
  }

  @override
  bool shouldRepaint(_RibbonPainter old) =>
      old.pageProgress != pageProgress || old.opacity != opacity;
}
