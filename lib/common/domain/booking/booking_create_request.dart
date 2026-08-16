/// The one booking-create payload every category flow submits.
///
/// ## Why this is not `BookingDraft`
///
/// [BookingDraft] already exists and means something else: the in-memory
/// selection preserved across the auth gate so a customer who signs in
/// mid-flow does not lose what they picked. It has no payment method, no
/// schedule in UTC and no idempotency — it is a *survival* model.
///
/// This is the *submission* model. The Master Command names either
/// `BookingDraft` or `BookingCreateRequest`; the first name is taken by a live
/// concept, and reusing it would produce two types with one name and two
/// meanings, which is the duplicate-truth failure the command forbids.
///
/// ## What it deliberately does not carry
///
/// **No total, no fee, no discount.** Pricing INPUTS travel — the option, the
/// add-ons, the aircon horsepower/height/distance keys — and the backend
/// computes money from them. The checkout screens still show a quote, and that
/// quote is a projection for the customer to read, never the number the booking
/// is created with. A client that sent a total would be asking the server to
/// trust arithmetic done on a device.
///
/// **No customer id, conceptually.** The legacy endpoint takes `?userId=`, and
/// that is passed by the submission service from the session rather than from
/// screen state — but it remains a client-supplied identifier on a legacy
/// route, and it is recorded as such. See the endpoint gap note in the TAB 08
/// certification.
library;

import 'package:client/common/domain/booking/booking_draft.dart'
    show BookingFlowType;

/// Why a request cannot be submitted. Codes, not sentences, so the analytics
/// label and the customer-facing copy are chosen by the caller rather than
/// baked into the domain.
enum BookingRequestInvalidity {
  noService,
  noAddress,
  noSchedule,
  scheduleInPast,
  noBranch,
  noPaymentMethod,
}

/// Payment methods the backend accepts. A closed set on purpose: the previous
/// check was an inline `{'CASH', 'PAYMONGO'}` literal duplicated in two stores,
/// and two copies of a closed set is one copy away from disagreeing.
const Set<String> kAcceptedPaymentMethods = {'CASH', 'PAYMONGO'};

class BookingCreateRequest {
  const BookingCreateRequest({
    required this.flowType,
    required this.serviceOptionId,
    required this.userAddressId,
    required this.schedule,
    required this.paymentMethod,
    this.branchId,
    this.pricingInputs = const <String, dynamic>{},
    this.requiresBranch = false,
  });

  final BookingFlowType flowType;

  /// Canonical `services.id`. Named for the legacy field it lands in —
  /// `serviceOptionId` — because that is what the endpoint reads. TAB 04
  /// established the two are the same value for every promoted row and that the
  /// backend resolves the column through `legacy_service_option_id`.
  final Object? serviceOptionId;

  final String userAddressId;
  final DateTime? schedule;
  final String paymentMethod;

  /// Beauty & Wellness only. Aircon has no branch.
  final Object? branchId;

  /// The `pricing` object exactly as this flow sends it. Inputs only — option
  /// and add-on ids, and the aircon horsepower/height/distance keys. Never an
  /// amount.
  ///
  /// Passed through verbatim rather than assembled here. The two flows do not
  /// send the same shape — aircon repeats `optionId` inside `pricing`, Beauty &
  /// Wellness sends only `addonOptionIds` — and normalising that difference
  /// would change a live money payload on the strength of it looking tidier.
  /// Unifying the ceremony is this tab's job; renegotiating the wire format is
  /// not, and would need the backend read that TAB 08 could not make.
  final Map<String, dynamic> pricingInputs;

  /// Whether this flow cannot be submitted without a branch.
  final bool requiresBranch;

  /// Everything wrong with this request, in a stable order.
  ///
  /// Returns a list rather than a first-failure so a caller can report all of
  /// it at once; the stores today report one sentence covering several fields,
  /// and that sentence stays their choice.
  List<BookingRequestInvalidity> validate({DateTime? now}) {
    final problems = <BookingRequestInvalidity>[];

    if (serviceOptionId == null || '$serviceOptionId'.trim().isEmpty) {
      problems.add(BookingRequestInvalidity.noService);
    }
    if (userAddressId.trim().isEmpty) {
      problems.add(BookingRequestInvalidity.noAddress);
    }
    if (requiresBranch &&
        (branchId == null || '$branchId'.trim().isEmpty)) {
      problems.add(BookingRequestInvalidity.noBranch);
    }
    if (schedule == null) {
      problems.add(BookingRequestInvalidity.noSchedule);
    } else if (!schedule!.isAfter(now ?? DateTime.now())) {
      // Separate from `noSchedule` because they are different customer
      // mistakes: one has not chosen, the other chose a time that has passed
      // while they were filling in the rest of the form.
      problems.add(BookingRequestInvalidity.scheduleInPast);
    }
    if (!kAcceptedPaymentMethods.contains(paymentMethod)) {
      problems.add(BookingRequestInvalidity.noPaymentMethod);
    }

    return problems;
  }

  bool get isValid => validate().isEmpty;

  /// The wire payload.
  ///
  /// The schedule is sent in UTC ISO-8601. The device's local zone is not the
  /// server's, and a naive local timestamp is how a 9am booking becomes a 1am
  /// one for somebody travelling.
  Map<String, dynamic> toPayload() => <String, dynamic>{
        'userAddressId': userAddressId,
        'serviceOptionId': serviceOptionId,
        if (branchId != null) 'branchId': branchId,
        'schedule': schedule!.toUtc().toIso8601String(),
        'paymentMethod': paymentMethod,
        'pricing': pricingInputs,
      };

  /// The analytics/journal label for this flow. One mapping, so the two stores
  /// cannot drift into reporting different names for the same category.
  String get categoryLabel => switch (flowType) {
        BookingFlowType.aircon => 'aircon',
        BookingFlowType.beautyWellness => 'beauty_wellness',
        BookingFlowType.jobOrder => 'job_order',
        BookingFlowType.store => 'store',
      };
}
