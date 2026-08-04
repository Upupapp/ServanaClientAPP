import 'package:flutter/material.dart';

import 'package:client/common/presentation/navigation/servana_nav_motion.dart';

/// Paints the navigation surface: a rounded bar whose top edge dips into a
/// cradle beneath the active destination.
///
/// A painter rather than a stack of clipped containers because the cradle has
/// to move continuously. Rebuilding a `ClipPath` every frame re-clips the whole
/// subtree; repainting a path does not, and this widget sits under a
/// `RepaintBoundary` so the animation never touches the page above it (§23).
///
/// The surface is drawn, not decorated: the shadow follows the same path as the
/// fill, so the cradle casts a shadow with the correct shape instead of the
/// rectangle a `BoxShadow` would give.
class ServanaCurvedNavPainter extends CustomPainter {
  const ServanaCurvedNavPainter({
    required this.cradleCentreX,
    required this.surfaceColor,
    required this.shadowColor,
    required this.borderColor,
    required this.showCradle,
  });

  /// Horizontal centre of the cradle, in local pixels.
  final double cradleCentreX;

  final Color surfaceColor;
  final Color shadowColor;

  /// Hairline along the top edge. Carries the surface/background boundary in
  /// dark mode, where a shadow alone is not visible (§20).
  final Color borderColor;

  /// False under reduced motion, which flattens the top edge entirely (§19) —
  /// the selected state is then carried by colour, weight and the bubble, never
  /// by motion alone (§30).
  final bool showCradle;

  /// Half-width of the dip. Wider than the bubble so the surface appears to
  /// yield around it rather than to have a notch cut out.
  static const double _cradleHalfWidth = 44;

  /// How deep the dip descends from the top edge.
  static const double _cradleDepth = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, ServanaNavMotion.surfaceRadius);

    // Top-left corner.
    path.quadraticBezierTo(0, 0, ServanaNavMotion.surfaceRadius, 0);

    if (showCradle) {
      final left = cradleCentreX - _cradleHalfWidth;
      final right = cradleCentreX + _cradleHalfWidth;

      path.lineTo(left, 0);
      // Two mirrored cubics rather than one arc: the shoulders need to leave
      // and rejoin the top edge tangentially, otherwise the join shows as a
      // crease at the exact moment the eye is following the bubble.
      path.cubicTo(
        left + _cradleHalfWidth * 0.45,
        0,
        cradleCentreX - _cradleHalfWidth * 0.62,
        _cradleDepth,
        cradleCentreX,
        _cradleDepth,
      );
      path.cubicTo(
        cradleCentreX + _cradleHalfWidth * 0.62,
        _cradleDepth,
        right - _cradleHalfWidth * 0.45,
        0,
        right,
        0,
      );
    }

    path.lineTo(size.width - ServanaNavMotion.surfaceRadius, 0);
    path.quadraticBezierTo(
        size.width, 0, size.width, ServanaNavMotion.surfaceRadius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Shadow first, offset upward: the bar sits at the screen bottom, so the
    // only edge that can cast a visible shadow is the top one.
    canvas.drawPath(
      path.shift(const Offset(0, -2)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawPath(path, Paint()..color = surfaceColor);

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(ServanaCurvedNavPainter old) =>
      old.cradleCentreX != cradleCentreX ||
      old.surfaceColor != surfaceColor ||
      old.shadowColor != shadowColor ||
      old.borderColor != borderColor ||
      old.showCradle != showCradle;
}
