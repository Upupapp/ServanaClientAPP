import 'package:client/common/domain/booking/booking_status.dart';

/// Typed result from a booking creation attempt.
///
/// Callers must check [success] before using [bookingId] or [status].
/// [success] == true + valid [bookingId] is the only valid success state —
/// missing bookingId is always treated as an error even without an exception.
class BookingSubmissionResult {
  const BookingSubmissionResult._({
    required this.success,
    this.bookingId,
    this.status,
    this.workerCode,
    this.errorMessage,
    this.errorCategory,
  });

  final bool success;
  final int? bookingId;
  final BookingStatus? status;
  final String? workerCode;
  final String? errorMessage;
  final BookingErrorCategory? errorCategory;

  factory BookingSubmissionResult.success({
    required int bookingId,
    required BookingStatus status,
    String? workerCode,
  }) {
    return BookingSubmissionResult._(
      success: true,
      bookingId: bookingId,
      status: status,
      workerCode: workerCode,
    );
  }

  factory BookingSubmissionResult.failure({
    required String message,
    BookingErrorCategory category = BookingErrorCategory.serverFailure,
  }) {
    return BookingSubmissionResult._(
      success: false,
      errorMessage: message,
      errorCategory: category,
    );
  }

  factory BookingSubmissionResult.missingBookingId() {
    return const BookingSubmissionResult._(
      success: false,
      errorMessage:
          'Booking was created but no reference was returned. Check My Bookings.',
      errorCategory: BookingErrorCategory.serverFailure,
    );
  }
}

/// Broad error categories for booking operations.
///
/// Maps to user-visible recovery actions. Raw API error bodies must never
/// be shown directly.
enum BookingErrorCategory {
  slotUnavailable,
  serviceUnavailable,
  addonUnavailable,
  addressOutsideCoverage,
  quoteExpired,
  priceChanged,
  authenticationRequired,
  duplicateSubmission,
  networkUnavailable,
  serverFailure,
  unknownFailure,
}

/// Converts raw API errors to [BookingErrorCategory] + user-safe messages.
abstract final class BookingErrorMapper {
  static ({BookingErrorCategory category, String message}) fromException(
    Object error,
  ) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('slot') || raw.contains('unavailable')) {
      return (
        category: BookingErrorCategory.slotUnavailable,
        message:
            'That time slot is no longer available. Please choose another.',
      );
    }
    if (raw.contains('address') || raw.contains('coverage')) {
      return (
        category: BookingErrorCategory.addressOutsideCoverage,
        message: 'This address is outside our service area.',
      );
    }
    if (raw.contains('quote') || raw.contains('expired')) {
      return (
        category: BookingErrorCategory.quoteExpired,
        message: 'Your price quote has expired. Please re-quote to continue.',
      );
    }
    if (raw.contains('price') || raw.contains('changed')) {
      return (
        category: BookingErrorCategory.priceChanged,
        message:
            'The price has changed since you last viewed it. Please review the updated total.',
      );
    }
    if (raw.contains('duplicate') || raw.contains('already')) {
      return (
        category: BookingErrorCategory.duplicateSubmission,
        message:
            'This booking may already have been created. Check My Bookings.',
      );
    }
    if (raw.contains('network') ||
        raw.contains('socket') ||
        raw.contains('connection') ||
        raw.contains('timeout') ||
        raw.contains('408')) {
      return (
        category: BookingErrorCategory.networkUnavailable,
        message:
            'No internet connection. Please check your connection and try again.',
      );
    }
    if (raw.contains('401') ||
        raw.contains('403') ||
        raw.contains('unauthorized')) {
      return (
        category: BookingErrorCategory.authenticationRequired,
        message: 'Your session has expired. Please sign in again.',
      );
    }
    return (
      category: BookingErrorCategory.serverFailure,
      message: 'Something went wrong. Please try again.',
    );
  }
}
