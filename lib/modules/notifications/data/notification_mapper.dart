import 'package:client/modules/notifications/domain/notification_target.dart';
import 'package:client/modules/notifications/domain/notification_type.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';

ServanaNotification mapNotification(Map<String, dynamic> json) {
  final route = json['route'] as Map<String, dynamic>?;
  final rawCreatedAt = json['createdAt'];
  final rawReadAt = json['readAt'];
  final rawExpiresAt = json['expiresAt'];
  final statusStr = (json['status'] as String?) ?? 'unread';

  return ServanaNotification(
    notificationKey:
        ((json['notificationKey'] ?? json['notification_key'] ?? '') as Object)
            .toString(),
    type: notificationTypeFromString(json['type'] as String?),
    title: ((json['title'] ?? '') as Object).toString(),
    safeBody:
        ((json['safeBody'] ?? json['safe_body'] ?? '') as Object).toString(),
    safeContextLabel:
        (json['safeContextLabel'] ?? json['safe_context_label']) as String?,
    target: targetFromRoute(route),
    isRead: statusStr == 'read',
    canMarkRead: (json['canMarkRead'] ?? json['can_mark_read'] ?? true) as bool,
    canDismiss: (json['canDismiss'] ?? json['can_dismiss'] ?? true) as bool,
    canOpenDetail:
        (json['canOpenDetail'] ?? json['can_open_detail'] ?? false) as bool,
    createdAt: rawCreatedAt != null
        ? DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now()
        : DateTime.now(),
    expiresAt: rawExpiresAt != null
        ? DateTime.tryParse(rawExpiresAt.toString())
        : null,
    readAt: rawReadAt != null ? DateTime.tryParse(rawReadAt.toString()) : null,
  );
}

// Maps a FCM RemoteMessage data payload to a minimal ServanaNotification for
// foreground display. The full notification is always fetched from the backend.
ServanaNotification? mapFcmDataToNotification(Map<String, dynamic> data) {
  final key = data['notificationKey'] as String?;
  final type = data['type'] as String?;
  if (key == null || key.isEmpty) return null;
  return ServanaNotification(
    notificationKey: key,
    type: notificationTypeFromString(type),
    title: (data['title'] as String?) ?? '',
    safeBody: (data['body'] as String?) ?? '',
    target: data['routeKey'] != null
        ? targetFromRoute({
            'routeKey': data['routeKey'],
            'resourceId': data['resourceId'] ?? '',
          })
        : null,
    isRead: false,
    canMarkRead: true,
    canDismiss: true,
    canOpenDetail: data['routeKey'] != null,
    createdAt: DateTime.now(),
  );
}
