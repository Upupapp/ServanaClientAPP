import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/shell/core_tab.dart';
import 'package:client/common/presentation/shell/quick_book_sheet.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

class MainNavScaffold extends StatelessWidget {
  const MainNavScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _navBlue = Color(0xFF1F44F2);
  static const _navGrey = Color(0xFF6D717F);
  static const _strokeColor = Color(0xFFE7E9EF);

  void _onTap(BuildContext context, int index) {
    // Only fire haptic when the tab actually changes (§64: centralised haptics).
    if (index != navigationShell.currentIndex) {
      AppHaptics.selection();
    }
    navigationShell.goBranch(
      index,
      // Re-selecting the active tab pops to its root (reselection behavior).
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// Returns the number of bookings that require immediate user action
  /// (OTP verification or payment). Used for the Bookings tab badge.
  int _actionCount(List<JobOrder> bookings) {
    return bookings.where((b) {
      final s = BookingStatusMapper.fromString(b.jobOrderStatusToString);
      return BookingStatusMapper.requiresOtp(s) ||
          BookingStatusMapper.requiresPayment(s);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final store = dpLocator<HomeStore>();
    final current = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Observer(
        builder: (_) {
          final badge = _actionCount(store.bookings.toList());
          return Container(
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
                    const SizedBox(width: 4),
                    _NavItem(
                      tab: CoreTab.home,
                      current: current,
                      badge: 0,
                      onTap: () => _onTap(context, CoreTab.home.index),
                    ),
                    _NavItem(
                      tab: CoreTab.bookings,
                      current: current,
                      badge: badge,
                      onTap: () => _onTap(context, CoreTab.bookings.index),
                    ),
                    // Central Book action — not a navigation branch.
                    Semantics(
                      button: true,
                      label: 'Book a service',
                      child: GestureDetector(
                        onTap: () => QuickBookSheet.show(context),
                        child: Container(
                          width: 49,
                          height: 49,
                          decoration: BoxDecoration(
                            color: _navBlue,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: _navBlue.withOpacity(.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    _NavItem(
                      tab: CoreTab.messages,
                      current: current,
                      badge: 0,
                      onTap: () => _onTap(context, CoreTab.messages.index),
                    ),
                    _NavItem(
                      tab: CoreTab.profile,
                      current: current,
                      badge: 0,
                      onTap: () => _onTap(context, CoreTab.profile.index),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.current,
    required this.badge,
    required this.onTap,
  });

  final CoreTab tab;
  final int current;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = tab.index == current;
    final color = isActive ? MainNavScaffold._navBlue : MainNavScaffold._navGrey;

    return Semantics(
      label: tab.semanticLabel(badge: badge),
      button: true,
      selected: isActive,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? MainNavScaffold._navBlue.withOpacity(.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? tab.activeIcon : tab.icon,
                    color: color,
                    size: 24,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -5,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: ColorPalette.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 10,
                  color: color,
                  letterSpacing: -0.4,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
