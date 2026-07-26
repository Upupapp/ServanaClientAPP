import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:flutter/material.dart';

class CategoryServiceCard extends StatelessWidget {
  final ServiceOptionSummary option;
  final Color accentColor;
  final VoidCallback onTap;

  const CategoryServiceCard({
    super.key,
    required this.option,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${option.name}, ${option.formattedPrice}. '
          '${option.hasAddons ? 'Add-ons available.' : ''}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _ServiceImage(imageAsset: option.imageAsset, accent: accentColor),
                const SizedBox(width: 14),
                Expanded(child: _ServiceInfo(option: option, accent: accentColor)),
                const SizedBox(width: 12),
                _BookButton(accent: accentColor, onTap: onTap),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  final String? imageAsset;
  final Color accent;
  const _ServiceImage({this.imageAsset, required this.accent});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Icon(Icons.spa_outlined, color: accent, size: 32),
    );

    if (imageAsset == null) return fallback;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: Image.asset(
        imageAsset!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _ServiceInfo extends StatelessWidget {
  final ServiceOptionSummary option;
  final Color accent;
  const _ServiceInfo({required this.option, required this.accent});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.name,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (option.shortDescription != null) ...[
            const SizedBox(height: 3),
            Text(
              option.shortDescription!,
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            option.formattedPrice,
            style: textTheme.bodyMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (option.hasAddons) ...[
            const SizedBox(height: 3),
            Text(
              'Add-ons available',
              style: textTheme.labelSmall?.copyWith(
                color: accent.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  const _BookButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
    );
  }
}
