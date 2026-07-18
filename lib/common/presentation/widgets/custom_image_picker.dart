import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/common/constants/color_palette.dart';

class CustomImagePicker extends StatelessWidget {
  const CustomImagePicker({
    super.key,
    this.aspectRation = 1,
    this.onImagePicked,
    this.value,
    this.source = ImageSource.gallery,
    this.lockAspectRation = true,
    this.error,
  });

  final void Function(XFile file)? onImagePicked;
  final XFile? value;
  final String? error;
  final ImageSource source;
  final bool lockAspectRation;
  final double aspectRation;

  @override
  Widget build(BuildContext context) {
    final ColorScheme themeColor = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final ImagePicker picker = ImagePicker();
        final aspectFraction = Fraction.fromDouble(aspectRation);

        // ignore: unused_local_variable
        final XFile? image = await picker.pickImage(source: source);

        if (image != null) {
          CroppedFile? croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            aspectRatio: CropAspectRatio(
              ratioX: aspectFraction.numerator.toDouble(),
              ratioY: aspectFraction.denominator.toDouble(),
            ),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Image',
                toolbarColor: ColorPalette.primaryColorDark,
                toolbarWidgetColor: ColorPalette.secondaryAccentColor,
                activeControlsWidgetColor: ColorPalette.primaryColorDark,
                hideBottomControls: true,
                lockAspectRatio: lockAspectRation,
              ),
              IOSUiSettings(
                title: 'Crop Image',
                aspectRatioLockEnabled: lockAspectRation,
                resetButtonHidden: true,
                rotateButtonsHidden: true,
                rotateClockwiseButtonHidden: true,
                aspectRatioPickerButtonHidden: true,
              ),
            ],
          );

          if (croppedFile != null) {
            onImagePicked?.call(XFile(croppedFile.path));
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: aspectRation,
            child: Container(
              decoration: BoxDecoration(
                color: (error != null)
                    ? themeColor.errorContainer
                    : ColorPalette.primaryColorLight,
                borderRadius: BorderRadius.circular(15),
                border: (error != null)
                    ? Border.all(
                        color: themeColor.error,
                        width: 1,
                      )
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: value != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: Image.file(File(value!.path)),
                      )
                    : Center(
                        child: Image.asset(
                          "assets/images/image_icon.png",
                          fit: BoxFit.contain,
                          height: 60,
                        ),
                      ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(
              height: 5,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 10,
                ),
                Text(
                  error!,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: themeColor.error,
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
