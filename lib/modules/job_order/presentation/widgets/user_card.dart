import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/presentation/widgets/app_image.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.name,
    required this.address,
    this.onChatTap,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;
  final String address;
  final void Function()? onChatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                radius: 100,
                backgroundImage: appImageProvider(photoUrl),
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
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
                Text(
                  address,
                  maxLines: 5,
                  style: TextStyle(
                    color: ColorPalette.accentText,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Chat with provider',
            onPressed: onChatTap,
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: ColorPalette.primaryColorDark,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
