/// Subcategory → its Services.
///
/// Step three, and the point at which the customer selects a canonical
/// `services.id`. Everything downstream — Service Detail, the booking draft,
/// the booking payload, provider matching — carries that same integer.
library;

import 'package:flutter/material.dart';

import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:client/modules/catalog/presentation/widgets/catalog_widgets.dart';

class SubcategoryScreen extends StatefulWidget {
  const SubcategoryScreen({
    super.key,
    required this.controller,
    required this.subcategoryId,
    required this.onServiceSelected,
  });

  final CatalogController controller;
  final int subcategoryId;

  /// Receives the whole Service so the caller routes on `service.id` and never
  /// has to reconstruct identity from a name (§35).
  final void Function(CatalogService service) onServiceSelected;

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
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
        final sub = controller.subcategoryById(widget.subcategoryId);
        final category =
            sub == null ? null : controller.categoryById(sub.categoryId);

        return Scaffold(
          appBar: AppBar(
            title: Text(sub?.name ?? 'Services'),
            bottom: category == null
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(24),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CatalogBreadcrumb(
                          categoryName: category.name,
                          subcategoryName: sub!.name,
                        ),
                      ),
                    ),
                  ),
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (sub == null) {
                  if (controller.isLoading) return const CatalogLoadingView();
                  if (controller.status == CatalogLoadStatus.failure) {
                    return CatalogErrorView(onRetry: controller.refresh);
                  }
                  return const CatalogEmptyView(
                    message: 'This category is no longer available.',
                  );
                }

                if (sub.services.isEmpty) {
                  return CatalogEmptyView(
                    message: 'No services are listed under ${sub.name} yet.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: sub.services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => ServiceCard(
                      service: sub.services[index],
                      onTap: widget.onServiceSelected,
                    ),
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
