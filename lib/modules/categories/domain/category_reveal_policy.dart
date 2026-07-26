import 'package:client/common/domain/services/service_category_config.dart';

enum RevealDecision {
  /// First visit for this category + motion enabled → full animated reveal.
  fullReveal,

  /// First visit but reduced motion preferred → skip decorations, shorten
  /// duration, still show the overlay card.
  reducedReveal,

  /// Already seen in this session → no overlay.
  skipReveal,
}

/// Session-scoped in-memory reveal policy.
///
/// Reset on logout via [AuthenticationBloc._onLogout].
/// Does NOT persist across app restarts — intentional (C06 V2 §32).
abstract final class CategoryRevealPolicy {
  static final Set<ServiceCategoryId> _seen = {};

  static RevealDecision decide({
    required ServiceCategoryId categoryId,
    required bool reducedMotion,
  }) {
    if (_seen.contains(categoryId)) return RevealDecision.skipReveal;
    return reducedMotion
        ? RevealDecision.reducedReveal
        : RevealDecision.fullReveal;
  }

  static void markSeen(ServiceCategoryId categoryId) =>
      _seen.add(categoryId);

  static bool hasSeen(ServiceCategoryId categoryId) =>
      _seen.contains(categoryId);

  static void reset() => _seen.clear();
}
