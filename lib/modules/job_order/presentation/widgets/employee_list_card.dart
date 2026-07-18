import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/presentation/widgets/app_image.dart';

class EmployeeListCard extends StatelessWidget {
  const EmployeeListCard({
    super.key,
    required this.name,
    this.position,
    this.contactNo,
    this.onTap,
    this.photoUrl,
  });

  final String name;
  final String? position;
  final String? contactNo;
  final String? photoUrl;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              height: 70,
              child: AspectRatio(
                aspectRatio: 1,
                child: CircleAvatar(
                  backgroundImage: appImageProvider(photoUrl),
                ),
              ),
            ),
            const Gap(10),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: ColorPalette.secondaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(1),
                if (position != null) ...[
                  Text(
                    position!,
                    style: TextStyle(
                      color: ColorPalette.accentText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(3),
                ],
                if (contactNo != null)
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/phone.png",
                        height: 20,
                        color: ColorPalette.primaryColorDark,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const Gap(5),
                      Text(
                        contactNo!,
                        style: TextStyle(
                          color: ColorPalette.accentText,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
