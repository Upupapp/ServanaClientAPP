import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/confirm_assignment_banner.dart';
import 'package:client/common/presentation/widgets/qr_worker_code_display.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_paymongo_screen.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

/// Step 3: Booking confirmed — shows confirmation and, for PAYMONGO bookings,
/// the hosted-checkout launcher.
class AirconConfirmationScreen extends StatefulWidget {
  static const String routeName = 'AirconConfirmation';
  static const String route = 'AirconConfirmation';

  const AirconConfirmationScreen({super.key});

  @override
  State<AirconConfirmationScreen> createState() =>
      _AirconConfirmationScreenState();
}

class _AirconConfirmationScreenState extends State<AirconConfirmationScreen> {
  final store = dpLocator<AirconBookingStore>();
  bool _paymongoCompleted = false;

  // Live BE auto-assignment surfaced on the confirmation screen so the user
  // can watch the worker land before navigating away. Mirrors the BW screen.
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
      if (!_canPollAssignment ||
          _assignPollAttempts >= _assignPollMaxAttempts) {
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
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      body: SafeArea(
        child: Observer(builder: (context) {
          final isPaymongo = store.paymentMethod == 'PAYMONGO';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColorDark.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your aircon service has been booked successfully.',
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
                  _DetailRow(
                    label: 'Amount',
                    value: '₱${store.quotedTotal.toStringAsFixed(2)}',
                    valueColor: ColorPalette.primaryColorDark,
                  ),
                  _DetailRow(
                    label: 'Payment',
                    value: isPaymongo ? 'Online Payment' : 'Cash',
                  ),
                  if (store.selectedAddress != null)
                    _DetailRow(
                      label: 'Address',
                      value:
                          '${store.selectedAddress!['addressOne'] ?? ''}, ${store.selectedAddress!['postTown'] ?? ''}',
                    ),
                  if (store.selectedSchedule != null)
                    _DetailRow(
                      label: 'Schedule',
                      value: _formatSchedule(store.selectedSchedule!),
                    ),
                  if (store.selectedHpKey != null)
                    _DetailRow(label: 'HP', value: store.selectedHpKey!),
                ]),

                // PayMongo hosted-checkout section.
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
                                onPressed: () => store.createPaymongoSession(),
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

                if (store.errorMessage != null && !isPaymongo)
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
                      'Back to Home',
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
    );
  }

  String _optionName() {
    final opt = store.selectedOption;
    if (opt == null) return 'Aircon Service';
    return (opt['level_3'] ??
            opt['name'] ??
            opt['optionName'] ??
            'Aircon Service')
        .toString();
  }

  String _formatSchedule(DateTime dt) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day}, ${dt.year} – $hour:$min $ampm';
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
    if (!mounted) return;
    final paid = await store.verifyPaymentStatus();
    if (paid && mounted) {
      setState(() => _paymongoCompleted = true);
      // Refresh bookings list so the Bookings tab shows the updated status.
      dpLocator<HomeStore>().loadBookings();
      // Now that payment is in, BE auto-assignment can start — watch for it.
      _startAssignmentPolling();
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

