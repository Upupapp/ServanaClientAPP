import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:flutter/material.dart';

/// Collapsing SliverAppBar hero for the category screen.
class CategoryHeroSliver extends StatelessWidget {
  final CategoryPresentationConfig config;
  final VoidCallback onBack;

  const CategoryHeroSliver({
    super.key,
    required this.config,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: config.theme.heroGradientStart,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _HeroBackground(config: config),
        title: Text(
          config.revealHeadline,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
      ),
      leading: Semantics(
        label: 'Back',
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
        ),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  final CategoryPresentationConfig config;
  const _HeroBackground({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.theme.heroGradientStart,
            config.theme.heroGradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: _DecorCircle(
              radius: 120,
              color: config.theme.secondaryAccent.withOpacity(0.12),
            ),
          ),
          Positioned(
            left: -16,
            bottom: -24,
            child: _DecorCircle(
              radius: 80,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Padding(
            // This is the FlexibleSpaceBar *background*, so its origin is the
            // raw top of the app bar — above the status bar, not below it.
            // A fixed `top: 60` therefore landed inside the toolbar band on any
            // device where the status bar plus toolbar exceeds 60, and the
            // subtitle rendered underneath the back button. It is
            // device-dependent, which is why it looked fine on some screens.
            //
            // Clearing the inset plus the toolbar puts it below the back button
            // on every device. When the bar collapses, the subtitle falls
            // outside the remaining height and is clipped, which is what should
            // happen — the pinned title carries the meaning at that point.
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
              20,
              0,
            ),
            child: Text(
              config.revealSubtext,
              // Expanded height is fixed at 180, so unbounded growth at large
              // text sizes would overflow the hero rather than reflow it. The
              // headline above carries the meaning; this line is supporting.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double radius;
  final Color color;
  const _DecorCircle({required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
