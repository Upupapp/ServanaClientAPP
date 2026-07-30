enum SupportTicketStatus {
  submitted,
  open,
  waitingForSupport,
  waitingForCustomer,
  escalated,
  resolved,
  closed,
  unknown;

  static SupportTicketStatus fromString(String? value) {
    switch (value) {
      case 'submitted':
        return submitted;
      case 'open':
        return open;
      case 'waiting_for_support':
        return waitingForSupport;
      case 'waiting_for_customer':
        return waitingForCustomer;
      case 'escalated':
        return escalated;
      case 'resolved':
        return resolved;
      case 'closed':
        return closed;
      default:
        return unknown;
    }
  }

  String get customerLabel {
    switch (this) {
      case submitted:
        return 'Submitted';
      case open:
        return 'Open';
      case waitingForSupport:
        return 'Waiting for Servana';
      case waitingForCustomer:
        return 'Your response needed';
      case escalated:
        return 'Escalated for review';
      case resolved:
        return 'Resolution provided';
      case closed:
        return 'Closed';
      case unknown:
        return 'Unknown';
    }
  }

  bool get isActive => switch (this) {
        submitted ||
        open ||
        waitingForSupport ||
        waitingForCustomer ||
        escalated =>
          true,
        _ => false,
      };

  bool get needsCustomerAction => this == waitingForCustomer;
}
