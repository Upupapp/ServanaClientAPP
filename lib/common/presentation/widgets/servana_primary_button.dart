import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';

/// Full-width primary action button styled with Servana's brand colours.
///
/// [ServanaPrimaryButton] — solid fill, use for the single most-important action.
/// [ServanaOutlinedButton] — border-only variant, use for secondary actions that
/// should sit alongside a primary without competing with it.
class ServanaPrimaryButton extends StatelessWidget {
  const ServanaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primaryColor,
          disabledBackgroundColor: ColorPalette.primaryColor.withOpacity(.55),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorPalette.primaryButtonTextColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        color: ColorPalette.primaryButtonTextColor, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryButtonTextFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ColorPalette.primaryButtonTextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Full-width outlined secondary button for Servana, designed to appear on both
/// dark (welcome screen) and light (in-app settings) backgrounds.
///
/// Supply [darkSurface] = true when rendering on a dark/image background so the
/// text and border are rendered in white instead of the brand dark colour.
class ServanaOutlinedButton extends StatelessWidget {
  const ServanaOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.darkSurface = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool darkSurface;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = darkSurface ? Colors.white : ColorPalette.primaryColorDark;
    final border = darkSurface
        ? const Color(0xAAFFFFFF)
        : ColorPalette.primaryColor.withOpacity(.6);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: FontPalette.primaryButtonTextFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
