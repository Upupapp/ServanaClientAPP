/// In-memory booking draft — preserved across the auth gate so the user
/// never loses their service selections when they sign in or register.
///
/// NOT persisted to Hive. Cleared after successful booking submission.
enum BookingDraftStatus {
  empty,
  editing,
  readyForReview,
  authenticationRequired,
  restoring,
  restored,
  expired,
  invalid,
  submitted,
  abandoned,
}

/// Type tag for which booking flow owns this draft.
enum BookingFlowType { jobOrder, store, aircon, beautyWellness }

class BookingDraft {
  const BookingDraft({
    required this.id,
    required this.createdAt,
    this.serviceId,
    this.merchantId,
    this.merchantName,
    this.categoryName,
    this.flowType,
    this.selectedServiceJson,
    this.selectedOptions = const [],
    this.selectedAddons = const [],
    this.quantity,
    this.notes,
    this.addressLine,
    this.lat,
    this.lon,
    this.selectedBranchId,
    this.selectedDate,
    this.selectedSlot,
    this.pricingSnapshot,
    this.sourceRouteName,
    this.returnRouteName,
    this.updatedAt,
    this.status = BookingDraftStatus.editing,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final BookingDraftStatus status;

  // Service identity
  final String? serviceId;
  final String? merchantId;
  final String? merchantName;
  final String? categoryName;
  final BookingFlowType? flowType;

  // Serialized selected service data (avoids complex type param on the class)
  final String? selectedServiceJson;

  // Configuration
  final List<String> selectedOptions;
  final List<String> selectedAddons;
  final int? quantity;
  final String? notes;

  // Location
  final String? addressLine;
  final double? lat;
  final double? lon;

  // Schedule
  final String? selectedBranchId;
  final DateTime? selectedDate;
  final String? selectedSlot;

  // Pricing
  final double? pricingSnapshot;

  // Navigation
  final String? sourceRouteName;
  final String? returnRouteName;

  // A draft expires after 24 hours of inactivity.
  bool get isExpired {
    final since = updatedAt ?? createdAt;
    return DateTime.now().difference(since) > const Duration(hours: 24);
  }

  bool get hasServiceSelected =>
      serviceId != null || selectedServiceJson != null;

  bool get isReadyForReview =>
      hasServiceSelected &&
      (addressLine != null || selectedBranchId != null) &&
      selectedDate != null;

  BookingDraft copyWith({
    BookingDraftStatus? status,
    String? serviceId,
    String? merchantId,
    String? merchantName,
    String? categoryName,
    BookingFlowType? flowType,
    String? selectedServiceJson,
    List<String>? selectedOptions,
    List<String>? selectedAddons,
    int? quantity,
    String? notes,
    String? addressLine,
    double? lat,
    double? lon,
    String? selectedBranchId,
    DateTime? selectedDate,
    String? selectedSlot,
    double? pricingSnapshot,
    String? sourceRouteName,
    String? returnRouteName,
  }) {
    return BookingDraft(
      id: id,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      status: status ?? this.status,
      serviceId: serviceId ?? this.serviceId,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      categoryName: categoryName ?? this.categoryName,
      flowType: flowType ?? this.flowType,
      selectedServiceJson: selectedServiceJson ?? this.selectedServiceJson,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      addressLine: addressLine ?? this.addressLine,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      pricingSnapshot: pricingSnapshot ?? this.pricingSnapshot,
      sourceRouteName: sourceRouteName ?? this.sourceRouteName,
      returnRouteName: returnRouteName ?? this.returnRouteName,
    );
  }
}
