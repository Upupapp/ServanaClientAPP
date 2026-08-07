import 'package:client/common/domain/address/address_display.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/payment_webview_screen.dart';
import 'package:client/common/presentation/widgets/confirm_assignment_banner.dart';
import 'package:client/common/presentation/widgets/booking_ux_components.dart';
import 'package:client/common/presentation/widgets/qr_worker_code_display.dart';
import 'package:client/common/services/assignment_polling_service.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
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

  final _poller = AssignmentPollingService();
  AssignmentPollResult? _lastPollResult;
  bool _pollTimedOut = false;

  bool get _isAssigned => _lastPollResult?.isAssigned == true;

  @override
  void initState() {
    super.initState();
    if (store.paymentMethod == 'PAYMONGO') {
      store.createPaymongoSession();
    }
    if (store.createdBookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startPolling());
    }
  }

  @override
  void dispose() {
    _poller.dispose();
    super.dispose();
  }

  void _startPolling() {
    final bookingId = store.createdBookingId;
    if (bookingId == null) return;
    _poller.start(
      bookingId: bookingId,
      onUpdate: (result) {
        if (mounted) setState(() => _lastPollResult = result);
      },
      onTimeout: () {
        if (mounted) setState(() => _pollTimedOut = true);
      },
    );
  }

  Future<void> _openPaymongo() async {
    final bookingId = store.createdBookingId;
    if (bookingId == null || store.paymongoCheckoutUrl == null) return;
    final paid = await context.pushNamed<bool>(
      PaymentWebViewScreen.routeName,
      extra: PaymentScreenArgs(
        bookingId: bookingId,
        checkoutUrl: store.paymongoCheckoutUrl!,
      ),
    );
    if (!mounted) return;
    if (paid == true) {
      setState(() => _paymongoCompleted = true);
      dpLocator<HomeStore>().loadBookings();
      _startPolling();
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
                  const BookingStageHeader(
                    current: 3,
                    total: 3,
                    label: 'Booking created',
                  ),
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
                    'Booking Created',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your booking was created successfully. Awaiting an assigned worker.',
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
                  const SizedBox(height: 20),
                  QrWorkerCodeDisplay(
                    bookingId: store.createdBookingId,
                    workerCode: store.workerCode,
                  ),
                  const SizedBox(height: 24),
                  _DetailCard(children: [
                    _DetailRow(
                      label: 'Service',
                      value: _optionName(),
                    ),
                    _DetailRow(
                      label: 'Estimated Total',
                      value: '₱${store.quotedTotal.toStringAsFixed(2)}',
                      valueColor: ColorPalette.primaryColorDark,
                    ),
                    _DetailRow(
                      label: 'Payment',
                      value: isPaymongo
                          ? 'PayMongo — available now'
                          : 'Cash — pay provider after service',
                    ),
                    if (store.selectedAddress != null)
                      _DetailRow(
                        label: 'Address',
                        value: formatAddressLine(
                          store.selectedAddress!['addressOne']?.toString(),
                          store.selectedAddress!['postTown']?.toString(),
                        ),
                      ),
                    if (store.selectedSchedule != null)
                      _DetailRow(
                        label: 'Schedule',
                        value: _formatSchedule(store.selectedSchedule!),
                      ),
                    if (store.selectedHpKey != null)
                      _DetailRow(label: 'HP', value: store.selectedHpKey!),
                  ]),
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
                          if (store.isPaymentLoading &&
                              store.paymongoCheckoutUrl == null)
                            const Center(child: CircularProgressIndicator())
                          else if (store.paymongoCheckoutUrl != null)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      ColorPalette.primaryColorDark,
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
                  if (store.createdBookingId != null) ...[
                    const SizedBox(height: 16),
                    ConfirmAssignmentBanner(
                      isAssigned: _isAssigned,
                      isPolling: _poller.isPolling,
                      timedOut: _pollTimedOut,
                      workerName: _lastPollResult?.workerName,
                      bookingStatus: _lastPollResult != null
                          ? BookingStatusMapper.confirmationTitle(
                              _lastPollResult!.status)
                          : null,
                    ),
                  ],
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
                        dpLocator<HomeStore>()
                            .addBooking(store.buildCreatedJobOrder());
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
    if (opt == null) return 'Aircon Service';
    return (opt['level_3'] ??
            opt['name'] ??
            opt['optionName'] ??
            'Aircon Service')
        .toString();
  }

  String _formatSchedule(DateTime dt) {
    const months = [
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
