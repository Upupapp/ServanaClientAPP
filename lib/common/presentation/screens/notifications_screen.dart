import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  static String routeName = "Notifications";
  static String route = "/Notifications";
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotificationTile(
            title: "Booking confirmed",
            subtitle: "Signature Facial • Today 2:30 PM",
            isNew: true,
          ),
          _NotificationTile(
            title: "Promo reminder",
            subtitle: "30% off on selected services",
            isNew: true,
          ),
          _NotificationTile(
            title: "Booking completed",
            subtitle: "Body Massage • Jan 28",
            isNew: false,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.isNew,
  });

  final String title;
  final String subtitle;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorPalette.border(.55)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isNew
                        ? ColorPalette.primaryColorDark
                        : ColorPalette.primaryColor)
                    .withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isNew
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: ColorPalette.primaryColorDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      color: ColorPalette.secondaryText.withOpacity(.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isNew)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColorDark,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
