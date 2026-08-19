import 'dart:convert';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Self-contained card that renders a QR encoding the booking id + worker code
/// together with the human-readable code below it. The provider app's scanner
/// reads the JSON payload and verifies the booking id, then sends the code
/// back to the backend as `workerCode` on the Start Job endpoint. If the
/// technician can't scan, they can type the digits manually.
///
/// When [workerCode] is null or empty the card renders a "pending" state: the
/// QR area shows a clock placeholder, the code field shows "Pending", and the
/// subtitle switches to [pendingSubtitle]. The BE only populates `workerCode`
/// once an assigned technician accepts the booking, so pending is the natural
/// state of any freshly-created booking and any booking still awaiting accept.
class QrWorkerCodeDisplay extends StatelessWidget {
  const QrWorkerCodeDisplay({
    super.key,
    required this.bookingId,
    required this.workerCode,
    this.title = 'Provider Service Code',
    this.subtitle =
        'Show this QR to your provider to start the service. They can also type the code.',
    this.pendingSubtitle =
        'Your service code will appear here once a provider accepts your booking.',
  });

  final int? bookingId;
  final String? workerCode;
  final String title;
  final String subtitle;
  final String pendingSubtitle;

  bool get _hasCode => workerCode != null && workerCode!.isNotEmpty;

  // QR payload schema:
  //   v: 2 → emits both `workerCode` (canonical) and `otp` (legacy) keys.
  //   v: 1 → only `bookingId` + `otp` (the original shape).
  // The deployed provider scanner reads `jsonData['otp']`, so the legacy key
  // is kept until the scanner is updated to prefer `workerCode`. The version
  // tag lets the scanner branch cleanly once it's updated.
  String get _qrPayload {
    if (bookingId != null) {
      return jsonEncode({
        'v': 2,
        'bookingId': bookingId,
        'workerCode': workerCode,
        'otp': workerCode,
      });
    }
    return workerCode ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: ColorPalette.primaryColorDark.withOpacity(.3)),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.shadow(.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: ColorPalette.primaryColorDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasCode ? subtitle : pendingSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.accentText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ColorPalette.primaryColorDark.withOpacity(.2),
              ),
            ),
            child: _hasCode
                ? QrImageView(
                    data: _qrPayload,
                    version: QrVersions.auto,
                    size: 180,
                    gapless: true,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  )
                : const _PendingPlaceholder(),
          ),
          const SizedBox(height: 14),
          _CodePill(workerCode: workerCode),
        ],
      ),
    );
  }
}

class _PendingPlaceholder extends StatelessWidget {
  const _PendingPlaceholder();

  @override
  Widget build(BuildContext context) {
    // A MINIMUM of 180 square, not a fixed 180. The placeholder holds an icon
    // and two lines of text, and at text scale 2.0 that content is taller than
    // 180 — so a fixed height clipped it on both confirmation screens, which
    // are the screens a customer lands on immediately after paying.
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, minHeight: 180),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 56,
            color: ColorPalette.accentText.withOpacity(.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Pending',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.accentText,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Awaiting provider',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.accentText.withOpacity(.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodePill extends StatelessWidget {
  const _CodePill({required this.workerCode});

  final String? workerCode;

  bool get _hasCode => workerCode != null && workerCode!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _hasCode
            ? ColorPalette.primaryColorDark.withOpacity(.1)
            : ColorPalette.accentText.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _hasCode
              ? ColorPalette.primaryColorDark.withOpacity(.3)
              : ColorPalette.accentText.withOpacity(.25),
        ),
      ),
      child: _hasCode
          ? Text(
              workerCode!,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.primaryColorDark,
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: 6,
              ),
            )
          : Text(
              'Pending',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.accentText,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
    );
  }
}
