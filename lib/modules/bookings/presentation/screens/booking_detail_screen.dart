import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/booking_otp_screen.dart';
import 'package:client/common/presentation/widgets/qr_worker_code_display.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_paymongo_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  static const String routeName = 'BookingDetail';
  static const String route = '/BookingDetail';

  final JobOrder booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late JobOrder _booking;
  bool _isRefreshing = false;

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
    _booking = widget.booking;
    // Always pull fresh state on open — the JobOrder we received from the list
    // can be stale (no workerUid yet) and the user expects to see assignment.
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
      _booking.paymentStatus == 'PENDING' &&
      _booking.paymentMethodUsed == 'PAYMONGO';

  /// A freshly-created booking sits in PENDING_OTP until the customer verifies
  /// the code; the BE assigns a technician only after that succeeds.
  bool get _needsOtp => (_bookingStatus ?? '').toUpperCase() == 'PENDING_OTP';

  bool get _isAssigned => _workerUid != null && _workerUid!.isNotEmpty;

  bool get _shouldPoll {
    if (_isAssigned) return false;
    if (_needsPayment) return false; // assignment only happens after payment
    if (_needsOtp) return false; // BE assigns a technician only after OTP confirm
    final s = _bookingStatus?.toUpperCase();
    return s == null ||
        s == 'CONFIRMED' ||
        s == 'PAID' ||
        s == 'PENDING';
  }

  /// Re-fetch this booking from the API and update state.
  Future<void> _refreshBooking() async {
    final bookingId = int.tryParse(_booking.jobOrderID);
    if (bookingId == null) return;

    if (!_isRefreshing) {
      setState(() => _isRefreshing = true);
    }
    try {
      final api = dpLocator<ServanaApiClient>();
      final res = await api.getBooking(bookingId);
      final b = res['booking'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;

      final paymentStatus =
          (b['paymentStatus'] ?? '').toString().toUpperCase();
      final status = (b['status'] ?? '').toString().toUpperCase();
      final workerUid = b['workerUid']?.toString();
      final eta = b['etaMinutes'];
      final assignedAtRaw = b['assignedAt']?.toString();
      final workerCode = b['workerCode']?.toString();
      final paymentMethod = (b['paymentMethod'] ?? '').toString().toUpperCase();

      // Update local booking with fresh payment info
      String statusLabel;
      if (status == 'WORKER_ASSIGNED') {
        statusLabel = 'Worker Assigned';
      } else if (paymentStatus == 'PAID') {
        statusLabel = 'Paid';
      } else if (status == 'CONFIRMED' && paymentStatus == 'PENDING') {
        statusLabel = 'Payment Required';
      } else {
        statusLabel = _booking.jobOrderStatusToString;
      }

      setState(() {
        _booking = _booking.copyWith(
          paymentStatus: paymentStatus,
          jobOrderStatusToString: statusLabel,
          // Keep the payment method authoritative from the API so an
          // optimistically-built JobOrder (which may lack it) still triggers
          // PayMongo "Continue Payment" once the booking leaves PENDING_OTP.
          paymentMethodUsed: paymentMethod.isEmpty
              ? _booking.paymentMethodUsed
              : paymentMethod,
        );
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

      // Also refresh the bookings list so the Bookings tab updates
      dpLocator<HomeStore>().loadBookings();

      // Drive the assignment poll: start it lazily once we know we need it,
      // and cancel it as soon as we don't.
      if (_shouldPoll) {
        _startPollingIfNeeded();
      } else {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (_) {
      // Silent fail — keep existing data
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Booking #${_booking.jobOrderNumber}',
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
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
            // QR + worker code — pinned to the top: it's the artefact the
            // technician needs at job start, and the customer should see it
            // first. The BE only populates `workerCode` once a technician
            // accepts the booking, so until then the card renders a "pending"
            // placeholder. Payment-pending state is folded into the pending
            // subtitle so the customer sees one consolidated next-step.
            QrWorkerCodeDisplay(
              bookingId: int.tryParse(_booking.jobOrderID),
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
              booking: _booking,
              needsOtp: _needsOtp,
              needsPayment: _needsPayment,
            ),

            const SizedBox(height: 20),

            // Service info
            _Section(title: 'Service', children: [
              _InfoRow(label: 'Service', value: _booking.merchantServiceName),
              _InfoRow(label: 'Brand', value: _booking.merchantName),
            ]),

            const SizedBox(height: 16),

            // Technician assignment — populated when BE auto-assigns
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
                    .format(_booking.scheduleDate),
              ),
              _InfoRow(
                label: 'Time',
                value: DateFormat('h:mm a').format(_booking.scheduleDate),
              ),
              if (_booking.address.isNotEmpty)
                _InfoRow(label: 'Address', value: _booking.address),
            ]),

            const SizedBox(height: 16),

            // Payment info
            _Section(title: 'Payment', children: [
              _InfoRow(
                label: 'Amount',
                value: '₱${_booking.totalAmount.toStringAsFixed(2)}',
                valueColor: ColorPalette.primaryColorDark,
              ),
              _InfoRow(
                label: 'Method',
                value: _paymentMethodLabel(),
              ),
              _InfoRow(
                label: 'Status',
                value: _paymentStatusLabel(),
                valueColor: _needsPayment ? Colors.orange : Colors.green,
              ),
            ]),

            const SizedBox(height: 16),

            // Booking meta
            _Section(title: 'Details', children: [
              _InfoRow(label: 'Booking ID', value: _booking.jobOrderID),
              _InfoRow(label: 'Reference', value: _booking.jobOrderNumber),
              _InfoRow(
                label: 'Created',
                value: DateFormat('MMM d, yyyy · h:mm a')
                    .format(_booking.createdDate),
              ),
              _InfoRow(
                label: 'Booking Status',
                value: _booking.jobOrderStatusToString,
              ),
            ]),

            const SizedBox(height: 24),

            // Confirm OTP — a freshly-created booking stays in PENDING_OTP until
            // the customer verifies the code; the BE assigns a technician only
            // after this succeeds, so it's the clear next step.
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

            // Continue Payment button — only after OTP is confirmed (payment
            // follows OTP in the flow).
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel() {
    switch (_booking.paymentMethodUsed) {
      case 'PAYMONGO':
        return 'Online Payment (PayMongo)';
      case 'CASH':
        return 'Cash';
      case 'GCASH':
        return 'GCash';
      default:
        return _booking.paymentMethodUsed ?? 'Unknown';
    }
  }

  String _paymentStatusLabel() {
    if (_needsPayment) return 'Awaiting Payment';
    if (_booking.paymentStatus == 'PAID') return 'Paid';
    if (_booking.paymentMethodUsed == 'CASH') return 'Pay on Service';
    return _booking.paymentStatus ?? 'Unknown';
  }

  Future<void> _confirmBookingOtp() async {
    final bookingId = int.tryParse(_booking.jobOrderID);
    if (bookingId == null) return;
    final ok = await context.pushNamed<bool>(
      BookingOtpScreen.routeName,
      extra: BookingOtpArgs(
        bookingId: bookingId,
        flow: BookingOtpFlow.resume,
      ),
    );
    // On success the booking left PENDING_OTP — refresh to surface the new
    // state (assignment polling for CASH, or "Continue Payment" for PayMongo).
    if (ok == true && mounted) await _refreshBooking();
  }

  Future<void> _continuePayment() async {
    final bwStore = dpLocator<BwBookingStore>();
    final bookingId = int.tryParse(_booking.jobOrderID);
    if (bookingId == null) return;

    bwStore.createdBookingId = bookingId;
    await bwStore.createPaymongoSession();

    if (!mounted) return;
    if (bwStore.paymongoCheckoutUrl != null) {
      await context.pushNamed<bool>(
        BwPaymongoScreen.routeName,
        extra: PaymongoCheckoutArgs(
          checkoutUrl: bwStore.paymongoCheckoutUrl!,
          verifyPaymentStatus: bwStore.verifyPaymentStatus,
        ),
      );

      // After returning from PayMongo, refresh this booking
      if (mounted) await _refreshBooking();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                bwStore.errorMessage ?? 'Could not create payment session.')),
      );
    }
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
      subtitle = parts.isEmpty ? 'On the way to your service.' : parts.join(' • ');
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.accentText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: valueColor ?? ColorPalette.secondaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
