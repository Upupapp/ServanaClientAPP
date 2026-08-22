/// The provider on a booking, as `GET /api/booking/:bookingId/provider` gives
/// them.
///
/// ## Why this is a shared type and not two parsers
///
/// Two screens want the same thing — the booking detail header and the chat
/// header — and until now only one of them read this endpoint. The chat screen
/// took its provider name from `JonOrderRepository.getJobOrderEmployees`, which
/// is `HttpBackend.getJobOrderEmployees`, which is:
///
///     Future<List<MerchantUser>> getJobOrderEmployees(...) async => [];
///
/// an unconditional stub in every release build. So the chat header, its empty
/// state and its message bubbles all said "Service Provider" for a provider the
/// booking screen could name.
///
/// Copying the booking screen's parse across would have made two readings of
/// one payload, which is how they drift (§10). This is that reading, moved.
///
/// ## The envelope
///
/// `{success: true, assigned: bool, worker: {...} | null}`.
///
/// **`assigned: false` is a normal state, not a failure.** The backend says so
/// in as many words: a customer watching a booking that has not been matched
/// yet is the ordinary case for the first minutes of every booking. It is kept
/// distinct from `assigned: true, worker: null` — matched, but the profile
/// could not be projected for this audience — because those are different
/// things to tell a customer.
library;

class BookingProviderProfile {
  const BookingProviderProfile({
    required this.assigned,
    this.name,
    this.phone,
  });

  /// Nobody is matched to this booking yet.
  static const none = BookingProviderProfile(assigned: false);

  final bool assigned;

  /// Null when no provider is assigned, or when the projection carried no
  /// nameable field. Never a placeholder — a caller that wants "Service
  /// Provider" on screen should say so itself rather than be handed it as
  /// though the server had answered.
  final String? name;

  final String? phone;

  factory BookingProviderProfile.fromResponse(Map<String, dynamic> response) {
    // `worker` is the documented key. `data` and the bare root stay in the
    // chain because this endpoint is read by builds older than this one and a
    // response shape is not owned by the newest client.
    final worker = response['worker'] as Map<String, dynamic>? ??
        response['data'] as Map<String, dynamic>? ??
        (response.containsKey('firstName') || response.containsKey('name')
            ? response
            : null);

    // Read the flag rather than inferring assignment from the presence of a
    // worker object: `assigned: true, worker: null` is a real answer and means
    // something different from "not matched yet".
    final assigned = response['assigned'] == true || worker != null;

    if (worker == null) {
      return BookingProviderProfile(assigned: assigned);
    }

    final first = worker['firstName']?.toString().trim() ?? '';
    final last = worker['lastName']?.toString().trim() ?? '';
    final composed = '$first $last'.trim();

    final name = composed.isNotEmpty
        ? composed
        : _firstNonEmpty([
            worker['name'],
            worker['fullName'],
            worker['displayName'],
            // Email last, and only because a name is better than a uid on
            // screen. It is a contact detail, so it is never preferred over
            // one the provider actually chose (§58).
            worker['email'],
          ]);

    final phone = _firstNonEmpty([
      worker['phoneNumber'],
      worker['phone'],
      worker['mobileNumber'],
    ]);

    return BookingProviderProfile(
      assigned: assigned,
      name: name,
      phone: phone,
    );
  }

  static String? _firstNonEmpty(List<Object?> candidates) {
    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
