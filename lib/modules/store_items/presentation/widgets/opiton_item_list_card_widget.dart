import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';

class OptionItemListCard extends StatefulWidget {
  const OptionItemListCard({
    super.key,
    required this.title,
    required this.subTitle,
    this.onToggle,
    this.value = false,
  });
  final String title;
  final String subTitle;
  final bool value;
  final void Function(bool value)? onToggle;

  @override
  State<OptionItemListCard> createState() => _OptionItemListCardState();
}

class _OptionItemListCardState extends State<OptionItemListCard> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 25,
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: ColorPalette.secondaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(3),
              Text(
                widget.subTitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.accentText,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
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
        const Gap(20),
      ],
    );
  }
}
