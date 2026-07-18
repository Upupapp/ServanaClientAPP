import 'package:configurable_expansion_tile_null_safety/configurable_expansion_tile_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/helpers/location_helper.dart';

class OptionListTileWidget extends StatelessWidget {
  const OptionListTileWidget({
    super.key,
    required this.optionGroupName,
    required this.optionItems,
    this.onTapSort,
    this.onItemOrdinalUpdated,
    required this.size,
  });

  final String optionGroupName;
  final Size size;
  final List<SelectionOptionItem> optionItems;
  final void Function(String value)? onTapSort;
  final void Function(int oldIndex, int newIndex, String value)?
      onItemOrdinalUpdated;

  @override
  Widget build(BuildContext context) {
    return ConfigurableExpansionTile(
      initiallyExpanded: false,
      header: (bool isExpanded,
          Animation<double> iconTurns,
          Animation<double> heightFactor,
          ConfigurableExpansionTileController controller) {
        return Container(
          width: size.width,
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      optionGroupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ColorPalette.secondaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${optionItems.length} item${(optionItems.length > 1) ? 's' : ''}",
                      style: TextStyle(
                        color: ColorPalette.accentText,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(10),
              RotatedBox(
                quarterTurns: isExpanded ? 1 : 3,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 38,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
            ],
          ),
        );
      },
      childrenBody: Padding(
        padding: const EdgeInsets.only(left: 11, right: 10, top: 10),
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
                    Expanded(
                      child: Text(
                        optionItems[index].merchantOptionItemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorPalette.accentText,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Text(
                      LocationHelper.localizedPrice(
                          optionItems[index].amount.toDouble()),
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
    );
  }
}
