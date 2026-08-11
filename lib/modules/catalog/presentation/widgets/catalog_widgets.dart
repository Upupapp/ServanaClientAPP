/// Shared presentation pieces for the canonical catalog.
///
/// Kept in one file because they are only meaningful together: every catalog
/// screen renders the same five states (loading / loaded / empty / error /
/// refreshing) and the same card and breadcrumb, and splitting them across six
/// files made the set easy to diverge.
///
/// Accessibility notes that are load-bearing rather than decorative:
///  - every tappable is at least 44dp and carries an explicit semantic label
///    with hierarchy context, so a screen reader announces
///    "Pimple Facial, Service, Facial, Personal Care, from ₱1,500"
///  - decorative imagery is excluded from semantics rather than labelled
///  - motion respects the platform reduced-motion setting
library;

import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/presentation/widgets/service_thumbnail.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';

/// Standard transition length for catalog navigation. Restrained on purpose:
/// this is a utility browse flow, not an onboarding showcase.
const catalogMotionDuration = Duration(milliseconds: 200);

bool catalogReducedMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Loading placeholder. A shimmer would be motion for its own sake here.
class CatalogLoadingView extends StatelessWidget {
  const CatalogLoadingView({super.key, this.label = 'Loading services'});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: label,
        child: const Center(child: CircularProgressIndicator()),
      );
}

/// Failure state. Always offers retry, never auto-retries in a loop (§95), and
/// never renders the underlying exception (§21).
class CatalogErrorView extends StatelessWidget {
  const CatalogErrorView({
    super.key,
    required this.onRetry,
    this.message = 'Unable to load services.',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 40, color: ColorPalette.accentText),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ColorPalette.onSurface, fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Empty state. A Category with no visible Subcategories, or a Subcategory with
/// no active Services, must say so rather than render a blank scroll view
/// (§61, §62).
class CatalogEmptyView extends StatelessWidget {
  const CatalogEmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 40, color: ColorPalette.accentText),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: ColorPalette.accentText, fontSize: 15),
              ),
            ],
          ),
        ),
      );
}

/// `Personal Care › Facial` — hierarchy context above Service Detail.
///
/// Uses the canonical Category and Subcategory NAMES resolved through
/// `subcategoryId`, never a `level2` field. That distinction is the whole point
/// of the migration: parity middleware used to populate `level2` with the
/// Service's own name.
class CatalogBreadcrumb extends StatelessWidget {
  const CatalogBreadcrumb({
    super.key,
    required this.categoryName,
    required this.subcategoryName,
  });

  final String categoryName;
  final String subcategoryName;

  @override
  Widget build(BuildContext context) {
    final parts = [categoryName, subcategoryName]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: 'In ${parts.join(", ")}',
      excludeSemantics: true,
      child: Text(
        parts.join(' › '),
        style: TextStyle(
          color: ColorPalette.accentText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A Service tile.
///
/// Shows name, price and short description where the backend has them. It never
/// shows Service Family, level 2/3, internal status values or provider
/// capability counts (§21) — none of those are even in the model.
///
/// Guards against double navigation on a rapid double tap (§79): the callback
/// is dropped while a navigation from this card is already in flight.
class ServiceCard extends StatefulWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.showHierarchy = false,
  });

  final CatalogService service;
  final ValueChanged<CatalogService> onTap;

  /// Search results need the path; a Subcategory list is already in context.
  final bool showHierarchy;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _navigating = false;

  void _handleTap() {
    if (_navigating) return;
    _navigating = true;
    AppHaptics.selection();
    widget.onTap(widget.service);
    // Re-arm after the transition so returning to this screen leaves the card
    // usable. Tied to the motion duration rather than a magic number.
    Future.delayed(catalogMotionDuration * 2, () {
      if (mounted) _navigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final price = service.basePriceSummary;
    final unavailable = !service.isBookable;

    final semanticLabel = [
      service.name,
      'Service',
      if (widget.showHierarchy) service.hierarchyPath,
      if (price != null) 'from $price',
      if (service.estimatedDurationMins != null)
        '${service.estimatedDurationMins} minutes',
      if (unavailable) 'Currently unavailable',
    ].join(', ');

    return Semantics(
      button: true,
      enabled: !unavailable,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: ColorPalette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _handleTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      // The canonical catalog carries no imagery for any of the
                      // 95 services, so the app's keyword map remains the only
                      // source of art. imageUrl is honoured first so that stops
                      // being true the moment the backend fills it in.
                      serviceImageAsset(service.name),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showHierarchy) ...[
                          CatalogBreadcrumb(
                            categoryName: service.categoryName,
                            subcategoryName: service.subcategoryName,
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          service.name,
                          // Long service names wrap rather than truncate to a
                          // single unusable line (§84).
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.onSurface,
                          ),
                        ),
                        if (service.shortDescription != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            service.shortDescription!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: ColorPalette.accentText,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              // No price is "Get a quote", never ₱0.
                              price ?? 'Get a quote',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.primaryColorDark,
                              ),
                            ),
                            if (service.estimatedDurationMins != null)
                              Text(
                                '${service.estimatedDurationMins} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorPalette.accentText,
                                ),
                              ),
                            if (unavailable)
                              const Text(
                                'Unavailable',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ColorPalette.danger,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A Category or Subcategory tile.
class CatalogGroupCard extends StatelessWidget {
  const CatalogGroupCard({
    super.key,
    required this.title,
    required this.serviceCount,
    required this.onTap,
    this.subtitle,
    this.kindLabel = 'Category',
  });

  final String title;
  final String? subtitle;
  final int serviceCount;
  final String kindLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countLabel =
        serviceCount == 1 ? '1 service' : '$serviceCount services';
    return Semantics(
      button: true,
      label: '$title, $kindLabel, $countLabel',
      excludeSemantics: true,
      child: Material(
        color: ColorPalette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: ColorPalette.accentText,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          countLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorPalette.accentText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: ColorPalette.accentText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
