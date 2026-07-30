import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/common/presentation/widgets/service_thumbnail.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_state.dart';
import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Booking lifecycle segments shown as horizontal filter chips.
enum _BookingSegment {
  actionRequired,
  upcoming,
  active,
  completed,
  cancelled,
  needsAttention,
}

extension _SegmentProps on _BookingSegment {
  String get label {
    switch (this) {
      case _BookingSegment.actionRequired:
        return 'Action Required';
      case _BookingSegment.upcoming:
        return 'Upcoming';
      case _BookingSegment.active:
        return 'Active';
      case _BookingSegment.completed:
        return 'Completed';
      case _BookingSegment.cancelled:
        return 'Cancelled';
      case _BookingSegment.needsAttention:
        return 'Needs Attention';
    }
  }

  IconData get icon {
    switch (this) {
      case _BookingSegment.actionRequired:
        return Icons.warning_amber_rounded;
      case _BookingSegment.upcoming:
        return Icons.event_available_outlined;
      case _BookingSegment.active:
        return Icons.play_circle_outline_rounded;
      case _BookingSegment.completed:
        return Icons.check_circle_outline;
      case _BookingSegment.cancelled:
        return Icons.cancel_outlined;
      case _BookingSegment.needsAttention:
        return Icons.error_outline_rounded;
    }
  }

  String get emptyText {
    switch (this) {
      case _BookingSegment.actionRequired:
        return 'No action required.';
      case _BookingSegment.upcoming:
        return 'No upcoming bookings.';
      case _BookingSegment.active:
        return 'No active bookings right now.';
      case _BookingSegment.completed:
        return 'No completed bookings yet.';
      case _BookingSegment.cancelled:
        return 'No cancelled bookings.';
      case _BookingSegment.needsAttention:
        return 'No bookings need attention right now.';
    }
  }

  Color get chipColor {
    switch (this) {
      case _BookingSegment.actionRequired:
        return const Color(0xFFF5A623);
      case _BookingSegment.upcoming:
        return const Color(0xFF2D78F5);
      case _BookingSegment.active:
        return const Color(0xFF2DBBA7);
      case _BookingSegment.completed:
        return const Color(0xFF6D717F);
      case _BookingSegment.cancelled:
        return const Color(0xFFE05B5B);
      case _BookingSegment.needsAttention:
        return const Color(0xFF9C27B0);
    }
  }
}

class _BookingsScreenState extends State<BookingsScreen> {
  final store = dpLocator<HomeStore>();
  final _dateFormat = DateFormat('MMMM d, yyyy');
  // Default to Upcoming — most users have 0 action-required bookings and
  // landing on an empty screen is a poor first impression. Action-Required
  // badges on the chip draw the eye when something actually needs attention.
  _BookingSegment _segment = _BookingSegment.upcoming;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _doLoad();
  }

  Future<void> _doLoad() async {
    try {
      await store.loadBookings();
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  /// Classify a booking into its lifecycle segment using the authoritative
  /// status string from the backend. Falls back to the old [JobOrderStatus]
  /// enum for bookings whose status string predates the canonical mapper.
  _BookingSegment _classify(JobOrder b) {
    final status = BookingStatusMapper.fromString(b.jobOrderStatusToString);

    if (BookingStatusMapper.requiresOtp(status) ||
        BookingStatusMapper.requiresPayment(status)) {
      return _BookingSegment.actionRequired;
    }

    switch (status) {
      // Payment in-flight — user already acted; show in Upcoming while processing.
      case BookingStatus.paymentProcessing:
      case BookingStatus.paymentPendingConfirmation:
      case BookingStatus.paid:
      case BookingStatus.awaitingAssignment:
      case BookingStatus.assigned:
      case BookingStatus.confirmed:
        return _BookingSegment.upcoming;

      case BookingStatus.enRoute:
      case BookingStatus.arrived:
      case BookingStatus.inProgress:
      case BookingStatus.awaitingCompletion:
        return _BookingSegment.active;

      case BookingStatus.completed:
      case BookingStatus.reviewed:
        return _BookingSegment.completed;

      case BookingStatus.cancelled:
      case BookingStatus.cancelledByProvider:
      case BookingStatus.cancelledByAdmin:
      case BookingStatus.expired:
      case BookingStatus.refunded:
        return _BookingSegment.cancelled;

      // Failed and unknown statuses surface in "Needs Attention" so the
      // customer is not left wondering why a booking appears nowhere.
      case BookingStatus.failed:
      case BookingStatus.unknown:
        return _BookingSegment.needsAttention;

      // Draft bookings are not server-persisted in a visible way;
      // fall through to the legacy JobOrderStatus fallback.
      default:
        break;
    }

    // Fallback: old JobOrderStatus enum for legacy or unrecognised status strings.
    switch (b.jobOrderStatus) {
      case JobOrderStatus.none:
        return _BookingSegment.cancelled;
      case JobOrderStatus.forReview:
        // FOR_REVIEW is handled by BookingStatusMapper → awaitingAssignment,
        // but map the enum value directly too as belt-and-suspenders.
        return _BookingSegment.upcoming;
      case JobOrderStatus.accepted:
        return _BookingSegment.upcoming;
      case JobOrderStatus.inTransit:
        return _BookingSegment.active;
      case JobOrderStatus.inProgress:
        return _BookingSegment.active;
      case JobOrderStatus.completed:
        return _BookingSegment.completed;
      case JobOrderStatus.cancelled:
        return _BookingSegment.cancelled;
    }
  }

  List<JobOrder> _filterForSegment(List<JobOrder> all) {
    return all.where((b) => _classify(b) == _segment).toList();
  }

  int _countForSegment(List<JobOrder> all, _BookingSegment seg) {
    return all.where((b) => _classify(b) == seg).length;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      // Reset segment and error to defaults whenever a new session starts,
      // so a returning user never sees the previous user's tab state.
      listenWhen: (_, next) =>
          next is AuthenticationAuthenticated || next is AuthenticationGuest,
      listener: (_, __) => setState(() {
        _segment = _BookingSegment.upcoming;
        _loadError = null;
      }),
      child: Scaffold(
        backgroundColor: ColorPalette.primaryBackground,
        body: Column(
          children: [
            _GradientHeader(
              selectedSegment: _segment,
              onSelect: (s) => setState(() => _segment = s),
              countFor: (s) => Observer(
                builder: (_) => _countBadge(
                    s, _countForSegment(store.bookings.toList(), s)),
              ),
              countValueFor: (s) =>
                  _countForSegment(store.bookings.toList(), s),
            ),
            Expanded(
              child: Observer(
                builder: (context) {
                  if (store.isLoading && store.bookings.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_loadError != null && store.bookings.isEmpty) {
                    return _buildLoadError();
                  }
                  // True empty state — customer has no bookings at all.
                  if (store.bookings.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _doLoad,
                      child: _buildGlobalEmpty(),
                    );
                  }
                  final filtered = _filterForSegment(store.bookings.toList())
                    ..sort((a, b) => b.scheduleDate.compareTo(a.scheduleDate));
                  return RefreshIndicator(
                    onRefresh: _doLoad,
                    child:
                        filtered.isEmpty ? _buildEmpty() : _buildList(filtered),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(_BookingSegment seg, int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: seg.chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: ColorPalette.secondaryText.withOpacity(.35),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Could not load bookings.',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w600,
              color: ColorPalette.secondaryText.withOpacity(.7),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() => _loadError = null);
              _doLoad();
            },
            child: Text(
              'Retry',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                color: ColorPalette.primaryColorDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
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
            _segment.emptyText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.secondaryText.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _segment = _BookingSegment.upcoming),
              child: Text(
                'View All Bookings',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => context.pushNamed(SearchScreen.routeName),
              child: Text(
                'Browse Services',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// True empty state — customer has zero bookings at all (not a filter result).
  Widget _buildGlobalEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Image.asset(
            'assets/images/states/end_of_list.png',
            width: 200,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'No bookings yet',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: ColorPalette.secondaryText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Your upcoming and past Servana bookings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.secondaryText.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: () => context.pushNamed(SearchScreen.routeName),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColorDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Browse Services',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<JobOrder> bookings) {
    final groups = _groupByDateProximity(bookings);
    final slivers = <Widget>[];

    for (final entry in groups.entries) {
      if (entry.value.isEmpty) continue;
      slivers
        ..add(_sectionHeader(entry.key, entry.value.length))
        ..add(_cardSliver(entry.value));
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final catchall = (_segment == _BookingSegment.upcoming ||
            _segment == _BookingSegment.active)
        ? 'Later'
        : 'Earlier';

    final groups = <String, List<JobOrder>>{
      'This Week': [],
      'This Month': [],
      catchall: [],
    };

    for (final b in bookings) {
      final d = b.scheduleDate;
      if (!d.isBefore(weekStart) && d.isBefore(weekEnd)) {
        groups['This Week']!.add(b);
      } else if (d.year == now.year && d.month == now.month) {
        groups['This Month']!.add(b);
      } else {
        groups[catchall]!.add(b);
      }
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
          (context, i) {
            final b = items[i];
            final seg = _classify(b);
            final displayName = b.merchantServiceName.isNotEmpty
                ? b.merchantServiceName
                : b.merchantName;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                label: '$displayName, ${seg.label}, '
                    '${_dateFormat.format(b.scheduleDate)}',
                hint: 'Opens booking detail',
                button: true,
                excludeSemantics: true,
                child: _BookingCard(
                  booking: b,
                  segment: seg,
                  dateFormat: _dateFormat,
                  onTap: () => context.go('/bookings/${b.jobOrderID}'),
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.selectedSegment,
    required this.onSelect,
    required this.countFor,
    required this.countValueFor,
  });

  final _BookingSegment selectedSegment;
  final ValueChanged<_BookingSegment> onSelect;
  final Widget Function(_BookingSegment) countFor;
  final int Function(_BookingSegment) countValueFor;

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
              const SizedBox(width: 26),
              Expanded(
                child: Text(
                  'My Bookings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              // Wrap in a 44×44 target so the tap area meets §30 minimum.
              SizedBox(
                width: 44,
                height: 44,
                child: Semantics(
                  label: 'View notifications',
                  button: true,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => context.pushNamed(NotificationsScreen.routeName),
                    behavior: HitTestBehavior.opaque,
                    child: const Center(
                      child: Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final seg in _BookingSegment.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Observer(
                      builder: (_) => _SegmentChip(
                        segment: seg,
                        isSelected: seg == selectedSegment,
                        count: countValueFor(seg),
                        countWidget: countFor(seg),
                        onTap: () => onSelect(seg),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.segment,
    required this.isSelected,
    required this.countWidget,
    required this.count,
    required this.onTap,
  });

  final _BookingSegment segment;
  final bool isSelected;
  final Widget countWidget;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${segment.label}${count > 0 ? ", $count" : ""}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                segment.icon,
                size: 13,
                color:
                    isSelected ? ColorPalette.primaryColorDark : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                segment.label,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                  color:
                      isSelected ? ColorPalette.primaryColorDark : Colors.white,
                ),
              ),
              countWidget,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.segment,
    required this.dateFormat,
    required this.onTap,
  });

  final JobOrder booking;
  final _BookingSegment segment;
  final DateFormat dateFormat;
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
                  // Booking number chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  // Status chip reflecting actual lifecycle segment
                  _StatusChip(segment: segment),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.segment});
  final _BookingSegment segment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: segment.chipColor.withOpacity(.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: segment.chipColor.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(segment.icon, size: 10, color: segment.chipColor),
          const SizedBox(width: 4),
          Text(
            segment.label,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: segment.chipColor,
            ),
          ),
        ],
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
