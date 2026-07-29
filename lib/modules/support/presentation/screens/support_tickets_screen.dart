import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/support/application/support_controller.dart';
import 'package:client/modules/support/presentation/screens/create_support_ticket_screen.dart';
import 'package:client/modules/support/presentation/screens/support_ticket_detail_screen.dart';
import 'package:client/modules/support/presentation/widgets/support_empty_state.dart';
import 'package:client/modules/support/presentation/widgets/support_ticket_card.dart';
import 'package:flutter/material.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  static const String route = '/support/tickets';
  static const String routeName = 'SupportTickets';

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  late final SupportController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<SupportController>();
    if (_ctrl.status == SupportLoadStatus.initial) {
      _ctrl.loadTickets();
    }
  }

  String _filterLabel(TicketFilter f) {
    switch (f) {
      case TicketFilter.open: return 'Open';
      case TicketFilter.needsAction: return 'Needs Action';
      case TicketFilter.resolved: return 'Resolved';
      case TicketFilter.closed: return 'Closed';
      case TicketFilter.all: return 'All';
    }
  }

  String _emptyTitle(TicketFilter f) {
    switch (f) {
      case TicketFilter.open: return 'No open requests';
      case TicketFilter.needsAction: return 'No requests need your response';
      case TicketFilter.resolved: return 'No resolved requests';
      case TicketFilter.closed: return 'No closed requests';
      case TicketFilter.all: return 'No support requests yet';
    }
  }

  String _emptyBody(TicketFilter f) {
    if (f == TicketFilter.all) {
      return 'When you contact Servana Support, your requests will appear here.';
    }
    return 'Try viewing All tickets or start a new request.';
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
          'My Requests',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            color: ColorPalette.secondaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded,
                color: ColorPalette.primaryColorDark),
            tooltip: 'New request',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CreateSupportTicketScreen(),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.status == SupportLoadStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      color: ColorPalette.accentText, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    _ctrl.error ?? 'Could not load support requests.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.accentText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _ctrl.loadTickets(refresh: true),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        color: ColorPalette.primaryColorDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter tabs
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: TicketFilter.values.map((f) {
                    final selected = _ctrl.filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Semantics(
                        selected: selected,
                        label: _filterLabel(f),
                        child: GestureDetector(
                          onTap: () => _ctrl.setFilter(f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? ColorPalette.primaryColorDark
                                  : ColorPalette.secondaryBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? ColorPalette.primaryColorDark
                                    : ColorPalette.border(.3),
                              ),
                            ),
                            child: Text(
                              _filterLabel(f),
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : ColorPalette.accentText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _ctrl.isLoading && _ctrl.tickets.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _ctrl.filteredTickets.isEmpty
                        ? SupportEmptyState(
                            icon: Icons.inbox_outlined,
                            title: _emptyTitle(_ctrl.filter),
                            body: _emptyBody(_ctrl.filter),
                            actionLabel: 'New Request',
                            onAction: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CreateSupportTicketScreen(),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _ctrl.loadTickets(refresh: true),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                              itemCount: _ctrl.filteredTickets.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final ticket = _ctrl.filteredTickets[i];
                                return SupportTicketCard(
                                  ticket: ticket,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SupportTicketDetailScreen(
                                        ticketKey: ticket.ticketKey,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
