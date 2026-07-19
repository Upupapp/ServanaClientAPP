import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:client/modules/messaging/presentation/screens/booking_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MessagesInboxScreen extends StatefulWidget {
  static String routeName = "MessagesInbox";
  static String route = "/Messages";
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final store = dpLocator<HomeStore>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => store.loadBookings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Only show bookings where a provider is or was assigned — those are the
  /// bookings that have an active chat thread. Pre-assignment and terminal
  /// states where nobody was ever assigned have no chat partner to show.
  bool _hasActiveChat(JobOrder b) {
    final status = BookingStatusMapper.fromString(b.jobOrderStatusToString);
    switch (status) {
      case BookingStatus.assigned:
      case BookingStatus.confirmed:
      case BookingStatus.enRoute:
      case BookingStatus.arrived:
      case BookingStatus.inProgress:
      case BookingStatus.awaitingCompletion:
      case BookingStatus.completed:
      case BookingStatus.reviewed:
        return true;
      default:
        break;
    }
    // Fallback for legacy JobOrderStatus values.
    return b.jobOrderStatus == JobOrderStatus.accepted ||
        b.jobOrderStatus == JobOrderStatus.inTransit ||
        b.jobOrderStatus == JobOrderStatus.inProgress ||
        b.jobOrderStatus == JobOrderStatus.completed;
  }

  /// Lower number = higher priority in the list.
  int _chatPriority(JobOrder b) {
    final status = BookingStatusMapper.fromString(b.jobOrderStatusToString);
    switch (status) {
      case BookingStatus.enRoute:
      case BookingStatus.arrived:
      case BookingStatus.inProgress:
      case BookingStatus.awaitingCompletion:
        return 0; // Active — show first
      case BookingStatus.assigned:
      case BookingStatus.confirmed:
        return 1; // Upcoming
      default:
        return 2; // Completed / other
    }
  }

  String _statusLabel(JobOrder b) {
    final status = BookingStatusMapper.fromString(b.jobOrderStatusToString);
    switch (status) {
      case BookingStatus.assigned:
        return 'Provider assigned';
      case BookingStatus.confirmed:
        return 'Booking confirmed';
      case BookingStatus.enRoute:
        return 'Provider en route';
      case BookingStatus.arrived:
        return 'Provider arrived';
      case BookingStatus.inProgress:
        return 'Service in progress';
      case BookingStatus.awaitingCompletion:
        return 'Awaiting completion';
      case BookingStatus.completed:
        return 'Service completed';
      case BookingStatus.reviewed:
        return 'Reviewed';
      default:
        return 'Booking #${b.jobOrderNumber}';
    }
  }

  List<JobOrder> _filtered(List<JobOrder> all) {
    final query = _searchQuery.trim().toLowerCase();
    final withChat = all.where(_hasActiveChat).toList()
      ..sort((a, b) {
        final pDiff = _chatPriority(a).compareTo(_chatPriority(b));
        if (pDiff != 0) return pDiff;
        return b.scheduleDate.compareTo(a.scheduleDate);
      });
    if (query.isEmpty) return withChat;
    return withChat
        .where((b) =>
            b.merchantName.toLowerCase().contains(query) ||
            b.merchantServiceName.toLowerCase().contains(query) ||
            b.jobOrderNumber.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Observer(
              builder: (context) {
                final filtered = _filtered(store.bookings.toList());
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
                  'Booking Conversations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed(NotificationsScreen.routeName),
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search,
                    color: ColorPalette.primaryColorDark, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    textInputAction: TextInputAction.search,
                    cursorColor: ColorPalette.primaryColorDark,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 14,
                      color: ColorPalette.secondaryText,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Search conversations',
                      hintStyle: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        color: ColorPalette.secondaryText.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.close,
                          color: ColorPalette.secondaryText.withOpacity(0.5),
                          size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _searchQuery.trim().isEmpty
                  ? 'No booking conversations yet.\n\nConversations with service providers appear here once a provider is assigned to your booking.'
                  : 'No conversations match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.secondaryText.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<JobOrder> bookings) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = bookings[i];
        // Use service name as the conversation title; fall back to booking number.
        final chatTitle = b.merchantServiceName.trim().isNotEmpty
            ? b.merchantServiceName.trim()
            : 'Booking #${b.jobOrderNumber}';
        return _ConversationTile(
          booking: b,
          statusLabel: _statusLabel(b),
          onTap: () => context.pushNamed(
            BookingChatScreen.routeName,
            pathParameters: {'jobOrderId': b.jobOrderID},
            extra: chatTitle,
          ),
        );
      },
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.booking,
    required this.statusLabel,
    required this.onTap,
  });

  final JobOrder booking;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = booking.merchantServiceName.trim().isNotEmpty
        ? booking.merchantServiceName.trim()
        : booking.merchantName;

    return Material(
      color: ColorPalette.secondaryBackground,
      borderRadius: BorderRadius.circular(15),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _InitialsAvatar(name: title),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: ColorPalette.secondaryText.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _smartDate(booking.scheduleDate),
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: ColorPalette.secondaryText.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: ColorPalette.secondaryText.withOpacity(0.35),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the scheduled service date as the conversation timestamp — this is
  /// when the service happens, which is more meaningful than booking creation.
  static String _smartDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    if (dDay == today) return 'Today';
    if (dDay == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (dDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(d);
  }
}

// ── Initials Avatar ───────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});
  final String name;

  static const _palette = [
    Color(0xFF2D78F5),
    Color(0xFFE96F9C),
    Color(0xFF9B6DE3),
    Color(0xFF2DBBA7),
    Color(0xFFF5A623),
  ];

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final color = name.isNotEmpty
        ? _palette[name.codeUnitAt(0) % _palette.length]
        : _palette[0];

    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}
