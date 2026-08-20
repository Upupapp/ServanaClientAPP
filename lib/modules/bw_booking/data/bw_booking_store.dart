import 'package:flutter/foundation.dart';
import 'package:client/modules/catalog/domain/serviceability.dart';
import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/common/domain/address/address_display.dart';
import 'dart:math';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/data/booking/booking_submission_service.dart';
import 'package:client/common/domain/booking/booking_create_request.dart';
import 'package:client/common/domain/booking/booking_submission_result.dart';
import 'package:client/common/domain/booking/booking_draft.dart'
    show BookingFlowType;
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_property.dart';
import 'package:client/core/analytics/events/booking_events.dart';
import 'package:client/core/recovery/draft_repository.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:client/modules/payments/data/payments_repository.dart';
import 'package:mobx/mobx.dart';

part 'bw_booking_store.g.dart';

class BwBookingStore extends _BwBookingStore with _$BwBookingStore {
  BwBookingStore({required super.api});
}

abstract class _BwBookingStore with Store {
  final ServanaApiClient api;

  _BwBookingStore({required this.api});

  /// Stable idempotency key for the current booking session.
  /// Generated once on first [createBooking] call; reused on retry; cleared on reset.
  String? _idempotencyKey;

  // ───────── Observable state ─────────

  /// Catalog / branch / slot / generic operations.
  @observable
  bool isLoading = false;

  /// Set true when address list is being fetched.
  @observable
  bool isAddressLoading = false;

  /// Stays true after successful booking creation — permanently disables submit.
  @observable
  bool isSubmitting = false;

  /// Set true while creating a PayMongo session.
  @observable
  bool isPaymentLoading = false;

  @observable
  String? errorMessage;

  /// Submission-specific error (shown on the submit button section).
  @observable
  String? submissionError;

  /// Address-operation-specific error.
  @observable
  String? addressError;

  /// The B&W service ID the user tapped (passed from navigation)
  @observable
  int? selectedServiceId;

  /// Options with add-ons for the selected service
  @observable
  ObservableList<Map<String, dynamic>> optionsWithAddons =
      ObservableList<Map<String, dynamic>>();

  /// Branches for the B&W service
  @observable
  ObservableList<Map<String, dynamic>> branches =
      ObservableList<Map<String, dynamic>>();

  /// Available time slots for the selected branch + date
  @observable
  ObservableList<Map<String, dynamic>> slots =
      ObservableList<Map<String, dynamic>>();

  /// User's saved addresses
  @observable
  ObservableList<Map<String, dynamic>> savedAddresses =
      ObservableList<Map<String, dynamic>>();

  // ──── User selections ────

  @observable
  Map<String, dynamic>? selectedOption;

  @observable
  ObservableList<int> selectedAddonIds = ObservableList<int>();

  @observable
  Map<String, dynamic>? selectedBranch;

  @observable
  DateTime? selectedDate;

  @observable
  Map<String, dynamic>? selectedSlot;

  /// A schedule the customer picked directly, for a service with no branch
  /// slots to choose from.
  ///
  /// Measured on production 2026-08-20: `GET /api/services/:id/branches`
  /// answers `branches: []` for NINE of the ten legacy families, and the
  /// canonical catalog handoff routes a Service straight to checkout without
  /// passing a branch screen at all. For 65 of the 95 services on offer there
  /// is therefore no slot to pick, and this is how the customer says when.
  @observable
  DateTime? selectedSchedule;

  @observable
  Map<String, dynamic>? selectedAddress;

  /// The backend's verdict on booking this service at [selectedAddress].
  ///
  /// Null means "not asked, or could not tell" — never "yes". The UI shows
  /// nothing in that state rather than a reassurance it did not earn.
  @observable
  Serviceability? serviceability;

  /// True while the check is in flight, so the screen can hold the submit
  /// button rather than let a customer race the answer.
  @observable
  bool isCheckingServiceability = false;

  @observable
  String paymentMethod = 'CASH';

  // ──── Booking result ────

  @observable
  Map<String, dynamic>? bookingResult;

  @observable
  int? createdBookingId;

  // Canonical wire field is `workerCode`. The legacy `otpCode` field is being
  // deprecated by the BE; do not fall back to it. Same value the provider
  // sends back on Start Job as `workerCode`.
  @observable
  String? workerCode;

  // ──── PayMongo ────

  @observable
  String? paymongoCheckoutUrl;

  // ───────── Computed ─────────

  /// Filter add-ons out of `optionsWithAddons`. Hosts that show "bookable
  /// services" (home recommended, search, category screens) all want this
  /// shape — keep the union of the three drift-prone checks in one place so
  /// callers stop diverging.
  @computed
  List<Map<String, dynamic>> get bookableOptions => optionsWithAddons
      .where((o) =>
          o['optionType'] != 'ADD_ON' &&
          o['isAddon'] != true &&
          o['is_addon'] != true)
      .toList();

  @computed
  double get estimatedTotal {
    double total = 0;
    if (selectedOption != null) {
      total += ServiceCardModel.extractPrice(selectedOption!).toDouble();
    }
    // Look up addons from selected option's nested addons array.
    final nestedAddons = (selectedOption?['addons'] as List?) ?? [];
    for (final addonId in selectedAddonIds) {
      final addon = nestedAddons.cast<Map<String, dynamic>?>().firstWhere(
            (a) => _parseInt(a?['id']) == addonId,
            orElse: () => null,
          );
      if (addon != null) {
        total += ServiceCardModel.extractPrice(addon).toDouble();
      }
    }
    return total;
  }

  // ───────── Actions ─────────

  @action
  void reset() {
    _idempotencyKey = null;
    selectedServiceId = null;
    selectedOption = null;
    selectedAddonIds.clear();
    selectedBranch = null;
    selectedDate = null;
    selectedSlot = null;
    selectedSchedule = null;
    selectedAddress = null;
    serviceability = null;
    paymentMethod = 'CASH';
    bookingResult = null;
    createdBookingId = null;
    workerCode = null;
    paymongoCheckoutUrl = null;
    errorMessage = null;
    submissionError = null;
    addressError = null;
    isSubmitting = false;
    isAddressLoading = false;
    isPaymentLoading = false;
    optionsWithAddons.clear();
    branches.clear();
    slots.clear();
    // Bridge the gap until the follow-up load() flips this true; otherwise
    // observers render an empty grid between reset() and load().
    isLoading = true;
  }

  /// Prepares the store for a Service scheduled directly, with no branch.
  ///
  /// Needed because [clearSelectionOnly] deliberately preserves `branches` for
  /// catalog reuse. Without this, a customer who opened Beauty & Wellness
  /// (legacy family 2, the one family that HAS a branch) and then picked a
  /// Personal Care service out of Search would arrive at checkout with a stale
  /// branch list — so [branchRequired] would be true, the screen would draw no
  /// branch control, and the booking would be refused for a field that flow
  /// never had.
  @action
  void beginBranchlessBooking() {
    selectedServiceId = null;
    selectedBranch = null;
    selectedSlot = null;
    selectedSchedule = null;
    selectedDate = null;
    branches.clear();
    slots.clear();
  }

  /// Clears only the active booking-flow selections without touching the
  /// cached service catalog. Use this when entering a category screen so the
  /// user starts a fresh booking while already-loaded options are reused.
  @action
  void clearSelectionOnly() {
    _idempotencyKey = null;
    selectedOption = null;
    selectedAddonIds.clear();
    selectedBranch = null;
    selectedDate = null;
    selectedSlot = null;
    selectedSchedule = null;
    selectedAddress = null;
    serviceability = null;
    paymentMethod = 'CASH';
    bookingResult = null;
    createdBookingId = null;
    workerCode = null;
    paymongoCheckoutUrl = null;
    errorMessage = null;
    submissionError = null;
    addressError = null;
    isSubmitting = false;
    isPaymentLoading = false;
    // optionsWithAddons, branches, slots, isLoading — NOT touched.
  }

  /// Triggers a load only if there's no cached data and no in-flight request.
  /// Used by hosts (home, search) that want fresh options without forcing
  /// a reload when the user is just navigating around.
  @action
  void ensureOptionsLoaded({required int serviceId}) {
    if (optionsWithAddons.isEmpty && !isLoading) {
      loadOptionsWithAddons(serviceId: serviceId);
    }
  }

  @action
  Future<void> loadOptionsWithAddons({required int serviceId}) async {
    isLoading = true;
    errorMessage = null;
    selectedServiceId = serviceId;
    try {
      final res = await api.listOptionsWithAddons(serviceId: serviceId);
      final data = _extractList(res);
      optionsWithAddons
        ..clear()
        ..addAll(data);
    } catch (e) {
      errorMessage = _errorMsg(e);
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> loadBranches({required int serviceId}) async {
    isLoading = true;
    errorMessage = null;
    try {
      final res = await api.getBeautyAndWellnessBranches(serviceId: serviceId);
      final data = _extractList(res);
      branches
        ..clear()
        ..addAll(data);
      if (branches.isNotEmpty && selectedBranch == null) {
        selectBranch(branches.first);
      }
    } catch (e) {
      errorMessage = _errorMsg(e);
    } finally {
      isLoading = false;
    }
  }

  /// Monotonic counter to discard stale slot responses when the user
  /// rapidly changes dates.
  int _slotRequestId = 0;

  @action
  Future<void> loadSlots() async {
    if (selectedBranch == null || selectedDate == null) return;
    isLoading = true;
    errorMessage = null;
    final requestId = ++_slotRequestId;
    try {
      final branchId =
          _parseInt(selectedBranch!['branchId'] ?? selectedBranch!['id']) ?? 0;
      final res =
          await api.getBranchSlots(branchId: branchId, date: selectedDate!);
      // Discard if a newer request was fired while we were waiting.
      if (requestId != _slotRequestId) return;
      final data = _extractList(res);
      slots
        ..clear()
        ..addAll(data);
    } catch (e) {
      if (requestId != _slotRequestId) return;
      errorMessage = _errorMsg(e);
    } finally {
      if (requestId == _slotRequestId) {
        isLoading = false;
      }
    }
  }

  @action
  Future<void> loadSavedAddresses() async {
    isAddressLoading = true;
    addressError = null;
    try {
      final res = await api.getAllUserAddresses();
      final data = _extractList(res);
      savedAddresses
        ..clear()
        ..addAll(data);
    } catch (e) {
      addressError = _errorMsg(e);
    } finally {
      isAddressLoading = false;
    }
  }

  @action
  void selectOption(Map<String, dynamic> option) {
    selectedOption = option;
    selectedAddonIds.clear();
  }

  @action
  void toggleAddon(int addonId) {
    if (selectedAddonIds.contains(addonId)) {
      selectedAddonIds.remove(addonId);
    } else {
      selectedAddonIds.add(addonId);
    }
  }

  @action
  void selectBranch(Map<String, dynamic> branch) {
    selectedBranch = branch;
    selectedSlot = null;
    slots.clear();
  }

  @action
  void setDate(DateTime date) {
    selectedDate = date;
    selectedSlot = null;
    // Carry a directly-chosen time onto the new day rather than dropping it.
    // Leaving `selectedSchedule` alone would submit the OLD date with the new
    // one on screen — the screen and the payload disagreeing about when.
    final existing = selectedSchedule;
    if (existing != null) {
      selectedSchedule = DateTime(
        date.year,
        date.month,
        date.day,
        existing.hour,
        existing.minute,
      );
    }
    loadSlots();
  }

  @action
  void selectSlot(Map<String, dynamic> slot) {
    selectedSlot = slot;
  }

  /// Sets a directly-chosen date and time.
  ///
  /// Clears any branch slot: the two are alternative answers to the same
  /// question, and holding both would leave [effectiveSchedule] deciding
  /// silently which one the customer meant.
  @action
  void setSchedule(DateTime schedule) {
    selectedSchedule = schedule;
    selectedSlot = null;
    selectedDate = DateTime(schedule.year, schedule.month, schedule.day);
  }

  @action
  void selectAddress(Map<String, dynamic> address) {
    selectedAddress = address;
    // Clear first: a verdict about the PREVIOUS address must not linger over
    // the new one for the length of a round trip.
    serviceability = null;
    checkServiceability();
  }

  /// Asks whether this service can be booked at the chosen address.
  ///
  /// Runs on address selection rather than at submit, which is the whole point:
  /// `createBooking` already answers this, and it answers it after the customer
  /// has chosen a date and a payment method.
  ///
  /// **A failure clears the verdict rather than inventing one.** If the check
  /// cannot be made, the app does not know — and it must not block a booking
  /// the server would accept, nor promise one it would refuse. The server runs
  /// the same test at submit and refuses honestly, so silence here costs a
  /// wasted form at worst; a wrong "unavailable" costs the booking outright.
  @action
  Future<void> checkServiceability() async {
    final address = selectedAddress;
    final serviceId = _canonicalServiceId;
    if (address == null || serviceId == null) {
      serviceability = null;
      return;
    }

    final lat = _coordinate(address['lat']);
    final lon = _coordinate(address['lon']);
    if (lat == null || lon == null) {
      // An address with no usable coordinates cannot be judged, and the
      // backend says so too (INVALID_LOCATION). Reported rather than assumed
      // serviceable: `createBooking` will refuse it with "Address missing
      // locationId." and the customer deserves to know before the form.
      serviceability = const Serviceability(
        serviceable: false,
        reason: ServiceabilityReason.invalidLocation,
      );
      return;
    }

    isCheckingServiceability = true;
    try {
      serviceability = await dpLocator<CatalogRepository>()
          .serviceability(serviceId: serviceId, lat: lat, lon: lon);
    } catch (e) {
      debugPrint('[BwBookingStore] serviceability check failed: $e');
      serviceability = null;
    } finally {
      isCheckingServiceability = false;
    }
  }

  /// The canonical `services.id` for the selected option, or null.
  ///
  /// `canonicalOptionMap` writes `catalogServiceId`; a legacy option map from
  /// the curated category path does not carry one, and `id` there is a
  /// `service_options.id`. They are equal for every promoted row today and stop
  /// being equal for the first Service created through the Admin API — so the
  /// canonical key is read by name and NOT inferred from `id`.
  int? get _canonicalServiceId {
    final raw = selectedOption?['catalogServiceId'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static double? _coordinate(Object? raw) {
    final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
    // Zero is Null Island, which is what an absent coordinate arrives as.
    if (value == null || value == 0) return null;
    return value;
  }

  @action
  void setPaymentMethod(String method) => paymentMethod = method;

  @action
  Future<void> createBooking() async {
    if (isSubmitting) return;
    isSubmitting = true;
    submissionError = null;
    _track(const BookingSubmittedEvent(serviceCategory: 'beauty_wellness'));
    try {
      // The schedule must be resolvable before the shared validation can say
      // anything useful about it — this is not a "missing field" check, it is
      // what makes a submitted timestamp meaningful, so it stays ahead of the
      // shared validation rather than inside it. Either a structurally valid
      // branch slot or a directly-chosen date and time will do.
      final schedule = effectiveSchedule;

      final optionId = selectedOption?['id'] ?? selectedOption?['optionId'];

      // The submission ceremony — session, validation, journal, transport,
      // parse — is shared with Aircon through one service. What stays here is
      // genuinely category-specific: the branch, the slot-derived schedule, and
      // how this flow speaks to the customer.
      final outcome = await dpLocator<BookingSubmissionService>().submit(
        request: BookingCreateRequest(
          flowType: BookingFlowType.beautyWellness,
          serviceOptionId: optionId,
          userAddressId:
              '${selectedAddress?['addressId'] ?? selectedAddress?['id'] ?? ''}',
          schedule: schedule,
          paymentMethod: paymentMethod,
          branchId: selectedBranch?['branchId'] ?? selectedBranch?['id'],
          requiresBranch: branchRequired,
          pricingInputs: <String, dynamic>{
            'addonOptionIds': selectedAddonIds.toList(),
          },
        ),
        // Generated once, on the first attempt that actually reaches the
        // network, and reused on every retry of this draft — regenerating on
        // retry is what turns one booking into two.
        idempotencyKey: () => _idempotencyKey ??= _uuidV4(),
        operationId: _uuidV4(),
      );

      switch (outcome) {
        case BookingRefused(unauthenticated: true):
          submissionError = 'You must be signed in to create a booking.';
          isSubmitting = false;
          _track(const BookingFailedEvent(
              serviceCategory: 'beauty_wellness',
              failureCode: 'unauthenticated'));

        // A schedule that has passed is reported separately from one that was
        // never chosen. They are different customer mistakes and this flow has
        // always distinguished them.
        case BookingRefused(reasons: final reasons)
            when schedule != null &&
                reasons.contains(BookingRequestInvalidity.scheduleInPast):
          submissionError = 'Choose a future booking schedule.';
          isSubmitting = false;
          _track(const BookingFailedEvent(
            serviceCategory: 'beauty_wellness',
            failureCode: 'invalid_schedule',
          ));

        case BookingRefused(reasons: final reasons):
          submissionError = _refusalMessage(reasons);
          isSubmitting = false;
          _track(const BookingFailedEvent(
            serviceCategory: 'beauty_wellness',
            failureCode: 'invalid_draft',
          ));

        case BookingAccepted(
            bookingId: final id,
            workerCode: final code,
            raw: final res
          ):
          bookingResult = res;
          createdBookingId = id;
          workerCode = code;
          _track(BookingCreatedEvent(
            serviceCategory: 'beauty_wellness',
            paymentMethod: paymentMethod.toLowerCase(),
            amountBand: AmountBandValues.forAmount(estimatedTotal),
          ));
        // isSubmitting intentionally NOT reset on success.

        case BookingFailed(error: final e):
          submissionError = _errorMsg(e);
          _track(const BookingFailedEvent(
            serviceCategory: 'beauty_wellness',
            failureCode: FailureCodeValues.networkError,
          ));
          isSubmitting = false;
      }
    } catch (e) {
      // The service returns failures rather than throwing, so this is the
      // belt-and-braces case: something threw building the request itself.
      submissionError = _errorMsg(e);
      _track(const BookingFailedEvent(
        serviceCategory: 'beauty_wellness',
        failureCode: FailureCodeValues.networkError,
      ));
      isSubmitting = false;
    }
  }

  /// Returns true if payment is confirmed, false otherwise.
  @action
  Future<bool> verifyPaymentStatus() async {
    if (createdBookingId == null) return false;
    isLoading = true;
    errorMessage = null;
    try {
      // The same ceremony AirconBookingStore uses. These two methods were
      // character-for-character identical, in two files, and either could have
      // been changed without the other.
      return await dpLocator<PaymentsRepository>()
          .isPaid('${createdBookingId!}');
    } catch (e) {
      errorMessage = _errorMsg(e);
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> createPaymongoSession() async {
    if (createdBookingId == null || isPaymentLoading) return;
    isPaymentLoading = true;
    errorMessage = null;
    paymongoCheckoutUrl = null;
    try {
      final session = await SessionService.getSession();
      final uid = session?.customerID ?? '';
      final intent = await dpLocator<PaymentsRepository>()
          .startCheckout('${createdBookingId!}');
      paymongoCheckoutUrl = intent.isUsable ? intent.checkoutUrl : null;
      // Backend can return success without a URL (e.g. on a partial session
      // failure). Surface that as an error so the confirmation screen shows
      // the Retry branch instead of an indefinite spinner.
      if (paymongoCheckoutUrl == null || paymongoCheckoutUrl!.isEmpty) {
        errorMessage = 'Payment session could not be started. Please retry.';
      } else if (uid.isNotEmpty) {
        // Persist checkout URL so the user can resume payment after an app crash.
        dpLocator<DraftRepository>()
            .savePaymentContext(PendingPaymentContext(
              bookingId: createdBookingId!,
              checkoutUrl: paymongoCheckoutUrl!,
              customerUid: uid,
              savedAt: DateTime.now(),
            ))
            .ignore();
      }
    } catch (e) {
      errorMessage = _errorMsg(e);
    } finally {
      isPaymentLoading = false;
    }
  }

  /// Names only what is actually missing.
  ///
  /// The previous copy read "Complete the service, branch, schedule, address,
  /// and payment details." on EVERY refusal. For a service with no branch that
  /// sent the customer hunting for a control the screen does not draw, and for
  /// a customer who had only forgotten their address it listed four fields they
  /// had already filled in. A refusal that names the wrong cause is the same
  /// class of defect as a sign-in screen blaming a password during an outage.
  String _refusalMessage(List<BookingRequestInvalidity> reasons) {
    final missing = <String>[
      for (final reason in reasons)
        switch (reason) {
          BookingRequestInvalidity.noService => 'a service',
          BookingRequestInvalidity.noAddress => 'a service address',
          BookingRequestInvalidity.noBranch => 'a branch',
          BookingRequestInvalidity.noSchedule => 'a date and time',
          BookingRequestInvalidity.scheduleInPast => 'a future date and time',
          BookingRequestInvalidity.noPaymentMethod => 'a payment method',
        },
    ];
    if (missing.isEmpty) return 'Complete your booking details to continue.';
    if (missing.length == 1) return 'Choose ${missing.single} to continue.';
    final last = missing.removeLast();
    return 'Choose ${missing.join(', ')} and $last to continue.';
  }

  // ───────── Derived state ─────────

  /// Whether this service actually offers a branch to choose.
  ///
  /// The client used to demand a branch on EVERY Beauty & Wellness booking
  /// (`requiresBranch: true`, unconditionally), which is stricter than the
  /// server: the backend's own validator types `branchId?: number` and
  /// `createBooking` guards every branch read with
  /// `if (payload.branchId !== undefined)`. Since production answers
  /// `branches: []` for nine of the ten legacy families, that rule refused
  /// bookings the server would have accepted — and the checkout screen draws
  /// no branch control, so the refusal named a field the customer could not
  /// fill in.
  ///
  /// Keyed on what was actually loaded rather than on the flow, so the one
  /// family that DOES have a branch still requires it.
  bool get branchRequired => branches.isNotEmpty;

  /// When the service is to happen, however the customer answered.
  ///
  /// A branch slot carries capacity the backend locks; a directly-chosen
  /// schedule does not. They are alternatives, never both, and null here is
  /// what makes "no schedule chosen" distinguishable from "a schedule that has
  /// passed" — two different customer mistakes this flow has always reported
  /// separately.
  DateTime? get effectiveSchedule {
    if (selectedDate != null && _hasValidSelectedSlot()) {
      return _buildScheduleDateTime();
    }
    return selectedSchedule;
  }

  // ───────── Helpers ─────────

  DateTime _buildScheduleDateTime() {
    final date = selectedDate ?? DateTime.now().add(const Duration(days: 1));
    if (selectedSlot != null) {
      final slotTime = selectedSlot!['slotTime']?.toString() ?? '';
      final parts = slotTime.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    }
    return date;
  }

  bool _hasValidSelectedSlot() {
    final slotTime = selectedSlot?['slotTime']?.toString() ?? '';
    final parts = slotTime.split(':');
    if (parts.length < 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return hour != null &&
        minute != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> res) {
    // Try common wrapper keys first, then fall back to the first List value.
    final raw = res['data'] ?? res['items'] ?? res['branches'] ?? res['slots'];
    if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    }
    // Fallback: find the first List value in the response map.
    for (final v in res.values) {
      if (v is List) return v.cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is double) return v.toInt();
    return null;
  }

  /// What the customer is told when something goes wrong.
  ///
  /// This used to put the backend's own sentence on screen for an API error,
  /// and `e.toString()` for anything else — so a dropped connection rendered
  /// "SocketException: Failed host lookup: 'api.servana.com.ph'" in a snackbar,
  /// and an out-of-coverage refusal arrived as raw server prose (§21).
  ///
  /// [BookingErrorMapper] was written for exactly this and had ZERO callers.
  /// It classifies by status first, so a 500 can no longer be reported as a
  /// connectivity problem.
  String _errorMsg(Object e) => BookingErrorMapper.fromException(e).message;

  /// Snapshot of the just-created booking built from current selections, used
  /// to open the booking detail screen and seed the bookings list immediately
  /// after creation. The detail screen refreshes live status/payment on open.
  JobOrder buildCreatedJobOrder() {
    final id = createdBookingId?.toString() ??
        'bw_${DateTime.now().millisecondsSinceEpoch}';
    final addr = selectedAddress;
    return JobOrder(
      jobOrderID: id,
      jobOrderNumber: 'BK-$id',
      merchantName: 'Servana',
      merchantID: 'servana',
      scheduleDate: _buildScheduleDateTime(),
      jobOrderStatus: JobOrderStatus.forReview,
      jobOrderStatusToString: 'For Review',
      address: formatAddressLine(
        addr?['addressOne']?.toString(),
        addr?['postTown']?.toString(),
      ),
      latitude: (addr?['lat'] as num?)?.toDouble() ?? 0,
      longitude: (addr?['lon'] as num?)?.toDouble() ?? 0,
      numberOfPersonnel: 1,
      distanceFromOffice: 0,
      merchantServiceName: _optionName(),
      downPayment: 0,
      totalAmount: estimatedTotal,
      paymentType: paymentMethod == 'PAYMONGO' ? 3 : 1,
      paymentStatus: 'PENDING',
      paymentMethodUsed: paymentMethod,
      createdDate: DateTime.now(),
    );
  }

  String _optionName() {
    final opt = selectedOption;
    if (opt == null) return 'Beauty & Wellness Service';
    return (opt['level_3'] ??
            opt['name'] ??
            opt['optionName'] ??
            'Beauty & Wellness Service')
        .toString();
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  static String _uuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
