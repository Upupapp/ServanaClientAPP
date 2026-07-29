import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/support/application/support_ticket_controller.dart';
import 'package:client/modules/support/presentation/widgets/support_reply_bubble.dart';
import 'package:client/modules/support/presentation/widgets/support_reply_composer.dart';
import 'package:client/modules/support/presentation/widgets/support_status_chip.dart';
import 'package:flutter/material.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketKey});

  final String ticketKey;
  static const String route = '/support/tickets/:ticketKey';
  static const String routeName = 'SupportTicketDetail';

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends State<SupportTicketDetailScreen> {
  late final SupportTicketController _ctrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<SupportTicketController>();
    _ctrl.addListener(_onControllerChange);
    _ctrl.loadTicket(widget.ticketKey);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChange);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (!mounted) return;
    // Scroll to bottom when replies load or a new reply arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _closeTicket() async {
    final confirm = await _showConfirm(
      context,
      title: 'Close this request?',
      body: 'Closing marks this request as resolved. You can reopen it if the issue returns.',
      confirmLabel: 'Close Request',
    );
    if (!confirm) return;
    await _ctrl.closeTicket();
  }

  Future<void> _reopenTicket() async {
    await _ctrl.reopenTicket();
  }

  Future<bool> _showConfirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorPalette.primaryBackground,
        title: Text(title,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              color: ColorPalette.secondaryText,
            )),
        content: Text(body,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.accentText,
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.primaryColorDark,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result == true;
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
        title: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) => Text(
            _ctrl.ticket != null
                ? '#${_ctrl.ticket!.shortRef}'
                : 'Request Detail',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              color: ColorPalette.secondaryText,
            ),
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) {
              final ticket = _ctrl.ticket;
              if (ticket == null) return const SizedBox.shrink();
              if (ticket.canClose) {
                return IconButton(
                  tooltip: 'Close request',
                  icon: Icon(Icons.check_circle_outline_rounded,
                      color: ColorPalette.primaryColorDark),
                  onPressed: _ctrl.isMutating ? null : _closeTicket,
                );
              }
              if (ticket.canReopen) {
                return TextButton(
                  onPressed: _ctrl.isMutating ? null : _reopenTicket,
                  child: Text(
                    'Reopen',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.primaryColorDark,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.status == TicketDetailStatus.loading &&
              _ctrl.ticket == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_ctrl.status == TicketDetailStatus.error &&
              _ctrl.ticket == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      color: ColorPalette.accentText, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    _ctrl.error ?? 'Could not load this request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.accentText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _ctrl.loadTicket(widget.ticketKey),
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

          final ticket = _ctrl.ticket;
          if (ticket == null) return const SizedBox.shrink();

          final canReply = ticket.canReply && !_ctrl.isMutating;

          return Column(
            children: [
              // Ticket header
              Container(
                color: ColorPalette.secondaryBackground,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.category.customerLabel,
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.accentText,
                              letterSpacing: .3,
                            ),
                          ),
                        ),
                        SupportStatusChip(status: ticket.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.title,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    if (ticket.bookingId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.link_rounded,
                              size: 12, color: ColorPalette.accentText),
                          const SizedBox(width: 4),
                          Text(
                            'Booking ref attached',
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontSize: 11,
                              color: ColorPalette.accentText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_ctrl.mutationError != null)
                _ErrorBanner(message: _ctrl.mutationError!),
              // Reply thread
              Expanded(
                child: ticket.replies.isEmpty
                    ? Center(
                        child: Text(
                          'No replies yet.\nServana Support will respond soon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            color: ColorPalette.accentText,
                            height: 1.6,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: ticket.replies.length,
                        itemBuilder: (context, i) {
                          final reply = ticket.replies[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SupportReplyBubble(
                              reply: reply,
                              onRetry: reply.isFailed
                                  ? () => _ctrl.retryReply(
                                      reply.clientReplyId ?? '')
                                  : null,
                              onDeleteFailed: reply.isFailed
                                  ? () => _ctrl.removeFailedReply(
                                      reply.clientReplyId ?? '')
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
              if (!ticket.canReply)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    ticket.status.isActive
                        ? 'Replies are temporarily disabled while your request is being reviewed.'
                        : 'This request is closed. Reopen it to send more messages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      color: ColorPalette.accentText.withOpacity(.7),
                    ),
                  ),
                ),
              if (canReply)
                SupportReplyComposer(
                  isSending: _ctrl.isReplying,
                  onSend: (msg) => _ctrl.sendReply(msg),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorPalette.danger.withOpacity(.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: ColorPalette.danger, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                color: ColorPalette.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
