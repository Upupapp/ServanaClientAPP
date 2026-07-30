/// Backend-authoritative provider rating aggregate.
/// Zero-state is represented by reviewCount == 0 and averageRating == 0.
class ReviewAggregate {
  const ReviewAggregate({
    required this.providerUid,
    required this.averageRating,
    required this.reviewCount,
    required this.distribution,
  });

  final String providerUid;
  final double averageRating;
  final int reviewCount;
  // distribution keys: 1, 2, 3, 4, 5
  final Map<int, int> distribution;

  bool get hasReviews => reviewCount > 0;

  factory ReviewAggregate.empty(String providerUid) => ReviewAggregate(
        providerUid: providerUid,
        averageRating: 0,
        reviewCount: 0,
        distribution: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );

  factory ReviewAggregate.fromMap(Map<String, dynamic> m) {
    final dist = <int, int>{};
    final raw = m['distribution'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final k = int.tryParse(entry.key.toString());
        final v = (entry.value as num?)?.toInt() ?? 0;
        if (k != null) dist[k] = v;
      }
    }
    for (var i = 1; i <= 5; i++) {
      dist.putIfAbsent(i, () => 0);
    }

    return ReviewAggregate(
      providerUid: m['providerUid'] as String? ?? '',
      averageRating: (m['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (m['reviewCount'] as num?)?.toInt() ?? 0,
      distribution: dist,
    );
  }

  String get displayRating =>
      hasReviews ? averageRating.toStringAsFixed(1) : '';
}
