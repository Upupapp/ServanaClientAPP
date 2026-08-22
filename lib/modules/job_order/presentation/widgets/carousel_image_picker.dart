import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:gap/gap.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:client/common/constants/color_palette.dart';

class CarouselImagePicker extends StatelessWidget {
  const CarouselImagePicker({
    super.key,
    this.onImagePicked,
  });

  final void Function(CroppedFile file)? onImagePicked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final ImagePicker picker = ImagePicker();
        final aspectFraction = Fraction.fromDouble(3 / 4);

        // ignore: unused_local_variable
        // Bounded at the picker, before the bytes are ever read.
        //
        // This used to be a bare `pickImage()`: a current phone hands
        // back a 12MP frame of 3-8 MB, which was then cropped and
        // uploaded whole. The bounds below are the cheapest possible
        // saving — the full frame is never decoded into memory at all —
        // and `UploadCompressor` still governs what finally goes out.
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2000,
          maxHeight: 2000,
          imageQuality: 88,
        );

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
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: 'Crop Image',
                aspectRatioLockEnabled: true,
                resetButtonHidden: true,
                rotateButtonsHidden: true,
                rotateClockwiseButtonHidden: true,
                aspectRatioPickerButtonHidden: true,
              ),
            ],
          );

          if (croppedFile != null) {
            onImagePicked?.call(croppedFile);
          }
        }
      },
      child: Container(
        width: 250,
        height: 300,
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBorder,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_rounded,
              color: ColorPalette.accentText,
              size: 50,
            ),
            const Gap(10),
            Text(
              "Add Photo",
              style: TextStyle(
                color: ColorPalette.accentText,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            )
          ],
        ),
      ),
    );
  }
}
