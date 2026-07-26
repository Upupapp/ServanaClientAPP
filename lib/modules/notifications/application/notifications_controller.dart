import 'package:client/modules/notifications/application/notifications_state.dart';
import 'package:client/modules/notifications/data/notifications_repository.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'package:flutter/foundation.dart';

class NotificationsController extends ChangeNotifier {
  final NotificationsRepository _repository;

  NotificationsController({required NotificationsRepository repository})
      : _repository = repository;

  NotificationsLoadState _state = NotificationsLoadState.initial;
  List<ServanaNotification> _notifications = [];
  int _unreadCount = 0;
  String? _error;
  String? _activeUid;

  // Incremented on logout/account-switch. Any async op that captures a
  // stale generation discards its result (LEAKSHIELD §5).
  int _sessionGen = 0;

  // Deduplicate foreground FCM messages by notificationKey.
  final Set<String> _seenKeys = {};

  NotificationsLoadState get state => _state;
  List<ServanaNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  String? get error => _error;
  bool get isEmpty => _state == NotificationsLoadState.ready && _notifications.isEmpty;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init(String uid) async {
    if (_state == NotificationsLoadState.loading) return;
    _activeUid = uid;
    final gen = ++_sessionGen;

    _state = NotificationsLoadState.loading;
    _error = null;
    notifyListeners();

    // Show cached data immediately while fetching fresh
    try {
      final cached = await _repository.loadCached(uid);
      final cachedCount = await _repository.loadCachedUnreadCount(uid);
      if (gen != _sessionGen) return;
      if (cached.isNotEmpty) {
        _notifications = cached;
        _unreadCount = cachedCount;
        notifyListeners();
      }
    } catch (_) {}

    await _fetch(uid, gen: gen, isRefresh: false);
  }

  Future<void> refresh() async {
    final uid = _activeUid;
    if (uid == null) return;
    if (_state == NotificationsLoadState.loading) return;
    final gen = _sessionGen;

    _state = NotificationsLoadState.refreshing;
    notifyListeners();

    await _fetch(uid, gen: gen, isRefresh: true);
  }

  Future<void> _fetch(String uid, {required int gen, required bool isRefresh}) async {
    try {
      final results = await Future.wait([
        _repository.fetchNotifications(uid: uid),
        _repository.fetchUnreadCount(uid),
      ]);
      if (gen != _sessionGen) return;
      _notifications = results[0] as List<ServanaNotification>;
      _unreadCount = results[1] as int;
      _seenKeys
        ..clear()
        ..addAll(_notifications.map((n) => n.notificationKey));
      _state = NotificationsLoadState.ready;
      _error = null;
    } catch (e) {
      if (gen != _sessionGen) return;
      if (isRefresh || _notifications.isEmpty) {
        _state = NotificationsLoadState.error;
        _error = 'Unable to load notifications. Pull down to retry.';
      } else {
        // Keep existing list, show offline state
        _state = NotificationsLoadState.offline;
      }
    }
    notifyListeners();
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  Future<void> markRead(String key) async {
    final idx = _notifications.indexWhere((n) => n.notificationKey == key);
    if (idx == -1) return;
    final prev = _notifications[idx];
    if (prev.isRead) return;

    // Optimistic update
    _notifications[idx] = prev.copyWith(isRead: true, canMarkRead: false);
    _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    try {
      await _repository.markRead(key);
    } catch (_) {
      // Rollback on failure
      if (_activeUid != null) {
        _notifications[idx] = prev;
        _unreadCount += 1;
        notifyListeners();
      }
    }
  }

  Future<void> markAllRead() async {
    final wasCount = _unreadCount;
    final prev = List<ServanaNotification>.from(_notifications);

    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true, canMarkRead: false))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _repository.markAllRead();
    } catch (_) {
      _notifications = prev;
      _unreadCount = wasCount;
      notifyListeners();
    }
  }

  Future<void> dismiss(String key) async {
    final idx = _notifications.indexWhere((n) => n.notificationKey == key);
    if (idx == -1) return;
    final removed = _notifications[idx];

    _notifications = List.from(_notifications)..removeAt(idx);
    if (!removed.isRead) _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    try {
      await _repository.dismiss(key);
    } catch (_) {
      // Restore on failure
      _notifications = List.from(_notifications)..insert(idx, removed);
      if (!removed.isRead) _unreadCount += 1;
      notifyListeners();
    }
  }

  // ─── Foreground FCM ────────────────────────────────────────────────────────

  /// Called by FcmCoordinator when a message arrives while the app is open.
  /// Increments unread count and prepends the notification if it is new.
  void onForegroundMessage(ServanaNotification notification) {
    if (_seenKeys.contains(notification.notificationKey)) return;
    _seenKeys.add(notification.notificationKey);
    _unreadCount += 1;
    _notifications = [notification, ..._notifications];
    notifyListeners();
  }

  // ─── Logout / account switch ───────────────────────────────────────────────

  void clearOnLogout() {
    final uid = _activeUid;
    ++_sessionGen;
    _activeUid = null;
    _notifications = [];
    _unreadCount = 0;
    _state = NotificationsLoadState.initial;
    _error = null;
    _seenKeys.clear();
    notifyListeners();
    // Clear the SharedPreferences cache for this account asynchronously.
    if (uid != null) {
      _repository.clearCacheForAccount(uid).ignore();
    }
  }
}
