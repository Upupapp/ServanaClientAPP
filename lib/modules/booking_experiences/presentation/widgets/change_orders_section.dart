/// Change orders on a booking, on the customer's own booking detail screen.
///
/// A provider can request extra work mid-job, the backend records it, and
/// `GET /api/additional/booking/:bookingId` has always returned it. The
/// customer app never called that route, so the request existed everywhere
/// except where the person paying for it could see it.
///
/// ## What it will not do
///
/// It shows; it does not decide. Accepting or paying for a change order is a
/// money-moving action with its own state machine and its own error codes, and
/// putting a button here that half-implements it would be worse than the
/// silence it replaces. The section says what has been asked and what state it
/// is in, and directs anything actionable to support.
library;

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/booking_experiences/application/booking_experiences_controller.dart';
import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChangeOrdersSection extends StatelessWidget {
  const ChangeOrdersSection({super.key, required this.state});

  final ChangeOrdersState state;

  @override
  Widget build(BuildContext context) {
    // Loading, unreadable, or genuinely none — all draw nothing. A booking
    // with no change orders is the overwhelmingly common case, and an empty
    // "Additional work" heading on every booking detail would be noise.
    if (state is! ChangeOrdersReady) return const SizedBox.shrink();

    final ready = state as ChangeOrdersReady;
    if (ready.isEmpty) return const SizedBox.shrink();

    final awaiting = ready.awaitingCustomer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Flexible, not fixed. The heading and the badge share one line
              // and the badge is the part that must stay whole — a count
              // clipped to "1 to p" is worse than a shortened heading. At 200%
              // text the two together are wider than a 320dp phone.
              Flexible(
                child: Text(
                  'Additional work',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ColorPalette.secondaryText,
                  ),
                ),
              ),
              if (awaiting.isNotEmpty) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: '${awaiting.length} awaiting your payment',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryColorDark.withOpacity(.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${awaiting.length} to pay',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          for (final request in ready.requests) _ChangeOrderRow(request),
        ],
      ),
    );
  }
}

class _ChangeOrderRow extends StatelessWidget {
  const _ChangeOrderRow(this.request);

  final AdditionalWorkRequest request;

  @override
  Widget build(BuildContext context) {
    // `approvedAmount` is what has been AGREED; `totalAmount` is what was
    // ASKED FOR. Showing the request where the agreement belongs charges a
    // customer for a proposal, so the agreed figure wins and the label says
    // which one is on screen.
    final agreed = request.approvedAmount;
    final asked = request.totalAmount;
    final amount = agreed ?? asked;
    final isAgreed = agreed != null;

    final peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.accentText.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(request.status),
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                if (amount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    isAgreed
                        ? 'Agreed ${peso.format(amount)}'
                        : 'Requested ${peso.format(amount)}',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      color: ColorPalette.accentText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (request.isPaid) ...[
            const SizedBox(width: 8),
            Text(
              'Paid',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: ColorPalette.primaryColorDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Customer-facing wording for a status.
  ///
  /// `unknown` is deliberately vague rather than guessed. The enum keeps it
  /// separate from every known state precisely so a build that meets a new
  /// server status does not present one the server never claimed.
  static String _label(AdditionalWorkStatus status) => switch (status) {
        AdditionalWorkStatus.pendingAdminApproval => 'Waiting for review',
        AdditionalWorkStatus.waitingForPayment => 'Waiting for your payment',
        AdditionalWorkStatus.waitingWorkerApproval =>
          'Waiting for your provider',
        AdditionalWorkStatus.accepted => 'Accepted',
        AdditionalWorkStatus.inProgress => 'In progress',
        AdditionalWorkStatus.proceeding => 'In progress',
        AdditionalWorkStatus.completed => 'Completed',
        AdditionalWorkStatus.rejected => 'Declined',
        AdditionalWorkStatus.cancelled => 'Cancelled',
        AdditionalWorkStatus.unknown => 'Additional work requested',
      };
}
