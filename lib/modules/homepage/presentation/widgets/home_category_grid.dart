import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/services/app_haptics.dart';

typedef CategoryTapCallback = void Function(String categoryKey);

class ServanaHomeCategoryGrid extends StatelessWidget {
  final bool animate;
  final CategoryTapCallback onCategoryTap;

  const ServanaHomeCategoryGrid({
    super.key,
    required this.animate,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    const categories = [
      _CategoryData(
        key: 'beauty_wellness',
        label: 'Beauty & Wellness',
        phrase: 'Facials · Massage · More',
        icon: Icons.spa_outlined,
        gradientColors: [Color(0xFF6C63FF), Color(0xFF9B8AFF)],
      ),
      _CategoryData(
        key: 'hair_nails',
        label: 'Hair & Nails',
        phrase: 'Hair · Nails · Treatments',
        icon: Icons.content_cut_outlined,
        gradientColors: [Color(0xFFE96F9C), Color(0xFFFF9CC8)],
      ),
      _CategoryData(
        key: 'massage',
        label: 'Massage',
        phrase: 'Relaxation · Therapeutic',
        icon: Icons.self_improvement_outlined,
        gradientColors: [Color(0xFF2D78F5), Color(0xFF5AABFF)],
      ),
      _CategoryData(
        key: 'aircon',
        label: 'Aircon Services',
        phrase: 'Cleaning · Repair · Install',
        icon: Icons.ac_unit_rounded,
        gradientColors: [Color(0xFF00BCD4), Color(0xFF0288D1)],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: List.generate(categories.length, (i) {
          final cat = categories[i];
          Widget tile = _HomeCategoryTile(
            data: cat,
            onTap: () {
              AppHaptics.categoryEntry();
              onCategoryTap(cat.key);
            },
          );

          if (animate && !reduced) {
            tile = tile
                .animate(delay: Duration(milliseconds: 300 + i * 60))
                .fadeIn(duration: 220.ms)
                .scale(
                  begin: const Offset(0.88, 0.88),
                  end: const Offset(1, 1),
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                );
          }
          return tile;
        }),
      ),
    );
  }
}

class _CategoryData {
  final String key;
  final String label;
  final String phrase;
  final IconData icon;
  final List<Color> gradientColors;

  const _CategoryData({
    required this.key,
    required this.label,
    required this.phrase,
    required this.icon,
    required this.gradientColors,
  });
}

class _HomeCategoryTile extends StatefulWidget {
  final _CategoryData data;
  final VoidCallback onTap;

  const _HomeCategoryTile({required this.data, required this.onTap});

  @override
  State<_HomeCategoryTile> createState() => _HomeCategoryTileState();
}

class _HomeCategoryTileState extends State<_HomeCategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: widget.data.label,
      button: true,
      hint: 'Browse ${widget.data.label} services',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) {
          if (!reduced) setState(() => _pressed = true);
        },
        onTapUp: (_) {
          if (!reduced) setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () {
          if (!reduced) setState(() => _pressed = false);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.data.gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.data.gradientColors[0].withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(widget.data.icon, color: Colors.white, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.label,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.data.phrase,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
