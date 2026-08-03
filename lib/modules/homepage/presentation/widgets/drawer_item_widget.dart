import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';

class DrawerItemWidget extends StatelessWidget {
  final String title;
  final String? iconFile;
  final void Function()? onTap;
  const DrawerItemWidget({
    super.key,
    required this.title,
    this.iconFile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: iconFile != null
          ? ImageIcon(
              AssetImage(iconFile!),
              size: 22,
              color: ColorPalette.primaryColorDark,
              semanticLabel: '',
            )
          : const SizedBox.square(
              dimension: 25,
            ),
      title: Text(
        title,
        maxLines: 4,
        style: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          color: ColorPalette.secondaryText,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: ColorPalette.primaryColorDark,
        size: 20,
      ),
    );
  }
}
