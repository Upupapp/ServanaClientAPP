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
        height: 120,
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
