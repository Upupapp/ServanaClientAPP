/// A typed, validated intent for where to return the user after authentication.
///
/// Created before the auth gate opens; consumed after successful login.
/// Prevents open redirects: only allow-listed destinations are valid.
enum ProtectedDestination {
  bookings,
  bookingDetail,
  bookingConfirm,
  messages,
  bookingChat,
  profile,
  savedAddresses,
  paymentMethods,
  notifications,
}

class AuthReturnIntent {
  const AuthReturnIntent({
    required this.destination,
    this.routeName,
    this.gateReason,
  });

  final ProtectedDestination destination;

  /// Named GoRouter route to navigate to after auth. Must match a registered
  /// route name. Null means navigate to the destination's default route.
  final String? routeName;

  /// Human-readable explanation shown on the auth gate (e.g. "to confirm your
  /// booking"). Should be phrased to complete "Sign in [gateReason]."
  final String? gateReason;

  static const _validRoutes = <String>{
    'Bookings',
    'BookingDetail',
    'Messages',
    'BookingChat',
    'Profile',
    'Notifications',
  };

  /// Returns a validated intent, or null if the [routeName] is not in the
  /// allow-list (prevents open redirects).
  static AuthReturnIntent? validated({
    required ProtectedDestination destination,
    String? routeName,
    String? gateReason,
  }) {
    if (routeName != null && !_validRoutes.contains(routeName)) return null;
    return AuthReturnIntent(
      destination: destination,
      routeName: routeName,
      gateReason: gateReason,
    );
  }

  String get displayReason {
    if (gateReason != null && gateReason!.isNotEmpty) return gateReason!;
    return switch (destination) {
      ProtectedDestination.bookings => 'to view your bookings',
      ProtectedDestination.bookingConfirm => 'to confirm your booking',
      ProtectedDestination.bookingDetail => 'to view booking details',
      ProtectedDestination.messages => 'to view your messages',
      ProtectedDestination.bookingChat => 'to open the booking chat',
      ProtectedDestination.profile => 'to access your profile',
      ProtectedDestination.savedAddresses => 'to manage your addresses',
      ProtectedDestination.paymentMethods => 'to manage payment methods',
      ProtectedDestination.notifications => 'to view notifications',
    };
  }
}
