import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/booking_events.dart';
import 'package:client/modules/tracking/domain/tracking_args.dart';
import 'package:client/common/presentation/responsive/servana_responsive.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/domain/booking/payment_status_parser.dart';
import 'package:client/common/presentation/screens/booking_otp_screen.dart';
import 'package:client/common/presentation/screens/payment_webview_screen.dart';
import 'package:client/common/presentation/widgets/qr_worker_code_display.dart';
import 'package:client/common/presentation/widgets/booking_ux_components.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_repository.dart';
import 'package:client/modules/bookings/data/booking_repository.dart';
import 'package:client/modules/booking_experiences/application/booking_experiences_controller.dart';
import 'package:client/modules/booking_experiences/presentation/widgets/change_orders_section.dart';
import 'package:client/modules/payments/data/payments_repository.dart';
import 'package:client/modules/bookings/presentation/widgets/booking_cancellation_sheet.dart';
import 'package:client/modules/bookings/presentation/widgets/booking_reschedule_sheet.dart';
import 'package:client/modules/review/presentation/screens/review_detail_screen.dart';
import 'package:client/modules/review/presentation/screens/review_form_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/messaging/presentation/stores/messaging_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  static const String routeName = 'BookingDetail';
  // Path-param route: replaces the old extra-based /BookingDetail.
  // Navigated to via context.go('/bookings/<id>') or context.push('/bookings/<id>').
  static const String route = '/bookings/:bookingId';

  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  // Nullable until the first API response; the build() shows a spinner until
  // populated.
  JobOrder? _booking;
  String _bookingId = '';
  bool _isRefreshing = false;
  String? _refreshError;

  /// The schedule exactly as the backend sent it, or null when it sent none.
  ///
  /// Distinct from `JobOrder.scheduleDate`, which falls back to `DateTime.now()`
  /// so the detail card always has something to render. That fallback must not
  /// travel back to the server as `expectedSchedule`.
  DateTime? _scheduledAt;

  // Worker assignment surfaced from the booking JSON. The JobOrder freezed
  // model predates the BE auto-assignment feature, so these live in screen
  // state until the model is extended.
  String? _workerUid;
  String? _workerName;
  String? _workerPhone;
  String? _bookingStatus;
  int? _etaMinutes;
  DateTime? _assignedAt;
  String? _workerCode;
  bool _hasReview = false;
  bool _detailViewTracked = false;

  // Poll for worker assignment for up to ~60s after the screen opens, while
  // the booking is still in a pre-assignment state. Stops as soon as a
  // workerUid lands.
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 5);
  static const _pollMaxAttempts = 12;
  int _pollAttempts = 0;

  /// Change orders the provider raised on this booking.
  ///
  /// The legacy route has always returned these and this app never called it,
  /// so a customer could be asked to pay for extra work with no sign of it
  /// anywhere they could look.
  final _experiences = dpLocator<BookingExperiencesController>();

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    // Always pull fresh state on open — no JobOrder is passed in anymore;
    // everything comes from the API.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBooking();
      // Not awaited and never fatal: a change-order fetch that fails must not
      // cost the customer the rest of their booking detail.
      unawaited(_experiences.load(_bookingId));
    });
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool get _needsPayment =>
      PaymentStatusParser.requiresPayment(_booking?.paymentStatus) &&
      _booking?.paymentMethodUsed == 'PAYMONGO';

  /// A freshly-created booking sits in PENDING_OTP (or FOR_OTP alias) until the
  /// customer verifies the code; the BE assigns a technician only after that.
  bool get _needsOtp => BookingStatusMapper.requiresOtp(
      BookingStatusMapper.fromString(_bookingStatus));

  bool get _isAssigned => _workerUid != null && _workerUid!.isNotEmpty;

  /// Whether the "Track Provider" button should be shown.
  ///
  /// Tracking is available when the booking is active (en route / arrived /
  /// in progress) and a worker has been assigned.
  bool get _isTrackable {
    if (!_isAssigned) return false;
    final s = BookingStatusMapper.fromString(_bookingStatus);
    return s == BookingStatus.enRoute ||
        s == BookingStatus.arrived ||
        s == BookingStatus.inProgress ||
        s == BookingStatus.awaitingCompletion;
  }

  /// Allow cancellation only for pre-service states where the booking can still
  /// be cleanly voided.  In-progress and terminal states are excluded.
  bool get _isCancellable {
    if (_bookingStatus == null) return false;
    final s = BookingStatusMapper.fromString(_bookingStatus);
    return s == BookingStatus.pendingOtp ||
        s == BookingStatus.otpVerified ||
        s == BookingStatus.pendingPayment ||
        s == BookingStatus.paid ||
        s == BookingStatus.awaitingAssignment ||
        s == BookingStatus.assigned ||
        s == BookingStatus.confirmed;
  }

  bool get _isCompleted {
    final s = _bookingStatus?.toUpperCase();
    return s == 'COMPLETED' || s == 'REVIEWED';
  }

  bool get _shouldPoll {
    if (_isAssigned) return false;
    if (_needsOtp) return false; // BE assigns only after OTP confirm
    final s = _bookingStatus?.toUpperCase();
    return s == null ||
        s == 'CONFIRMED' ||
        s == 'PAID' ||
        s == 'PENDING' ||
        s == 'AWAITING_ASSIGNMENT';
  }

  /// Re-fetch this booking from the API and update state.
  Future<void> _refreshBooking() async {
    final bookingId = int.tryParse(_bookingId);
    if (bookingId == null) return;

    if (!_isRefreshing) {
      setState(() {
        _isRefreshing = true;
        _refreshError = null;
      });
    }
    try {
      // Through the repository, not ServanaApiClient.
      //
      // The repository is the seam that chooses between the canonical
      // `/api/v1/bookings/:id` transport and the legacy one, and returns the
      // same `CustomerBooking` either way. It was built, registered and never
      // resolved — this screen kept calling `getBooking` and re-deriving every
      // field from the raw map, so `V1Capability.bookingReads` was inert no
      // matter how it was configured: the object that reads the flag had no
      // callers.
      //
      // Every fallback chain this used to run inline now lives in
      // `CustomerBooking.fromApiMap`, which is where both transports share it.
      // They were moved rather than dropped, and
      // `test/bookings/customer_booking_fidelity_test.dart` pins each one —
      // the amount that falls back to finalPrice/quotedPrice, the service
      // OPTION name winning over its parent, branchName as the place, and the
      // three-source status reconciliation.
      final booking =
          await dpLocator<BookingRepository>().getBookingById(_bookingId);

      final paymentStatus = booking.paymentStatus;
      final status = booking.effectiveWireStatus;
      final workerUid = booking.workerUid;
      final eta = booking.etaMinutes;
      final assignedAt = booking.assignedAt;
      final workerCode = booking.workerCode;
      final paymentMethod = (booking.paymentMethod ?? '').toUpperCase();

      // `scheduledAt` on the model substitutes `now` when the backend sends
      // nothing parseable. That substitution is fine for RENDERING and wrong
      // for `expectedSchedule`: sending a fabricated instant as "the schedule
      // I last read" would refuse every reschedule with
      // BOOKING_SCHEDULE_CHANGED. So the unresolved value is kept separately
      // and null must stay null.
      _scheduledAt = booking.hasResolvedSchedule ? booking.scheduledAt : null;

      String statusLabel;
      if (status == 'WORKER_ASSIGNED') {
        statusLabel = 'Provider Assigned';
      } else if (status == 'CONFIRMED' &&
          (workerUid == null || workerUid.isEmpty)) {
        statusLabel = paymentMethod == 'PAYMONGO' && paymentStatus != 'PAID'
            ? 'PENDING_PAYMENT'
            : 'AWAITING_ASSIGNMENT';
      } else {
        statusLabel = status;
      }

      setState(() {
        if (_booking == null) {
          // First load — project the domain model onto the render model.
          //
          // Every alias chain that used to be written out here now lives in
          // `CustomerBooking.fromApiMap`, so both transports share one reading
          // of the payload and this screen cannot drift from the bookings
          // list. `latitude`/`longitude` arrive NULL rather than 0 when
          // unknown, which is what `_nullIfZero` below already wanted.
          _booking = JobOrder(
            jobOrderID: _bookingId,
            jobOrderNumber: booking.bookingNumber,
            scheduleDate: booking.scheduledAt,
            merchantServiceName: booking.serviceName,
            merchantName: booking.serviceCategory,
            merchantServicePhoto: booking.servicePhotoUrl ?? '',
            address: booking.addressLine,
            latitude: booking.latitude ?? 0,
            longitude: booking.longitude ?? 0,
            totalAmount: booking.totalAmount,
            downPayment: booking.downPayment,
            numberOfPersonnel: booking.numberOfPersonnel,
            distanceFromOffice: 0,
            paymentType: 0,
            createdDate: booking.createdAt,
            paymentStatus: paymentStatus.isEmpty ? null : paymentStatus,
            paymentMethodUsed: paymentMethod.isEmpty ? null : paymentMethod,
            jobOrderStatusToString: statusLabel,
          );
        } else {
          // Subsequent refresh — update only the fields that change.
          _booking = _booking!.copyWith(
            paymentStatus: paymentStatus,
            jobOrderStatusToString: statusLabel,
            paymentMethodUsed: paymentMethod.isEmpty
                ? _booking!.paymentMethodUsed
                : paymentMethod,
          );
        }

        _bookingStatus = status.isEmpty ? _bookingStatus : status;
        _hasReview = status == 'REVIEWED';
        if (workerUid != null && workerUid.isNotEmpty) {
          _workerUid = workerUid;
        }
        if (eta != null) _etaMinutes = eta;
        if (assignedAt != null) _assignedAt = assignedAt;
        if (workerCode != null && workerCode.isNotEmpty) {
          _workerCode = workerCode;
        }
      });

      // First time we see an assigned provider, look up their display details.
      //
      // Keyed on the booking, not on the provider's uid: the endpoint decides
      // entitlement from a booking this customer already owns, so there is no
      // way to phrase a request about an arbitrary provider. _workerUid is still
      // the trigger — it is how we know someone has been assigned.
      final bookingIdInt = int.tryParse(_bookingId);
      if (_workerUid != null && _workerName == null && bookingIdInt != null) {
        unawaited(_loadWorkerProfile(bookingIdInt));
      }

      // Track detail view once per screen visit.
      if (!_detailViewTracked) {
        _detailViewTracked = true;
        _track(BookingDetailViewedEvent(
            bookingStatusCategory:
                (_bookingStatus ?? 'unknown').toLowerCase()));
      }

      // Also refresh the bookings list so the Bookings tab updates.
      dpLocator<HomeStore>().loadBookings();

      if (_shouldPoll) {
        _startPollingIfNeeded();
      } else {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _refreshError = 'Could not refresh. Tap ↻ to retry.');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadWorkerProfile(int bookingId) async {
    try {
      final api = dpLocator<ServanaApiClient>();
      final res = await api.getBookingProvider(bookingId);
      final w = res['worker'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;
      final first = w['firstName']?.toString() ?? '';
      final last = w['lastName']?.toString() ?? '';
      final composed = '$first $last'.trim();
      final name = composed.isNotEmpty
          ? composed
          : (w['name']?.toString() ?? w['email']?.toString() ?? 'Provider');
      final phone = w['phoneNumber']?.toString();
      if (!mounted) return;
      setState(() {
        _workerName = name;
        _workerPhone = phone == null || phone.isEmpty ? null : phone;
      });
    } catch (_) {
      // Name lookup is best-effort; UID alone is still useful in the UI.
    }
  }

  void _startPollingIfNeeded() {
    if (_pollTimer != null && _pollTimer!.isActive) return;
    if (!_shouldPoll) return;
    _pollAttempts = 0;
    _pollTimer = Timer.periodic(_pollInterval, (timer) {
      _pollAttempts++;
      if (!_shouldPoll || _pollAttempts >= _pollMaxAttempts) {
        timer.cancel();
        _pollTimer = null;
        return;
      }
      _refreshBooking();
    });
  }

  /// Navigate to the live tracking screen for this booking.
  void _openTracking() {
    context.push(
      '/bookings/$_bookingId/track',
      extra: TrackingArgs(
        bookingId: _bookingId,
        workerUid: _workerUid ?? '',
        workerName: _workerName,
        workerPhone: _workerPhone,
        serviceAddress: _booking?.address,
        // Absent coordinates must arrive as null, not 0.
        //
        // JobOrder.latitude is a non-nullable double, so this screen collapses
        // a missing value to 0 when it builds the model. TrackingRepository
        // then does `latitude ?? seedLatitude ?? 14.5995` — a deliberate
        // fallback to Manila when nothing is known. But 0.0 is not null, so it
        // wins that chain and the tracking map opens on 0°N 0°E, in the Gulf of
        // Guinea, instead of the city the booking is in.
        //
        // getBookingById cannot supply these today: user_address has no
        // lat/lon columns at all — the coordinates live in MongoDB, keyed by
        // location_id — so the field is absent from every response and this
        // path is always taken.
        //
        // Exactly (0, 0) is in the Atlantic off West Africa and cannot be a
        // Philippine service address, so treating it as "unknown" is safe.
        serviceLatitude: _nullIfZero(_booking?.latitude),
        serviceLongitude: _nullIfZero(_booking?.longitude),
      ),
    );
  }

  /// Treats a zero coordinate as unknown.
  ///
  /// Named rather than inlined so both call sites read the same and neither can
  /// drift back to passing the raw value.
  static double? _nullIfZero(double? v) => (v == null || v == 0) ? null : v;

  /// Open the booking's chat conversation via C14 MessagingStore.
  Future<void> _openMessaging() async {
    try {
      final msgStore = dpLocator<MessagingStore>();
      await msgStore.openConversation(_bookingId);
    } catch (_) {
      // If openConversation fails (e.g. first time, no conversation yet),
      // navigate anyway — BookingChatScreen creates the conversation on send.
    }
    if (mounted) context.go('/bookings/$_bookingId/messages');
  }

  /// Whether the active transport can move a booking at all.
  ///
  /// Not a state rule and deliberately not one: the state rule
  /// (`RESCHEDULABLE_STATES`) belongs to the backend, and a copy here would be
  /// the fourth client-side duplicate of a server policy in this file's
  /// vicinity. This asks only whether the endpoint is reachable.
  bool get _canReschedule =>
      !_isCompleted &&
      dpLocator<BookingLifecycleRepository>().canOfferReschedule;

  void _showRescheduleSheet() {
    BookingRescheduleSheet.show(
      context,
      bookingId: _bookingId,
      currentSchedule: _scheduledAt,
      onRescheduled: (_) => _refreshBooking(),
    );
  }

  void _showCancellationSheet() {
    // `expectedState` is deliberately NOT passed.
    //
    // The sheet accepts it and the canonical route honours it, but the only
    // state this screen holds is `_bookingStatus` — the LEGACY status string,
    // whose vocabulary includes values like CONFIRMED and PAID that are not
    // canonical states at all. Sending one would not add a concurrency guard;
    // it would manufacture a BOOKING_STATE_CONFLICT on a booking that is
    // perfectly cancellable.
    //
    // Supplying it correctly needs the canonical state on the read path, which
    // is a booking-read concern rather than an action one. Recorded in
    // docs/convergence-v1/TAB10_CERTIFICATION.md.
    BookingCancellationSheet.show(
      context,
      bookingId: _bookingId,
      onCancelled: () {
        // Refresh to surface the CANCELLED status.
        _refreshBooking();
      },
    );
  }

  Future<void> _openReviewForm() async {
    final b = _booking;
    final reviewed = await context.pushNamed<bool>(
      ReviewFormScreen.routeName,
      queryParameters: {
        'bookingId': _bookingId,
        if (b != null)
          'bookingLabel': 'Booking #$_bookingId — ${b.merchantServiceName}',
      },
    );
    if (reviewed == true && mounted) _refreshBooking();
  }

  void _openReviewDetail() {
    context.pushNamed(
      ReviewDetailScreen.routeName,
      queryParameters: {'bookingId': _bookingId},
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lightweight scaffold + spinner until the first API response arrives.
    if (_booking == null) {
      return Scaffold(
        backgroundColor: ColorPalette.primaryBackground,
        appBar: AppBar(
          title: Text(
            'Booking #$_bookingId',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: ColorPalette.primaryColorDark,
          foregroundColor: ColorPalette.primaryText,
          elevation: 0,
          actions: [
            if (_isRefreshing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
          ],
        ),
        body: _refreshError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _refreshError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.danger,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _refreshBooking,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    // Full detail view — _booking is guaranteed non-null below this point.
    final booking = _booking!;

    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Booking #${booking.jobOrderNumber}',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: ColorPalette.primaryColorDark,
        foregroundColor: ColorPalette.primaryText,
        elevation: 0,
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              onPressed: _refreshBooking,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh booking',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_refreshError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: ColorPalette.danger.withOpacity(.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: ColorPalette.danger.withOpacity(.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: ColorPalette.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _refreshError!,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 13,
                          color: ColorPalette.danger,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Dismiss error',
                      button: true,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _refreshError = null),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: ColorPalette.danger),
                      ),
                    ),
                  ],
                ),
              ),

            // QR + worker code
            QrWorkerCodeDisplay(
              bookingId: int.tryParse(_bookingId),
              workerCode: _workerCode,
              subtitle:
                  'Show this QR to your provider to start the service. They can also type the code.',
              pendingSubtitle: _needsOtp
                  ? 'Confirm your booking with the OTP below to continue.'
                  : _needsPayment
                      ? 'You can pay now while we assign a provider. Your service code will appear after assignment.'
                      : 'Your service code will appear here once a provider accepts your booking.',
            ),
            const SizedBox(height: 20),

            // Status banner
            _StatusBanner(
              booking: booking,
              needsOtp: _needsOtp,
              needsPayment: _needsPayment,
              status: _bookingStatus,
            ),

            const SizedBox(height: 16),
            CompactBookingLifecycle(
              status: BookingStatusMapper.fromString(_bookingStatus),
              isAssigned: _isAssigned,
            ),

            const SizedBox(height: 20),

            // Service info
            _Section(title: 'Service', children: [
              _InfoRow(label: 'Service', value: booking.merchantServiceName),
              _InfoRow(label: 'Brand', value: booking.merchantName),
            ]),

            const SizedBox(height: 16),

            // Technician assignment
            _AssignmentCard(
              isAssigned: _isAssigned,
              isPolling: _pollTimer?.isActive == true,
              workerName: _workerName,
              workerPhone: _workerPhone,
              etaMinutes: _etaMinutes,
              assignedAt: _assignedAt,
              needsPayment: _needsPayment,
            ),

            const SizedBox(height: 16),

            // Schedule & Location
            _Section(title: 'Schedule & Location', children: [
              _InfoRow(
                label: 'Date',
                value: DateFormat('EEEE, MMMM d, yyyy')
                    .format(booking.scheduleDate),
              ),
              _InfoRow(
                label: 'Time',
                value: DateFormat('h:mm a').format(booking.scheduleDate),
              ),
              if (booking.address.isNotEmpty)
                _InfoRow(label: 'Address', value: booking.address),
            ]),

            const SizedBox(height: 16),

            // Payment info
            _Section(title: 'Payment', children: [
              _InfoRow(
                label: _isCompleted ? 'Final Total' : 'Estimated Total',
                value: '₱${booking.totalAmount.toStringAsFixed(2)}',
                valueColor: ColorPalette.primaryColorDark,
              ),
              _InfoRow(
                label: 'Method',
                value: _paymentMethodLabel(booking),
              ),
              _InfoRow(
                label: 'Status',
                value: _paymentStatusLabel(booking),
                valueColor: _needsPayment ? Colors.orange : Colors.green,
              ),
            ]),

            // Change orders the provider raised on this booking. Sits under
            // Payment because that is what it is about, and draws nothing at
            // all when there are none — which is almost every booking.
            ListenableBuilder(
              listenable: _experiences,
              builder: (context, _) =>
                  ChangeOrdersSection(state: _experiences.state),
            ),

            const SizedBox(height: 16),

            // Booking meta
            _Section(title: 'Details', children: [
              _InfoRow(label: 'Booking ID', value: _bookingId),
              _InfoRow(label: 'Reference', value: booking.jobOrderNumber),
              _InfoRow(
                label: 'Created',
                value: DateFormat('MMM d, yyyy · h:mm a')
                    .format(booking.createdDate),
              ),
              _InfoRow(
                label: 'Booking Status',
                value: booking.jobOrderStatusToString,
              ),
            ]),

            const SizedBox(height: 24),

            // Confirm OTP
            if (_needsOtp)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _confirmBookingOtp,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(
                    'Confirm OTP',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColorDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

            // Continue Payment — only after OTP is confirmed.
            if (_needsPayment && !_needsOtp)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _continuePayment,
                  icon: const Icon(Icons.payment_rounded),
                  label: Text(
                    'Continue Payment',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

            // Track Provider — available when booking is active (enRoute/arrived/inProgress).
            if (_isTrackable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openTracking,
                  icon: const Icon(Icons.location_on_rounded),
                  label: Text(
                    'Track Provider',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColorDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],

            // Message Provider — available once a technician is assigned.
            if (_isAssigned) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openMessaging,
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(
                    'Message Provider',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalette.primaryColorDark,
                    side: BorderSide(
                        color: ColorPalette.primaryColorDark.withOpacity(.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],

            // Reschedule — offered only when the active transport HAS the
            // endpoint, which is never in a shipped build.
            //
            // The gate is the transport's own answer, not a state check. The
            // only reschedule route that has ever existed is admin-only and
            // answers a customer token with 403, so a button drawn from a
            // status rule would be a feature the app appears to have and does
            // not. Whether THIS booking may be moved is then the backend's
            // decision, and it names the rule that refused.
            if (_canReschedule) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showRescheduleSheet,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Reschedule'),
                ),
              ),
            ],

            // Cancel Booking — only for pre-service states.
            if (_isCancellable) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _showCancellationSheet,
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],

            // Leave a Review — available after completion, one per booking.
            if (_isCompleted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _hasReview
                    ? OutlinedButton.icon(
                        onPressed: _openReviewDetail,
                        icon: const Icon(Icons.star_rounded),
                        label: Text(
                          'View Your Review',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _openReviewForm,
                        icon: const Icon(Icons.star_outline_rounded),
                        label: Text(
                          'Leave a Review',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel(JobOrder booking) {
    switch (booking.paymentMethodUsed) {
      case 'PAYMONGO':
        return 'Online Payment (PayMongo)';
      case 'CASH':
        return 'Cash';
      case 'GCASH':
        return 'GCash';
      default:
        return booking.paymentMethodUsed ?? 'Unknown';
    }
  }

  String _paymentStatusLabel(JobOrder booking) {
    if (_needsPayment) return 'Awaiting Payment';
    if (booking.paymentStatus == 'PAID') return 'Paid';
    if (booking.paymentMethodUsed == 'CASH') return 'Pay on Service';
    return booking.paymentStatus ?? 'Unknown';
  }

  Future<void> _confirmBookingOtp() async {
    final bookingId = int.tryParse(_bookingId);
    if (bookingId == null) return;
    final ok = await context.pushNamed<bool>(
      BookingOtpScreen.routeName,
      extra: BookingOtpArgs(
        bookingId: bookingId,
        flow: BookingOtpFlow.resume,
      ),
    );
    if (ok == true && mounted) await _refreshBooking();
  }

  Future<void> _continuePayment() async {
    final bookingId = int.tryParse(_bookingId);
    if (bookingId == null) return;

    setState(() => _isRefreshing = true);
    String? checkoutUrl;
    String? errorMsg;
    try {
      // The fourth copy of this call, and the one that was subtly wrong: it
      // read `data ?? res` for the envelope but only ever looked at the root
      // for the URL, so a response shape both booking stores handled would have
      // produced "Payment session could not be started" here. One ceremony now.
      final intent =
          await dpLocator<PaymentsRepository>().startCheckout('$bookingId');
      checkoutUrl = intent.isUsable ? intent.checkoutUrl : null;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        errorMsg = 'Payment session could not be started. Please retry.';
      }
    } catch (e) {
      errorMsg = 'Could not create payment session. Please try again.';
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }

    if (!mounted) return;
    if (errorMsg != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
      return;
    }

    await context.pushNamed<bool>(
      PaymentWebViewScreen.routeName,
      extra: PaymentScreenArgs(bookingId: bookingId, checkoutUrl: checkoutUrl!),
    );
    if (mounted) await _refreshBooking();
  }
}

/// The headline state of a booking.
///
/// This used to decide what to say from `paymentStatus` and whether the
/// scheduled time was in the future, and never looked at the booking's actual
/// status at all. Every combination it did not recognise fell through to a
/// final `else` that rendered a green tick and "Your booking has been
/// confirmed."
///
/// A cash booking still waiting for a technician hits exactly that path — not
/// paid, nothing to pay, schedule already passed — so the screen showed
/// "Confirmed" in green directly above a card reading "Pending / Awaiting
/// technician". The two disagreed because only one of them was reading the
/// status.
///
/// `BookingStatusMapper` already carries a customer-facing label and subtitle
/// for all 22 states. The fix is to use it, and to make the fallback say it
/// does not know rather than inventing the most reassuring answer available.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.booking,
    required this.needsOtp,
    required this.needsPayment,
    required this.status,
  });
  final JobOrder booking;
  final bool needsOtp;
  final bool needsPayment;

  /// Raw wire status, e.g. `PENDING`, `WORKER_ASSIGNED`. Null until first load.
  final String? status;

  @override
  Widget build(BuildContext context) {
    final isPaid = booking.paymentStatus == 'PAID';
    final isUpcoming = booking.scheduleDate.isAfter(DateTime.now());
    final s = BookingStatusMapper.fromString(status);

    Color color;
    IconData icon;
    String text;
    String subtitle;

    // OTP and payment stay ahead of the status: both are things the customer
    // must DO, and an actionable prompt outranks a description of state.
    if (needsOtp) {
      color = ColorPalette.primaryColorDark;
      icon = Icons.verified_user_outlined;
      text = 'Awaiting Verification';
      subtitle = 'Confirm the OTP to activate this booking.';
    } else if (needsPayment) {
      color = Colors.orange;
      icon = Icons.payment_rounded;
      text = 'Payment Required';
      subtitle = 'Complete your payment to confirm this booking.';
    } else if (s == BookingStatus.unknown) {
      // Deliberately neutral. An unrecognised status means the app and the
      // backend disagree about the vocabulary, and the one thing that must not
      // happen is telling the customer their booking is fine because we could
      // not read it. Grey, and honest.
      color = ColorPalette.accentText;
      icon = Icons.help_outline_rounded;
      text = 'Status Unavailable';
      subtitle = 'Pull down to refresh, or contact support if this persists.';
    } else {
      text = BookingStatusMapper.customerLabel(s);
      subtitle = BookingStatusMapper.heroSubtitle(s);

      switch (BookingStatusMapper.groupCategory(s)) {
        case 'needsAttention':
          color = Colors.orange;
          icon = Icons.error_outline_rounded;
          break;
        case 'active':
          color = ColorPalette.primaryColorDark;
          icon = Icons.directions_run_rounded;
          break;
        case 'completed':
          color = Colors.green;
          icon = Icons.check_circle_rounded;
          break;
        case 'cancelled':
          color = ColorPalette.danger;
          icon = Icons.cancel_outlined;
          break;
        case 'upcoming':
        default:
          color = ColorPalette.primaryColorDark;
          icon = Icons.schedule_rounded;
          break;
      }

      // Keep the two details the generic copy cannot know: the date of an
      // upcoming paid booking, and that payment has landed.
      if (isPaid && isUpcoming && s == BookingStatus.confirmed) {
        subtitle =
            'Your booking is confirmed for ${DateFormat('MMM d').format(booking.scheduleDate)}.';
      } else if (isPaid && s == BookingStatus.paid) {
        subtitle = 'Payment has been received.';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.isAssigned,
    required this.isPolling,
    required this.workerName,
    required this.workerPhone,
    required this.etaMinutes,
    required this.assignedAt,
    required this.needsPayment,
  });

  final bool isAssigned;
  final bool isPolling;
  final String? workerName;
  final String? workerPhone;
  final int? etaMinutes;
  final DateTime? assignedAt;
  final bool needsPayment;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    if (isAssigned) {
      color = ColorPalette.primaryColorDark;
      icon = Icons.person_pin_rounded;
      title = workerName ?? 'Provider assigned';
      final parts = <String>[];
      if (workerPhone != null) parts.add(workerPhone!);
      if (etaMinutes != null) parts.add('ETA $etaMinutes min');
      if (assignedAt != null) {
        parts.add('Assigned ${DateFormat('h:mm a').format(assignedAt!)}');
      }
      subtitle =
          parts.isEmpty ? 'On the way to your service.' : parts.join(' • ');
    } else if (isPolling) {
      color = Colors.blueGrey;
      icon = Icons.search_rounded;
      title = 'Assigning a provider';
      subtitle = needsPayment
          ? 'You can pay with PayMongo now while assignment is in progress.'
          : 'A provider will be assigned to your booking soon.';
    } else {
      color = Colors.blueGrey;
      icon = Icons.hourglass_empty_rounded;
      title = 'Awaiting provider assignment';
      subtitle = needsPayment
          ? 'You can pay with PayMongo now; assignment does not need to finish first.'
          : 'Pull-to-refresh or tap the refresh icon to check again.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPolling && !isAssigned)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
            )
          else
            Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorPalette.border(.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: ColorPalette.accentText,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  /// Shown when there is no value.
  ///
  /// An empty string rendered as a zero-width Text, so the row collapsed to its
  /// label alone. On the booking detail screen that produced a "Service"
  /// heading followed by the bare words "Service" and "Brand" with nothing
  /// beside them, which reads as a broken screen rather than as missing data.
  /// An em dash says "we don't have this" in a way a blank never can.
  static const String _absent = '—';

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? _absent : value;
    final labelStyle = TextStyle(
      fontFamily: FontPalette.primaryFontFamily,
      color: ColorPalette.accentText,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    final valueStyle = TextStyle(
      fontFamily: FontPalette.primaryFontFamily,
      color: valueColor ?? ColorPalette.secondaryText,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );

    if (ServanaResponsive.useStackedDetailRow(context)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 2),
            Text(display, style: valueStyle),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: labelStyle),
          ),
          Expanded(child: Text(display, style: valueStyle)),
        ],
      ),
    );
  }
}
