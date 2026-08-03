import 'package:flutter/material.dart';
import 'package:client/common/constants/color_palette.dart';

class ChipContainer extends StatelessWidget {
  const ChipContainer({
    super.key,
    this.isSelected = false,
    required this.imageIcon,
    this.onTap,
    this.padding =
        const EdgeInsets.only(top: 10, bottom: 7, right: 10, left: 10),
    this.size = 18,
    this.semanticLabel,
  });

  final bool isSelected;
  final String imageIcon;
  final double size;
  final EdgeInsets padding;
  final void Function()? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected
                  ? ColorPalette.primaryColor
                  : ColorPalette.secondaryAccentColor,
              width: 3,
            ),
          ),
          child: Center(
            child: Image.asset(
              imageIcon,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
