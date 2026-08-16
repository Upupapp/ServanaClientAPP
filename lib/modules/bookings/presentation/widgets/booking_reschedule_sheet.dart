/// Modal bottom sheet that proposes a new start time for a booking.
///
/// ## Why this sheet decides nothing
///
/// It picks a date, a time and a reason, sends them, and renders whatever comes
/// back. It does **not** check the 24-hour notice window, the 90-day lead
/// bound, whether the booking is in a reschedulable state, or whether the
/// assigned provider is free. Every one of those is a server rule with a code
/// of its own — `BOOKING_RESCHEDULE_NOTICE_REQUIRED`,
/// `BOOKING_SCHEDULE_INVALID`, `BOOKING_NOT_RESCHEDULABLE`,
/// `BOOKING_RESCHEDULE_PROVIDER_CONFLICT` — and a client copy of any of them
/// would be a second policy that drifts from the first.
///
/// That is a deliberate contrast with cancellation, which grew three copies of
/// its own availability rule (`_isCancellable` on the detail screen,
/// `_cancellable` in `BookingActionResolver`, and the backend's). Reschedule
/// starts with one.
///
/// ## Not reachable in any shipped build
///
/// [BookingLifecycleRepository.canOfferReschedule] is false on the legacy
/// transport, because the only reschedule route that has ever existed is
/// admin-only and answers a customer token with 403. The detail screen consults
/// that flag before offering the entry point, so this sheet appears when the
/// canonical capability is on and not before. Showing a button that 403s would
/// be worse than showing none.
library;

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/accessibility/focus_coordinator.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_repository.dart';
import 'package:client/modules/bookings/domain/booking_reschedule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingRescheduleSheet extends StatefulWidget {
  const BookingRescheduleSheet._({
    required this.bookingId,
    required this.onRescheduled,
    this.currentSchedule,
  });

  final String bookingId;

  /// Called with the accepted start time once the backend applies the move.
  final ValueChanged<DateTime> onRescheduled;

  /// The schedule the caller last read.
  ///
  /// Sent back as `expectedSchedule`, which is what turns a lost update into
  /// `BOOKING_SCHEDULE_CHANGED`. Nullable only because a call site may not have
  /// it; every one that does should pass it.
  final DateTime? currentSchedule;

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    required ValueChanged<DateTime> onRescheduled,
    DateTime? currentSchedule,
  }) {
    final priorFocus = FocusScope.of(context).focusedChild;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookingRescheduleSheet._(
        bookingId: bookingId,
        onRescheduled: onRescheduled,
        currentSchedule: currentSchedule,
      ),
    ).whenComplete(() => FocusCoordinator.restoreToNode(priorFocus));
  }

  @override
  State<BookingRescheduleSheet> createState() => _BookingRescheduleSheetState();
}

class _BookingRescheduleSheetState extends State<BookingRescheduleSheet> {
  static final DateFormat _dateFormat = DateFormat('EEE, MMM d, y');
  static final DateFormat _timeFormat = DateFormat('h:mm a');

  DateTime? _proposed;
  RescheduleReason? _reason;
  bool _isSubmitting = false;
  String? _error;

  /// The proposal cannot be corrected here — the booking is in a state that
  /// may not be moved at all, or is not the caller's.
  bool _isRefusedOutright = false;

  bool get _canSubmit =>
      _proposed != null && _reason != null && !_isSubmitting && !_isRefusedOutright;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final seed = _proposed ?? widget.currentSchedule ?? now;

    // `lastDate` is a picker bound, not the policy. The backend owns the real
    // lead limit and refuses beyond it with BOOKING_SCHEDULE_INVALID; this is
    // only there because showDatePicker requires a range. It is set wider than
    // any plausible policy so the picker never becomes the thing that refuses.
    final date = await showDatePicker(
      context: context,
      initialDate: seed.isBefore(now) ? now : seed,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (time == null || !mounted) return;

    setState(() {
      _proposed =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final result = await dpLocator<BookingLifecycleRepository>().reschedule(
        bookingId: widget.bookingId,
        request: BookingRescheduleRequest(
          scheduledAt: _proposed!,
          reasonCode: _reason,
          expectedSchedule: widget.currentSchedule,
        ),
      );

      if (!mounted) return;

      if (result.isPendingProvider) {
        // Reachable the day RESCHEDULE_REQUIRES_PROVIDER_ACCEPTANCE flips true.
        // Telling the customer their booking has moved when it has only been
        // proposed is the failure this branch exists to prevent.
        setState(() {
          _isSubmitting = false;
          _error = 'Requested. Your provider needs to confirm the new time.';
          _isRefusedOutright = true;
        });
        return;
      }

      if (!result.isAccepted) {
        setState(() {
          _isSubmitting = false;
          _error = 'That time could not be used. Please pick another.';
        });
        return;
      }

      Navigator.of(context).pop();
      widget.onRescheduled(result.scheduledAt ?? _proposed!);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        // The backend names the rule that refused, and `safeMessage` carries
        // its wording — "A booking must be moved at least 24 hours before it
        // starts", "The assigned provider is not free then". Replacing those
        // with one generic sentence is what would make the refusal useless.
        _error = failure.safeMessage;
        // A validation failure means THIS time or reason was wrong, and the
        // customer can pick another. A state conflict or an access refusal
        // means the booking itself cannot be moved.
        _isRefusedOutright = failure is StateConflictFailure ||
            failure is ForbiddenFailure ||
            failure is NotFoundFailure;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final proposed = _proposed;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reschedule Booking',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: ColorPalette.primaryColorDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.currentSchedule == null
                        ? 'Pick a new date and time.'
                        : 'Currently ${_dateFormat.format(widget.currentSchedule!)} '
                            'at ${_timeFormat.format(widget.currentSchedule!)}.',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: ColorPalette.accentText,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // New time
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: OutlinedButton.icon(
                onPressed: (_isSubmitting || _isRefusedOutright)
                    ? null
                    : _pickDateTime,
                icon: Icon(
                  Icons.edit_calendar_outlined,
                  color: ColorPalette.primaryColorDark,
                ),
                label: Text(
                  proposed == null
                      ? 'Choose a new date and time'
                      : '${_dateFormat.format(proposed)} at '
                          '${_timeFormat.format(proposed)}',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  side: BorderSide(
                    color: ColorPalette.primaryColorDark.withOpacity(.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Why are you moving it?',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ColorPalette.secondaryText,
                ),
              ),
            ),

            // The customer subset only. PROVIDER_SUPPLY and OPERATIONAL are
            // valid on the endpoint but are an admin's vocabulary, and offering
            // them would invite a customer to attribute the move to their
            // provider in a record that is kept.
            ...RescheduleReason.customerChoices.map(
              (reason) => RadioListTile<RescheduleReason>(
                value: reason,
                groupValue: _reason,
                onChanged: (_isSubmitting || _isRefusedOutright)
                    ? null
                    : (v) => setState(() => _reason = v),
                title: Text(
                  reason.label,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                activeColor: ColorPalette.primaryColorDark,
                dense: true,
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.danger.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: ColorPalette.danger.withOpacity(.3)),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: ColorPalette.danger,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColorDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Request New Time',
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPalette.primaryColorDark,
                      side: BorderSide(
                          color: ColorPalette.primaryColorDark.withOpacity(.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      _isRefusedOutright ? 'Close' : 'Keep Current Time',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
