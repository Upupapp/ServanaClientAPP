import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
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
///
/// ## Status first, prose last
///
/// This used to search the exception's `toString()` for keywords and nothing
/// else. Keyword-searching a message is the fault that once told customers
/// their password was wrong during an outage: 502 and 504 matched no list, so
/// a gateway error fell through to the default.
///
/// Here the default was at least safe — "Something went wrong" — but every
/// 500-class failure still had to be recognised by whatever words the server
/// happened to use, and the booking route's real refusals do not contain the
/// words this searched for. `bookingService.createBooking` throws "Service not
/// available in your area." for an out-of-coverage address, and that string
/// contains neither "address" nor "coverage": it matched nothing and arrived as
/// "Something went wrong. Please try again." for a customer whose only real
/// option was to pick a different address.
///
/// A [ServanaApiException] carries the status the server answered with, and a
/// status is a fact. The body's `code` is the next most reliable thing, because
/// the backend states it deliberately. Prose is consulted last, and only to
/// sharpen a category the status has already chosen.
abstract final class BookingErrorMapper {
  static ({BookingErrorCategory category, String message}) fromException(
    Object error,
  ) {
    if (error is ServanaApiException) {
      return _fromApi(error);
    }

    final raw = error.toString().toLowerCase();
    if (_looksLikeTransport(raw)) {
      return (
        category: BookingErrorCategory.networkUnavailable,
        message:
            'No internet connection. Please check your connection and try again.',
      );
    }
    return _fromProse(raw);
  }

  /// The device never reached a server.
  ///
  /// Nothing else may claim this category. A 500 means the server answered, and
  /// telling that customer to check their connection sends them to fix a
  /// network that is working.
  static bool _looksLikeTransport(String raw) =>
      raw.contains('socket') ||
      raw.contains('failed host lookup') ||
      raw.contains('network is unreachable') ||
      raw.contains('connection refused') ||
      raw.contains('connection closed') ||
      raw.contains('handshake');

  static ({BookingErrorCategory category, String message}) _fromApi(
    ServanaApiException error,
  ) {
    final status = error.statusCode;
    final code = _codeOf(error.body);
    final prose = error.body.toLowerCase();

    // 408 is minted by the client's own timeout wrapper, not by the server, so
    // it is the one status that genuinely means "no round trip completed".
    if (status == 408) {
      return (
        category: BookingErrorCategory.networkUnavailable,
        message: 'The request timed out. Please try again.',
      );
    }

    if (status == 401 || status == 403) {
      return (
        category: BookingErrorCategory.authenticationRequired,
        message: 'Your session has expired. Please sign in again.',
      );
    }

    if (status == 409) {
      if (code == 'SLOT_UNAVAILABLE' || code == 'SLOT_FULL') {
        return (
          category: BookingErrorCategory.slotUnavailable,
          message: 'That time is no longer available. Please choose another.',
        );
      }
      return (
        category: BookingErrorCategory.duplicateSubmission,
        message:
            'This booking may already have been created. Check My Bookings.',
      );
    }

    if (status >= 500) {
      // Deliberately NOT a connectivity message.
      return (
        category: BookingErrorCategory.serverFailure,
        message: 'Servana could not complete your booking just now. '
            'Please try again in a moment.',
      );
    }

    if (status == 400 || status == 422) {
      return _fromProse(prose);
    }

    return (
      category: BookingErrorCategory.unknownFailure,
      message: 'Something went wrong. Please try again.',
    );
  }

  /// The backend's `code` field, when it states one — deliberate and stable,
  /// unlike the message beside it. Reads the nested `error.code` too, which is
  /// the envelope the auth routes use.
  static String? _codeOf(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final nested = decoded['error'];
        final code = decoded['code'] ??
            (nested is Map<String, dynamic> ? nested['code'] : null);
        final text = code?.toString().trim();
        return (text == null || text.isEmpty) ? null : text.toUpperCase();
      }
    } catch (_) {}
    return null;
  }

  /// Sharpens a 400 into the specific thing the customer can act on.
  ///
  /// The phrases matched here are the ones `bookingService.createBooking`
  /// actually throws, read from the handler rather than guessed: "Service not
  /// available in your area.", "Invalid address.", "Address missing
  /// locationId.", "Invalid service option.", "The booking schedule must be in
  /// the future."
  static ({BookingErrorCategory category, String message}) _fromProse(
    String raw,
  ) {
    if (raw.contains('not available in your area') ||
        raw.contains('coverage') ||
        raw.contains('service area')) {
      return (
        category: BookingErrorCategory.addressOutsideCoverage,
        message: 'This address is outside our service area. '
            'Try another saved address.',
      );
    }
    if (raw.contains('address')) {
      return (
        category: BookingErrorCategory.addressOutsideCoverage,
        message:
            'We could not use that address. Please choose or add another one.',
      );
    }
    if (raw.contains('slot')) {
      return (
        category: BookingErrorCategory.slotUnavailable,
        message: 'That time is no longer available. Please choose another.',
      );
    }
    if (raw.contains('duplicate') || raw.contains('already')) {
      return (
        category: BookingErrorCategory.duplicateSubmission,
        message:
            'This booking may already have been created. Check My Bookings.',
      );
    }
    if (raw.contains('quote')) {
      return (
        category: BookingErrorCategory.quoteExpired,
        message: 'Your price quote has expired. Please re-quote to continue.',
      );
    }
    if (raw.contains('schedule')) {
      return (
        category: BookingErrorCategory.unknownFailure,
        message: 'Please choose a booking time in the future.',
      );
    }
    if (raw.contains('service option') || raw.contains('service')) {
      return (
        category: BookingErrorCategory.serviceUnavailable,
        message: 'This service is not available to book right now.',
      );
    }
    if (raw.contains('price') || raw.contains('changed')) {
      return (
        category: BookingErrorCategory.priceChanged,
        message: 'The price has changed since you last viewed it. '
            'Please review the updated total.',
      );
    }
    return (
      category: BookingErrorCategory.serverFailure,
      message: 'Something went wrong. Please try again.',
    );
  }
}
