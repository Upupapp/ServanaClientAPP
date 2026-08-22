import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/booking_ux_components.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Step 2: User picks a date and available time slot (branch is auto-selected).
class BwBranchSlotScreen extends StatefulWidget {
  static const String routeName = 'BwBranchSlot';
  static const String route = 'BwBranchSlot';

  const BwBranchSlotScreen({super.key});

  @override
  State<BwBranchSlotScreen> createState() => _BwBranchSlotScreenState();
}

class _BwBranchSlotScreenState extends State<BwBranchSlotScreen> {
  final store = dpLocator<BwBookingStore>();

  @override
  void initState() {
    super.initState();
    if (store.selectedServiceId != null) {
      store.loadBranches(serviceId: store.selectedServiceId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Select Date & Time',
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
        if (store.isLoading && store.branches.isEmpty) {
          return const Center(
            child: BookingLoadingState('Loading available providers and times'),
          );
        }

        if (store.errorMessage != null && store.branches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: ColorPalette.danger),
                  const SizedBox(height: 12),
                  Text(
                    store.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: store.selectedServiceId != null
                        ? () => store.loadBranches(
                            serviceId: store.selectedServiceId!)
                        : () => Navigator.of(context).pop(),
                    child: Text(
                        store.selectedServiceId != null ? 'Retry' : 'Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BookingStageHeader(
                current: 3,
                total: 5,
                label: 'Choose schedule',
              ),
              // ──── Select Date ────
              const _SectionTitle('Select Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
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
                      // Expanded, or the formatted date demands its full
                      // intrinsic width and the Row overflows — up to 343px at
                      // text scale 2.0. The clipped text is the chosen date.
                      Expanded(
                        child: Text(
                          store.selectedDate != null
                              ? DateFormat('EEE, MMM d yyyy')
                                  .format(store.selectedDate!)
                              : 'Tap to select a date',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            color: store.selectedDate != null
                                ? ColorPalette.secondaryText
                                : ColorPalette.accentText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ──── Time ────
              //
              // A branch slot carries capacity the backend locks; a service
              // with no branch has none to offer, and production answers
              // `branches: []` for nine of the ten legacy families. Before
              // this, such a service showed an empty slot list, left Continue
              // permanently disabled, and gave the customer nothing to read
              // that explained why — a silent dead end at the last step before
              // checkout.
              if (!store.branchRequired) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Time'),
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: 'Choose a time',
                  child: InkWell(
                    onTap: _pickTime,
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
                          Icon(Icons.schedule_rounded,
                              color: ColorPalette.primaryColorDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              store.selectedSchedule != null
                                  ? DateFormat('h:mm a')
                                      .format(store.selectedSchedule!)
                                  : 'Tap to choose a time',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontWeight: FontWeight.w600,
                                color: store.selectedSchedule != null
                                    ? ColorPalette.secondaryText
                                    : ColorPalette.accentText,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: ColorPalette.accentText),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This service is scheduled directly with your provider, so '
                  'there are no branch times to choose from.',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.accentText,
                  ),
                ),
              ],

              // ──── Available Time Slots ────
              if (store.branchRequired && store.selectedDate != null) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Available Time Slots'),
                const SizedBox(height: 8),
                if (store.isLoading && store.slots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: BookingLoadingState(
                        'Loading available times',
                        compact: true,
                      ),
                    ),
                  )
                else if (store.slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No available slots for this date.',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.accentText,
                        ),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: store.slots.map((slot) {
                      // Slots have no slotId — use slotTime as identity.
                      final slotTime = slot['slotTime']?.toString() ?? '';
                      final selectedSlotTime =
                          store.selectedSlot?['slotTime']?.toString();
                      final isSelected = slotTime == selectedSlotTime;
                      final isAvailable = slot['available'] == true;
                      final remaining = slot['remainingCapacity'];
                      final displayTime = _formatSlotTime(slotTime);

                      return ChoiceChip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(displayTime),
                            if (remaining is int)
                              Text(
                                '$remaining left',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? ColorPalette.primaryText.withOpacity(.8)
                                      : ColorPalette.accentText,
                                ),
                              ),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: ColorPalette.primaryColorDark,
                        checkmarkColor: ColorPalette.primaryText,
                        disabledColor:
                            ColorPalette.secondaryBackground.withOpacity(.5),
                        labelStyle: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: isSelected
                              ? ColorPalette.primaryText
                              : isAvailable
                                  ? ColorPalette.secondaryText
                                  : ColorPalette.accentText,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected:
                            isAvailable ? (_) => store.selectSlot(slot) : null,
                      );
                    }).toList(),
                  ),
              ],

              const SizedBox(height: 32),

              // Error
              if (store.errorMessage != null && store.branches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    store.errorMessage!,
                    style: TextStyle(
                        color: ColorPalette.danger,
                        fontFamily: FontPalette.primaryFontFamily),
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
                  onPressed: _canContinue() ? _onContinue : null,
                  child: Text(
                    'Continue',
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

  /// The same rule the checkout and the store apply: a branch only when one is
  /// on offer, and a resolvable schedule however it was answered.
  bool _canContinue() {
    if (store.branchRequired && store.selectedBranch == null) return false;
    return store.effectiveSchedule != null;
  }

  void _onContinue() {
    context.pushNamed(BwCheckoutScreen.routeName);
  }

  /// Time only — the date is already chosen above, and `setSchedule` keeps the
  /// two in one value so nothing downstream has to recombine them.
  Future<void> _pickTime() async {
    final date = store.selectedDate;
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a date first.')),
      );
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: store.selectedSchedule != null
          ? TimeOfDay.fromDateTime(store.selectedSchedule!)
          : TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    store.setSchedule(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: store.selectedDate ?? DateTime.now(),
    );
    if (date == null || !mounted) return;
    store.setDate(date);
  }

  String _formatSlotTime(String slotTime) {
    final parts = slotTime.split(':');
    if (parts.length < 2) return slotTime;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: FontPalette.primaryFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: ColorPalette.secondaryText,
      ),
    );
  }
}
