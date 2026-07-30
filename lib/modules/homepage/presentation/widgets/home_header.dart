import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';

class ServanaHomeHeader extends StatelessWidget {
  final String? firstName;
  final bool isAuthenticated;
  final bool animate;
  final int notificationCount;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  const ServanaHomeHeader({
    super.key,
    this.firstName,
    required this.isAuthenticated,
    required this.animate,
    this.notificationCount = 0,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final doAnimate = animate && !reduced;

    String greeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good morning';
      if (hour < 17) return 'Good afternoon';
      return 'Good evening';
    }

    final greetingLine = isAuthenticated && firstName != null
        ? '${greeting()}, $firstName!'
        : 'Welcome to Servana';
    const subLine = 'What service do you need today?';

    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu button
          Semantics(
            label: 'Open navigation menu',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onMenuTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingLine,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLine,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          Semantics(
            label: notificationCount > 0
                ? 'View $notificationCount notifications'
                : 'View notifications',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorPalette.primaryColorDark,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ),
        ],
      ),
    );

    if (!doAnimate) return content;

    return content
        .animate()
        .fadeIn(duration: 220.ms, delay: 80.ms)
        .slideY(
          begin: -0.1,
          end: 0,
          duration: 220.ms,
          delay: 80.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
