/// Chooses between a canonical and a compatibility data source.
///
/// ## The shape this enforces
///
///     FeatureRepository
///       → CanonicalV1DataSource        when the capability is available
///       → LegacyCompatibilityDataSource otherwise
///       → the SAME domain model either way
///
/// The last line is the part that matters. Both sources must satisfy one
/// interface returning one domain type, so the repository's callers — BLoCs,
/// controllers, widgets — cannot tell which one answered. If a widget could
/// tell, the migration would reach the presentation layer and this whole tab
/// would have bought nothing.
///
/// ## Why a router object rather than an `if`
///
/// An inline `if (availability.isAvailable(...))` inside each repository is the
/// same logic, but it is not testable as a unit and it drifts: one repository
/// checks the master switch, another forgets and checks only the capability.
/// Routing through one object means the decision is made the same way
/// everywhere and a test can assert *which* source was chosen without making a
/// network call.
///
/// ## It never falls back
///
/// [select] does not catch a canonical failure and retry on legacy. That
/// sounds like resilience and is actually the most dangerous behaviour
/// available here: a canonical 404 during a partial rollout would silently
/// double-send mutations to two different backends, and a canonical 409 would
/// be retried against a legacy route that does not enforce the same state
/// machine. One source answers, and its failure is the answer.
library;

import 'package:client/core/network/canonical_availability.dart';

class CanonicalRouter {
  const CanonicalRouter({required CanonicalAvailability availability})
      : _availability = availability;

  final CanonicalAvailability _availability;

  /// Returns [canonical] when [capability] is available, else [compatibility].
  ///
  /// Both are passed as already-constructed sources rather than as builders:
  /// constructing a data source is cheap, and lazy construction would hide
  /// which one exists from a test that wants to assert on it.
  T select<T>(
    V1Capability capability, {
    required T canonical,
    required T compatibility,
  }) =>
      _availability.isAvailable(capability) ? canonical : compatibility;

  /// True when [capability] is served by the canonical source.
  ///
  /// For the rare call that has no canonical successor at all and must stay on
  /// the compatibility source even in a migrated domain — see
  /// `DELETE /api/user/notifications/:key`, which v1 has no equivalent for.
  bool isCanonical(V1Capability capability) =>
      _availability.isAvailable(capability);

  /// Diagnostics only. Rendered in developer surfaces, never to a customer.
  String describe() => _availability.toString();
}
