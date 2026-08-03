import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/tracking/domain/tracking_eta.dart';
import 'package:client/modules/tracking/domain/tracking_freshness.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays the booking ETA from the backend.
///
/// TRACK-GAP-003: The ETA is computed once at assignment (haversine, 30 km/h).
/// It is NOT a live countdown. This card always shows:
///   - The original ETA in minutes
///   - The absolute ETA time ("by HH:MM")
///   - Whether the ETA has expired ("Should have arrived")
///   - The staleness of the underlying location data
class TrackingEtaCard extends StatelessWidget {
  const TrackingEtaCard({
    super.key,
    required this.eta,
    required this.freshness,
    required this.bookingStatus,
  });

  final TrackingEta? eta;
  final TrackingFreshness freshness;
  final String bookingStatus;

  @override
  Widget build(BuildContext context) {
    if (eta == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final e = eta!;
    final expired = e.isExpired(now);
    final remaining = e.remainingMinutes(now);

    final Color headerColor =
        expired ? Colors.orange.shade700 : ColorPalette.primaryColorDark;

    final String etaLabel;
    final String etaSublabel;

    if (expired) {
      etaLabel = 'Should have arrived';
      etaSublabel = 'ETA was ${DateFormat('h:mm a').format(e.etaAt)}';
    } else {
      etaLabel = '$remaining min away';
      etaSublabel = 'Estimated by ${DateFormat('h:mm a').format(e.etaAt)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorPalette.border(.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: headerColor.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              expired ? Icons.schedule_rounded : Icons.directions_car_rounded,
              color: headerColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etaLabel,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: headerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  etaSublabel,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.accentText,
                  ),
                ),
                const SizedBox(height: 4),
                _EstimateNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 11, color: ColorPalette.accentText.withOpacity(.7)),
        const SizedBox(width: 4),
        Text(
          'Estimated at assignment · not a live countdown',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontSize: 10,
            color: ColorPalette.accentText.withOpacity(.7),
          ),
        ),
      ],
    );
  }
}
