import 'package:flutter/material.dart';

class CategorySkeletonList extends StatelessWidget {
  final int count;
  const CategorySkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _SkeletonCard(),
        ),
        childCount: count,
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _shimmer(context, width: 80, radius: 16, isLeft: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(context, width: 140, height: 14),
                  const SizedBox(height: 8),
                  _shimmer(context, width: 80, height: 12),
                ],
              ),
            ),
            _shimmer(context, width: 36, height: 36, radius: 18),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(
    BuildContext context, {
    double? width,
    double height = 80,
    double radius = 8,
    bool isLeft = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        borderRadius: isLeft
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              )
            : BorderRadius.circular(radius),
      ),
    );
  }
}
