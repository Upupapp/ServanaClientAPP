import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/presentation/widgets/app_image.dart';

class MenuItemWidget extends StatelessWidget {
  final void Function()? onTap;

  final MerchantServiceModel item;
  final bool isOrdinalEditMode;
  final Function(int id, bool value)? onItemToggled;

  const MenuItemWidget({
    super.key,
    this.onTap,
    required this.item,
    this.isOrdinalEditMode = false,
    this.onItemToggled,
  });

  @override
  Key? get key => Key("${item.hashCode}");

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      // No fixed height, and the thumbnail no longer derives its size from one.
      //
      // This started as SizedBox(height: 120) around text that scales, so the
      // row clipped its own content. Scaling that height did not work either:
      // the thumbnail was an AspectRatio(1) OF THE ROW HEIGHT, so the image
      // grew with the text and a 240px square swallowed a 320px handset.
      // Capping the height brought the clipping back at 2.0, because the text
      // still needed more room than the cap allowed.
      //
      // The two were coupled and had to be separated: the thumbnail is now a
      // fixed 120 square, and the row takes whatever height its tallest child
      // needs. A list row growing with the text is correct; a thumbnail
      // growing with it is not.
      child: SizedBox(
        width: double.maxFinite,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: AppImage(
                url: item.merchantServicePictureURL,
                fit: BoxFit.cover,
              ),
            ),
            const Gap(10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.merchantServiceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  // ignore: unnecessary_null_comparison
                  if (item.merchantServiceDescription != null) ...[
                    Text(
                      item.merchantServiceDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ColorPalette.accentText,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Gap(5),
                  ],
                  Text(
                    item.amount.toStringAsFixed(2),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
