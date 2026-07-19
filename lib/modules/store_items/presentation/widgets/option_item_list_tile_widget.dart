import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/store_items/presentation/widgets/confirm_option_item_delete_dialog.dart';

class OptionItemListTileWidget extends StatelessWidget {
  const OptionItemListTileWidget({
    super.key,
    this.onTapSort,
    this.onItemOrdinalUpdated,
    required this.size,
    required this.optionName,
    required this.optionPrice,
    this.onTapDelete,
  });

  final String optionName;
  final String optionPrice;
  final Size size;
  final void Function(String value)? onTapSort;
  final void Function()? onTapDelete;
  final void Function(int oldIndex, int newIndex, String value)?
      onItemOrdinalUpdated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            optionName,
            style: TextStyle(
              color: ColorPalette.secondaryText,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            optionPrice,
            style: TextStyle(
              color: ColorPalette.accentText,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Gap(15),
          InkWell(
            onTap: () {
              ConfirmOptionItemDeleteDialog.showDialog(
                context: context,
                onConfirm: () {
                  onTapDelete?.call();
                },
              );
            },
            child: const Icon(
              Icons.delete,
              size: 25,
              color: ColorPalette.danger,
            ),
          ),
          const Gap(10),
        ],
      ),
    );
  }
}
