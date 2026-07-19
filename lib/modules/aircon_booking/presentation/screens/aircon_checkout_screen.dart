import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/auth/auth_return_intent.dart';
import 'package:client/common/domain/booking/booking_draft.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/address_form_screen.dart';
import 'package:client/common/presentation/screens/authentication_gate_screen.dart';
import 'package:client/common/presentation/screens/booking_otp_screen.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart';
import 'package:client/modules/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Step 2: User selects a saved address, schedule date/time, payment method,
/// then creates the booking via the Servana API.
class AirconCheckoutScreen extends StatefulWidget {
  static const String routeName = 'AirconCheckout';
  static const String route = 'AirconCheckout';

  const AirconCheckoutScreen({super.key});

  @override
  State<AirconCheckoutScreen> createState() => _AirconCheckoutScreenState();
}

class _AirconCheckoutScreenState extends State<AirconCheckoutScreen> {
  final store = dpLocator<AirconBookingStore>();

  @override
  void initState() {
    super.initState();
    store.loadSavedAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: ColorPalette.primaryColorDark,
        foregroundColor: ColorPalette.primaryText,
        elevation: 0,
      ),
      body: Observer(builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ──── Quote summary ────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColorLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'Aircon Service Quote',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _optionName(),
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${store.quotedTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                    if (store.selectedHpKey != null ||
                        store.selectedHeightKey != null ||
                        store.selectedDistanceKey != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          [
                            if (store.selectedHpKey != null)
                              store.selectedHpKey,
                            if (store.selectedHeightKey != null)
                              _labelify(store.selectedHeightKey!),
                            if (store.selectedDistanceKey != null)
                              store.selectedDistanceKey,
                          ].join(' • '),
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            color: ColorPalette.accentText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ──── Select Address ────
              _SectionHeader(
                title: 'Service Address',
                trailing: TextButton(
                  onPressed: () => store.loadSavedAddresses(),
                  child: const Text('Refresh'),
                ),
              ),
              const SizedBox(height: 8),

              if (store.isLoading && store.savedAddresses.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (store.savedAddresses.isEmpty)
                InkWell(
                  onTap: _addNewAddress,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ColorPalette.secondaryBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ColorPalette.primaryColorDark.withOpacity(.4),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.add_location_alt_rounded,
                            size: 36, color: ColorPalette.primaryColorDark),
                        const SizedBox(height: 8),
                        Text(
                          'No saved addresses yet.\nTap here to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            color: ColorPalette.primaryColorDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ...store.savedAddresses.map((addr) {
                  final addrId = addr['addressId'] ?? addr['id'] ?? '';
                  final selectedId = store.selectedAddress?['addressId'] ??
                      store.selectedAddress?['id'];
                  final isSelected = addrId == selectedId;
                  final label = addr['label'] ?? '';
                  final line1 = addr['addressOne'] ?? '';
                  final line2 = addr['postTown'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => store.selectAddress(addr),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorPalette.primaryColorDark
                              : ColorPalette.secondaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? ColorPalette.primaryColorDark
                                : ColorPalette.border(.55),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: isSelected
                                  ? ColorPalette.primaryText
                                  : ColorPalette.primaryColorDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (label.toString().isNotEmpty)
                                    Text(
                                      label.toString(),
                                      style: TextStyle(
                                        fontFamily:
                                            FontPalette.primaryFontFamily,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? ColorPalette.primaryText
                                            : ColorPalette.secondaryText,
                                      ),
                                    ),
                                  Text(
                                    '$line1, $line2',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: FontPalette.primaryFontFamily,
                                      color: isSelected
                                          ? ColorPalette.primaryText
                                              .withOpacity(.85)
                                          : ColorPalette.accentText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  color: ColorPalette.primaryText),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                // Add new address button
                InkWell(
                  onTap: _addNewAddress,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ColorPalette.primaryColorDark.withOpacity(.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 20, color: ColorPalette.primaryColorDark),
                        const SizedBox(width: 6),
                        Text(
                          'Add New Address',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.primaryColorDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ──── Schedule ────
              _SectionHeader(title: 'Schedule'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickSchedule,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ColorPalette.secondaryBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ColorPalette.border(.55)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          color: ColorPalette.primaryColorDark),
                      const SizedBox(width: 12),
                      Text(
                        store.selectedSchedule != null
                            ? DateFormat('EEE, MMM d yyyy – h:mm a')
                                .format(store.selectedSchedule!)
                            : 'Tap to select date & time',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontWeight: FontWeight.w600,
                          color: store.selectedSchedule != null
                              ? ColorPalette.secondaryText
                              : ColorPalette.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ──── Payment method ────
              _SectionHeader(title: 'Payment Method'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PaymentMethodTile(
                      icon: Icons.payments_rounded,
                      label: 'Cash',
                      selected: store.paymentMethod == 'CASH',
                      onTap: () => store.setPaymentMethod('CASH'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PaymentMethodTile(
                      icon: Icons.credit_card_rounded,
                      label: 'PayMongo',
                      selected: store.paymentMethod == 'PAYMONGO',
                      onTap: () => store.setPaymentMethod('PAYMONGO'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Error
              if (store.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    store.errorMessage!,
                    style: TextStyle(
                      color: ColorPalette.danger,
                      fontFamily: FontPalette.primaryFontFamily,
                    ),
                  ),
                ),

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
                  onPressed: store.isLoading ? null : _onConfirmBooking,
                  child: store.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
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

  String _labelify(String key) => key
      .replaceAll('_', ' ')
      .replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());

  Future<void> _addNewAddress() async {
    final result = await Navigator.of(context).push<AddressFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddressFormScreen(
          title: 'Add Address',
          actionLabel: 'Save Address',
          showGps: true,
        ),
      ),
    );
    if (!mounted || result == null) return;

    // Save the address to Servana API
    try {
      final session = await SessionService.getSession();
      final userId = session?.customerID ?? '';
      final api = dpLocator<ServanaApiClient>();

      final lat = result.location.latitude;
      final lon = result.location.longitude;
      final payload = <String, dynamic>{
        'userId': userId,
        'locationId': 'loc_${lat.toStringAsFixed(6)}_${lon.toStringAsFixed(6)}',
        'addressOne': result.address,
        'addressTwo':
            [result.unit, result.street].where((s) => s.isNotEmpty).join(', '),
        'zipCode': '',
        'postTown': result.city.isNotEmpty ? result.city : result.province,
        'country': 'Philippines',
        'lat': lat,
        'lon': lon,
        'label': result.landmark.isNotEmpty
            ? result.landmark
            : (result.barangay.isNotEmpty ? result.barangay : 'Home'),
        'isPrimary': store.savedAddresses.isEmpty,
      };

      final res = await api.addUserAddress(payload: payload);

      // Refresh the list so the new address appears
      await store.loadSavedAddresses();

      // Auto-select the newly created address
      final newAddrId =
          res['data']?['addressId'] ?? res['addressId'] ?? res['data']?['id'];
      if (newAddrId != null) {
        final match =
            store.savedAddresses.cast<Map<String, dynamic>?>().firstWhere(
                  (a) => (a?['addressId'] ?? a?['id']) == newAddrId,
                  orElse: () => null,
                );
        if (match != null) store.selectAddress(match);
      } else if (store.savedAddresses.isNotEmpty) {
        // Fallback: select the last one (most recently added)
        store.selectAddress(store.savedAddresses.last);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    }
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    store.setSchedule(date.copyWith(hour: time.hour, minute: time.minute));
  }

  bool _submitting = false;

  Future<void> _onConfirmBooking() async {
    // Gate: guest users are redirected to sign in; the draft preserves all
    // form state so the flow resumes automatically after authentication.
    if (!dpLocator<AuthStateService>().isAuthenticated) {
      dpLocator<BookingDraftService>().save(BookingDraft(
        id: 'aircon_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        flowType: BookingFlowType.aircon,
        returnRouteName: AirconCheckoutScreen.routeName,
      ));
      if (!mounted) return;
      context.goNamed(
        AuthenticationGateScreen.routeName,
        extra: const AuthReturnIntent(destination: ProtectedDestination.bookingConfirm),
      );
      return;
    }
    // Block re-entry for the whole submit — including the window between the
    // create completing and the navigation removing this screen, where a second
    // tap would otherwise create a duplicate booking.
    if (_submitting || store.isLoading) return;
    final errors = <String>[];
    if (store.selectedAddress == null) errors.add('Select an address.');
    if (store.selectedSchedule == null) errors.add('Select a schedule.');

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.join('\n'))),
      );
      return;
    }

    _submitting = true;
    await store.createBooking();
    if (!mounted) return;

    if (store.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(store.errorMessage!)),
      );
      _submitting = false;
      return;
    }

    final bookingId = store.createdBookingId;
    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Booking created but no reference was returned. Check My Bookings.'),
        ),
      );
      _submitting = false;
      return;
    }

    // The booking now exists — commit to it. Reset the stack to My Bookings and
    // anchor the booking detail screen beneath the OTP step: there's no way back
    // to address/payment (prevents double-booking), and backing out of OTP lands
    // on the booking's detail page.
    final jobOrder = store.buildCreatedJobOrder();
    dpLocator<HomeStore>().addBooking(jobOrder);
    final router = GoRouter.of(context);
    router.goNamed(BookingsScreen.routeName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.pushNamed(BookingDetailScreen.routeName, extra: jobOrder);
      router.pushNamed(
        BookingOtpScreen.routeName,
        extra: BookingOtpArgs(
          bookingId: bookingId,
          flow: BookingOtpFlow.checkout,
          confirmationRouteName: AirconConfirmationScreen.routeName,
        ),
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: ColorPalette.secondaryText,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? ColorPalette.primaryColorDark
              : ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? ColorPalette.primaryColorDark
                : ColorPalette.border(.55),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 28,
                color: selected
                    ? ColorPalette.primaryText
                    : ColorPalette.primaryColorDark),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                color: selected
                    ? ColorPalette.primaryText
                    : ColorPalette.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
