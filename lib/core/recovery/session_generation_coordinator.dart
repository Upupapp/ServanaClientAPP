import 'package:flutter/foundation.dart';

/// Single authoritative source of the current auth-session generation.
///
/// The generation is a monotonically-increasing integer. Increment it by
/// calling [advance] on every login or account switch. In-flight async
/// operations capture the generation at dispatch time and compare it on
/// completion; if the generation has advanced, the response is stale and
/// must be discarded.
///
/// This coordinator replaces ad-hoc per-controller `_generation` counters
/// for operations that span module boundaries.
class SessionGenerationCoordinator extends ChangeNotifier {
  int _generation = 0;

  /// Current generation number.
  int get current => _generation;

  /// Increment the generation — call on login or account switch.
  /// All in-flight callbacks captured before this call will see a mismatch
  /// and must discard their results.
  void advance() {
    _generation++;
    notifyListeners();
  }

  /// Returns true if [captured] matches the current generation.
  bool isValid(int captured) => captured == _generation;

  /// Resets to 0. For testing only — never call in production.
  @visibleForTesting
  void resetForTesting() {
    _generation = 0;
    notifyListeners();
  }
}
