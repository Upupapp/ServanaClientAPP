import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/services/app_haptics.dart';
import '../../domain/home_promotion.dart';

class ServanaPromotionBanner extends StatefulWidget {
  final HomePromotion promotion;
  final VoidCallback? onCtaTap;

  const ServanaPromotionBanner({
    super.key,
    required this.promotion,
    this.onCtaTap,
  });

  @override
  State<ServanaPromotionBanner> createState() => _ServanaPromotionBannerState();
}

class _ServanaPromotionBannerState extends State<ServanaPromotionBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final promo = widget.promotion;

    final (bg1, bg2) = switch (promo.theme) {
      HomeBannerTheme.primaryBlue =>
        (const Color(0xFF1A3DB5), const Color(0xFF0A1F6E)),
      HomeBannerTheme.wellness =>
        (const Color(0xFF6C3DB5), const Color(0xFF3D1E7A)),
      HomeBannerTheme.reengagementNavy =>
        (const Color(0xFF0F2060), const Color(0xFF1A3480)),
      HomeBannerTheme.categoryPurple =>
        (const Color(0xFF4A2DB5), const Color(0xFF2A1080)),
    };

    Widget banner = Semantics(
      label: promo.accessibilityDescription,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          AppHaptics.medium();
          widget.onCtaTap?.call();
        },
        onTapCancel: () {
          setState(() => _pressed = false);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 172,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Decorative petal (right side)
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                // Orange accent line (bottom-left)
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Container(
                    height: 2,
                    width: 48,
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryColor.withOpacity(0.60),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo.title,
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (promo.subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                promo.subtitle!,
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.72),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // CTA
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: ColorPalette.primaryColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            promo.ctaLabel,
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!reduced) {
      banner = switch (promo.motion) {
        HomeMotionPreset.productReveal ||
        HomeMotionPreset.categoryBloom =>
          banner
              .animate()
              .fadeIn(duration: 360.ms)
              .slideY(
                begin: 0.12,
                end: 0,
                duration: 360.ms,
                curve: Curves.easeOutCubic,
              ),
        HomeMotionPreset.wellnessRipple => banner
            .animate()
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: const Cubic(0.2, 0, 0, 1),
            )
            .fadeIn(duration: 400.ms),
        _ => banner.animate().fadeIn(duration: 300.ms),
      };
    }

    return banner;
  }
}
