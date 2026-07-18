import 'package:flutter/material.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';

class PrimaryButton extends StatelessWidget {
  final void Function()? onClick;
  final String? text;
  final bool enabled;
  final double? height;
  final double? width;
  final Widget? leading;
  final Widget? trailing;

  const PrimaryButton({
    super.key,
    this.onClick,
    this.text,
    this.enabled = true,
    this.height = 50,
    this.width = 105,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onClick,
      style: TextButton.styleFrom(
        backgroundColor: ColorPalette.primaryColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(50),
          ),
        ),
        minimumSize: Size(width!, height!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? const SizedBox.shrink(),
          Text(
            text ?? '',
            style: TextStyle(
              fontFamily: FontPalette.primaryButtonTextFontFamily,
              color: ColorPalette.primaryButtonTextColor,
              fontSize: 15,
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
