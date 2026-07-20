import 'package:client/modules/landing/presentation/controllers/welcome_experience_controller.dart';
import 'package:flutter/material.dart';

/// Wraps [child] and translates it horizontally based on [pageIndex] and the
/// current [WelcomeExperienceController.pageProgress].
///
/// The [parallaxFactor] controls how much the layer moves relative to the
/// page width. Lower values push the layer further "into" the background:
///
///   0.05 – atmospheric / deepest background  (barely moves)
///   0.15 – environment / photo layer
///   0.35 – model / mid-ground content
///   0.55 – cards and interface elements
///   0.80 – foreground particles / ribbon accents
///
/// The layer is wrapped in [RepaintBoundary] so parallax translation does
/// not trigger repaints of non-animating siblings.
class WelcomeParallaxLayer extends StatelessWidget {
  const WelcomeParallaxLayer({
    super.key,
    required this.controller,
    required this.pageIndex,
    required this.parallaxFactor,
    required this.child,
    this.verticalFactor = 0.0,
  });

  final WelcomeExperienceController controller;
  final int pageIndex;

  /// Horizontal travel factor (0 = stationary, 1 = full page scroll speed).
  final double parallaxFactor;

  /// Optional subtle vertical drift (useful for atmospheric layers).
  final double verticalFactor;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListenableBuilder(
        listenable: controller,
        // Pass child through so it is not rebuilt on every scroll frame.
        builder: (_, Widget? stable) {
          final width = MediaQuery.sizeOf(context).width;
          final height = MediaQuery.sizeOf(context).height;
          final dx = controller.parallaxOffset(pageIndex, parallaxFactor, width);
          // Subtle vertical: deeper layers drift slightly upward while swiping.
          final dy = verticalFactor > 0
              ? -((controller.pageProgress - pageIndex).abs()) * height * verticalFactor
              : 0.0;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: stable,
          );
        },
        child: child,
      ),
    );
  }
}
