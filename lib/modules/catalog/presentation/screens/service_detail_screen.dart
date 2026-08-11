/// Service Detail — centred on one canonical `services.id`.
///
/// This is where identity has to be right. The Service shown, the Service put
/// into the booking draft and the Service the backend matches a provider
/// against are the same integer, and it is the one in the route.
///
/// Four terminal states, all of them honest:
///  - success       — bookable, CTA enabled
///  - unavailable   — the row resolved but the backend says it cannot be booked
///                    (archived, deactivated, or under a deactivated parent).
///                    Never silently redirected to some other Service (§54).
///  - notFound      — the id does not exist at all
///  - failure       — the request failed; retry offered, no auto-retry loop
library;

import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/presentation/widgets/service_thumbnail.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/catalog/application/service_detail_controller.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:client/modules/catalog/presentation/widgets/catalog_widgets.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({
    super.key,
    required this.controller,
    required this.serviceId,
    required this.onStartBooking,
  });

  final ServiceDetailController controller;

  /// Canonical `services.id`.
  final int serviceId;

  /// Called with the resolved Service and the selected add-on ids. The caller
  /// owns booking-flow routing; this screen owns identity and configuration.
  final void Function(CatalogServiceDetail detail, Set<int> addonIds)
      onStartBooking;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.load(widget.serviceId);
    });
  }

  @override
  void didUpdateWidget(covariant ServiceDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceId != widget.serviceId) {
      widget.controller.load(widget.serviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final detail = controller.detail;
        final service = detail?.service ?? controller.preview;

        return Scaffold(
          appBar: AppBar(title: Text(service?.name ?? 'Service')),
          // The CTA lives in a safe-area-aware bottom bar so it can never sit
          // under the gesture inset or a bottom navigation bar (§80).
          bottomNavigationBar: detail == null
              ? null
              : _BookingBar(
                  controller: controller,
                  onStartBooking: () {
                    AppHaptics.selection();
                    widget.onStartBooking(detail, controller.selectedAddonIds);
                  }),
          body: SafeArea(
            child: switch (controller.status) {
              ServiceDetailStatus.idle ||
              ServiceDetailStatus.loading =>
                const CatalogLoadingView(label: 'Loading service'),
              ServiceDetailStatus.failure => CatalogErrorView(
                  onRetry: () => controller.load(widget.serviceId),
                  message: 'Unable to load this service.',
                ),
              ServiceDetailStatus.notFound => const CatalogEmptyView(
                  message: 'This service is currently unavailable.',
                ),
              ServiceDetailStatus.unavailable ||
              ServiceDetailStatus.success =>
                _DetailBody(controller: controller),
            },
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.controller});

  final ServiceDetailController controller;

  @override
  Widget build(BuildContext context) {
    final detail = controller.detail!;
    final service = detail.service;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            serviceImageAsset(service.name),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: 14),
        CatalogBreadcrumb(
          categoryName: service.categoryName,
          subcategoryName: service.subcategoryName,
        ),
        const SizedBox(height: 6),
        // Heading semantics so a screen reader can jump here.
        Semantics(
          header: true,
          child: Text(
            service.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ColorPalette.onSurface,
            ),
          ),
        ),
        if (!detail.available) ...[
          const SizedBox(height: 12),
          const _UnavailableNotice(),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              service.basePriceSummary ?? 'Get a quote',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColorPalette.primaryColorDark,
              ),
            ),
            if (service.estimatedDurationMins != null)
              Text(
                'About ${service.estimatedDurationMins} min',
                style: TextStyle(fontSize: 13, color: ColorPalette.accentText),
              ),
          ],
        ),
        if (service.shortDescription != null) ...[
          const SizedBox(height: 12),
          Text(service.shortDescription!,
              style: TextStyle(fontSize: 15, color: ColorPalette.onSurface)),
        ],
        if (detail.fullDescription != null) ...[
          const SizedBox(height: 10),
          Text(detail.fullDescription!,
              style: TextStyle(fontSize: 14, color: ColorPalette.accentText)),
        ],
        _BulletSection(title: "What's included", items: detail.inclusions),
        _BulletSection(title: 'Not included', items: detail.exclusions),
        if (detail.addons.isNotEmpty) ...[
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              'Add-ons',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorPalette.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            // Names the relationship explicitly. An add-on is configuration
            // beneath this Service, never an alternative Service (§70).
            'Optional extras for ${service.name}.',
            style: TextStyle(fontSize: 13, color: ColorPalette.accentText),
          ),
          const SizedBox(height: 8),
          for (final addon in detail.addons)
            _AddonTile(
              addon: addon,
              selected: controller.selectedAddonIds.contains(addon.id),
              enabled: detail.available,
              onToggle: () {
                AppHaptics.selection();
                controller.toggleAddon(addon.id);
              },
            ),
        ],
      ],
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice();

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorPalette.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: ColorPalette.danger),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This service is currently unavailable.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ColorPalette.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: ColorPalette.accentText)),
                Expanded(
                  child: Text(
                    item,
                    style:
                        TextStyle(fontSize: 14, color: ColorPalette.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AddonTile extends StatelessWidget {
  const _AddonTile({
    required this.addon,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final CatalogAddon addon;
  final bool selected;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final price = addon.basePriceSummary;
    return Semantics(
      // A checkbox, not a button: selection state must be announced, and
      // `selected` is what conveys it without relying on colour alone.
      inMutuallyExclusiveGroup: false,
      checked: selected,
      enabled: enabled,
      label: [addon.name, if (price != null) price].join(', '),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: CheckboxListTile(
          value: selected,
          onChanged: enabled ? (_) => onToggle() : null,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(addon.name,
              style: TextStyle(fontSize: 15, color: ColorPalette.onSurface)),
          subtitle: price == null
              ? null
              : Text(price,
                  style:
                      TextStyle(fontSize: 13, color: ColorPalette.accentText)),
        ),
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.controller, required this.onStartBooking});

  final ServiceDetailController controller;
  final VoidCallback onStartBooking;

  @override
  Widget build(BuildContext context) {
    final total = controller.estimatedTotal;
    final canBook = controller.canStartBooking;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (total != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Estimated total',
                      style: TextStyle(
                          fontSize: 11, color: ColorPalette.accentText)),
                  Text(
                    '₱${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: FilledButton(
                onPressed: canBook ? onStartBooking : null,
                child: Text(canBook ? 'Book now' : 'Unavailable'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
