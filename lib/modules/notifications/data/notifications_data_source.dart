/// The contract both notification transports satisfy.
///
/// `NotificationsRemoteDataSource` implements it over the legacy
/// `/api/user/notifications*` routes; `NotificationsCanonicalDataSource`
/// implements it over `/api/v1/notifications*`. `NotificationsRepository`
/// holds this type and not either concrete class, so the choice between them
/// is one line in the repository and invisible to `NotificationsController`
/// and to every widget.
///
/// ## What is deliberately NOT here
///
/// `dismiss` — deleting a notification. TAB 01's delta matrix found that
/// legacy `DELETE /api/user/notifications/:key` has **no canonical successor**:
/// v1 offers list, unread-count, read and read-all, and no delete. Putting
/// `dismiss` on this interface would force the canonical implementation to
/// either invent an endpoint that does not exist or throw at runtime on a
/// button the customer can see.
///
/// Leaving it off means the gap is visible in the type system: the repository
/// has to reach for the compatibility source explicitly, and the reason is
/// written down next to the call. That is the honest shape of a partially
/// migrated domain, and it is why `V1Capability.notifications` being enabled
/// still does not make this domain fully canonical.
library;

import 'package:client/modules/notifications/domain/servana_notification.dart';

abstract interface class NotificationsDataSource {
  /// The inbox. [filter] is passed through untouched; null means everything.
  Future<List<ServanaNotification>> listNotifications({String? filter});

  /// The unread badge count.
  Future<int> getUnreadCount();

  /// Marks one notification read.
  ///
  /// Returns the resulting unread count when the transport can supply it
  /// without a second round trip, and null when it cannot. v1 returns it from
  /// the same store resolution the list used; the legacy route returns nothing,
  /// so callers must treat null as "re-fetch if you need the badge" rather
  /// than as zero.
  Future<int?> markRead(String key);

  /// Marks the whole inbox read.
  Future<void> markAllRead();

  /// Registers this device for push.
  Future<void> registerFcmToken(String token);

  /// Releases this device from push.
  Future<void> clearFcmToken();
}
