import 'package:client/modules/job_order/presentation/screens/job_order_screen.dart';
import 'package:client/modules/job_order/presentation/widgets/bedroom_selector_bottom_sheet.dart';
import 'package:configurable_expansion_tile_null_safety/configurable_expansion_tile_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/modules/store_items/presentation/widgets/store_item_widget.dart';
import 'package:go_router/go_router.dart';

class CategoryTileWidget extends StatelessWidget {
  const CategoryTileWidget({
    super.key,
    required this.screenSize,
    required this.categoryName,
    required this.categoryId,
    required this.items,
    this.isInSortMode = false,
    this.onTapSort,
    this.onItemOrdinalUpdated,
    this.onItemToggled,
    this.onCategoryEdit,
    required this.merchantId,
    required this.merchantName,
  });

  final Size screenSize;
  final String categoryName;
  final String merchantId;
  final String merchantName;
  final int categoryId;
  final bool isInSortMode;
  final List<MerchantServiceModel> items;
  final void Function(String value)? onTapSort;
  final void Function()? onCategoryEdit;
  final void Function(int oldIndex, int newIndex, String value)?
      onItemOrdinalUpdated;
  final void Function(int itemId, int categoryId, bool value)? onItemToggled;

  @override
  Widget build(BuildContext context) {
    return ConfigurableExpansionTile(
      initiallyExpanded: true,
      header: (bool isExpanded,
          Animation<double> iconTurns,
          Animation<double> heightFactor,
          ConfigurableExpansionTileController controller) {
        return Container(
          width: screenSize.width,
          padding: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: ColorPalette.primaryColorLight,
          ),
          child: Row(
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
              Text(
                categoryName,
                style: TextStyle(
                  color: ColorPalette.accentText,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      childrenBody: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
        child: isInSortMode
            ? ReorderableListView.builder(
                onReorder: (int oldIndex, int newIndex) {
                  onItemOrdinalUpdated?.call(oldIndex, newIndex, categoryName);
                },
                buildDefaultDragHandles: false,
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                itemCount: items.length,
                proxyDecorator: (child, index, animation) => Material(
                  color: ColorPalette.transparent,
                  child: child,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return ReorderableDragStartListener(
                    index: index,
                    key: Key("${items[index].hashCode}"),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: StoreItemCardWidget(
                        item: items[index],
                        isOrdinalEditMode: isInSortMode,
                      ),
                    ),
                  );
                },
              )
            : Column(
                children: List.generate(
                  items.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: StoreItemCardWidget(
                      item: items[index],
                      onItemToggled: (id, value) {
                        onItemToggled?.call(id, categoryId, value);
                      },
                      onTap: () async {
                        final result = await BedroomSelectorBottomSheet.show(
                          context,
                          service: items[index],
                        );
                        if (result != null && context.mounted) {
                          context.goNamed(
                            JobOrderScreen.routeName,
                            extra: items[index],
                            pathParameters: {
                              "id": merchantId,
                              "name": merchantName,
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
