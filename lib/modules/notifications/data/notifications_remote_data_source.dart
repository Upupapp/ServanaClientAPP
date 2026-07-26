import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'notification_mapper.dart';

class NotificationsRemoteDataSource {
  final ServanaApiClient _api;

  NotificationsRemoteDataSource(this._api);

  Future<List<ServanaNotification>> listNotifications({String? filter}) async {
    final result = await _api.listNotifications(filter: filter);
    final raw = (result['data']?['notifications'] as List?) ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(mapNotification)
        .toList();
  }

  Future<int> getUnreadCount() async {
    final result = await _api.getNotificationsUnreadCount();
    return (result['data']?['count'] as int?) ?? 0;
  }

  Future<void> markRead(String key) async {
    await _api.markNotificationRead(key);
  }

  Future<void> markAllRead() async {
    await _api.markAllNotificationsRead();
  }

  Future<void> dismiss(String key) async {
    await _api.deleteNotification(key);
  }

  Future<void> registerFcmToken(String token) async {
    await _api.registerFcmToken(token);
  }

  Future<void> clearFcmToken() async {
    await _api.clearFcmToken();
  }
}
