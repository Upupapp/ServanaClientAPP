/// Notifications over the canonical `/api/v1` namespace.
///
/// ## This is not reachable in any shipped build
///
/// It is selected only when `CanonicalAvailability.isAvailable(
/// V1Capability.notifications)` is true, which requires the build to be
/// compiled with `--dart-define=CANONICAL_V1_ENABLED=true` AND
/// `CANONICAL_V1_CAPABILITIES=notifications`. No production build passes
/// either, because `/api/v1` is absent from the backend's `origin/main`
/// (TAB 01, `docs/convergence-v1/TAB01_BACKEND_DELTA_MATRIX.md` §1). It exists
/// now so the migration is a flag flip and a test run on the day v1 deploys,
/// rather than a rewrite under time pressure.
///
/// ## Same domain object, different wire
///
/// Every method returns exactly what the legacy source returns. The item
/// projection is shared: the v1 handler answers `{data:{notifications:[…]}}`
/// with the same inbox rows the legacy route serves, so [mapNotification]
/// reads both without a branch. Where the two genuinely differ, the difference
/// is absorbed here and never surfaced:
///
///  - v1 paginates (`meta.page`); the legacy route returns everything. This
///    source requests a page large enough to match legacy behaviour and
///    reports only the items, so the repository's contract is unchanged.
///  - v1's markRead returns the resulting unread count; legacy returns
///    nothing. The interface makes that nullable rather than making callers
///    ask which transport they have.
library;

import 'package:client/core/network/api_envelope.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/notifications/data/notification_mapper.dart';
import 'package:client/modules/notifications/data/notifications_data_source.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';

class NotificationsCanonicalDataSource implements NotificationsDataSource {
  NotificationsCanonicalDataSource(this._api);

  final V1ApiClient _api;

  /// Matches the backend's `maxLimit` for this route. Asking for more is
  /// clamped server-side, so this is the largest single page available and
  /// keeps parity with the legacy route's unpaginated response.
  static const int _pageLimit = 100;

  @override
  Future<List<ServanaNotification>> listNotifications({String? filter}) async {
    final page = await _api.getPage<ServanaNotification>(
      V1Endpoints.notifications(),
      mapItem: mapNotification,
      itemsKey: 'notifications',
      limit: _pageLimit,
      query: <String, dynamic>{if (filter != null && filter.isNotEmpty) 'filter': filter},
    );
    return page.items;
  }

  @override
  Future<int> getUnreadCount() async {
    final envelope = await _api.get(V1Endpoints.notificationsUnreadCount());
    return _readCount(envelope) ?? 0;
  }

  @override
  Future<int?> markRead(String key) async {
    final envelope = await _api.patch(V1Endpoints.notificationRead(key));
    return _readCount(envelope);
  }

  @override
  Future<void> markAllRead() async {
    await _api.post(V1Endpoints.notificationsReadAll());
  }

  @override
  Future<void> registerFcmToken(String token) async {
    // Device registration is account-scoped server-side: the uid is the token
    // subject and the row is upserted on the device token, so this body
    // deliberately carries no identifier of its own.
    await _api.post(
      V1Endpoints.meDevices(),
      body: <String, dynamic>{'token': token, 'platform': 'mobile'},
    );
  }

  @override
  Future<void> clearFcmToken() async {
    await _api.delete(V1Endpoints.meDevices());
  }

  /// Reads an unread count from whichever of the two places it appears.
  ///
  /// `unreadCount` rides in `meta` on the list route and `count` sits in
  /// `data` on the dedicated route. Returning null rather than 0 when neither
  /// is present matters: 0 would clear a badge that may be non-empty.
  static int? _readCount(ApiEnvelope envelope) {
    final data = envelope.asMap;
    final direct = data['count'] ?? data['unreadCount'];
    if (direct is int) return direct;
    if (direct is num) return direct.toInt();
    return null;
  }
}
