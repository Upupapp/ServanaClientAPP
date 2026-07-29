enum SupportTicketCategory {
  booking,
  payment,
  refund,
  serviceQuality,
  providerConduct,
  account,
  technical,
  promotion,
  privacy,
  safety,
  other;

  static SupportTicketCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'booking': return booking;
      case 'payment': return payment;
      case 'refund': return refund;
      case 'service_quality': return serviceQuality;
      case 'provider_conduct': return providerConduct;
      case 'account': return account;
      case 'technical': return technical;
      case 'promotion': return promotion;
      case 'privacy': return privacy;
      case 'safety': return safety;
      default: return other;
    }
  }

  String get apiKey {
    switch (this) {
      case booking: return 'booking';
      case payment: return 'payment';
      case refund: return 'refund';
      case serviceQuality: return 'service_quality';
      case providerConduct: return 'provider_conduct';
      case account: return 'account';
      case technical: return 'technical';
      case promotion: return 'promotion';
      case privacy: return 'privacy';
      case safety: return 'safety';
      case other: return 'other';
    }
  }

  String get customerLabel {
    switch (this) {
      case booking: return 'Booking Issue';
      case payment: return 'Payment Issue';
      case refund: return 'Refund Request';
      case serviceQuality: return 'Service Quality';
      case providerConduct: return 'Provider Conduct';
      case account: return 'Account Problem';
      case technical: return 'Technical Issue';
      case promotion: return 'Promotion Concern';
      case privacy: return 'Privacy Request';
      case safety: return 'Safety Concern';
      case other: return 'Other';
    }
  }

  bool get requiresBooking => switch (this) {
    booking || serviceQuality || providerConduct => true,
    _ => false,
  };

  bool get isHighPriority => switch (this) {
    safety || providerConduct => true,
    _ => false,
  };

  bool get isPaymentRelated => switch (this) {
    payment || refund => true,
    _ => false,
  };
}
