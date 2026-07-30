import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:flutter/material.dart';

/// A compact status banner that reflects the booking's current lifecycle state.
///
/// Status transitions are detected by the tracking controller's polling cycle
/// (TRACK-GAP-004 — no socket push). The banner auto-updates when the
/// [status] observable changes in the parent.
class TrackingStatusBar extends StatelessWidget {
  const TrackingStatusBar({
    super.key,
    required this.status,
    required this.isPolling,
  });

  final BookingStatus status;
  final bool isPolling;

  @override
  Widget build(BuildContext context) {
    final config = _configForStatus(status);

    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: config.color.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.color.withOpacity(.25)),
        ),
        child: Row(
          children: [
            if (isPolling && !BookingStatusMapper.isTerminal(status))
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: config.color,
                ),
              )
            else
              Icon(config.icon, size: 20, color: config.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BookingStatusMapper.customerLabel(status),
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: config.color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    BookingStatusMapper.heroSubtitle(status),
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 11,
                      color: ColorPalette.accentText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _configForStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.enRoute:
        return _StatusConfig(
          color: ColorPalette.primaryColorDark,
          icon: Icons.directions_car_rounded,
        );
      case BookingStatus.arrived:
        return const _StatusConfig(
          color: Color(0xFF16A34A),
          icon: Icons.check_circle_rounded,
        );
      case BookingStatus.inProgress:
        return _StatusConfig(
          color: ColorPalette.primaryColor,
          icon: Icons.construction_rounded,
        );
      case BookingStatus.awaitingCompletion:
        return const _StatusConfig(
          color: Color(0xFF7C3AED),
          icon: Icons.hourglass_bottom_rounded,
        );
      case BookingStatus.completed:
      case BookingStatus.reviewed:
        return const _StatusConfig(
          color: Color(0xFF16A34A),
          icon: Icons.verified_rounded,
        );
      case BookingStatus.cancelled:
      case BookingStatus.cancelledByProvider:
      case BookingStatus.cancelledByAdmin:
      case BookingStatus.expired:
      case BookingStatus.failed:
        return const _StatusConfig(
          color: ColorPalette.danger,
          icon: Icons.cancel_rounded,
        );
      default:
        return _StatusConfig(
          color: ColorPalette.accentText,
          icon: Icons.schedule_rounded,
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({required this.color, required this.icon});
  final Color color;
  final IconData icon;
}
