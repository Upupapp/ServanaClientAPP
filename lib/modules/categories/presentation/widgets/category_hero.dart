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
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
            child: Text(
              config.revealSubtext,
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
