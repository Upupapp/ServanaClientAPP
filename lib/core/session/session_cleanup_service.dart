/// Clears every customer-scoped thing this device holds.
///
/// ## Why this exists
///
/// The sequence below was ~90 lines inline in `AuthenticationBloc._onLogout`,
/// spread over five `try`/`catch` blocks reaching into two dozen singletons. It
/// is correct — it is the accumulated result of the LEAKSHIELD passes, and each
/// line is there because something leaked across accounts on a shared device.
/// It was also unreachable from anywhere else, so "account switch" could not
/// reuse it, and untestable, so nothing could prove a step had not been
/// dropped.
///
/// This moves the sequence, unchanged in order and semantics, behind one call
/// with two properties it did not have:
///
///  - **Isolation per step.** One failing step cannot skip the ones after it.
///    The old code grouped ~15 clears into a single `try`, so a throw in the
///    second one silently skipped thirteen.
///  - **Auditability.** It returns which steps ran and which failed, so a
///    logout that half-worked is a reportable fact rather than a silence.
///
/// ## What is deliberately NOT cleared
///
///  - `catalog_cache_v2` — the public service catalog. It is not
///    customer-scoped, and clearing it would make every sign-out cost a full
///    catalog refetch for no privacy gain.
///  - Campaign frequency history — account-scoped and deliberately durable, so
///    a permanent dismissal cannot be reset by signing out and back in.
///  - The Hive cipher key in `SecureStorageHelper` — deleting it orphans every
///    box on the device, including other accounts' unrelated local data.
library;

/// One named unit of teardown.
class CleanupStep {
  const CleanupStep(this.name, this.run);

  final String name;
  final Future<void> Function() run;
}

/// What actually happened, for logging and for tests.
class CleanupReport {
  CleanupReport(this.completed, this.failed);

  final List<String> completed;
  final Map<String, Object> failed;

  bool get isClean => failed.isEmpty;

  @override
  String toString() => isClean
      ? 'CleanupReport(all ${completed.length} steps clean)'
      : 'CleanupReport(${completed.length} clean, failed: ${failed.keys.join(', ')})';
}

class SessionCleanupService {
  const SessionCleanupService();

  /// Runs [steps] in order, isolating each one.
  ///
  /// Never throws. A logout the customer asked for must complete even if the
  /// device is in a state where half of it fails; the alternative is trapping
  /// them in a signed-in app because a cache would not clear.
  Future<CleanupReport> run(List<CleanupStep> steps) async {
    final completed = <String>[];
    final failed = <String, Object>{};
    for (final step in steps) {
      try {
        await step.run();
        completed.add(step.name);
      } catch (error) {
        // Recorded, not rethrown, and the loop continues to the next step.
        failed[step.name] = error;
      }
    }
    return CleanupReport(completed, failed);
  }
}
