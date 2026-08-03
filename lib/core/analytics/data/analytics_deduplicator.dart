// In-memory event deduplicator.
// Events with a non-null dedupKey are suppressed if the same key fired
// within the dedup window. The window is intentionally short (2s default)
// to catch only rapid-repeat fires (widget rebuild, route restoration, etc.)
// while allowing legitimate repeated user actions.
final class AnalyticsDeduplicator {
  AnalyticsDeduplicator({Duration window = const Duration(seconds: 2)})
      : _window = window;

  final Duration _window;
  final Map<String, DateTime> _seen = {};

  // Returns true if this key has been seen within the window (should suppress).
  // Returns false and records the key if it's new or expired.
  bool shouldSuppress(String dedupKey) {
    _evictExpired();
    final last = _seen[dedupKey];
    if (last != null && DateTime.now().difference(last) < _window) {
      return true;
    }
    _seen[dedupKey] = DateTime.now();
    return false;
  }

  void clear() => _seen.clear();

  void _evictExpired() {
    final cutoff = DateTime.now().subtract(_window);
    _seen.removeWhere((_, ts) => ts.isBefore(cutoff));
  }
}
