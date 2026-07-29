import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/presentation/screens/create_support_ticket_screen.dart';
import 'package:client/modules/support/presentation/screens/help_center_screen.dart';
import 'package:client/modules/support/presentation/screens/safety_support_screen.dart';
import 'package:client/modules/support/presentation/screens/support_tickets_screen.dart';
import 'package:flutter/material.dart';

class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({super.key});

  static const String route = '/support';
  static const String routeName = 'SupportHome';

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  late final SupportController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<SupportController>();
    _ctrl.loadTickets();
    _ctrl.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: ColorPalette.secondaryText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Safety banner — always first
          _SafetyBanner(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SafetySupportScreen()),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How can we help?',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          _SupportOptionCard(
            icon: Icons.calendar_today_outlined,
            title: 'Booking Issue',
            subtitle: 'Problems with a booked service',
            onTap: () => _openCreate(context, category: 'booking'),
          ),
          _SupportOptionCard(
            icon: Icons.credit_card_outlined,
            title: 'Payment or Refund',
            subtitle: 'Charges, billing, or refund requests',
            onTap: () => _openCreate(context, category: 'payment'),
          ),
          _SupportOptionCard(
            icon: Icons.person_off_outlined,
            title: 'Provider Conduct',
            subtitle: 'Concerns about your service provider',
            onTap: () => _openCreate(context, category: 'provider_conduct'),
          ),
          _SupportOptionCard(
            icon: Icons.manage_accounts_outlined,
            title: 'Account Problem',
            subtitle: 'Login, profile, or account access',
            onTap: () => _openCreate(context, category: 'account'),
          ),
          _SupportOptionCard(
            icon: Icons.build_outlined,
            title: 'Technical Issue',
            subtitle: 'App errors or glitches',
            onTap: () => _openCreate(context, category: 'technical'),
          ),
          _SupportOptionCard(
            icon: Icons.more_horiz_rounded,
            title: 'Other',
            subtitle: 'Something else not listed above',
            onTap: () => _openCreate(context, category: 'other'),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Ticket history row
          ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) {
              final open = _ctrl.tickets.where((t) => t.status.isActive).length;
              final unread = _ctrl.unreadCount;
              return _HistoryRow(
                openCount: open,
                unreadCount: unread,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Help center row
          _HelpCenterRow(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreate(BuildContext context, {required String category}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateSupportTicketScreen(initialCategory: category),
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Safety and emergency support',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.emergency_outlined, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety & Emergency',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Feeling unsafe or in danger? Tap here.',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 12,
                        color: Colors.white.withOpacity(.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportOptionCard extends StatelessWidget {
  const _SupportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title: $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorPalette.border(.18)),
          ),
          child: Row(
            children: [
              Icon(icon, color: ColorPalette.primaryColorDark, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 12,
                        color: ColorPalette.accentText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: ColorPalette.accentText.withOpacity(.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.openCount,
    required this.unreadCount,
    required this.onTap,
  });
  final int openCount;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'My support requests',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorPalette.border(.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.inbox_outlined,
                  color: ColorPalette.primaryColorDark, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Support Requests',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    if (openCount > 0)
                      Text(
                        '$openCount open ticket${openCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 12,
                          color: ColorPalette.accentText,
                        ),
                      ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColorDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right_rounded,
                  color: ColorPalette.accentText.withOpacity(.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpCenterRow extends StatelessWidget {
  const _HelpCenterRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Help center and FAQ',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorPalette.border(.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  color: ColorPalette.primaryColorDark, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Help Center & FAQ',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.secondaryText,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: ColorPalette.accentText.withOpacity(.6)),
            ],
          ),
        ),
      ),
    );
  }
}
