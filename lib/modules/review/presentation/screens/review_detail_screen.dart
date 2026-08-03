import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/review/application/review_detail_controller.dart';
import 'package:client/modules/review/presentation/widgets/review_card.dart';
import 'package:flutter/material.dart';

class ReviewDetailScreen extends StatefulWidget {
  const ReviewDetailScreen({
    super.key,
    this.bookingId,
    this.reviewId,
  }) : assert(bookingId != null || reviewId != null,
            'Provide at least one of bookingId or reviewId');

  final String? bookingId;
  final String? reviewId;

  static const String route = '/review/detail';
  static const String routeName = 'ReviewDetail';

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  late final ReviewDetailController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<ReviewDetailController>();
    _ctrl.addListener(_onChange);
    _load();
  }

  void _load() {
    if (widget.bookingId != null) {
      _ctrl.loadByBooking(widget.bookingId!);
    } else {
      _ctrl.loadById(widget.reviewId!);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showReportDialog() async {
    String selectedReason = 'INACCURATE';
    final detailsCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report this review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this review?'),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, ss) => DropdownButtonFormField<String>(
                value: selectedReason,
                items: const [
                  DropdownMenuItem(
                      value: 'INACCURATE', child: Text('Inaccurate')),
                  DropdownMenuItem(value: 'SPAM', child: Text('Spam')),
                  DropdownMenuItem(
                      value: 'HARASSMENT', child: Text('Harassment')),
                  DropdownMenuItem(
                      value: 'HATE_SPEECH', child: Text('Hate speech')),
                  DropdownMenuItem(
                      value: 'PERSONAL_INFORMATION',
                      child: Text('Personal info')),
                  DropdownMenuItem(
                      value: 'THREATENING_CONTENT', child: Text('Threatening')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (v) {
                  if (v != null) ss(() => selectedReason = v);
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Additional details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Submit report'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _ctrl.reportReview(
        reason: selectedReason,
        details:
            detailsCtrl.text.trim().isNotEmpty ? detailsCtrl.text.trim() : null,
      );
      detailsCtrl.dispose();
      if (mounted && _ctrl.reportSubmitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')),
        );
      }
    } else {
      detailsCtrl.dispose();
    }
  }

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
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Your review',
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

    if (status == ReviewDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == ReviewDetailStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: ColorPalette.danger),
              const SizedBox(height: 16),
              Text(
                _ctrl.error ?? 'Could not load review.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 15,
                  color: ColorPalette.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final review = _ctrl.review;
    if (review == null) {
      return Center(
        child: Text(
          'No review found.',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            color: ColorPalette.accentText,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: ReviewCard(
        review: review,
        showPrivate: true,
        onReport: _showReportDialog,
      ),
    );
  }
}
