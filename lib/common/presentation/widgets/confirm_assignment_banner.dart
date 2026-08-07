import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';

/// Post-confirmation status banner that surfaces backend auto-assignment
/// to the customer while they're still on the confirmation screen.
///
/// Three visual states, driven by [isAssigned] and [isPolling]:
/// - **Assigned** — worker UID came back; banner shows the worker's name.
/// - **Polling** — actively watching for assignment.
/// - **Idle** — waiting (e.g. paused while a PayMongo payment is pending).
class ConfirmAssignmentBanner extends StatelessWidget {
  const ConfirmAssignmentBanner({
    super.key,
    required this.isAssigned,
    required this.isPolling,
    required this.workerName,
    required this.bookingStatus,
    this.timedOut = false,
  });

  final bool isAssigned;
  final bool isPolling;
  final String? workerName;
  final String? bookingStatus;

  /// True when the polling window closed without finding an assignment.
  final bool timedOut;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    if (isAssigned) {
      color = ColorPalette.primaryColorDark;
      icon = Icons.person_pin_circle_rounded;
      title =
          workerName == null ? 'Provider assigned' : 'Assigned to $workerName';
      subtitle = 'Your provider will reach out shortly.';
    } else if (isPolling) {
      color = Colors.blueGrey;
      icon = Icons.search_rounded;
      title = 'Assigning a provider';
      subtitle = 'A provider will be assigned to your booking soon.';
    } else if (timedOut) {
      color = Colors.blueGrey;
      icon = Icons.info_outline_rounded;
      title = 'Assignment in progress';
      subtitle =
          'It\'s taking a bit longer than usual. Check My Bookings to see your assignment.';
    } else {
      color = Colors.blueGrey;
      icon = Icons.hourglass_empty_rounded;
      title = 'Awaiting provider assignment';
      subtitle = 'You\'ll see the assignment in your bookings shortly.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPolling && !isAssigned)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
            )
          else
            Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
