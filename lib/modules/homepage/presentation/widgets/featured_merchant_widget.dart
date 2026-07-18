import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class FeaturedMerchantWidget extends StatelessWidget {
  final String imageURL;
  final String? heroKey;
  final void Function()? onTap;
  const FeaturedMerchantWidget({
    super.key,
    required this.imageURL,
    this.onTap,
    this.heroKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 6 / 4,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorPalette.secondaryColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                clipBehavior: Clip.antiAlias,
                child: Hero(
                  tag: "merchantListImage_${heroKey ?? imageURL}",
                  child: AppImage(
                    url: imageURL,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const Gap(5),
            Text(
              "Title",
              maxLines: 4,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.secondaryText,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
            Row(
              children: [
                Text(
                  "1.5km ●",
                  maxLines: 4,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 13,
                  ),
                ),
                Icon(
                  Icons.star,
                  color: ColorPalette.primaryColor,
                  size: 20,
                ),
                const Gap(3),
                Text(
                  "4.5",
                  maxLines: 4,
                  style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
