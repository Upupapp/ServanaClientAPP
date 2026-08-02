import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/core/accessibility/focus_coordinator.dart';

/// Outcome styling for [ServanaAlertDialog].
enum ServanaAlertType { success, error, warning, info }

/// The app's standard one- or two-button alert.
///
/// Replaces `AwesomeDialog`, which was used at six call sites and was the only
/// reason `awesome_dialog` — and through it the whole Rive runtime — was in the
/// dependency tree. `librive_text.so` ships 4 KB page-aligned, which blocks the
/// Play upload for a target of API 35+, so the cheapest fix for that library
/// was to stop shipping it rather than to chase a version that fixes it.
///
/// Built on Flutter's own [AlertDialog] rather than another package: it gets
/// correct focus trapping, scrim semantics and text scaling for free, and it
/// restores focus on dismiss the way `LogoutDialog` already does.
class ServanaAlertDialog {
  const ServanaAlertDialog._();

  /// Shows the alert and completes when it closes.
  ///
  /// Callers that navigate afterwards should `await` this — dismissing a route
  /// while its dialog is still on top leaves the dialog orphaned over the new
  /// screen.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    ServanaAlertType type = ServanaAlertType.info,
    String okText = 'OK',
    VoidCallback? onOk,
    String? cancelText,
    VoidCallback? onCancel,
  }) async {
    final priorFocus = FocusScope.of(context).focusedChild;

    await showDialog<void>(
      context: context,
      // Matches AwesomeDialog's behaviour: these carry an outcome the customer
      // needs to acknowledge, and one of them resends a verification email.
      barrierDismissible: cancelText == null,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorPalette.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(_icon(type), color: _color(type), size: 40),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: ColorPalette.secondaryText,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontSize: 14,
            height: 1.4,
            color: ColorPalette.accentText,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onCancel?.call();
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(88, 48),
                foregroundColor: ColorPalette.accentText,
              ),
              child: Text(
                cancelText,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onOk?.call();
            },
            style: FilledButton.styleFrom(
              // Comfortably past the 48pt minimum touch target.
              minimumSize: const Size(96, 48),
              backgroundColor: _color(type),
              foregroundColor: ColorPalette.primaryButtonTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              okText,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (context.mounted) {
      FocusCoordinator.restoreToNode(priorFocus);
    }
  }

  static IconData _icon(ServanaAlertType type) => switch (type) {
        ServanaAlertType.success => Icons.check_circle_rounded,
        ServanaAlertType.error => Icons.error_rounded,
        ServanaAlertType.warning => Icons.warning_rounded,
        ServanaAlertType.info => Icons.info_rounded,
      };

  static Color _color(ServanaAlertType type) => switch (type) {
        ServanaAlertType.success => const Color(0xFF16A34A),
        ServanaAlertType.error => ColorPalette.danger,
        ServanaAlertType.warning => ColorPalette.primaryColor,
        ServanaAlertType.info => ColorPalette.primaryColorDark,
      };
}
