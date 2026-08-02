import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/navigation/servana_curved_main_navigation.dart';
import 'package:client/common/presentation/navigation/servana_nav_motion.dart';
import 'package:client/common/presentation/shell/core_tab.dart';
import 'package:client/common/presentation/shell/quick_book_sheet.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_event.dart';
import 'package:client/core/analytics/events/navigation_events.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/messaging/presentation/stores/messaging_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

/// Shell for the four primary branches plus the central Book action.
///
/// Owns navigation, haptics and analytics. The chrome is
/// [ServanaCurvedMainNavigation], which knows nothing about routing — keeping
/// branch handling here is what lets GoRouter remain the single source of
/// truth for which tab is selected (§1, §21).
class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  // §11/§22/§24 — passive branch changes must not produce user feedback.
  //
  // No "was this the user?" flag is tracked, because the structure makes the
  // question unnecessary: haptics and analytics live ONLY inside
  // _onTabSelected, which is reachable only from a tap. A deep link, a
  // notification route or a cold-start restore moves currentIndex without ever
  // entering this method, so it cannot fire feedback even by accident. A flag
  // would have to be kept correct forever; this cannot go wrong.

  void _track(AnalyticsEvent event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {
      // Analytics must never break navigation.
    }
  }

  void _onTabSelected(CoreTab tab) {
    final index = tab.index;
    final current = widget.navigationShell.currentIndex;

    if (index != current) {
      AppHaptics.selection();
      _track(MainTabSelectedEvent(
        tabKey: tab.name,
        previousTabKey: CoreTab.values
            .firstWhere((t) => t.index == current, orElse: () => CoreTab.home)
            .name,
      ));
      widget.navigationShell.goBranch(index, initialLocation: false);
      return;
    }

    // Reselection. §10: the haptic and the event are earned only if the branch
    // ACTUALLY pops. A tap on a tab already at its root did nothing, and
    // pretending otherwise trains the customer to distrust the feedback.
    final navigator = Navigator.maybeOf(context);
    final willPop = navigator?.canPop() ?? false;

    widget.navigationShell.goBranch(index, initialLocation: true);

    if (willPop) {
      AppHaptics.light();
      _track(MainTabReselectedEvent(tabKey: tab.name));
    }
  }

  Future<void> _onBookPressed() async {
    if (!mounted) return;
    _track(const QuickBookOpenedEvent(entrySource: 'main_nav'));
    // The medium haptic lives inside QuickBookSheet.show (§7). Calling it only
    // when still mounted is what stops the haptic firing for a sheet that
    // cannot open.
    await QuickBookSheet.show(context);
  }

  /// Bookings needing immediate action — OTP or payment.
  int _actionCount(List<JobOrder> bookings) {
    return bookings.where((b) {
      final s = BookingStatusMapper.fromString(b.jobOrderStatusToString);
      return BookingStatusMapper.requiresOtp(s) ||
          BookingStatusMapper.requiresPayment(s);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final homeStore = dpLocator<HomeStore>();
    final msgStore = dpLocator<MessagingStore>();

    return Scaffold(
      // extendBody is deliberately OFF.
      //
      // Turning it on let the page scroll under the bar's rounded corners,
      // which looks better and buries the last item on every scrolling screen
      // behind the navigation — reported from the emulator: the bottom of Home
      // was unreachable. §30 is explicit that the navigation must not cover
      // content, and that outranks the corner treatment.
      body: _BranchTransition(
        index: widget.navigationShell.currentIndex,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: Observer(
        // Observer wraps ONLY the badge-dependent chrome (§23). The branch
        // content above is outside it, so an unread count arriving never
        // rebuilds the page the customer is reading.
        builder: (_) => ServanaCurvedMainNavigation(
          currentIndex: widget.navigationShell.currentIndex,
          bookingsBadge: _actionCount(homeStore.bookings.toList()),
          messagesBadge: msgStore.totalUnread,
          onTabSelected: _onTabSelected,
          onBookPressed: _onBookPressed,
        ),
      ),
    );
  }
}

/// Fade, rise and settle for branch content (§9).
///
/// Wraps the shell rather than replacing it: `StatefulShellRoute.indexedStack`
/// still owns every branch's navigator, so scroll offsets, list filters and
/// nested routes survive a tab change. Swapping in a rebuilt list of screens
/// would animate more cheaply and destroy all of it (§9, §21).
class _BranchTransition extends StatelessWidget {
  const _BranchTransition({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (ServanaNavMotion.reduced(context)) return child;

    return TweenAnimationBuilder<double>(
      // Keyed on the branch index so the tween restarts on each change.
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: ServanaNavMotion.pageFor(context),
      curve: ServanaNavMotion.pageCurve,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, ServanaNavMotion.pageRiseOffset * (1 - t)),
          child: Transform.scale(
            scale: ServanaNavMotion.pageStartScale +
                ((1 - ServanaNavMotion.pageStartScale) * t),
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}
