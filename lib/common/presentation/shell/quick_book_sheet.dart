import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_repair_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/beauty_wellness_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/hair_nails_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/massage_screen.dart';
import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom sheet presented by the central Book action in [MainNavScaffold].
///
/// Shows the four service categories and a "Browse all" escape hatch.
/// Navigates using named routes so the back stack works correctly.
class QuickBookSheet extends StatelessWidget {
  const QuickBookSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.medium();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const QuickBookSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: ColorPalette.secondaryBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Book a Service',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: ColorPalette.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a service category to get started',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                color: ColorPalette.secondaryText.withOpacity(.55),
              ),
            ),
            const SizedBox(height: 20),
            _CategoryRow(
              icon: Icons.ac_unit_rounded,
              label: 'Aircon Services',
              color: const Color(0xFF2D78F5),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(AirconRepairScreen.routeName);
              },
            ),
            const SizedBox(height: 10),
            _CategoryRow(
              icon: Icons.spa_rounded,
              label: 'Beauty & Wellness',
              color: const Color(0xFFE96F9C),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(BeautyWellnessScreen.routeName);
              },
            ),
            const SizedBox(height: 10),
            _CategoryRow(
              icon: Icons.content_cut_rounded,
              label: 'Hair & Nails',
              color: const Color(0xFF9B6DE3),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(HairNailsScreen.routeName);
              },
            ),
            const SizedBox(height: 10),
            _CategoryRow(
              icon: Icons.self_improvement_rounded,
              label: 'Massage',
              color: const Color(0xFF2DBBA7),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed(MassageScreen.routeName);
              },
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Browse all services',
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(SearchScreen.routeName);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 18,
                        color: ColorPalette.primaryColorDark,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Browse all services',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: ColorPalette.primaryColorDark,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
