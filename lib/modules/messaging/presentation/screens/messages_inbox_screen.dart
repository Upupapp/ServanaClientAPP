import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
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

  List<JobOrder> _filtered(List<JobOrder> all) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all
        .where((b) =>
            b.merchantName.toLowerCase().contains(query) ||
            b.jobOrderNumber.toLowerCase().contains(query) ||
            b.merchantServiceName.toLowerCase().contains(query))
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
                final all = store.bookings.toList()
                  ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
                final filtered = _filtered(all);
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
              const Expanded(
                child: Text(
                  'My Messages',
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
                      fontFamily: 'Gothic A1',
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
                        fontFamily: 'Gothic A1',
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
          child: Text(
            _searchQuery.trim().isEmpty
                ? 'No conversations yet'
                : 'No conversations match your search',
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
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = bookings[i];
        return _ConversationTile(
          booking: b,
          onTap: () => context.pushNamed(
            BookingChatScreen.routeName,
            pathParameters: {"jobOrderId": b.jobOrderID},
            extra: b.merchantName,
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.booking, required this.onTap});
  final JobOrder booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = booking.merchantServiceName.trim().isEmpty
        ? 'Booking #${booking.jobOrderNumber}'
        : '${booking.merchantServiceName} · Booking #${booking.jobOrderNumber}';

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
              const _Avatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      booking.merchantName,
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
                      subtitle,
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
                    _smartTimestamp(booking.createdDate),
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

  static String _smartTimestamp(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    if (dDay == today) {
      return DateFormat('h:mm a').format(d).toLowerCase();
    }
    if (dDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(d);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/messages/avatar_default.png',
        width: 45,
        height: 45,
        fit: BoxFit.cover,
      ),
    );
  }
}
