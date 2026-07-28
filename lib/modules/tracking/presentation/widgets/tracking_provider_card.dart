import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:client/modules/tracking/domain/tracking_freshness.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows provider identity and last-location timestamp.
///
/// "Last seen" time is derived from [BookingTrackingState.providerLocation.updatedAt]
/// — a backend-authoritative timestamp. It is never synthesised.
class TrackingProviderCard extends StatelessWidget {
  const TrackingProviderCard({
    super.key,
    required this.state,
    required this.onMessageTap,
  });

  final BookingTrackingState state;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    final name = state.providerName;
    final phone = state.providerPhone;
    final loc = state.providerLocation;
    final freshness = state.freshness;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColorDark.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_pin_circle_rounded,
                  color: ColorPalette.primaryColorDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Your Provider',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    if (loc != null) ...[
                      const SizedBox(height: 2),
                      _LastSeenLabel(updatedAt: loc.updatedAt, freshness: freshness),
                    ] else ...[
                      const SizedBox(height: 2),
                      Text(
                        'Locating provider…',
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
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  color: ColorPalette.primaryColorDark,
                  onTap: onMessageTap,
                ),
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    color: const Color(0xFF16A34A),
                    onTap: () => _launchPhone(phone),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _LastSeenLabel extends StatelessWidget {
  const _LastSeenLabel({required this.updatedAt, required this.freshness});

  final DateTime updatedAt;
  final TrackingFreshness freshness;

  String _label() {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return DateFormat('h:mm a').format(updatedAt);
  }

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (freshness) {
      case TrackingFreshness.live:
        color = const Color(0xFF16A34A);
        break;
      case TrackingFreshness.stale:
        color = const Color(0xFFF59E0B);
        break;
      case TrackingFreshness.unknown:
        color = ColorPalette.accentText;
        break;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text(
          'Last seen ${_label()}',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
