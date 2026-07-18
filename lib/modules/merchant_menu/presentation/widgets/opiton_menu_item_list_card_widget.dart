import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';

class OptionMenuItemListCard extends StatefulWidget {
  const OptionMenuItemListCard({
    super.key,
    required this.title,
    required this.price,
    this.onToggle,
    this.value = false,
  });
  final String title;
  final double price;
  final bool value;
  final void Function(bool value)? onToggle;

  @override
  State<OptionMenuItemListCard> createState() => _OptionMenuItemListCardState();
}

class _OptionMenuItemListCardState extends State<OptionMenuItemListCard> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            widget.onToggle?.call(!widget.value);
          },
          child: Theme(
            data: Theme.of(context).copyWith(
              unselectedWidgetColor: ColorPalette.secondaryAccentColor,
            ),
            child: Transform.scale(
              scale: 1.3,
              child: Checkbox(
                value: widget.value,
                checkColor: ColorPalette.primaryText,
                activeColor: ColorPalette.primaryColor,
                shape: const CircleBorder(),
                onChanged: (value) {
                  widget.onToggle?.call(!widget.value);
                },
              ),
            ),
          ),
        ),
        Text(
          widget.title,
          style: TextStyle(
            color: ColorPalette.secondaryText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          "${(widget.price > 0) ? '+' : ''}${widget.price.toStringAsFixed(2)}",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: ColorPalette.accentText,
            fontSize: 18,
          ),
        ),
        const Gap(20),
      ],
    );
  }
}
