import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:client/common/constants/color_palette.dart';

class InfoDialog {
  static void showDialog({
    required BuildContext context,
    required String msg,
    required String title,
    void Function()? onConfirm,
    void Function()? onCancel,
  }) {
    Dialogs.bottomMaterialDialog(
        msg: msg,
        title: title,
        context: context,
        actions: [
          IconsButton(
            onPressed: () {
              onConfirm?.call();
              context.pop();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            text: 'Ok',
            color: ColorPalette.primaryColor,
            textStyle: TextStyle(color: ColorPalette.primaryButtonTextColor),
            iconColor: ColorPalette.primaryButtonTextColor,
          ),
        ]);
  }
}
