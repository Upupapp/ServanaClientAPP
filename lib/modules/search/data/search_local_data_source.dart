import 'package:shared_preferences/shared_preferences.dart';

class SearchLocalDataSource {
  static const String _kHistoryKey = 'search_recent_terms';
  static const int _kMaxHistory = 10;

  static Future<List<String>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kHistoryKey) ?? const [];
  }

  static Future<void> addTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kHistoryKey) ?? [];
    final updated = [term, ...existing.where((t) => t != term)]
        .take(_kMaxHistory)
        .toList();
    await prefs.setStringList(_kHistoryKey, updated);
  }

  static Future<void> removeTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kHistoryKey) ?? [];
    await prefs.setStringList(
        _kHistoryKey, existing.where((t) => t != term).toList());
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }
}
