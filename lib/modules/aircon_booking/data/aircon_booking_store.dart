import 'package:client/common/domain/address/address_display.dart';
import 'dart:convert';
import 'dart:math';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/data/booking/booking_submission_service.dart';
import 'package:client/common/domain/booking/booking_create_request.dart';
import 'package:client/common/domain/booking/booking_draft.dart' show BookingFlowType;
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_property.dart';
import 'package:client/core/analytics/events/booking_events.dart';
import 'package:client/core/recovery/draft_repository.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:client/modules/payments/data/payments_repository.dart';
import 'package:mobx/mobx.dart';

part 'aircon_booking_store.g.dart';

class AirconBookingStore extends _AirconBookingStore with _$AirconBookingStore {
  AirconBookingStore({required super.api});
}

abstract class _AirconBookingStore with Store {
  final ServanaApiClient api;

  _AirconBookingStore({required this.api});

  /// Stable idempotency key for the current booking session.
  /// Generated once on first [createBooking] call; reused on retry; cleared on reset.
  String? _idempotencyKey;

  // ───────── Observable state ─────────

  /// Catalog / quote / generic operations (options loading, quote fetch).
  @observable
  bool isLoading = false;

  /// Set true when address list is being fetched. Separate from [isLoading]
  /// so address spinners don't disable the quote CTA.
  @observable
  bool isAddressLoading = false;

  /// Set true from booking creation until the screen navigates away (or an
  /// error resets it). Stays true on success — keeps the submit button
  /// permanently disabled after one successful creation.
  @observable
  bool isSubmitting = false;

  /// Set true while creating a PayMongo session. Separate so the payment
  /// section can show its own spinner without disabling the whole screen.
  @observable
  bool isPaymentLoading = false;

  @observable
  String? errorMessage;

  /// Submission-specific error (distinct from catalog errorMessage).
  @observable
  String? submissionError;

  /// Address-operation-specific error.
  @observable
  String? addressError;

  /// Top-level services returned by GET /api/services
  @observable
  ObservableList<Map<String, dynamic>> services =
      ObservableList<Map<String, dynamic>>();

  /// Level-2 sub-services for aircon (serviceId = 1)
  @observable
  ObservableList<Map<String, dynamic>> level2Services =
      ObservableList<Map<String, dynamic>>();

  /// Options with add-ons for the selected service
  @observable
  ObservableList<Map<String, dynamic>> optionsWithAddons =
      ObservableList<Map<String, dynamic>>();

  /// User's saved addresses
  @observable
  ObservableList<Map<String, dynamic>> savedAddresses =
      ObservableList<Map<String, dynamic>>();

  // ──── User selections ────

  @observable
  Map<String, dynamic>? selectedOption;

  @observable
  String? selectedHpKey;

  @observable
  String? selectedHeightKey;

  @observable
  String? selectedDistanceKey;

  @observable
  ObservableList<int> selectedAddonIds = ObservableList<int>();

  @observable
  Map<String, dynamic>? selectedAddress;

  @observable
  DateTime? selectedSchedule;

  @observable
  String paymentMethod = 'CASH';

  // ──── Quote result ────

  @observable
  Map<String, dynamic>? quoteResult;

  @observable
  double quotedTotal = 0;

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

  /// Filter add-ons out of `optionsWithAddons` — same shape contract as
  /// BwBookingStore.bookableOptions.
  @computed
  List<Map<String, dynamic>> get bookableOptions => optionsWithAddons
      .where((o) =>
          o['optionType'] != 'ADD_ON' &&
          o['isAddon'] != true &&
          o['is_addon'] != true)
      .toList();

  // ───────── Actions ─────────

  @action
  void reset() {
    _idempotencyKey = null;
    selectedOption = null;
    selectedHpKey = null;
    selectedHeightKey = null;
    selectedDistanceKey = null;
    selectedAddonIds.clear();
    selectedAddress = null;
    selectedSchedule = null;
    paymentMethod = 'CASH';
    quoteResult = null;
    quotedTotal = 0;
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
    // Bridge the gap until the follow-up load() flips this true; otherwise
    // observers render an empty grid between reset() and load().
    isLoading = true;
  }

  @action
  Future<void> loadServices() async {
    isLoading = true;
    errorMessage = null;
    try {
      final res = await api.listServices();
      final data = _extractList(res);
      services
        ..clear()
        ..addAll(data);
    } catch (e) {
      errorMessage = _errorMsg(e);
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> loadLevel2Services({int serviceId = 1}) async {
    isLoading = true;
    errorMessage = null;
    try {
      final res = await api.listLevel2Services(serviceId: serviceId);
      final data = _extractList(res);
      level2Services
        ..clear()
        ..addAll(data);
    } catch (e) {
      errorMessage = _errorMsg(e);
    } finally {
      isLoading = false;
    }
  }

  /// Clears only the active booking-flow selections without touching the
  /// cached service catalog. Use this when entering the Aircon screen so the
  /// user starts a fresh booking while already-loaded options are reused.
  @action
  void clearSelectionOnly() {
    _idempotencyKey = null;
    selectedOption = null;
    selectedHpKey = null;
    selectedHeightKey = null;
    selectedDistanceKey = null;
    selectedAddonIds.clear();
    selectedAddress = null;
    selectedSchedule = null;
    paymentMethod = 'CASH';
    quoteResult = null;
    quotedTotal = 0;
    bookingResult = null;
    createdBookingId = null;
    workerCode = null;
    paymongoCheckoutUrl = null;
    errorMessage = null;
    submissionError = null;
    addressError = null;
    isSubmitting = false;
    isPaymentLoading = false;
    // optionsWithAddons — NOT touched.
  }

  /// Triggers a load only if there's no cached data and no in-flight request.
  /// Used by hosts (home, search) that want fresh options without forcing
  /// a reload when the user is just navigating around.
  @action
  void ensureOptionsLoaded({int serviceId = 1}) {
    if (optionsWithAddons.isEmpty && !isLoading) {
      loadOptionsWithAddons(serviceId: serviceId);
    }
  }

  @action
  Future<void> loadOptionsWithAddons({int serviceId = 1}) async {
    isLoading = true;
    errorMessage = null;
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

  /// Drops the cached quote so the screen reverts the CTA from
  /// "Proceed to Checkout" back to "Get Quote". Called from every input
  /// mutator below — any change to pricing inputs must force a re-quote.
  @action
  void _invalidateQuote() {
    quoteResult = null;
    quotedTotal = 0;
  }

  @action
  void selectOption(Map<String, dynamic> option) {
    if (selectedOption?['id'] == option['id'] &&
        selectedOption?['optionId'] == option['optionId']) {
      return;
    }
    selectedOption = option;
    selectedAddonIds.clear();
    _invalidateQuote();
  }

  @action
  void setHpKey(String key) {
    if (selectedHpKey == key) return;
    selectedHpKey = key;
    _invalidateQuote();
  }

  @action
  void setHeightKey(String key) {
    if (selectedHeightKey == key) return;
    selectedHeightKey = key;
    _invalidateQuote();
  }

  @action
  void setDistanceKey(String key) {
    if (selectedDistanceKey == key) return;
    selectedDistanceKey = key;
    _invalidateQuote();
  }

  @action
  void toggleAddon(int addonId) {
    if (selectedAddonIds.contains(addonId)) {
      selectedAddonIds.remove(addonId);
    } else {
      selectedAddonIds.add(addonId);
    }
    _invalidateQuote();
  }

  @action
  void selectAddress(Map<String, dynamic> address) {
    selectedAddress = address;
  }

  @action
  void setSchedule(DateTime dt) => selectedSchedule = dt;

  @action
  void setPaymentMethod(String method) => paymentMethod = method;

  @action
  Future<void> getQuote() async {
    if (selectedOption == null) return;
    isLoading = true;
    errorMessage = null;
    try {
      final optionId = selectedOption!['id'] ?? selectedOption!['optionId'];
      final payload = <String, dynamic>{
        'optionId': optionId,
        if (selectedHpKey != null) 'hpKey': selectedHpKey,
        if (selectedHeightKey != null) 'heightKey': selectedHeightKey,
        if (selectedDistanceKey != null) 'distanceKey': selectedDistanceKey,
        'addonOptionIds': selectedAddonIds.toList(),
        'parts': <dynamic>[],
      };
      final res = await api.getAirconQuote(payload: payload);
      quoteResult = res;
      quotedTotal = _extractTotal(res);
    } catch (e) {
      errorMessage = _errorMsg(e);
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> createBooking() async {
    // Guard: only one submission per booking draft.
    if (isSubmitting) return;
    isSubmitting = true;
    submissionError = null;
    _track(const BookingSubmittedEvent(serviceCategory: 'aircon'));
    try {
      final optionId = selectedOption?['id'] ?? selectedOption?['optionId'];

      // The submission ceremony — session, validation, journal, transport,
      // parse — is shared with Beauty & Wellness through one service. What
      // stays here is what is genuinely category-specific: which fields exist,
      // what the pricing inputs are, and how this flow speaks to the customer.
      final outcome = await dpLocator<BookingSubmissionService>().submit(
        request: BookingCreateRequest(
          flowType: BookingFlowType.aircon,
          serviceOptionId: optionId,
          userAddressId:
              '${selectedAddress?['addressId'] ?? selectedAddress?['id'] ?? ''}',
          schedule: selectedSchedule,
          paymentMethod: paymentMethod,
          pricingInputs: <String, dynamic>{
            'optionId': optionId,
            if (selectedHpKey != null) 'hpKey': selectedHpKey,
            if (selectedHeightKey != null) 'heightKey': selectedHeightKey,
            if (selectedDistanceKey != null) 'distanceKey': selectedDistanceKey,
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
              serviceCategory: 'aircon', failureCode: 'unauthenticated'));

        case BookingRefused():
          submissionError =
              'Complete the service, address, schedule, and payment details.';
          isSubmitting = false;
          _track(const BookingFailedEvent(
            serviceCategory: 'aircon',
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
            serviceCategory: 'aircon',
            paymentMethod: paymentMethod.toLowerCase(),
            amountBand: AmountBandValues.forAmount(quotedTotal),
          ));
        // isSubmitting intentionally NOT reset on success — keeps the button
        // permanently disabled after a booking is created.

        case BookingFailed(error: final e):
          submissionError = _errorMsg(e);
          _track(const BookingFailedEvent(
            serviceCategory: 'aircon',
            failureCode: FailureCodeValues.networkError,
          ));
          // Reset on error only so the user can retry after a genuine failure.
          isSubmitting = false;
      }
    } catch (e) {
      // The service returns failures rather than throwing, so this is the
      // belt-and-braces case: something threw building the request itself.
      submissionError = _errorMsg(e);
      _track(const BookingFailedEvent(
        serviceCategory: 'aircon',
        failureCode: FailureCodeValues.networkError,
      ));
      isSubmitting = false;
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
      // One ceremony. This block used to unwrap the envelope and pick between
      // `checkoutUrl` and `checkout_url` itself — as did BwBookingStore, and as
      // did an inline block in BookingDetailScreen, which read only the root
      // and so would have missed a wrapped response the other two handled.
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

  /// Returns true if payment is confirmed, false otherwise.
  @action
  Future<bool> verifyPaymentStatus() async {
    if (createdBookingId == null) return false;
    isLoading = true;
    errorMessage = null;
    try {
      // Was a whole-booking fetch plus PaymentStatusParser, duplicated in
      // BwBookingStore and again in PaymentWebViewScreen. The repository still
      // re-reads the booking on the legacy transport — R-06 is a missing
      // endpoint, not something a client can refactor away — but it does so in
      // one place, and swaps to GET …/payment the moment the capability is on.
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
  Future<Map<String, dynamic>?> getBookingTracking() async {
    if (createdBookingId == null) return null;
    isLoading = true;
    errorMessage = null;
    try {
      final res = await api.getBookingTracking(createdBookingId!);
      return res;
    } catch (e) {
      errorMessage = _errorMsg(e);
      return null;
    } finally {
      isLoading = false;
    }
  }

  // ───────── Helpers ─────────

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> res) {
    final raw = res['data'] ?? res['items'] ?? res;
    if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  double _extractTotal(Map<String, dynamic> res) {
    // /api/quote returns { success, quote: { base, final, ... } }.
    // Tolerate legacy/alt shapes (data wrapper, total/amount keys, numeric
    // strings) so older mock responses still parse.
    final quote = res['quote'] ?? res['data'] ?? res;
    if (quote is Map) {
      final t = quote['final'] ??
          quote['finalPrice'] ??
          quote['total'] ??
          quote['totalAmount'] ??
          quote['amount'];
      if (t is num) return t.toDouble();
      if (t is String) return double.tryParse(t) ?? 0;
    }
    return 0;
  }

  String _errorMsg(Object e) {
    if (e is ServanaApiException) {
      try {
        final decoded = jsonDecode(e.body);
        if (decoded is Map<String, dynamic>) {
          final msg = decoded['message'] ?? decoded['error'];
          if (msg != null) return msg.toString();
        }
      } catch (_) {}
      return 'Something went wrong (${e.statusCode}).';
    }
    return e.toString();
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

  /// Snapshot of the just-created booking built from current selections, used
  /// to open the booking detail screen and seed the bookings list immediately
  /// after creation. The detail screen refreshes live status/payment on open.
  JobOrder buildCreatedJobOrder() {
    final id = createdBookingId?.toString() ??
        'aircon_${DateTime.now().millisecondsSinceEpoch}';
    final addr = selectedAddress;
    return JobOrder(
      jobOrderID: id,
      jobOrderNumber: 'BK-$id',
      merchantName: 'Servana',
      merchantID: 'servana',
      scheduleDate: selectedSchedule ?? DateTime.now(),
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
      totalAmount: quotedTotal,
      paymentType: paymentMethod == 'PAYMONGO' ? 3 : 1,
      paymentStatus: 'PENDING',
      paymentMethodUsed: paymentMethod,
      createdDate: DateTime.now(),
    );
  }

  String _optionName() {
    final opt = selectedOption;
    if (opt == null) return 'Aircon Service';
    return (opt['level_3'] ??
            opt['name'] ??
            opt['optionName'] ??
            'Aircon Service')
        .toString();
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }
}
