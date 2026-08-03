import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/support/application/support_create_controller.dart';
import 'package:client/modules/support/domain/support_ticket_category.dart';
import 'package:client/modules/support/presentation/screens/support_ticket_detail_screen.dart';
import 'package:flutter/material.dart';

class CreateSupportTicketScreen extends StatefulWidget {
  const CreateSupportTicketScreen({super.key, this.initialCategory});

  /// apiKey value e.g. 'booking', 'payment', 'other'
  final String? initialCategory;

  static const String route = '/support/new';
  static const String routeName = 'SupportCreate';

  @override
  State<CreateSupportTicketScreen> createState() =>
      _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
  late final SupportCreateController _ctrl;

  // Step: 0 = category, 1 = describe, 2 = submitting/done
  int _step = 0;
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bookingCtrl = TextEditingController();
  final _subjectFocus = FocusNode();
  final _descFocus = FocusNode();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<SupportCreateController>();
    _ctrl.addListener(_onCtrlChange);

    // Apply initial category from caller
    if (widget.initialCategory != null) {
      final cat = SupportTicketCategory.fromString(widget.initialCategory);
      _ctrl.setCategory(cat);
      _step = 1; // Skip category selection
    } else {
      _ctrl.loadDraft();
    }

    // Seed text fields from controller (draft restore)
    _subjectCtrl.text = _ctrl.subject;
    _descCtrl.text = _ctrl.description;
    _bookingCtrl.text = _ctrl.bookingId ?? '';

    _subjectCtrl.addListener(() => _ctrl.setSubject(_subjectCtrl.text));
    _descCtrl.addListener(() => _ctrl.setDescription(_descCtrl.text));
  }

  @override
  void dispose() {
    // Persist any unsaved form content so it survives navigation-away
    if (_ctrl.description.trim().isNotEmpty) _ctrl.saveDraft().ignore();
    _ctrl.removeListener(_onCtrlChange);
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _bookingCtrl.dispose();
    _subjectFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _onCtrlChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _selectCategory(SupportTicketCategory cat) {
    _ctrl.setCategory(cat);
    setState(() {
      _step = 1;
      _validationError = null;
    });
  }

  Future<void> _submit() async {
    // Sync booking reference if entered
    final booking = _bookingCtrl.text.trim();
    if (booking.isNotEmpty) {
      _ctrl.setBookingContext(bookingId: booking);
    } else {
      _ctrl.clearBookingContext();
    }

    final ok = await _ctrl.submit();
    if (!ok || !mounted) return;

    // Navigate to the created ticket
    final ticket = _ctrl.createdTicket;
    _ctrl.reset();
    if (!mounted) return;
    if (ticket != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              SupportTicketDetailScreen(ticketKey: ticket.ticketKey),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  bool get _canSubmit =>
      _ctrl.description.trim().length >= 10 && !_ctrl.isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: ColorPalette.secondaryText),
          onPressed: () {
            if (_step > 0 && widget.initialCategory == null) {
              setState(() {
                _step--;
                _validationError = null;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Back',
        ),
        title: Text(
          _step == 0 ? 'What do you need help with?' : 'Describe your issue',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: _step == 0 ? _buildCategoryStep() : _buildDescribeStep(),
    );
  }

  Widget _buildCategoryStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: SupportTicketCategory.values
          .where((c) => c != SupportTicketCategory.safety)
          .map((cat) {
        return _CategoryTile(
          category: cat,
          selected: _ctrl.category == cat,
          onTap: () => _selectCategory(cat),
        );
      }).toList(),
    );
  }

  Widget _buildDescribeStep() {
    final isSubmitting = _ctrl.isSubmitting;
    final isSuccess = _ctrl.status == CreateTicketStatus.succeeded;

    if (isSuccess) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF16A34A), size: 56),
            const SizedBox(height: 14),
            Text(
              'Request submitted!',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorPalette.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColorDark.withOpacity(.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _ctrl.category.customerLabel,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              ),
              if (widget.initialCategory == null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _step = 0;
                    _validationError = null;
                  }),
                  child: Text(
                    'Change',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      color: ColorPalette.primaryColorDark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject (optional)
                const _SectionLabel('Subject (optional)'),
                const SizedBox(height: 6),
                TextField(
                  controller: _subjectCtrl,
                  focusNode: _subjectFocus,
                  enabled: !isSubmitting,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                    color: ColorPalette.secondaryText,
                  ),
                  decoration: _inputDeco(
                    'e.g. Provider arrived late and was unprofessional',
                  ),
                ),
                const SizedBox(height: 14),
                // Booking reference for relevant categories
                if (_ctrl.category.requiresBooking ||
                    _ctrl.category.isPaymentRelated) ...[
                  const _SectionLabel('Booking reference (optional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bookingCtrl,
                    enabled: !isSubmitting,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 14,
                      color: ColorPalette.secondaryText,
                    ),
                    decoration: _inputDeco('Leave blank if unknown'),
                  ),
                  const SizedBox(height: 14),
                ],
                // Description — required
                const _SectionLabel('Describe your issue'),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  focusNode: _descFocus,
                  enabled: !isSubmitting,
                  minLines: 5,
                  maxLines: 12,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                    color: ColorPalette.secondaryText,
                  ),
                  decoration: _inputDeco(
                    'Please share what happened, when it occurred, and how Servana can help…',
                  ),
                ),
                if (_validationError != null || _ctrl.error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _validationError ?? _ctrl.error ?? '',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
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
                  16,
                  10,
                  16,
                  10 + MediaQuery.of(context).padding.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColorDark,
                      disabledBackgroundColor:
                          ColorPalette.primaryColorDark.withOpacity(.4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                        : const Text('Submit Request'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide:
              BorderSide(color: ColorPalette.primaryColorDark, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorPalette.border(.15)),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: FontPalette.primaryFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ColorPalette.secondaryText,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });
  final SupportTicketCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: category.customerLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? ColorPalette.primaryColorDark.withOpacity(.06)
                : ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
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
                _iconFor(category),
                color: selected
                    ? ColorPalette.primaryColorDark
                    : ColorPalette.accentText,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.customerLabel,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    Text(
                      _subtitleFor(category),
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 12,
                        color: ColorPalette.accentText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ColorPalette.accentText.withOpacity(.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SupportTicketCategory c) {
    switch (c) {
      case SupportTicketCategory.booking:
        return Icons.calendar_today_outlined;
      case SupportTicketCategory.payment:
        return Icons.credit_card_outlined;
      case SupportTicketCategory.refund:
        return Icons.currency_exchange_rounded;
      case SupportTicketCategory.serviceQuality:
        return Icons.star_half_rounded;
      case SupportTicketCategory.providerConduct:
        return Icons.person_off_outlined;
      case SupportTicketCategory.account:
        return Icons.manage_accounts_outlined;
      case SupportTicketCategory.technical:
        return Icons.build_outlined;
      case SupportTicketCategory.promotion:
        return Icons.local_offer_outlined;
      case SupportTicketCategory.privacy:
        return Icons.lock_outline_rounded;
      case SupportTicketCategory.other:
        return Icons.more_horiz_rounded;
      case SupportTicketCategory.safety:
        return Icons.emergency_outlined;
    }
  }

  String _subtitleFor(SupportTicketCategory c) {
    switch (c) {
      case SupportTicketCategory.booking:
        return 'Cancellations, rescheduling, provider issues';
      case SupportTicketCategory.payment:
        return 'Charges, billing, payment failures';
      case SupportTicketCategory.refund:
        return 'Request a refund or dispute a charge';
      case SupportTicketCategory.serviceQuality:
        return 'The service did not meet expectations';
      case SupportTicketCategory.providerConduct:
        return 'Unprofessional or concerning behavior';
      case SupportTicketCategory.account:
        return 'Login, profile, or account access';
      case SupportTicketCategory.technical:
        return 'App errors, crashes, or glitches';
      case SupportTicketCategory.promotion:
        return 'Promo codes or rewards not applied';
      case SupportTicketCategory.privacy:
        return 'Data access or deletion requests';
      case SupportTicketCategory.other:
        return 'Something not listed above';
      case SupportTicketCategory.safety:
        return 'Safety or emergency concern';
    }
  }
}
