import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';

class PaymentMethodCard extends StatefulWidget {
  const PaymentMethodCard({
    super.key,
    this.onToggle,
    this.value = false,
    required this.name,
    required this.icon,
  });
  final String name;
  final Widget icon;
  final bool value;
  final void Function(bool value)? onToggle;

  @override
  State<PaymentMethodCard> createState() => _AssignEmployeeListCardState();
}

class _AssignEmployeeListCardState extends State<PaymentMethodCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: ColorPalette.primaryColorLight,
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 8,
          ),
          widget.icon,
          const Gap(15),
          Text(
            widget.name,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.bold,
              color: ColorPalette.accentText,
              fontSize: 17,
            ),
          ),
          const Spacer(),
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
        ],
      ),
    );
  }
}
