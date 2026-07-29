import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/review/application/review_form_controller.dart';
import 'package:client/modules/review/domain/review_visibility.dart';
import 'package:client/modules/review/presentation/widgets/review_dimension_row.dart';
import 'package:client/modules/review/presentation/widgets/review_rating_control.dart';
import 'package:flutter/material.dart';

class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.bookingId,
    this.bookingLabel,
    this.serviceCategory,
  });

  final String bookingId;
  final String? bookingLabel;
  final String? serviceCategory;

  static const String route     = '/review/new';
  static const String routeName = 'ReviewForm';

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  late final ReviewFormController _ctrl;
  final _publicCtrl  = TextEditingController();
  final _privateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<ReviewFormController>();
    _ctrl.addListener(_onChange);
    _ctrl.loadEligibility(widget.bookingId, serviceCategory: widget.serviceCategory);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    _publicCtrl.dispose();
    _privateCtrl.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _submit() async {
    final ok = await _ctrl.submit();
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true); // signal success to caller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: ColorPalette.secondaryText),
          onPressed: () => Navigator.of(context).pop(false),
          tooltip: 'Close',
        ),
        title: Text(
          'Leave a review',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final status = _ctrl.status;

    if (status == ReviewFormStatus.loadingEligibility) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == ReviewFormStatus.notEligible) {
      return _NotEligibleView(reason: _ctrl.eligibility?.reason);
    }

    if (status == ReviewFormStatus.succeeded) {
      return _SuccessView(onDone: () => Navigator.of(context).pop(true));
    }

    if (status == ReviewFormStatus.failed &&
        _ctrl.draft == null) {
      return _ErrorView(
        message: _ctrl.error ?? 'Could not load review form.',
        onRetry: () => _ctrl.loadEligibility(widget.bookingId,
            serviceCategory: widget.serviceCategory),
      );
    }

    final draft = _ctrl.draft;
    if (draft == null) return const Center(child: CircularProgressIndicator());

    final isSubmitting = _ctrl.isSubmitting;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking label
                if (widget.bookingLabel != null) ...[
                  Text(
                    widget.bookingLabel!,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: ColorPalette.accentText,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Overall rating
                const _SectionLabel('How was your overall experience?'),
                const SizedBox(height: 14),
                Center(
                  child: ReviewRatingControl(
                    rating:          draft.overallRating,
                    onRatingChanged: isSubmitting ? (_) {} : _ctrl.setRating,
                    size:            52,
                    enabled:         !isSubmitting,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _ratingLabel(draft.overallRating),
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: ColorPalette.primaryColorDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Dimensions
                if (_ctrl.dimensionKeys.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('Rate specific aspects'),
                  const SizedBox(height: 4),
                  ..._ctrl.dimensionKeys.map((key) => ReviewDimensionRow(
                    dimensionKey:   key,
                    score:          draft.dimensions[key] ?? 0,
                    onScoreChanged: isSubmitting
                        ? (_) {}
                        : (v) => _ctrl.setDimension(key, v),
                    enabled:        !isSubmitting,
                  )),
                ],

                // Public comment
                const SizedBox(height: 24),
                const _SectionLabel('Tell others about your experience (optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _publicCtrl,
                  enabled:    !isSubmitting,
                  minLines:   3,
                  maxLines:   8,
                  maxLength:  2000,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: _ctrl.setPublicComment,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                    color: ColorPalette.secondaryText,
                  ),
                  decoration: _inputDeco(
                    'Share what went well or how it could be improved…',
                  ),
                ),

                // Private feedback
                const SizedBox(height: 16),
                const _SectionLabel('Private feedback for Servana (optional)'),
                const SizedBox(height: 4),
                Text(
                  'Only visible to our team — not shown publicly.',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.accentText,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _privateCtrl,
                  enabled:    !isSubmitting,
                  minLines:   2,
                  maxLines:   6,
                  maxLength:  2000,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: _ctrl.setPrivateFeedback,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                    color: ColorPalette.secondaryText,
                  ),
                  decoration: _inputDeco('Anything you\'d like Servana to know…'),
                ),

                // Visibility
                const SizedBox(height: 16),
                const _SectionLabel('Who can see your review?'),
                const SizedBox(height: 8),
                _VisibilitySelector(
                  value:    draft.visibility,
                  onChanged: isSubmitting ? null : _ctrl.setVisibility,
                ),

                // Error
                if (_ctrl.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _ctrl.error!,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: ColorPalette.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Submit bar
        Container(
          color: ColorPalette.primaryBackground,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20, 12, 20,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!isSubmitting && draft.isSubmittable) ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColorDark,
                      disabledBackgroundColor:
                          ColorPalette.primaryColorDark.withOpacity(.35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Submit review'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very good';
      case 5: return 'Excellent';
      default: return 'Tap a star to rate';
    }
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontFamily: FontPalette.primaryFontFamily,
      fontSize: 13,
      color: ColorPalette.accentText.withOpacity(.5),
    ),
    filled: true,
    fillColor: ColorPalette.secondaryBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ColorPalette.border(.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ColorPalette.border(.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ColorPalette.primaryColorDark, width: 1.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ColorPalette.border(.15)),
    ),
  );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontFamily: FontPalette.primaryFontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: ColorPalette.secondaryText,
    ),
  );
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({required this.value, required this.onChanged});
  final ReviewVisibility value;
  final ValueChanged<ReviewVisibility>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ReviewVisibility.values.map((v) {
        final selected = v == value;
        return InkWell(
          onTap: onChanged != null ? () => onChanged!(v) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? ColorPalette.primaryColorDark.withOpacity(.06)
                  : ColorPalette.secondaryBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? ColorPalette.primaryColorDark
                    : ColorPalette.border(.18),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconFor(v),
                  size: 18,
                  color: selected
                      ? ColorPalette.primaryColorDark
                      : ColorPalette.accentText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    v.displayLabel,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: ColorPalette.primaryColorDark),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(ReviewVisibility v) {
    switch (v) {
      case ReviewVisibility.public:          return Icons.public_rounded;
      case ReviewVisibility.anonymousPublic: return Icons.person_off_outlined;
      case ReviewVisibility.private:         return Icons.lock_outline_rounded;
    }
  }
}

class _NotEligibleView extends StatelessWidget {
  const _NotEligibleView({this.reason});
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final msg = _message(reason);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 48, color: ColorPalette.accentText),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 15,
                color: ColorPalette.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }

  String _message(String? reason) {
    switch (reason) {
      case 'REVIEW_ALREADY_SUBMITTED':
        return 'You\'ve already reviewed this booking.';
      case 'REVIEW_WINDOW_EXPIRED':
        return 'The 14-day review window for this booking has closed.';
      case 'REVIEW_WINDOW_NOT_OPEN':
        return 'You can leave a review once the service is complete.';
      case 'BOOKING_NOT_COMPLETED':
        return 'Reviews are only available after the service is completed.';
      case 'BOOKING_CANCELLED':
        return 'Reviews are not available for cancelled bookings.';
      default:
        return 'This booking is not eligible for a review at this time.';
    }
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF16A34A), size: 60),
            const SizedBox(height: 16),
            Text(
              'Thanks for your review!',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorPalette.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps improve the Servana experience for everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 14,
                color: ColorPalette.accentText,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primaryColorDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: ColorPalette.danger),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 15,
                  color: ColorPalette.secondaryText,
                )),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
