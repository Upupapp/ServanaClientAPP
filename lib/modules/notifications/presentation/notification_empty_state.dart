import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';

class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: ColorPalette.accentText.withOpacity(0.3),
            ),
            const SizedBox(height: 14),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ColorPalette.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking updates, reminders, and service alerts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                color: ColorPalette.accentText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
