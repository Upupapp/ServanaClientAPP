/// The contract both Home composition transports satisfy.
///
/// `HomeCompositionCompatibilityDataSource` assembles Home from the calls the
/// app already makes; `HomeCompositionCanonicalDataSource` fetches it in one
/// request from `/api/v1/home`.
///
/// ## Why the return type carries failures instead of throwing
///
/// [fetchComposition] returns a [HomeComposition] and does **not** throw for a
/// section-level problem. That is the whole point of the tab: a section failure
/// is a value inside the composition, so it cannot unwind the screen. The
/// method throws only when nothing at all could be produced — the single case
/// that genuinely warrants a full-screen error.
library;

import 'package:client/modules/homepage/domain/home_composition.dart';

abstract interface class HomeCompositionDataSource {
  /// Home, with per-section outcomes.
  ///
  /// Throws only if the composition could not be attempted at all. Any section
  /// that fails individually comes back as [HomeSectionFailed].
  Future<HomeComposition> fetchComposition();

  /// Re-fetches one section, for an inline retry.
  ///
  /// Returns the section's new outcome — including a fresh [HomeSectionFailed]
  /// if it failed again. Never throws, so a retry tap cannot crash Home.
  Future<HomeSection> fetchSection(HomeSectionType type);
}
