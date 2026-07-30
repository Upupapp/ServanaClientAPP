import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/repositories/address_repository.dart';
import 'package:client/common/domain/auth/auth_return_intent.dart';
import 'package:client/common/domain/booking/booking_draft.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/address_form_screen.dart';
import 'package:client/common/presentation/screens/authentication_gate_screen.dart';
import 'package:client/common/presentation/screens/booking_otp_screen.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Step 3: User selects address, confirms payment method, reviews summary.
class BwCheckoutScreen extends StatefulWidget {
  static const String routeName = 'BwCheckout';
  static const String route = 'BwCheckout';

  const BwCheckoutScreen({super.key});

  @override
  State<BwCheckoutScreen> createState() => _BwCheckoutScreenState();
}

class _BwCheckoutScreenState extends State<BwCheckoutScreen> {
  final store = dpLocator<BwBookingStore>();

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
              // ──── Booking summary ────
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
                      'Booking Summary',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      '₱${store.estimatedTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (store.selectedBranch != null)
                      Text(
                        _branchName(),
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.accentText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (store.selectedDate != null &&
                        store.selectedSlot != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${DateFormat('EEE, MMM d yyyy').format(store.selectedDate!)} • ${_slotTime()}',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            color: ColorPalette.accentText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (store.selectedAddonIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${store.selectedAddonIds.length} add-on(s) selected',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            color: ColorPalette.accentText,
                            fontSize: 12,
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
                    child: Semantics(
                      label:
                          'Select ${label.toString().isNotEmpty ? label.toString() : line1.toString()} address',
                      button: true,
                      selected: isSelected,
                      excludeSemantics: true,
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
                                        fontFamily:
                                            FontPalette.primaryFontFamily,
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
                    ),
                  );
                }),
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

              // ──── Payment method ────
              const _SectionHeader(title: 'Payment Method'),
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

              // Submission error
              if (store.submissionError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    store.submissionError!,
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
                  onPressed: store.isSubmitting ? null : _onConfirmBooking,
                  child: store.isSubmitting
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
    if (opt == null) return 'Beauty & Wellness Service';
    return (opt['level_3'] ??
            opt['name'] ??
            opt['optionName'] ??
            'Beauty & Wellness Service')
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

    final repo = dpLocator<AddressRepository>();
    final outcome = await repo.createAddress(
      result: result,
      isPrimary: store.savedAddresses.isEmpty,
    );

    if (!mounted) return;
    switch (outcome) {
      case AddressCreated(:final newAddress, :final allAddresses):
        store.savedAddresses
          ..clear()
          ..addAll(allAddresses);
        store.selectAddress(newAddress);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved!')),
        );
      case AddressError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      case AddressSuccess():
        break;
    }
  }

  Future<void> _onConfirmBooking() async {
    if (!dpLocator<AuthStateService>().isAuthenticated) {
      final opt = store.selectedOption;
      dpLocator<BookingDraftService>().save(BookingDraft(
        id: 'bw_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        flowType: BookingFlowType.beautyWellness,
        returnRouteName: BwCheckoutScreen.routeName,
        selectedOptions: opt != null
            ? [(opt['id'] ?? opt['optionId'] ?? '').toString()]
            : const [],
        selectedAddons:
            store.selectedAddonIds.map((id) => id.toString()).toList(),
        selectedBranchId:
            (store.selectedBranch?['branchId'] ?? store.selectedBranch?['id'])
                ?.toString(),
        addressLine: store.selectedAddress?['addressOne']?.toString(),
        lat: (store.selectedAddress?['lat'] as num?)?.toDouble(),
        lon: (store.selectedAddress?['lon'] as num?)?.toDouble(),
        selectedDate: store.selectedDate,
        selectedSlot: (store.selectedSlot?['slotTime'] ?? '').toString(),
        pricingSnapshot: store.estimatedTotal > 0 ? store.estimatedTotal : null,
      ));
      if (!mounted) return;
      context.goNamed(
        AuthenticationGateScreen.routeName,
        extra: const AuthReturnIntent(
            destination: ProtectedDestination.bookingConfirm),
      );
      return;
    }

    if (store.isSubmitting) return;

    final errors = <String>[];
    if (store.selectedOption == null) errors.add('No service selected.');
    if (store.selectedBranch == null) errors.add('No branch selected.');
    if (store.selectedDate == null) errors.add('No date selected.');
    if (store.selectedSlot == null) errors.add('No time slot selected.');
    if (store.selectedAddress == null) errors.add('Select an address.');

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }

    await store.createBooking();
    if (!mounted) return;

    if (store.submissionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(store.submissionError!)),
      );
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
      return;
    }

    dpLocator<HomeStore>().addBooking(store.buildCreatedJobOrder());
    dpLocator<BookingDraftService>().clear();

    final router = GoRouter.of(context);
    router.goNamed(BookingsScreen.routeName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.pushNamed(
        BookingOtpScreen.routeName,
        extra: BookingOtpArgs(
          bookingId: bookingId,
          flow: BookingOtpFlow.checkout,
          confirmationRouteName: BwConfirmationScreen.routeName,
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
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: InkWell(
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
                  fontSize: 12,
                  color: selected
                      ? ColorPalette.primaryText
                      : ColorPalette.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
