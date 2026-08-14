import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/notifications/data/notifications_data_source.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'notification_mapper.dart';

/// Notifications over the legacy `/api/user/notifications*` routes.
///
/// This is the **compatibility** source in the TAB 02 pattern, and it is the
/// one every shipped build uses — the canonical namespace is not deployed.
/// It is unchanged in behaviour: the same calls, the same envelope reads, the
/// same domain objects. It now also declares [NotificationsDataSource] so the
/// repository can hold the interface rather than this class.
///
/// [dismiss] is intentionally not part of that interface. Legacy
/// `DELETE /api/user/notifications/:key` has no canonical successor, so it
/// stays here and the repository calls it directly — see
/// `notifications_data_source.dart` for why that gap is expressed in types.
class NotificationsRemoteDataSource implements NotificationsDataSource {
  final ServanaApiClient _api;

  NotificationsRemoteDataSource(this._api);

  @override
  Future<List<ServanaNotification>> listNotifications({String? filter}) async {
    final result = await _api.listNotifications(filter: filter);
    final raw = (result['data']?['notifications'] as List?) ?? [];
    return raw.whereType<Map<String, dynamic>>().map(mapNotification).toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final result = await _api.getNotificationsUnreadCount();
    return (result['data']?['count'] as int?) ?? 0;
  }

  /// The legacy route answers with no body, so there is no count to report.
  /// Null means "unknown", never zero — see [NotificationsDataSource.markRead].
  @override
  Future<int?> markRead(String key) async {
    await _api.markNotificationRead(key);
    return null;
  }

  @override
  Future<void> markAllRead() async {
    await _api.markAllNotificationsRead();
  }

  /// Deletes a notification. **Compatibility-only** — no canonical successor.
  Future<void> dismiss(String key) async {
    await _api.deleteNotification(key);
  }

  @override
  Future<void> registerFcmToken(String token) async {
    await _api.registerFcmToken(token);
  }

  @override
  Future<void> clearFcmToken() async {
    await _api.clearFcmToken();
  }
}
