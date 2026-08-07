class BookingCreateResult {
  const BookingCreateResult({
    required this.bookingId,
    this.workerCode,
  });

  final int bookingId;
  final String? workerCode;
}

/// Parses the compatible response envelopes used by current and older booking
/// APIs. A successful create response without an authoritative booking ID is
/// rejected so callers do not discard their recovery journal or lock the UI.
abstract final class BookingCreateResponseParser {
  static BookingCreateResult parse(Map<String, dynamic> response) {
    final candidates = <Map<String, dynamic>>[response];
    _addMap(candidates, response['booking']);
    _addMap(candidates, response['data']);

    final data = response['data'];
    if (data is Map) {
      _addMap(candidates, data['booking']);
    }

    int? bookingId;
    String? workerCode;
    for (final candidate in candidates.reversed) {
      bookingId ??= _positiveInt(
        candidate['bookingId'] ?? candidate['booking_id'] ?? candidate['id'],
      );
      workerCode ??= _nonEmptyString(
        candidate['workerCode'] ?? candidate['worker_code'],
      );
    }

    if (bookingId == null) {
      throw const FormatException(
        'Booking was created but the server response did not include its ID. '
        'Please retry to safely recover the booking.',
      );
    }

    return BookingCreateResult(
      bookingId: bookingId,
      workerCode: workerCode,
    );
  }

  static void _addMap(List<Map<String, dynamic>> output, Object? value) {
    if (value is Map) output.add(Map<String, dynamic>.from(value));
  }

  static int? _positiveInt(Object? value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString().trim() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static String? _nonEmptyString(Object? value) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? null : parsed;
  }
}
