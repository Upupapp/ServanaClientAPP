class ReviewEligibility {
  const ReviewEligibility({
    required this.bookingId,
    required this.eligible,
    this.reason,
    this.reviewId,
    this.reviewWindowOpensAt,
    this.reviewWindowClosesAt,
    this.editableUntil,
    this.availableActions = const [],
  });

  final String bookingId;
  final bool eligible;
  final String? reason;
  final String? reviewId;
  final DateTime? reviewWindowOpensAt;
  final DateTime? reviewWindowClosesAt;
  final DateTime? editableUntil;
  final List<String> availableActions;

  bool get canEdit => availableActions.contains('EDIT_REVIEW');
  bool get canDelete => availableActions.contains('DELETE_REVIEW');
  bool get canView => availableActions.contains('VIEW_REVIEW');
  bool get hasReview => reviewId != null;

  factory ReviewEligibility.fromMap(Map<String, dynamic> m) {
    final window = m['reviewWindow'] as Map<String, dynamic>?;
    return ReviewEligibility(
      bookingId: m['bookingId'] as String? ?? '',
      eligible: m['eligible'] as bool? ?? false,
      reason: m['reason'] as String?,
      reviewId: m['reviewId'] as String?,
      reviewWindowOpensAt: window != null
          ? DateTime.tryParse(window['opensAt'].toString())
          : null,
      reviewWindowClosesAt: window != null
          ? DateTime.tryParse(window['closesAt'].toString())
          : null,
      editableUntil: m['editableUntil'] != null
          ? DateTime.tryParse(m['editableUntil'].toString())
          : null,
      availableActions:
          (m['availableActions'] as List?)?.cast<String>() ?? const [],
    );
  }
}
