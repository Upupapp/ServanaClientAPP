import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:flutter/material.dart';

class CategoryQuickActionsSliver extends StatelessWidget {
  final List<CategoryFilterChip> chips;
  final String? selectedLabel;
  final Color accentColor;
  final ValueChanged<String?> onChipSelected;

  const CategoryQuickActionsSliver({
    super.key,
    required this.chips,
    required this.selectedLabel,
    required this.accentColor,
    required this.onChipSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.length <= 1) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ChipBarDelegate(
        chips: chips,
        selectedLabel: selectedLabel,
        accentColor: accentColor,
        onChipSelected: onChipSelected,
      ),
    );
  }
}

class _ChipBarDelegate extends SliverPersistentHeaderDelegate {
  final List<CategoryFilterChip> chips;
  final String? selectedLabel;
  final Color accentColor;
  final ValueChanged<String?> onChipSelected;

  const _ChipBarDelegate({
    required this.chips,
    required this.selectedLabel,
    required this.accentColor,
    required this.onChipSelected,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 52,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final selected =
              (selectedLabel ?? 'All') == chip.label;
          return Semantics(
            button: true,
            selected: selected,
            label: chip.label,
            child: GestureDetector(
              onTap: () => onChipSelected(selected ? null : chip.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? accentColor
                      : accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? accentColor
                        : accentColor.withOpacity(0.2),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  chip.label,
                  style: TextStyle(
                    color: selected ? Colors.white : accentColor,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_ChipBarDelegate old) =>
      old.selectedLabel != selectedLabel ||
      old.accentColor != accentColor ||
      old.chips.length != chips.length;
}
