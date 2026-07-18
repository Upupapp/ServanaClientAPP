import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/common/presentation/widgets/service_thumbnail.dart';
import 'package:client/modules/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  static String routeName = "Bookings";
  static String route = "/Bookings";
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

enum _BookingsTab { paid, scheduled, done, review }

extension _BookingsTabLabel on _BookingsTab {
  String get label {
    switch (this) {
      case _BookingsTab.paid:
        return 'Paid';
      case _BookingsTab.scheduled:
        return 'Scheduled';
      case _BookingsTab.done:
        return 'Done';
      case _BookingsTab.review:
        return 'Review';
    }
  }

  IconData get icon {
    switch (this) {
      case _BookingsTab.paid:
        return Icons.payments_outlined;
      case _BookingsTab.scheduled:
        return Icons.event_available_outlined;
      case _BookingsTab.done:
        return Icons.check_circle_outline;
      case _BookingsTab.review:
        return Icons.star_outline_rounded;
    }
  }

  String get emptyText {
    switch (this) {
      case _BookingsTab.paid:
        return 'No paid bookings yet.';
      case _BookingsTab.scheduled:
        return 'Nothing scheduled.';
      case _BookingsTab.done:
        return 'No completed bookings.';
      case _BookingsTab.review:
        return 'No bookings to review.';
    }
  }
}

class _BookingsScreenState extends State<BookingsScreen> {
  final store = dpLocator<HomeStore>();
  final _dateFormat = DateFormat('MMMM d, yyyy');
  _BookingsTab _tab = _BookingsTab.scheduled;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => store.loadBookings());
  }

  // Status checks use the typed enum rather than locale-bound label strings —
  // see http_backend._mapApiBookingToJobOrder for how API status maps to enum.
  bool _needsPayment(JobOrder b) =>
      b.jobOrderStatus == JobOrderStatus.forReview;

  bool _isCompleted(JobOrder b) =>
      b.jobOrderStatus == JobOrderStatus.completed;

  bool _isCancelled(JobOrder b) =>
      b.jobOrderStatus == JobOrderStatus.cancelled;

  bool _isAbandoned(JobOrder b) =>
      b.jobOrderStatus == JobOrderStatus.none;

  List<JobOrder> _filterForTab(List<JobOrder> all) {
    final visible = all
        .where((b) => !_isAbandoned(b) && !_isCancelled(b))
        .toList();
    switch (_tab) {
      case _BookingsTab.paid:
        // Money has changed hands but service hasn't completed yet.
        return visible
            .where((b) => b.paymentStatus == 'PAID' && !_isCompleted(b))
            .toList();
      case _BookingsTab.scheduled:
        // Anything not yet completed — covers upcoming, in-progress, and any
        // late-running bookings whose scheduleDate is past but not closed out.
        return visible.where((b) => !_isCompleted(b)).toList();
      case _BookingsTab.done:
        return visible.where(_isCompleted).toList();
      case _BookingsTab.review:
        // No review system yet; this tab stays empty by design.
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      body: Column(
        children: [
          _GradientHeader(
            selectedTab: _tab,
            onSelectTab: (t) => setState(() => _tab = t),
          ),
          Expanded(
            child: Observer(
              builder: (context) {
                if (store.isLoading && store.bookings.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filtered = _filterForTab(store.bookings.toList());
                return RefreshIndicator(
                  onRefresh: () => store.loadBookings(),
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : _buildList(filtered),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    // Wrap in a scrollable so RefreshIndicator works on empty state too.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Image.asset(
            'assets/images/states/end_of_list.png',
            width: 180,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _tab.emptyText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.secondaryText.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<JobOrder> bookings) {
    final groups = _groupByDateProximity(bookings);

    final slivers = <Widget>[];

    // Action Required section appears at top of Scheduled tab when applicable.
    if (_tab == _BookingsTab.scheduled) {
      final actionRequired = bookings.where(_needsPayment).toList()
        ..sort((a, b) => b.scheduleDate.compareTo(a.scheduleDate));
      if (actionRequired.isNotEmpty) {
        slivers
          ..add(_sectionHeader('Action Required', actionRequired.length))
          ..add(_cardSliver(actionRequired));
      }
    }

    for (final entry in groups.entries) {
      // Skip Action Required bookings already rendered up top.
      final items = _tab == _BookingsTab.scheduled
          ? entry.value.where((b) => !_needsPayment(b)).toList()
          : entry.value;
      if (items.isEmpty) continue;
      slivers
        ..add(_sectionHeader(entry.key, items.length))
        ..add(_cardSliver(items));
    }

    slivers.add(SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Center(
          child: Image.asset(
            'assets/images/states/end_of_list.png',
            width: 160,
            fit: BoxFit.contain,
          ),
        ),
      ),
    ));

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );
  }

  Map<String, List<JobOrder>> _groupByDateProximity(List<JobOrder> bookings) {
    // TODO(timezone): scheduleDate is parsed in the device's local zone. PH is
    // UTC+8 with no DST so domestic users are fine, but a traveler with phone
    // clock on a different zone will see week boundaries shift by the offset.
    // Pin a UTC contract on the backend before localising bucket math.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // ISO week: weekday is 1=Mon..7=Sun.
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7)); // exclusive

    final catchallLabel =
        _tab == _BookingsTab.scheduled ? 'Later' : 'Earlier';
    final groups = <String, List<JobOrder>>{
      'This Week': [],
      'This Month': [],
      catchallLabel: [],
    };

    for (final b in bookings) {
      final d = b.scheduleDate;
      if (!d.isBefore(weekStart) && d.isBefore(weekEnd)) {
        groups['This Week']!.add(b);
      } else if (d.year == now.year && d.month == now.month) {
        groups['This Month']!.add(b);
      } else {
        groups[catchallLabel]!.add(b);
      }
    }

    // Newest first within each group (works for both past + future since the
    // user mostly cares about closest to "now" first).
    for (final list in groups.values) {
      list.sort((a, b) => b.scheduleDate.compareTo(a.scheduleDate));
    }
    return groups;
  }

  Widget _sectionHeader(String label, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _cardSliver(List<JobOrder> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BookingCard(
              booking: items[i],
              dateFormat: _dateFormat,
              needsPayment: _needsPayment(items[i]),
              onTap: () => _onBookingTap(items[i]),
            ),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  void _onBookingTap(JobOrder booking) {
    context.pushNamed(BookingDetailScreen.routeName, extra: booking);
  }
}

/// Gradient header that wraps the title row + the icon-card chip strip.
/// Wrapping both inside the gradient gives it visual presence and lets the
/// inactive chip labels (white text) sit on the dark blue background where
/// they read.
class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.selectedTab,
    required this.onSelectTab,
  });

  final _BookingsTab selectedTab;
  final ValueChanged<_BookingsTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorPalette.primaryColorDark,
            ColorPalette.primaryGradientEnd(),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 26), // balance bell for centered title
              const Expanded(
                child: Text(
                  'My Bookings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Gothic A1',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    context.pushNamed(NotificationsScreen.routeName),
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final tab in _BookingsTab.values)
                _IconChip(
                  tab: tab,
                  isSelected: tab == selectedTab,
                  onTap: () => onSelectTab(tab),
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _BookingsTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 63,
            height: 58,
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorPalette.primaryColor
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: Colors.white, width: 1)
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              tab.icon,
              size: 24,
              color: isSelected
                  ? Colors.white
                  : ColorPalette.primaryColorDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tab.label,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
              // Active label uses a brighter peach than Figma's #FFB67D so it
              // hits WCAG AA on the dark-blue gradient (4.5:1+); inactive is
              // pure white and reads at ~8:1.
              color: isSelected
                  ? const Color(0xFFFFD2A8)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.dateFormat,
    required this.needsPayment,
    required this.onTap,
  });

  final JobOrder booking;
  final DateFormat dateFormat;
  final bool needsPayment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = booking.merchantServiceName.isEmpty
        ? booking.merchantName
        : booking.merchantServiceName;
    final addressLine =
        booking.address.trim().isEmpty ? 'Service near you' : booking.address;

    return Material(
      color: const Color(0xFFFAFCFF),
      borderRadius: BorderRadius.circular(15),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryColorDark.withOpacity(.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorPalette.primaryColorDark.withOpacity(.3),
                      ),
                    ),
                    child: Text(
                      '#${booking.jobOrderNumber}',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                  ),
                  if (needsPayment)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Payment Required',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: ColorPalette.primaryText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: ColorPalette.primaryColorDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MetaRow(
                          icon: Icons.calendar_today_outlined,
                          text: dateFormat.format(booking.scheduleDate),
                        ),
                        const SizedBox(height: 4),
                        _MetaRow(
                          icon: Icons.location_on_outlined,
                          text: addressLine,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _Thumbnail(
                      photoUrl: booking.merchantServicePhoto,
                      fallbackName: displayName,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.photoUrl, required this.fallbackName});
  final String photoUrl;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    const w = 102.0;
    const h = 77.0;
    if (photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          serviceImageAsset(fallbackName),
          width: w,
          height: h,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      serviceImageAsset(fallbackName),
      width: w,
      height: h,
      fit: BoxFit.cover,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ColorPalette.primaryColorDark),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 12,
              color: ColorPalette.secondaryText.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
