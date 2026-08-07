import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/constants/servana_urls.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingStageHeader extends StatelessWidget {
  const BookingStageHeader({
    super.key,
    required this.current,
    required this.total,
    required this.label,
  });

  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final value = current.clamp(1, total) / total;
    return Semantics(
      label: 'Booking step $current of $total: $label',
      value: '${(value * 100).round()} percent complete',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP $current OF $total  •  $label',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ColorPalette.primaryColorDark,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: ColorPalette.border(.35),
                color: ColorPalette.primaryColorDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingLoadingState extends StatelessWidget {
  const BookingLoadingState(this.label, {super.key, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 12 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.accentText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingCancellationDisclosure extends StatelessWidget {
  const BookingCancellationDisclosure({super.key});

  Future<void> _openPolicy() async {
    await launchUrl(
      Uri.parse(ServanaUrls.cancellationPolicy),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Cancellation terms. You may request cancellation before service starts. Eligibility for fees or refunds follows the Servana cancellation policy. Review cancellation policy.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorPalette.border(.55)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.policy_outlined, color: ColorPalette.primaryColorDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancellation terms',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You may request cancellation before service starts. Any fees or refund eligibility follow Servana’s cancellation policy.',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      height: 1.35,
                      color: ColorPalette.accentText,
                    ),
                  ),
                  TextButton(
                    onPressed: _openPolicy,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text('Review cancellation policy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactBookingLifecycle extends StatelessWidget {
  const CompactBookingLifecycle({
    super.key,
    required this.status,
    required this.isAssigned,
  });

  final BookingStatus status;
  final bool isAssigned;

  int get _current {
    if (status == BookingStatus.completed || status == BookingStatus.reviewed) {
      return 4;
    }
    if (status == BookingStatus.enRoute ||
        status == BookingStatus.arrived ||
        status == BookingStatus.inProgress ||
        status == BookingStatus.awaitingCompletion) {
      return 3;
    }
    if (isAssigned ||
        status == BookingStatus.assigned ||
        status == BookingStatus.confirmed) {
      return 2;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Created', 'Provider', 'Service', 'Complete'];
    return Semantics(
      container: true,
      label: 'Booking lifecycle. Current stage: ${labels[_current - 1]}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorPalette.border(.45)),
        ),
        child: Row(
          children: List.generate(labels.length * 2 - 1, (index) {
            if (index.isOdd) {
              final completed = index ~/ 2 + 1 < _current;
              return Expanded(
                child: Container(
                  height: 2,
                  color: completed
                      ? ColorPalette.primaryColorDark
                      : ColorPalette.border(.45),
                ),
              );
            }
            final stage = index ~/ 2 + 1;
            final completed = stage < _current;
            final active = stage == _current;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed || active
                        ? ColorPalette.primaryColorDark
                        : ColorPalette.border(.35),
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : _iconFor(stage),
                    size: 17,
                    color: completed || active
                        ? Colors.white
                        : ColorPalette.accentText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  labels[stage - 1],
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active
                        ? ColorPalette.primaryColorDark
                        : ColorPalette.accentText,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  IconData _iconFor(int stage) => switch (stage) {
        1 => Icons.receipt_long_outlined,
        2 => Icons.person_search_outlined,
        3 => Icons.home_repair_service_outlined,
        _ => Icons.flag_outlined,
      };
}
