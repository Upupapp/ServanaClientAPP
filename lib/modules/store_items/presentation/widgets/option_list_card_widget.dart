import 'package:configurable_expansion_tile_null_safety/configurable_expansion_tile_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';

class OptionListCardWidget extends StatelessWidget {
  const OptionListCardWidget({
    super.key,
    required this.optionGroupName,
    required this.optionItems,
    this.onTapSort,
    this.onItemOrdinalUpdated,
    required this.size,
  });

  final String optionGroupName;
  final Size size;
  final List<StoreOptionItem> optionItems;
  final void Function(String value)? onTapSort;
  final void Function(int oldIndex, int newIndex, String value)?
      onItemOrdinalUpdated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ConfigurableExpansionTile(
        initiallyExpanded: false,
        header: (bool isExpanded,
            Animation<double> iconTurns,
            Animation<double> heightFactor,
            ConfigurableExpansionTileController controller) {
          return Container(
            width: size.width,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    RotatedBox(
                      quarterTurns: isExpanded ? 1 : 3,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 38,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        optionGroupName,
                        maxLines: 1,
                        style: TextStyle(
                          color: ColorPalette.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Gap(15),
                    Text(
                      "Edit",
                      style: TextStyle(
                        color: ColorPalette.primaryColorDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(10),
                  ],
                ),
                Row(
                  children: [
                    const Gap(50),
                    Text(
                      "${optionItems.length} item${(optionItems.length > 1) ? 's' : ''}",
                      style: TextStyle(
                        color: ColorPalette.accentText,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        childrenBody: Padding(
          padding:
              const EdgeInsets.only(left: 60, right: 20, top: 10, bottom: 5),
          child: ReorderableListView.builder(
            onReorder: (int oldIndex, int newIndex) {
              onItemOrdinalUpdated?.call(oldIndex, newIndex, optionGroupName);
            },
            buildDefaultDragHandles: false,
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            itemCount: optionItems.length,
            proxyDecorator: (child, index, animation) => Material(
              color: ColorPalette.transparent,
              child: child,
            ),
            itemBuilder: (BuildContext context, int index) {
              return ReorderableDragStartListener(
                index: index,
                key: Key("${optionItems[index].hashCode}"),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Text(
                        optionItems[index].merchantOptionItemName,
                        style: TextStyle(
                          color: ColorPalette.accentText,
                          fontSize: 17,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Php 99",
                        style: TextStyle(
                          color: ColorPalette.accentText,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
