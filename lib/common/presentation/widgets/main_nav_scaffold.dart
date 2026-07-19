import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavScaffold extends StatelessWidget {
  const MainNavScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _navBlue = Color(0xFF1F44F2);
  static const _navGrey = Color(0xFF6D717F);
  static const _strokeColor = Color(0xFFE7E9EF);

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;

    Widget navItem({
      required IconData icon,
      required String label,
      required int index,
    }) {
      final isActive = index == current;
      final color = isActive ? _navBlue : _navGrey;
      return InkWell(
        onTap: () => _onTap(context, index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 10,
                  color: color,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _strokeColor)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 8),
                navItem(icon: Icons.home_rounded, label: 'Home', index: 0),
                navItem(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Bookings',
                    index: 1),
                GestureDetector(
                  onTap: () => context.pushNamed(SearchScreen.routeName),
                  child: Container(
                    width: 49,
                    height: 49,
                    decoration: BoxDecoration(
                      color: _navBlue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
                navItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Messages',
                    index: 2),
                navItem(
                    icon: Icons.person_rounded, label: 'Profile', index: 3),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
