/// Catalog root — Categories.
///
/// Step one of `Category → Subcategory → Service`. Ordering is the backend's
/// `displayOrder` with a name tie-break, applied server-side; this screen does
/// not re-sort (§57).
library;

import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/presentation/widgets/catalog_widgets.dart';

class CatalogBrowseScreen extends StatefulWidget {
  const CatalogBrowseScreen({
    super.key,
    required this.controller,
    required this.onCategorySelected,
  });

  final CatalogController controller;
  final void Function(int categoryId) onCategorySelected;

  @override
  State<CatalogBrowseScreen> createState() => _CatalogBrowseScreenState();
}

class _CatalogBrowseScreenState extends State<CatalogBrowseScreen> {
  @override
  void initState() {
    super.initState();
    // Post-frame so a synchronous cache hit cannot notify listeners during the
    // first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;

            if (controller.status == CatalogLoadStatus.loading) {
              return const CatalogLoadingView();
            }
            if (controller.status == CatalogLoadStatus.failure) {
              return CatalogErrorView(onRetry: controller.refresh);
            }
            if (controller.status == CatalogLoadStatus.empty) {
              return const CatalogEmptyView(
                message: 'No services are available right now.',
              );
            }

            final categories = controller.catalog.categories;
            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: categories.length +
                    (controller.isShowingCachedData ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (controller.isShowingCachedData && index == 0) {
                    return const _CachedNotice();
                  }
                  final category = categories[
                      index - (controller.isShowingCachedData ? 1 : 0)];
                  return CatalogGroupCard(
                    title: category.name,
                    subtitle: category.description,
                    serviceCount: category.serviceCount,
                    onTap: () => widget.onCategorySelected(category.id),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Says plainly that this is saved data. Booking still revalidates against the
/// backend, so this is an honesty affordance rather than a warning (§49).
class _CachedNotice extends StatelessWidget {
  const _CachedNotice();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 16, color: ColorPalette.accentText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Showing saved services. Pull to refresh.',
                  style:
                      TextStyle(fontSize: 12, color: ColorPalette.accentText),
                ),
              ),
            ],
          ),
        ),
      );
}
