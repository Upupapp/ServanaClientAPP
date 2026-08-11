/// Category → its Subcategories.
///
/// Step two. Reads from the already-loaded tree, so selecting a Category is
/// instant and cannot race (§96) — the whole hierarchy arrived in one fetch.
///
/// A Category reached by deep link before the catalog has loaded triggers the
/// load itself rather than showing an empty screen.
library;

import 'package:flutter/material.dart';

import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/presentation/widgets/catalog_widgets.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
    required this.controller,
    required this.categoryId,
    required this.onSubcategorySelected,
  });

  final CatalogController controller;
  final int categoryId;
  final void Function(int subcategoryId) onSubcategorySelected;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.catalog.isEmpty) widget.controller.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final category = controller.categoryById(widget.categoryId);

        return Scaffold(
          appBar: AppBar(title: Text(category?.name ?? 'Services')),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (category == null) {
                  if (controller.isLoading) return const CatalogLoadingView();
                  if (controller.status == CatalogLoadStatus.failure) {
                    return CatalogErrorView(onRetry: controller.refresh);
                  }
                  // Loaded, but this id is not in the visible catalog — it was
                  // archived or deactivated since the link was made.
                  return const CatalogEmptyView(
                    message: 'This category is no longer available.',
                  );
                }

                if (category.subcategories.isEmpty) {
                  return CatalogEmptyView(
                    message:
                        'No services are listed under ${category.name} yet.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: category.subcategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sub = category.subcategories[index];
                      return CatalogGroupCard(
                        title: sub.name,
                        subtitle: sub.description,
                        serviceCount: sub.serviceCount,
                        kindLabel: 'Subcategory',
                        onTap: () => widget.onSubcategorySelected(sub.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
