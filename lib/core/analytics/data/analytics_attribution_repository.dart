import 'package:shared_preferences/shared_preferences.dart';

// First-touch and last-touch campaign attribution storage.
// Only approved UTM parameters are persisted — arbitrary URL params are NOT.
class AnalyticsAttributionRepository {
  static const _approvedParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'referral_category'
  };
  static const _firstTouchKey = 'analytics_attribution_first_v1';
  static const _lastTouchKey = 'analytics_attribution_last_v1';

  // Allowlist-filter raw params before persisting.
  Map<String, String> _filterParams(Map<String, String?> raw) {
    final result = <String, String>{};
    for (final key in _approvedParams) {
      final val = raw[key];
      if (val != null && val.isNotEmpty && val.length <= 200) {
        result[key] = val;
      }
    }
    return result;
  }

  Future<void> recordAttribution(Map<String, String?> rawParams) async {
    final filtered = _filterParams(rawParams);
    if (filtered.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    // Persist last-touch always
    await prefs.setString(_lastTouchKey, _encode(filtered));
    // Persist first-touch only if not yet set
    if (!prefs.containsKey(_firstTouchKey)) {
      await prefs.setString(_firstTouchKey, _encode(filtered));
    }
  }

  Future<Map<String, String>?> getFirstTouch() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_firstTouchKey);
    return raw == null ? null : _decode(raw);
  }

  Future<Map<String, String>?> getLastTouch() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastTouchKey);
    return raw == null ? null : _decode(raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstTouchKey);
    await prefs.remove(_lastTouchKey);
  }

  String _encode(Map<String, String> m) => m.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');

  Map<String, String> _decode(String raw) {
    final result = <String, String>{};
    for (final part in raw.split('&')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        result[part.substring(0, idx)] =
            Uri.decodeComponent(part.substring(idx + 1));
      }
    }
    return result;
  }
}
