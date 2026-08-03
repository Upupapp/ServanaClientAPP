import '../domain/analytics_event.dart';
import '../domain/experiment_assignment.dart';
import 'analytics_coordinator.dart';

// Experiment assignment and exposure coordinator.
// In C21, experiment infrastructure is a foundation stub:
// assignments are served through RemoteConfig (future) or hard-coded defaults.
// The exposure event fires only when the variant actually affects behavior.
class ExperimentCoordinator {
  ExperimentCoordinator({required AnalyticsCoordinator analytics})
      : _analytics = analytics;

  final AnalyticsCoordinator _analytics;
  final Map<String, ExperimentAssignment> _assignments = {};

  // Get the current assignment for an experiment.
  // Returns control if no assignment exists (safe default).
  ExperimentAssignment getAssignment(String experimentKey) {
    return _assignments[experimentKey] ??
        ExperimentAssignment(
          experimentKey: experimentKey,
          variantKey: 'control',
          assignmentId: 'default',
          assignedAt: DateTime.now(),
          scope: 'device',
        );
  }

  // Register an assignment (called by RemoteConfig or feature initialization).
  void registerAssignment(ExperimentAssignment assignment) {
    if (assignment.isExpired) return;
    _assignments[assignment.experimentKey] = assignment;
  }

  // Emit exposure event — only call when the variant is ACTUALLY SHOWN.
  // Do not call merely because a config was fetched.
  Future<void> recordExposure({
    required String experimentKey,
    required String surface,
  }) async {
    final assignment = getAssignment(experimentKey);
    await _analytics.track(ExperimentExposedEvent(
      experimentKey: experimentKey,
      variantKey: assignment.variantKey,
      surface: surface,
    ));
  }

  void clearOnLogout() => _assignments.clear();
}
