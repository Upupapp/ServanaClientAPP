import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/notifications/domain/notification_type.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final ServanaNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onMarkRead;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDismiss,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.notificationKey),
      direction: notification.canDismiss
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: ColorPalette.danger.withOpacity(0.85),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isUnread
                ? ColorPalette.primaryColorLight.withOpacity(0.45)
                : ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread
                  ? ColorPalette.primaryColorDark.withOpacity(0.14)
                  : ColorPalette.secondaryBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.shadow(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotifIcon(type: notification.type, isUnread: isUnread),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 13.5,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: ColorPalette.secondaryText,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isUnread)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorPalette.primaryColorDark,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.safeBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 12,
                          color: ColorPalette.accentText,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _timeAgo(notification.createdAt),
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontSize: 11,
                              color: ColorPalette.accentText.withOpacity(0.7),
                            ),
                          ),
                          if (notification.safeContextLabel != null) ...[
                            Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 11,
                                color: ColorPalette.accentText.withOpacity(0.5),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                notification.safeContextLabel!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontSize: 11,
                                  color:
                                      ColorPalette.accentText.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (notification.canMarkRead && isUnread)
                            GestureDetector(
                              onTap: onMarkRead,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  'Mark read',
                                  style: TextStyle(
                                    fontFamily: FontPalette.primaryFontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: ColorPalette.primaryColorDark,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _NotifIcon extends StatelessWidget {
  final ServanaNotificationType type;
  final bool isUnread;

  const _NotifIcon({required this.type, required this.isUnread});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolve();
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  (IconData, Color) _resolve() {
    return switch (type) {
      ServanaNotificationType.bookingCreated => (
          Icons.calendar_today_rounded,
          ColorPalette.primaryColorDark,
        ),
      ServanaNotificationType.bookingConfirmed => (
          Icons.check_circle_outline_rounded,
          Colors.green,
        ),
      ServanaNotificationType.bookingCancelled => (
          Icons.cancel_outlined,
          ColorPalette.danger,
        ),
      ServanaNotificationType.serviceCompleted => (
          Icons.star_border_rounded,
          Colors.amber,
        ),
      ServanaNotificationType.providerAssigned => (
          Icons.person_outline_rounded,
          ColorPalette.primaryColorDark,
        ),
      ServanaNotificationType.providerEnRoute ||
      ServanaNotificationType.providerArrived =>
        (Icons.directions_car_outlined, Colors.blue),
      ServanaNotificationType.paymentPaid ||
      ServanaNotificationType.paymentFailed =>
        (Icons.receipt_long_outlined, Colors.green),
      ServanaNotificationType.messageReceived => (
          Icons.chat_bubble_outline_rounded,
          ColorPalette.primaryColor,
        ),
      ServanaNotificationType.bookingReminder => (
          Icons.access_time_rounded,
          Colors.orange,
        ),
      _ => (Icons.notifications_none_rounded, ColorPalette.accentText),
    };
  }
}
