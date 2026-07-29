class ExperimentAssignment {
  const ExperimentAssignment({
    required this.experimentKey,
    required this.variantKey,
    required this.assignmentId,
    required this.assignedAt,
    required this.scope,
    this.expiresAt,
  });

  final String experimentKey;
  // 'control' | named treatment variant
  final String variantKey;
  // Stable opaque identifier for this assignment — used for dedup
  final String assignmentId;
  final DateTime assignedAt;
  // 'account' | 'device' | 'session'
  final String scope;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isControl => variantKey == 'control';

  ExperimentAssignment copyWith({String? variantKey}) => ExperimentAssignment(
        experimentKey: experimentKey,
        variantKey: variantKey ?? this.variantKey,
        assignmentId: assignmentId,
        assignedAt: assignedAt,
        scope: scope,
        expiresAt: expiresAt,
      );
}
