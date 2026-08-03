import 'dart:convert';
import 'dart:math';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_property.dart';
import 'package:client/core/analytics/events/booking_events.dart';
import 'package:client/core/recovery/draft_repository.dart';
import 'package:client/core/recovery/operation_journal.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
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

  @observable
  Map<String, dynamic>? selectedAddress;

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
    selectedAddress = null;
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
    selectedAddress = null;
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
    loadSlots();
  }

  @action
  void selectSlot(Map<String, dynamic> slot) {
    selectedSlot = slot;
  }

  @action
  void selectAddress(Map<String, dynamic> address) {
    selectedAddress = address;
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
      final session = await SessionService.getSession();
      final userId = session?.customerID ?? '';
      if (userId.isEmpty) {
        submissionError = 'You must be signed in to create a booking.';
        _track(const BookingFailedEvent(
            serviceCategory: 'beauty_wellness',
            failureCode: 'unauthenticated'));
        return;
      }

      // Generate a stable idempotency key once; reuse on retry — never regenerate.
      _idempotencyKey ??= _uuidV4();

      final addressId =
          selectedAddress?['addressId'] ?? selectedAddress?['id'] ?? '';
      final optionId = selectedOption?['id'] ?? selectedOption?['optionId'];

      // Build schedule from selectedDate + selectedSlot time
      final schedule = _buildScheduleDateTime();

      final payload = <String, dynamic>{
        'userAddressId': addressId,
        'serviceOptionId': optionId,
        'schedule': schedule.toUtc().toIso8601String(),
        'paymentMethod': paymentMethod,
        'pricing': <String, dynamic>{
          'addonOptionIds': selectedAddonIds.toList(),
        },
      };

      // Journal the operation before the API call so a process kill during
      // the network request leaves a reconcilable record.
      final opId = _uuidV4();
      dpLocator<OperationJournal>()
          .record(JournaledOperation(
            id: opId,
            type: 'booking.create',
            customerUid: userId,
            payload: {
              'category': 'beauty_wellness',
              'paymentMethod': paymentMethod
            },
            startedAt: DateTime.now(),
            idempotencyKey: _idempotencyKey,
          ))
          .ignore();

      final res = await api.createBooking(
        userId: userId,
        payload: payload,
        idempotencyKey: _idempotencyKey,
      );
      bookingResult = res;
      // Try every possible nesting: top-level, under 'data', under 'booking'.
      final booking = res['booking'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;
      createdBookingId = _parseInt(booking['bookingId']) ??
          _parseInt(booking['id']) ??
          _parseInt(res['bookingId']) ??
          _parseInt(res['id']);
      workerCode =
          (booking['workerCode'] ?? res['workerCode'] ?? '').toString();
      if (workerCode!.isEmpty) workerCode = null;

      // Booking confirmed — remove the pending journal entry.
      dpLocator<OperationJournal>().resolve(userId, opId).ignore();

      _track(BookingCreatedEvent(
        serviceCategory: 'beauty_wellness',
        paymentMethod: paymentMethod.toLowerCase(),
        amountBand: AmountBandValues.forAmount(estimatedTotal),
      ));
      // isSubmitting intentionally NOT reset on success.
    } catch (e) {
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
      final res = await api.getBooking(createdBookingId!);
      final booking = res['booking'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;
      final paymentStatus =
          (booking['paymentStatus'] ?? '').toString().toUpperCase();
      return paymentStatus == 'PAID';
    } catch (e) {
      errorMessage = _errorMsg(e);
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> createPaymongoSession() async {
    if (createdBookingId == null) return;
    isPaymentLoading = true;
    errorMessage = null;
    try {
      final session = await SessionService.getSession();
      final uid = session?.customerID ?? '';
      final res = await api.createPaymongoSession(bookingId: createdBookingId!);
      final data = res['data'] ?? res;
      paymongoCheckoutUrl =
          data['checkoutUrl']?.toString() ?? data['checkout_url']?.toString();
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
      address: '${addr?['addressOne'] ?? ''}, ${addr?['postTown'] ?? ''}',
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
