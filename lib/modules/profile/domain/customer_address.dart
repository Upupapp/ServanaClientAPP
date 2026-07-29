/// Canonical customer address — maps the GET /api/user/alluseraddresses response.
class CustomerAddress {
  const CustomerAddress({
    required this.addressId,
    required this.userId,
    this.locationId,
    required this.addressOne,
    this.addressTwo,
    this.zipCode,
    this.postTown,
    this.country,
    this.label,
    this.isPrimary = false,
    this.lat,
    this.lon,
  });

  final String addressId;
  final String userId;
  final String? locationId;
  final String addressOne;
  final String? addressTwo;
  final String? zipCode;
  final String? postTown;
  final String? country;
  final String? label;
  final bool isPrimary;
  final double? lat;
  final double? lon;

  String get displayLabel => (label != null && label!.isNotEmpty) ? label! : 'Address';

  String get displayLine1 => addressOne;

  String get displayLine2 {
    final parts = <String>[
      if (addressTwo != null && addressTwo!.isNotEmpty) addressTwo!,
      if (postTown != null && postTown!.isNotEmpty) postTown!,
    ];
    return parts.join(', ');
  }
}
