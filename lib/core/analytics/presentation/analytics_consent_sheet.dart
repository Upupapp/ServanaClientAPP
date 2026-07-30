import 'package:client/common/constants/color_palette.dart';
import 'package:client/core/accessibility/focus_coordinator.dart';
import 'package:flutter/material.dart';

/// Shows the analytics consent bottom sheet and returns true if the user
/// accepted full analytics, or false if they chose essential-only.
///
/// The sheet is non-dismissible (WillPopScope + isDismissible: false) so users
/// must make an explicit choice — PDPA/GDPR require affirmative, unambiguous
/// consent (no pre-ticked boxes, no dark patterns).
Future<bool> showAnalyticsConsentSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AnalyticsConsentSheet(),
  );
  return result ?? false;
}

class _AnalyticsConsentSheet extends StatefulWidget {
  const _AnalyticsConsentSheet();

  @override
  State<_AnalyticsConsentSheet> createState() => _AnalyticsConsentSheetState();
}

class _AnalyticsConsentSheetState extends State<_AnalyticsConsentSheet> {
  final FocusNode _titleFocus = FocusCoordinator.createModalTrap();

  @override
  void initState() {
    super.initState();
    FocusCoordinator.requestFocusPostFrame(context, node: _titleFocus);
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle — decorative, hidden from accessibility tree
            ExcludeSemantics(
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: ColorPalette.secondaryBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Semantics(
              header: true,
              focusable: true,
              focused: true,
              child: Focus(
                focusNode: _titleFocus,
                child: Text(
                  'Help us improve Servana',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.secondaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'d like to collect anonymous usage data to improve the app and diagnose crashes. '
              'Your personal information is never shared.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ColorPalette.accentText,
              ),
            ),
            const SizedBox(height: 16),
            const _ConsentPoint(
              icon: Icons.analytics_outlined,
              label: 'Usage analytics',
              detail: 'Which features you use, so we can improve them.',
            ),
            const _ConsentPoint(
              icon: Icons.bug_report_outlined,
              label: 'Crash reporting',
              detail: 'Automatic crash reports to fix issues faster.',
            ),
            const _ConsentPoint(
              icon: Icons.speed_outlined,
              label: 'Performance monitoring',
              detail: 'Load times and app health — no personal data.',
            ),
            const SizedBox(height: 8),
            Text(
              'You can change this at any time in Settings → Privacy.',
              style: TextStyle(
                fontSize: 12,
                color: ColorPalette.accentText,
              ),
            ),
            const SizedBox(height: 24),
            // Accept button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryColorDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Accept & Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Essential-only button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ColorPalette.accentText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Essential Only',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: ColorPalette.primaryColorDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorPalette.accentText,
                    height: 1.4,
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
