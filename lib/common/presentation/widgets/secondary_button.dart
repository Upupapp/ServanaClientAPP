import 'package:flutter/material.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:gap/gap.dart';

class SecondaryButton extends StatelessWidget {
  final void Function()? onClick;
  final String? text;
  final bool enabled;
  final double height;
  final double borderRadius;
  final double width;
  final Widget? leading;
  final Widget? trailing;
  final Color? forgroundColor;

  const SecondaryButton({
    super.key,
    this.onClick,
    this.text,
    this.enabled = true,
    this.height = 50,
    this.width = 105,
    this.leading,
    this.trailing,
    this.borderRadius = 50,
    this.forgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onClick,
      style: TextButton.styleFrom(
        backgroundColor: ColorPalette.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(borderRadius),
          ),
        ),
        minimumSize: Size(width, height),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const Gap(5),
          ],
          Text(
            text ?? '',
            style: TextStyle(
              fontFamily: FontPalette.primaryButtonTextFontFamily,
              color: forgroundColor ?? ColorPalette.primaryButtonTextColor,
              fontSize: 15,
            ),
          ),
          if (trailing != null) ...[
            const Gap(5),
            trailing!,
          ],
        ],
      ),
    );
  }
}
