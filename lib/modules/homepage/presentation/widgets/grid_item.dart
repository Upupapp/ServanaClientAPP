import 'package:flutter/material.dart';
import 'package:client/common/constants/color_palette.dart';

class DashBoardGridItem extends StatelessWidget {
  final Widget? icon;
  final String? label;
  final void Function()? onTap;

  const DashBoardGridItem({super.key, this.icon, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: icon,
              ),
            ),
            if (label != null) ...[
              const SizedBox(
                height: 5,
              ),
              Text(
                label ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: ColorPalette.secondaryText,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
