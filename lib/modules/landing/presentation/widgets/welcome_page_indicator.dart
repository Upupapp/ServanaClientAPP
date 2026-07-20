import 'package:client/modules/landing/presentation/controllers/welcome_experience_controller.dart';
import 'package:flutter/material.dart';

/// Premium page-progress indicator that responds continuously to swipe.
///
/// Each segment expands/contracts proportional to how close [pageProgress] is
/// to that page — so at 0.5 both segments are equally sized. The active
/// segment is distinguished by width AND colour (not colour alone), satisfying
/// the accessibility requirement in §29.
///
/// Semantics: the outer [Semantics] widget announces "Page N of M" to screen
/// readers. Individual segments are excluded from the tree ([ExcludeSemantics])
/// so TalkBack does not read three separate unlabelled containers.
class WelcomePageIndicator extends StatelessWidget {
  const WelcomePageIndicator({
    super.key,
    required this.controller,
    required this.pageCount,
  });

  final WelcomeExperienceController controller;
  final int pageCount;

  static const double _dotH = 6.0;
  static const double _minW = 8.0;
  static const double _maxW = 28.0;
  static const double _spacing = 6.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page indicator: ${controller.currentPage + 1} of $pageCount',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: controller,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(pageCount, _buildSegment),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegment(int i) {
    // activeFraction: 1.0 when page == i, 0.0 when page == i±1
    final activeFraction =
        (1.0 - (controller.pageProgress - i).abs()).clamp(0.0, 1.0);
    final width = _minW + (_maxW - _minW) * activeFraction;
    final color = Color.lerp(
      const Color(0x66FFFFFF),
      Colors.white,
      activeFraction,
    )!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _spacing / 2),
      width: width,
      height: _dotH,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(activeFraction > 0.5 ? 4.0 : 8.0),
      ),
    );
  }
}
