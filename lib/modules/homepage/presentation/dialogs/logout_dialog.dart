import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:client/common/constants/color_palette.dart';

class LogoutDialog {
  static void showDialog({
    required BuildContext context,
    void Function()? onConfirm,
    void Function()? onCancel,
  }) {
    Dialogs.bottomMaterialDialog(
        msg: 'Are you sure you want to logout?',
        title: 'Logout',
        context: context,
        actions: [
          IconsButton(
            onPressed: () {
              onCancel?.call();
              context.pop();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            text: 'Cancel',
            color: ColorPalette.secondaryColor,
            textStyle: TextStyle(color: ColorPalette.primaryButtonTextColor),
            iconColor: ColorPalette.primaryButtonTextColor,
          ),
          IconsButton(
            onPressed: () {
              onConfirm?.call();
              context.pop();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            text: 'Logout',
            iconData: Icons.logout_rounded,
            color: ColorPalette.primaryColor,
            textStyle: TextStyle(color: ColorPalette.primaryButtonTextColor),
            iconColor: ColorPalette.primaryButtonTextColor,
          ),
        ]);
  }
}
