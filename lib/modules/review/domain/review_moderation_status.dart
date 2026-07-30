enum ReviewModerationStatus {
  notRequired,
  pending,
  approved,
  rejected,
  hidden,
  removed,
  flagged;

  static ReviewModerationStatus fromString(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'PENDING':
        return ReviewModerationStatus.pending;
      case 'APPROVED':
        return ReviewModerationStatus.approved;
      case 'REJECTED':
        return ReviewModerationStatus.rejected;
      case 'HIDDEN':
        return ReviewModerationStatus.hidden;
      case 'REMOVED':
        return ReviewModerationStatus.removed;
      case 'FLAGGED':
        return ReviewModerationStatus.flagged;
      default:
        return ReviewModerationStatus.notRequired;
    }
  }

  bool get isVisible =>
      this == ReviewModerationStatus.notRequired ||
      this == ReviewModerationStatus.approved;

  bool get isSuppressed =>
      this == ReviewModerationStatus.hidden ||
      this == ReviewModerationStatus.removed ||
      this == ReviewModerationStatus.rejected;

  String get displayLabel {
    switch (this) {
      case ReviewModerationStatus.notRequired:
        return '';
      case ReviewModerationStatus.pending:
        return 'Under review';
      case ReviewModerationStatus.approved:
        return 'Approved';
      case ReviewModerationStatus.rejected:
        return 'Not published';
      case ReviewModerationStatus.hidden:
        return 'Temporarily hidden';
      case ReviewModerationStatus.removed:
        return 'Removed';
      case ReviewModerationStatus.flagged:
        return 'Flagged for review';
    }
  }
}
