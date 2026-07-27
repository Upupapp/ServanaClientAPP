import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/responsive/servana_responsive.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/presentation/screens/booking_otp_screen.dart';
import 'package:client/common/presentation/screens/payment_webview_screen.dart';
import 'package:client/common/presentation/widgets/qr_worker_code_display.dart';
import 'package:client/modules/bookings/presentation/widgets/booking_cancellation_sheet.dart';
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

  // Poll for worker assignment for up to ~60s after the screen opens, while
  // the booking is still in a pre-assignment state. Stops as soon as a
  // workerUid lands.
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 5);
  static const _pollMaxAttempts = 12;
  int _pollAttempts = 0;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    // Always pull fresh state on open — no JobOrder is passed in anymore;
    // everything comes from the API.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBooking();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool get _needsPayment =>
      _booking?.paymentStatus == 'PENDING' &&
      _booking?.paymentMethodUsed == 'PAYMONGO';

  /// A freshly-created booking sits in PENDING_OTP (or FOR_OTP alias) until the
  /// customer verifies the code; the BE assigns a technician only after that.
  bool get _needsOtp => BookingStatusMapper.requiresOtp(
      BookingStatusMapper.fromString(_bookingStatus));

  bool get _isAssigned => _workerUid != null && _workerUid!.isNotEmpty;

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

  bool get _shouldPoll {
    if (_isAssigned) return false;
    if (_needsPayment) return false; // assignment only happens after payment
    if (_needsOtp) return false; // BE assigns only after OTP confirm
    final s = _bookingStatus?.toUpperCase();
    return s == null || s == 'CONFIRMED' || s == 'PAID' || s == 'PENDING';
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
      final api = dpLocator<ServanaApiClient>();
      final res = await api.getBooking(bookingId);
      final b = res['booking'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;

      final paymentStatus = (b['paymentStatus'] ?? '').toString().toUpperCase();
      final status = (b['status'] ?? '').toString().toUpperCase();
      final workerUid =
          b['workerUid']?.toString() ?? b['providerUid']?.toString();
      final eta = b['etaMinutes'];
      final assignedAtRaw = b['assignedAt']?.toString();
      final workerCode = b['workerCode']?.toString();
      final paymentMethod = (b['paymentMethod'] ?? b['paymentMethodUsed'] ?? '')
          .toString()
          .toUpperCase();

      // Parse scheduled datetime from any of the backend's canonical aliases.
      final scheduleRaw = b['scheduledAt']?.toString() ??
          b['scheduleAt']?.toString() ??
          b['schedule']?.toString();
      final scheduleDate =
          scheduleRaw != null ? DateTime.tryParse(scheduleRaw) : null;

      String statusLabel;
      if (status == 'WORKER_ASSIGNED') {
        statusLabel = 'Worker Assigned';
      } else if (paymentStatus == 'PAID') {
        statusLabel = 'Paid';
      } else if (status == 'CONFIRMED' && paymentStatus == 'PENDING') {
        statusLabel = 'Payment Required';
      } else {
        statusLabel = b['statusLower']?.toString() ?? status;
      }

      setState(() {
        if (_booking == null) {
          // First load — construct JobOrder from API map.
          final now = DateTime.now();
          final createdAtRaw = b['createdAt']?.toString();
          _booking = JobOrder(
            jobOrderID: _bookingId,
            jobOrderNumber: b['bookingCode']?.toString() ??
                b['bookingNumber']?.toString() ??
                _bookingId,
            scheduleDate: scheduleDate ?? now,
            merchantServiceName: b['serviceName']?.toString() ??
                (b['service'] is Map
                    ? (b['service'] as Map)['name']?.toString()
                    : null) ??
                '',
            merchantName: b['merchantName']?.toString() ??
                b['providerName']?.toString() ??
                '',
            merchantServicePhoto: b['servicePhotoUrl']?.toString() ??
                b['servicePhoto']?.toString() ??
                '',
            address:
                b['addressLine']?.toString() ?? b['address']?.toString() ?? '',
            latitude: (b['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (b['longitude'] as num?)?.toDouble() ?? 0,
            totalAmount: (b['totalAmount'] as num?)?.toDouble() ?? 0,
            downPayment: (b['downPayment'] as num?)?.toDouble() ?? 0,
            numberOfPersonnel: (b['numberOfPersonnel'] as num?)?.toInt() ?? 0,
            distanceFromOffice: 0,
            paymentType: 0,
            createdDate: createdAtRaw != null
                ? (DateTime.tryParse(createdAtRaw) ?? now)
                : now,
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
        if (workerUid != null && workerUid.isNotEmpty) {
          _workerUid = workerUid;
        }
        if (eta is num) _etaMinutes = eta.toInt();
        if (assignedAtRaw != null && assignedAtRaw.isNotEmpty) {
          _assignedAt = DateTime.tryParse(assignedAtRaw);
        }
        if (workerCode != null && workerCode.isNotEmpty) {
          _workerCode = workerCode;
        }
      });

      // First time we see a workerUid, look up the technician's name.
      if (_workerUid != null && _workerName == null) {
        unawaited(_loadWorkerProfile(_workerUid!));
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

  Future<void> _loadWorkerProfile(String uid) async {
    try {
      final api = dpLocator<ServanaApiClient>();
      final res = await api.getWorkerByUid(uid);
      final w = res['worker'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;
      final first = w['firstName']?.toString() ?? '';
      final last = w['lastName']?.toString() ?? '';
      final composed = '$first $last'.trim();
      final name = composed.isNotEmpty
          ? composed
          : (w['name']?.toString() ?? w['email']?.toString() ?? 'Technician');
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

  void _showCancellationSheet() {
    BookingCancellationSheet.show(
      context,
      bookingId: _bookingId,
      onCancelled: () {
        // Refresh to surface the CANCELLED status.
        _refreshBooking();
      },
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
                    GestureDetector(
                      onTap: () => setState(() => _refreshError = null),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: ColorPalette.danger),
                    ),
                  ],
                ),
              ),

            // QR + worker code
            QrWorkerCodeDisplay(
              bookingId: int.tryParse(_bookingId),
              workerCode: _workerCode,
              subtitle:
                  'Show this QR to your technician to start the service. They can also type the code.',
              pendingSubtitle: _needsOtp
                  ? 'Confirm your booking with the OTP below to continue.'
                  : _needsPayment
                      ? 'Complete your payment first. Once paid and a technician accepts, your worker code will appear here.'
                      : 'Your worker code will appear here once a technician accepts your booking.',
            ),
            const SizedBox(height: 20),

            // Status banner
            _StatusBanner(
              booking: booking,
              needsOtp: _needsOtp,
              needsPayment: _needsPayment,
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
                label: 'Amount',
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
      final api = dpLocator<ServanaApiClient>();
      final res = await api.createPaymongoSession(bookingId: bookingId);
      final data = res['data'] ?? res;
      checkoutUrl =
          data['checkoutUrl']?.toString() ?? data['checkout_url']?.toString();
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.booking,
    required this.needsOtp,
    required this.needsPayment,
  });
  final JobOrder booking;
  final bool needsOtp;
  final bool needsPayment;

  @override
  Widget build(BuildContext context) {
    final isPaid = booking.paymentStatus == 'PAID';
    final isUpcoming = booking.scheduleDate.isAfter(DateTime.now());

    Color color;
    IconData icon;
    String text;
    String subtitle;

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
    } else if (isPaid && isUpcoming) {
      color = ColorPalette.primaryColorDark;
      icon = Icons.schedule_rounded;
      text = 'Upcoming';
      subtitle =
          'Your booking is confirmed for ${DateFormat('MMM d').format(booking.scheduleDate)}.';
    } else if (isPaid) {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
      text = 'Paid';
      subtitle = 'Payment has been received.';
    } else {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
      text = 'Confirmed';
      subtitle = 'Your booking has been confirmed.';
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

    if (needsPayment) {
      color = Colors.orange;
      icon = Icons.payment_rounded;
      title = 'Awaiting payment';
      subtitle = 'A technician will be assigned once payment is received.';
    } else if (isAssigned) {
      color = ColorPalette.primaryColorDark;
      icon = Icons.person_pin_rounded;
      title = workerName ?? 'Technician assigned';
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
      title = 'Assigning a technician';
      subtitle = 'A technician will be assigned to your booking soon.';
    } else {
      color = Colors.blueGrey;
      icon = Icons.hourglass_empty_rounded;
      title = 'Awaiting technician assignment';
      subtitle = 'Pull-to-refresh or tap the refresh icon to check again.';
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
                  'Technician',
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

  @override
  Widget build(BuildContext context) {
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
            Text(value, style: valueStyle),
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
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}
