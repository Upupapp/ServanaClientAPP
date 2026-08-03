import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  static const String route = '/support/help';
  static const String routeName = 'SupportHelp';

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const _articles = [
    _Article(
      id: 'bk-001',
      category: 'Bookings',
      title: 'How do I cancel a booking?',
      body:
          'You can request a cancellation from the Bookings tab. Open the booking and look for the cancellation option. '
          'Cancellation fees may apply depending on how close to the scheduled time you cancel. '
          'If the cancellation option is unavailable, contact Support for assistance.',
    ),
    _Article(
      id: 'bk-002',
      category: 'Bookings',
      title: 'What if my provider does not arrive?',
      body:
          'If your provider has not arrived within the expected window, tap "Get Help" on your active booking. '
          'Servana will assist you with rebooking or a refund within 24 hours.',
    ),
    _Article(
      id: 'bk-003',
      category: 'Bookings',
      title: 'Can I reschedule a booking?',
      body:
          'Rescheduling must be arranged with Servana Support. Contact us through the Support section '
          'and reference your booking details. We will work with you and the provider to find a new time.',
    ),
    _Article(
      id: 'py-001',
      category: 'Payments',
      title: 'How is payment processed?',
      body:
          'Payments are processed securely through PayMongo. Servana never stores your card details. '
          'You will receive a payment confirmation once your transaction is complete.',
    ),
    _Article(
      id: 'py-002',
      category: 'Payments',
      title: 'When will I receive my refund?',
      body:
          'Refunds are processed once Servana approves the request. Processing time depends on your payment method. '
          'Card refunds typically appear within 5–10 business days. GCash and Maya refunds may be faster.',
    ),
    _Article(
      id: 'py-003',
      category: 'Payments',
      title: 'What if I was charged but the booking is not confirmed?',
      body:
          'Contact Servana Support with your booking reference and payment details. '
          'We will investigate and resolve the discrepancy, including issuing a refund if warranted.',
    ),
    _Article(
      id: 'ac-001',
      category: 'Account',
      title: 'How do I update my profile information?',
      body:
          'Go to Profile → Edit Profile to update your name, phone number, birthdate, and gender. '
          'Email changes require identity verification and must be done through Settings.',
    ),
    _Article(
      id: 'ac-002',
      category: 'Account',
      title: 'Is my personal information safe?',
      body: 'Servana uses industry-standard encryption to protect your data. '
          'Your personal information is only shared with providers assigned to your bookings, '
          'and only as needed to fulfil the service.',
    ),
    _Article(
      id: 'sf-001',
      category: 'Safety',
      title: 'What should I do if I feel unsafe during a service?',
      body:
          'If you are in immediate danger, contact local emergency services (911) immediately. '
          'For safety concerns related to a booking, use the Safety option in the Support section. '
          'Servana takes all safety reports seriously and reviews them as a priority.',
    ),
  ];

  String _search = '';
  String? _activeCategory;

  List<_Article> get _filtered {
    var list = _articles.toList();
    if (_activeCategory != null) {
      list = list.where((a) => a.category == _activeCategory).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.body.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<String> get _categories =>
      _articles.map((a) => a.category).toSet().toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: ColorPalette.secondaryText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Help Center',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 14,
                color: ColorPalette.secondaryText,
              ),
              decoration: InputDecoration(
                hintText: 'Search help articles…',
                hintStyle: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText.withOpacity(.5)),
                prefixIcon: Icon(Icons.search_rounded,
                    color: ColorPalette.accentText.withOpacity(.6)),
                filled: true,
                fillColor: ColorPalette.secondaryBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ColorPalette.border(.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ColorPalette.border(.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: ColorPalette.primaryColorDark, width: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _activeCategory == null,
                  onTap: () => setState(() => _activeCategory = null),
                ),
                for (final c in _categories)
                  _CategoryChip(
                    label: c,
                    selected: _activeCategory == c,
                    onTap: () => setState(() =>
                        _activeCategory = _activeCategory == c ? null : c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No articles found',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        color: ColorPalette.accentText,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _ArticleTile(article: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? ColorPalette.primaryColorDark
                : ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? ColorPalette.primaryColorDark
                  : ColorPalette.border(.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : ColorPalette.accentText,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleTile extends StatefulWidget {
  const _ArticleTile({required this.article});
  final _Article article;

  @override
  State<_ArticleTile> createState() => _ArticleTileState();
}

class _ArticleTileState extends State<_ArticleTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !_expanded,
      expanded: _expanded,
      label: widget.article.title,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ColorPalette.border(.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.article.title,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: ColorPalette.accentText,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.article.body,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 13,
                    color: ColorPalette.accentText,
                    height: 1.55,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Article {
  const _Article({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
  });
  final String id;
  final String category;
  final String title;
  final String body;
}
