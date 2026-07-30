import 'package:flutter/semantics.dart';

/// Throttled live-region announcements for the Servana Client app.
///
/// Prevents overwhelming screen-reader users with rapid-fire updates
/// (e.g. live tracking, unread counts, search result counts).
///
/// Usage:
///   LiveRegionManager.announce('Payment confirmed');
///   LiveRegionManager.announcePolite('3 services found');
///   LiveRegionManager.announceAssertive('Session expired. Please sign in again.');
class LiveRegionManager {
  LiveRegionManager._();

  static final Map<String, DateTime> _lastAnnounced = {};

  /// Announce a polite update. Will NOT repeat the same message within
  /// [minInterval]. Use for non-urgent content (search count, message received).
  static void announcePolite(
    String message, {
    Duration minInterval = const Duration(seconds: 3),
  }) {
    _announce(message, assertive: false, minInterval: minInterval);
  }

  /// Announce an assertive update for truly urgent content.
  /// Use sparingly: session expired, critical validation failure, safety alert.
  /// Always fires regardless of interval.
  static void announceAssertive(String message) {
    _announce(message, assertive: true, minInterval: Duration.zero);
  }

  /// Generic announce — polite by default. Only fires if message changed
  /// OR enough time has passed.
  static void announce(
    String message, {
    bool assertive = false,
    Duration minInterval = const Duration(seconds: 2),
  }) {
    _announce(message, assertive: assertive, minInterval: minInterval);
  }

  static void _announce(
    String message, {
    required bool assertive,
    required Duration minInterval,
  }) {
    if (message.isEmpty) return;
    final now = DateTime.now();
    final last = _lastAnnounced[message];
    if (last != null && now.difference(last) < minInterval) return;
    _lastAnnounced[message] = now;
    // Flutter's SemanticsService.announce is polite by default on both
    // platforms. For assertive content we interrupt by sending immediately
    // (interval = zero) rather than relying on a missing API parameter.
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Clear the throttle cache. Call on screen changes to allow fresh
  /// announcements for the same messages on a new screen.
  static void clearCache() => _lastAnnounced.clear();

  /// Announce a search result count exactly once per search.
  static void announceResultCount(int count) {
    final label = count == 0
        ? 'No services found'
        : '$count service${count == 1 ? '' : 's'} found';
    announcePolite(label, minInterval: const Duration(milliseconds: 800));
  }

  /// Announce a tracking status update. Throttled to once per 30 seconds
  /// for the same status to avoid "Provider moved, provider moved, ..." spam.
  static void announceTrackingUpdate(String status) {
    announcePolite(status, minInterval: const Duration(seconds: 30));
  }
}
