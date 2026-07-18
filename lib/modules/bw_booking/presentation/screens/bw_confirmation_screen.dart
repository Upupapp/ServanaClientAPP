import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/confirm_assignment_banner.dart';
import 'package:client/common/presentation/widgets/qr_worker_code_display.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_paymongo_screen.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Step 4: Booking confirmed — shows confirmation, payment follow-up.
class BwConfirmationScreen extends StatefulWidget {
  static const String routeName = 'BwConfirmation';
  static const String route = 'BwConfirmation';

  const BwConfirmationScreen({super.key});

  @override
  State<BwConfirmationScreen> createState() => _BwConfirmationScreenState();
}

class _BwConfirmationScreenState extends State<BwConfirmationScreen> {
  final store = dpLocator<BwBookingStore>();
  bool _paymongoCompleted = false;

  // Live BE auto-assignment surfaced on the confirmation screen so the user
  // can watch the worker land before navigating away.
  String? _workerUid;
  String? _workerName;
  String? _bookingStatus;
  Timer? _assignPollTimer;
  static const _assignPollInterval = Duration(seconds: 5);
  static const _assignPollMaxAttempts = 12;
  int _assignPollAttempts = 0;

  bool get _isAssigned => _workerUid != null && _workerUid!.isNotEmpty;
  bool get _canPollAssignment {
    if (_isAssigned) return false;
    if (store.createdBookingId == null) return false;
    // PAYMONGO bookings only auto-assign post-payment.
    if (store.paymentMethod == 'PAYMONGO' && !_paymongoCompleted) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (store.paymentMethod == 'PAYMONGO') {
      store.createPaymongoSession();
    } else if (store.createdBookingId != null) {
      // CASH bookings can be auto-assigned immediately after creation — start
      // watching as soon as the screen opens.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAssignmentPolling();
      });
    }
  }

  @override
  void dispose() {
    _assignPollTimer?.cancel();
    super.dispose();
  }

  void _startAssignmentPolling() {
    if (!_canPollAssignment) return;
    if (_assignPollTimer != null && _assignPollTimer!.isActive) return;
    _assignPollAttempts = 0;
    // Kick once immediately so the user doesn't wait for the first interval.
    _pollAssignmentOnce();
    _assignPollTimer = Timer.periodic(_assignPollInterval, (timer) {
      _assignPollAttempts++;
      if (!_canPollAssignment || _assignPollAttempts >= _assignPollMaxAttempts) {
        timer.cancel();
        _assignPollTimer = null;
        return;
      }
      _pollAssignmentOnce();
    });
  }

  Future<void> _pollAssignmentOnce() async {
    final id = store.createdBookingId;
    if (id == null) return;
    try {
      final api = dpLocator<ServanaApiClient>();
      final res = await api.getBooking(id);
      final b = res['booking'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;
      final status = (b['status'] ?? '').toString().toUpperCase();
      final workerUid = b['workerUid']?.toString();
      if (!mounted) return;
      setState(() {
        _bookingStatus = status.isEmpty ? _bookingStatus : status;
        if (workerUid != null && workerUid.isNotEmpty) _workerUid = workerUid;
      });
      if (_workerUid != null && _workerName == null) {
        unawaited(_loadWorkerName(_workerUid!));
      }
    } catch (_) {
      // Silent — keep polling until attempts are exhausted.
    }
  }

  Future<void> _loadWorkerName(String uid) async {
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
      if (!mounted) return;
      setState(() => _workerName = name);
    } catch (_) {
      // Best effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ColorPalette.primaryBackground,
        body: SafeArea(
          child: Observer(builder: (context) {
          final isPaymongo = store.paymentMethod == 'PAYMONGO';

          final isPendingPayment = isPaymongo && !_paymongoCompleted;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isPendingPayment
                        ? Colors.orange.withOpacity(.12)
                        : ColorPalette.primaryColorDark.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPendingPayment
                        ? Icons.payment_rounded
                        : Icons.check_circle_rounded,
                    size: 48,
                    color: isPendingPayment
                        ? Colors.orange
                        : ColorPalette.primaryColorDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isPendingPayment
                      ? 'Payment Required'
                      : 'Booking Confirmed!',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPendingPayment
                      ? 'Your booking has been created but requires payment to be confirmed.'
                      : 'Your beauty & wellness service has been booked successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText,
                  ),
                ),
                if (store.createdBookingId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Booking #${store.createdBookingId}',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.primaryColorDark,
                      fontSize: 16,
                    ),
                  ),
                ],

                // QR + worker code — surfaced immediately so the customer can
                // show it to the technician on arrival without scrolling past
                // details. Fresh bookings have no worker code yet (the BE
                // populates it only after a technician accepts), so the card
                // renders its pending placeholder until that happens.
                const SizedBox(height: 20),
                QrWorkerCodeDisplay(
                  bookingId: store.createdBookingId,
                  workerCode: store.workerCode,
                ),

                const SizedBox(height: 24),

                // Booking details card
                _DetailCard(children: [
                  _DetailRow(
                    label: 'Service',
                    value: _optionName(),
                  ),
                  if (store.selectedBranch != null)
                    _DetailRow(
                      label: 'Branch',
                      value: _branchName(),
                    ),
                  if (store.selectedDate != null &&
                      store.selectedSlot != null)
                    _DetailRow(
                      label: 'Schedule',
                      value:
                          '${DateFormat('EEE, MMM d yyyy').format(store.selectedDate!)} • ${_slotTime()}',
                    ),
                  _DetailRow(
                    label: 'Amount',
                    value: '₱${store.estimatedTotal.toStringAsFixed(2)}',
                    valueColor: ColorPalette.primaryColorDark,
                  ),
                  _DetailRow(
                    label: 'Payment',
                    value: store.paymentMethod == 'PAYMONGO'
                        ? 'Online Payment'
                        : 'Cash',
                  ),
                  if (store.selectedAddress != null)
                    _DetailRow(
                      label: 'Address',
                      value:
                          '${store.selectedAddress!['addressOne'] ?? ''}, ${store.selectedAddress!['postTown'] ?? ''}',
                    ),
                  if (store.selectedAddonIds.isNotEmpty)
                    _DetailRow(
                      label: 'Add-ons',
                      value: '${store.selectedAddonIds.length} selected',
                    ),
                ]),

                // PayMongo section
                if (isPaymongo && !_paymongoCompleted) ...[
                  const SizedBox(height: 24),
                  Container(
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
                          'Complete Payment',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: ColorPalette.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You will be redirected to PayMongo to complete your payment securely.',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            color: ColorPalette.accentText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (store.isLoading &&
                            store.paymongoCheckoutUrl == null)
                          const Center(child: CircularProgressIndicator())
                        else if (store.paymongoCheckoutUrl != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorPalette.primaryColorDark,
                                foregroundColor: ColorPalette.primaryText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _openPaymongo,
                              icon: const Icon(Icons.credit_card_rounded),
                              label: const Text('Pay with PayMongo'),
                            ),
                          )
                        else if (store.errorMessage != null)
                          Column(
                            children: [
                              Text(
                                store.errorMessage!,
                                style: TextStyle(
                                  color: ColorPalette.danger,
                                  fontFamily: FontPalette.primaryFontFamily,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    store.createPaymongoSession(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],

                if (isPaymongo && _paymongoCompleted) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryColorDark.withOpacity(.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: ColorPalette.primaryColorDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Payment submitted. You will be notified when confirmed.',
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.primaryColorDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Auto-assignment status — visible whenever a booking ID exists
                // and assignment is in flight or done. Hidden while a PAYMONGO
                // payment is still pending since assignment can't start yet.
                if (store.createdBookingId != null &&
                    (!isPaymongo || _paymongoCompleted)) ...[
                  const SizedBox(height: 16),
                  ConfirmAssignmentBanner(
                    isAssigned: _isAssigned,
                    isPolling: _assignPollTimer?.isActive == true,
                    workerName: _workerName,
                    bookingStatus: _bookingStatus,
                  ),
                ],

                if (store.errorMessage != null &&
                    !isPaymongo)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      store.errorMessage!,
                      style: TextStyle(
                        color: ColorPalette.danger,
                        fontFamily: FontPalette.primaryFontFamily,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                      foregroundColor: ColorPalette.primaryButtonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      _pushBookingToHomeStore();
                      context.goNamed(HomeScreen.routeName);
                    },
                    child: Text(
                      isPendingPayment
                          ? 'Pay Later & Go Home'
                          : 'Back to Home',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
          }),
        ),
      ),
    );
  }

  String _optionName() {
    final opt = store.selectedOption;
    if (opt == null) return 'Beauty & Wellness Service';
    return (opt['level_3'] ?? opt['name'] ?? opt['optionName'] ?? 'Beauty & Wellness Service')
        .toString();
  }

  String _branchName() {
    final b = store.selectedBranch;
    if (b == null) return '';
    return (b['branchName'] ?? b['name'] ?? '').toString();
  }

  String _slotTime() {
    final slot = store.selectedSlot;
    if (slot == null) return '';
    final slotTime = slot['slotTime']?.toString() ?? '';
    final parts = slotTime.split(':');
    if (parts.length < 2) return slotTime;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  void _pushBookingToHomeStore() {
    dpLocator<HomeStore>().addBooking(store.buildCreatedJobOrder());
  }

  Future<void> _openPaymongo() async {
    if (store.paymongoCheckoutUrl == null) return;
    await context.pushNamed<bool>(
      BwPaymongoScreen.routeName,
      extra: PaymongoCheckoutArgs(
        checkoutUrl: store.paymongoCheckoutUrl!,
        verifyPaymentStatus: store.verifyPaymentStatus,
      ),
    );
    if (mounted) {
      // Refresh booking status regardless of result
      final paid = await store.verifyPaymentStatus();
      if (paid && mounted) {
        setState(() => _paymongoCompleted = true);
        // Refresh bookings list so Bookings tab shows updated status
        dpLocator<HomeStore>().loadBookings();
        // Now that payment is in, BE auto-assignment can start — watch for it.
        _startAssignmentPolling();
      }
    }
  }

}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.shadow(.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.accentText,
                fontWeight: FontWeight.w600,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

