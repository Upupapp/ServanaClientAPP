import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/bookings/data/booking_repository.dart';
import 'package:flutter/material.dart';

/// Modal bottom sheet that collects a cancellation reason and calls the
/// cancel endpoint via [BookingRepository].
///
/// Usage:
/// ```dart
/// await BookingCancellationSheet.show(
///   context,
///   bookingId: '42',
///   onCancelled: () => _refreshBooking(),
/// );
/// ```
class BookingCancellationSheet extends StatefulWidget {
  final String bookingId;
  final VoidCallback onCancelled;

  const BookingCancellationSheet._({
    required this.bookingId,
    required this.onCancelled,
  });

  /// Show the sheet and return when it is dismissed.
  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    required VoidCallback onCancelled,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookingCancellationSheet._(
        bookingId: bookingId,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<BookingCancellationSheet> createState() =>
      _BookingCancellationSheetState();
}

class _BookingCancellationSheetState extends State<BookingCancellationSheet> {
  static const _reasons = [
    'Schedule changed',
    'Booked by mistake',
    'No longer needed',
    'Provider delay',
    'Price concern',
    'Other',
  ];

  String? _selectedReason;
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final repo = dpLocator<BookingRepository>();
      await repo.cancelBooking(widget.bookingId, _selectedReason!);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCancelled();
      }
    } catch (e) {
      // BACKEND_GAP-C15-001: no customer-facing cancel endpoint; admin route
      // returns HTTP 403 for non-admin tokens.  Surface a clear message
      // rather than a cryptic error.
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = 'Cancellation is not available at this time. '
              'Please contact support if you need to cancel.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This action cannot be undone. Please select a reason.',
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

          // Reason list
          ...List.generate(_reasons.length, (i) {
            final reason = _reasons[i];
            return RadioListTile<String>(
              value: reason,
              groupValue: _selectedReason,
              onChanged: _isSubmitting
                  ? null
                  : (v) => setState(() => _selectedReason = v),
              title: Text(
                reason,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: ColorPalette.secondaryText,
                ),
              ),
              activeColor: ColorPalette.primaryColorDark,
              dense: true,
            );
          }),

          // Error banner
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

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: (_selectedReason == null || _isSubmitting)
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.withOpacity(.4),
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
                          'Cancel Booking',
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
                    'Keep Booking',
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
    );
  }
}
