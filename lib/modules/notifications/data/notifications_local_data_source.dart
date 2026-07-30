import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String _kNotificationsKey = 'notifications_cache_v1';
const String _kUnreadCountKey = 'notifications_unread_count_v1';
const int _kMaxCached = 30;

/// Account-scoped cache. The uid prefix prevents leaking one account's
/// cached notifications to the next (LEAKSHIELD §5).
class NotificationsLocalDataSource {
  static String _key(String uid) => '${_kNotificationsKey}_$uid';
  static String _countKey(String uid) => '${_kUnreadCountKey}_$uid';

  Future<List<Map<String, dynamic>>> loadCached(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCached(
      String uid, List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final limited = notifications.take(_kMaxCached).toList();
    await prefs.setString(_key(uid), jsonEncode(limited));
  }

  Future<int> loadCachedUnreadCount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey(uid)) ?? 0;
  }

  Future<void> saveCachedUnreadCount(String uid, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey(uid), count);
  }

  Future<void> clearForAccount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_key(uid)),
      prefs.remove(_countKey(uid)),
    ]);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = prefs.getKeys().where(
          (k) =>
              k.startsWith(_kNotificationsKey) ||
              k.startsWith(_kUnreadCountKey),
        );
    for (final k in toRemove) {
      await prefs.remove(k);
    }
  }
}
