import 'package:client/modules/notifications/domain/notification_target.dart';
import 'package:client/modules/notifications/domain/notification_type.dart';

class ServanaNotification {
  final String notificationKey;
  final ServanaNotificationType type;
  final String title;
  final String safeBody;
  final String? safeContextLabel;
  final NotificationTarget? target;
  final bool isRead;
  final bool canMarkRead;
  final bool canDismiss;
  final bool canOpenDetail;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? readAt;

  const ServanaNotification({
    required this.notificationKey,
    required this.type,
    required this.title,
    required this.safeBody,
    this.safeContextLabel,
    this.target,
    required this.isRead,
    required this.canMarkRead,
    required this.canDismiss,
    required this.canOpenDetail,
    required this.createdAt,
    this.expiresAt,
    this.readAt,
  });

  ServanaNotification copyWith({bool? isRead, bool? canMarkRead}) =>
      ServanaNotification(
        notificationKey: notificationKey,
        type: type,
        title: title,
        safeBody: safeBody,
        safeContextLabel: safeContextLabel,
        target: target,
        isRead: isRead ?? this.isRead,
        canMarkRead: canMarkRead ?? this.canMarkRead,
        canDismiss: canDismiss,
        canOpenDetail: canOpenDetail,
        createdAt: createdAt,
        expiresAt: expiresAt,
        readAt: readAt,
      );
}
