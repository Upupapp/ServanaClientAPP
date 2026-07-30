import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/support/domain/support_ticket.dart';
import 'package:client/modules/support/presentation/widgets/support_status_chip.dart';
import 'package:flutter/material.dart';

class SupportTicketCard extends StatelessWidget {
  const SupportTicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${ticket.category.customerLabel}: ${ticket.title}. Status: ${ticket.status.customerLabel}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorPalette.border(.18)),
          ),
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
                  if (ticket.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColorDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ticket.unreadCount > 99
                            ? '99+'
                            : '${ticket.unreadCount}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ticket.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              if (ticket.safeSummary.isNotEmpty)
                Text(
                  ticket.safeSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 13,
                    color: ColorPalette.accentText,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SupportStatusChip(status: ticket.status),
                  const Spacer(),
                  if (ticket.updatedAt != null)
                    Text(
                      _formatDate(ticket.updatedAt!),
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 11,
                        color: ColorPalette.accentText.withOpacity(.7),
                      ),
                    ),
                ],
              ),
              if (ticket.status.needsCustomerAction) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.reply_rounded,
                          size: 12, color: Color(0xFFB45309)),
                      const SizedBox(width: 4),
                      Text(
                        'Your response is needed',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
