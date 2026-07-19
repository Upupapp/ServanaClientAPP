import 'package:client/common/domain/services/service_category_config.dart';

/// In-memory per-session tracker for category first-view reveals.
///
/// Resets on every cold start — the full reveal plays once per app launch per
/// category, then uses the shorter repeat-view entrance on subsequent visits.
///
/// Call [reset] on user logout so the next account on the device gets its own
/// first-view reveals rather than inheriting the previous user's history.
///
/// All public methods are synchronous and constant-time.
abstract final class CategoryExperienceHistory {
  static final _seen = <ServiceCategoryId>{};

  /// Returns true if the first-view reveal has already played this session.
  static bool hasSeenFirstView(ServiceCategoryId id) => _seen.contains(id);

  /// Marks [id] as having had its first-view reveal. Call immediately before
  /// starting the overlay so accidental double-mounts don't replay it.
  static void markFirstViewSeen(ServiceCategoryId id) => _seen.add(id);

  /// Clears all seen entries. Called from logout so the next user of the device
  /// gets their own first-view reveals.
  static void reset() => _seen.clear();

  // Alias kept for test setUp clarity — delegates to [reset].
  static void resetForTesting() => reset();
}
