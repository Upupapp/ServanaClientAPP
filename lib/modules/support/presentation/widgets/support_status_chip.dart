import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/support/domain/support_ticket_status.dart';
import 'package:flutter/material.dart';

class SupportStatusChip extends StatelessWidget {
  const SupportStatusChip({super.key, required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors();
    return Semantics(
      label: 'Status: ${status.customerLabel}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          status.customerLabel,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }

  (Color, Color, Color) _colors() {
    switch (status) {
      case SupportTicketStatus.submitted:
        return (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), const Color(0xFFBFDBFE));
      case SupportTicketStatus.open:
      case SupportTicketStatus.waitingForSupport:
        return (const Color(0xFFF0FDF4), const Color(0xFF15803D), const Color(0xFFBBF7D0));
      case SupportTicketStatus.waitingForCustomer:
        return (const Color(0xFFFFFBEB), const Color(0xFFB45309), const Color(0xFFFDE68A));
      case SupportTicketStatus.escalated:
        return (const Color(0xFFFFF7ED), const Color(0xFFC2410C), const Color(0xFFFED7AA));
      case SupportTicketStatus.resolved:
        return (const Color(0xFFF0FDF4), const Color(0xFF166534), const Color(0xFFBBF7D0));
      case SupportTicketStatus.closed:
        return (const Color(0xFFF9FAFB), const Color(0xFF6B7280), const Color(0xFFE5E7EB));
      case SupportTicketStatus.unknown:
        return (const Color(0xFFF9FAFB), const Color(0xFF9CA3AF), const Color(0xFFE5E7EB));
    }
  }
}
