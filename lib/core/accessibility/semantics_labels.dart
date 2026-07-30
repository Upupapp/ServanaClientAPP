/// Centralized, localizable semantic labels for every reusable action
/// and state in the Servana Client app.
///
/// Rules:
/// - Describe the ACTION or DESTINATION, not the control type.
/// - Omit "button" / "icon" — the platform announces the role.
/// - Match visible copy where possible (Voice Control parity).
/// - All strings are candidates for l10n; keep them in one place.
abstract final class SemanticsLabels {
  // ── Navigation ────────────────────────────────────────────────────────────
  static const String back = 'Go back';
  static const String close = 'Close';
  static const String dismiss = 'Dismiss';
  static const String openMenu = 'Open menu';
  static const String moreActions = 'More actions';

  // ── Bottom navigation ─────────────────────────────────────────────────────
  static const String tabHome = 'Home';
  static const String tabBookings = 'My bookings';
  static const String tabMessages = 'Messages';
  static const String tabProfile = 'Profile';
  static String tabMessagesWithUnread(int count) =>
      'Messages, $count unread';

  // ── Authentication ────────────────────────────────────────────────────────
  static const String signIn = 'Sign in';
  static const String signInWithEmail = 'Sign in with email';
  static const String signInWithMobile = 'Sign in with mobile number';
  static const String createAccount = 'Create account';
  static const String forgotPassword = 'Forgot password';
  static const String browseAsGuest = 'Browse services as guest';
  static const String skipOnboarding = 'Skip onboarding';
  static const String logout = 'Sign out';

  static const String fieldEmail = 'Email address';
  static const String fieldPassword = 'Password';
  static const String fieldMobile = 'Mobile number';
  static const String fieldFullName = 'Full name';
  static const String fieldOtp = 'One-time verification code';
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';

  // ── Home ──────────────────────────────────────────────────────────────────
  static const String searchServices = 'Search services';
  static const String viewNotifications = 'View notifications';
  static const String viewActiveBooking = 'View active booking';
  static const String rebookService = 'Book again';
  static const String browseAllServices = 'Browse all services';
  static const String openQuickBook = 'Quick book a service';

  // ── Search ────────────────────────────────────────────────────────────────
  static const String clearSearch = 'Clear search';
  static const String filterByCategory = 'Filter by category';
  static const String sortResults = 'Sort results';
  static const String refreshResults = 'Refresh results';
  static String searchResultsCount(int count) =>
      '$count service${count == 1 ? '' : 's'} found';
  static const String noSearchResults =
      'No services found. Try a different search term or category.';

  // ── Service / Booking ─────────────────────────────────────────────────────
  static const String bookService = 'Book this service';
  static const String viewServiceDetails = 'View service details';
  static const String chooseOptions = 'Choose service options';
  static const String chooseAddons = 'Choose add-ons';
  static const String chooseAddress = 'Choose service address';
  static const String chooseSchedule = 'Choose schedule';
  static const String reviewBooking = 'Review your booking';
  static const String confirmBooking = 'Confirm booking';
  static const String cancelBooking = 'Cancel booking';
  static const String keepBooking = 'Keep booking';
  static const String rescheduleBooking = 'Reschedule booking';
  static const String viewBookingDetails = 'View booking details';
  static const String messageProvider = 'Message your provider';
  static const String trackProvider = 'Track your provider';
  static const String continuePayment = 'Continue to payment';
  static const String retryPayment = 'Retry payment';

  static String bookingStep(int step, int total) =>
      'Step $step of $total';
  static String bookingStatus(String status) => 'Booking status: $status';

  // ── Address ───────────────────────────────────────────────────────────────
  static const String addAddress = 'Add new address';
  static const String editAddress = 'Edit address';
  static const String deleteAddress = 'Delete address';
  static const String keepAddress = 'Keep address';
  static const String setAsPrimary = 'Set as primary address';
  static const String searchAddress = 'Search for an address';
  static const String confirmLocation = 'Confirm this location';
  static const String recenterMap = 'Recenter map to current location';
  static const String zoomIn = 'Zoom in';
  static const String zoomOut = 'Zoom out';

  static String addressCardLabel(
    String label,
    String addressLine,
    bool isPrimary,
    bool isServiceable,
  ) {
    final parts = <String>[label, addressLine];
    if (isPrimary) parts.add('primary address');
    parts.add(isServiceable ? 'serviceable' : 'not serviceable in your area');
    return parts.join(', ');
  }

  // ── Payment ───────────────────────────────────────────────────────────────
  static const String proceedToPayment = 'Proceed to secure payment';
  static const String paymentProcessing = 'Payment is being processed';
  static const String paymentSuccess = 'Payment confirmed';
  static const String paymentFailed = 'Payment failed. Please try again.';
  static const String checkPaymentStatus = 'Check payment status';
  static const String returnToBooking = 'Return to booking';

  // ── Messaging ─────────────────────────────────────────────────────────────
  static const String sendMessage = 'Send message';
  static const String retryMessage = 'Retry sending this message';
  static const String attachImage = 'Attach image';
  static const String removeAttachment = 'Remove attachment';
  static const String markConversationRead = 'Mark as read';
  static const String messageField = 'Type a message';
  static String newMessagesAvailable(int count) =>
      '$count new message${count == 1 ? '' : 's'} available. Swipe up to read.';
  @Deprecated(
    'Dead code — zero callers. Remove if no caller is added by 2026-Q4.',
  )
  static String messageDelivered(String sender, String preview) =>
      '$sender: $preview';

  // ── Tracking ──────────────────────────────────────────────────────────────
  static const String trackingMapSummary = 'Live tracking map';
  static const String recenterTracking = 'Recenter tracking map';
  static const String viewTrackingDetails = 'View tracking details';
  static String trackingStatus(String status, String? eta) {
    if (eta != null) return '$status. Estimated arrival: $eta.';
    return status;
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String editProfile = 'Edit profile';
  static const String changeProfilePhoto = 'Change profile photo';
  static const String takePhoto = 'Take photo';
  static const String chooseFromGallery = 'Choose from photo library';
  static const String removePhoto = 'Remove profile photo';
  static const String verifyEmail = 'Verify email address';
  static const String verifyMobile = 'Verify mobile number';
  static const String savedAddresses = 'Saved addresses';

  // ── Support ───────────────────────────────────────────────────────────────
  static const String contactSupport = 'Contact support';
  static const String reportSafetyIssue = 'Report a safety issue';
  static const String immediateHelp = 'Get immediate help';
  static const String createSupportTicket = 'Create support request';
  static const String replyToTicket = 'Reply to support ticket';
  static const String closeTicket = 'Close support ticket';
  static const String reopenTicket = 'Reopen support ticket';
  static const String sendSupportReply = 'Send reply';

  // ── Review ────────────────────────────────────────────────────────────────
  static const String writeReview = 'Write a review';
  static const String submitReview = 'Submit review';
  static const String editReview = 'Edit your review';
  static const String deleteReview = 'Delete your review';
  static const String keepReview = 'Keep your review';
  static const String reportReview = 'Report this review';

  static String ratingLabel(int rating, int max, String meaning) =>
      '$rating of $max, $meaning';
  static String ratingHint(int current) =>
      current == 0 ? 'Tap a star to select a rating' : 'Double-tap to change';
  static const String ratingMeaningPoor = 'Poor';
  static const String ratingMeaningFair = 'Fair';
  static const String ratingMeaningGood = 'Good';
  static const String ratingMeaningVeryGood = 'Very good';
  static const String ratingMeaningExcellent = 'Excellent';

  static String ratingMeaning(int rating) => switch (rating) {
        1 => ratingMeaningPoor,
        2 => ratingMeaningFair,
        3 => ratingMeaningGood,
        4 => ratingMeaningVeryGood,
        5 => ratingMeaningExcellent,
        _ => '',
      };

  // ── Settings ─────────────────────────────────────────────────────────────
  static const String openSettings = 'Open settings';
  static const String openPrivacySettings = 'Open privacy and legal settings';
  static const String openAppearanceSettings = 'Open appearance settings';
  static const String openNotificationSettings = 'Open notification settings';
  static const String openPermissionsSettings = 'Open system permissions';

  // ── Loading and error states ──────────────────────────────────────────────
  static const String loading = 'Loading';
  static const String loadingServices = 'Loading services';
  static const String loadingBookings = 'Loading bookings';
  static const String loadingMessages = 'Loading messages';
  static const String loadingProfile = 'Loading profile';
  static const String loadingPayment = 'Checking payment status';
  static const String retryAction = 'Retry';
  static const String genericError =
      'Something went wrong. Please try again.';

  // ── Offline / recovery ────────────────────────────────────────────────────
  static const String offline = 'No internet connection';
  static const String reconnected = 'Connected. Refreshing your content.';
  static const String draftRestored = 'Your previous booking draft has been restored.';

  // ── Consent ───────────────────────────────────────────────────────────────
  static const String consentAccept = 'Accept analytics and continue';
  static const String consentEssentialOnly =
      'Use essential features only, decline analytics';
  static const String consentAnalyticsToggle =
      'Usage analytics and crash reports';

  // ── Empty states ──────────────────────────────────────────────────────────
  static const String noBookings = 'No bookings yet';
  static const String noMessages = 'No messages yet';
  static const String noNotifications = 'No notifications yet';
  static const String noSupportTickets = 'No support requests yet';
  static const String noReviews = 'No reviews yet';
  static const String noAddresses = 'No saved addresses';
}
