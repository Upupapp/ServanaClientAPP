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
      child: SizedBox(
        width: double.maxFinite,
        // Scaled, not fixed. The name, description and price inside all grow
        // with the text scale while 120 did not, so the row clipped its own
        // content at 1.3. This widget is used by three screens.
        // Scaled but CAPPED. The row contains an AspectRatio(1) image, so
        // height and width grow together — at text scale 2.0 an uncapped 240
        // is a 240px square on a 320px handset, which pushes the whole screen
        // over. 180 gives the text the room it needs without letting the
        // thumbnail eat the row.
        height: MediaQuery.textScalerOf(context).scale(120).clamp(120.0, 180.0),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
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
