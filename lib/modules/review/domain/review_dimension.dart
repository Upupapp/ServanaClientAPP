/// A single scored dimension within a review (e.g. Punctuality = 4).
class ReviewDimensionScore {
  const ReviewDimensionScore({
    required this.dimensionKey,
    required this.score,
  });

  final String dimensionKey;
  final int score; // 1–5

  factory ReviewDimensionScore.fromMap(Map<String, dynamic> m) =>
      ReviewDimensionScore(
        dimensionKey: m['dimensionKey'] as String? ?? '',
        score: (m['score'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'dimensionKey': dimensionKey,
        'score': score,
      };

  String get label => labelFor(dimensionKey);

  static String labelFor(String key) => _label(key);

  static String _label(String key) {
    switch (key) {
      case 'SERVICE_QUALITY':
        return 'Service quality';
      case 'PROFESSIONALISM':
        return 'Professionalism';
      case 'PUNCTUALITY':
        return 'Punctuality';
      case 'COMMUNICATION':
        return 'Communication';
      case 'VALUE':
        return 'Value for money';
      case 'CLEANLINESS':
        return 'Cleanliness';
      case 'ACCURACY':
        return 'Accuracy of booking';
      default:
        return key.toLowerCase().replaceAll('_', ' ');
    }
  }
}

/// The set of dimensions shown for a given service type.
class ReviewDimensionSet {
  static const List<String> general = [
    'SERVICE_QUALITY',
    'PROFESSIONALISM',
    'PUNCTUALITY',
    'COMMUNICATION',
    'VALUE',
  ];

  static const List<String> cleaning = [
    'SERVICE_QUALITY',
    'CLEANLINESS',
    'PROFESSIONALISM',
    'PUNCTUALITY',
    'VALUE',
  ];

  static const List<String> installation = [
    'ACCURACY',
    'SERVICE_QUALITY',
    'PROFESSIONALISM',
    'PUNCTUALITY',
    'VALUE',
  ];

  static List<String> forCategory(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('clean') || c.contains('housekeep')) return cleaning;
    if (c.contains('install') || c.contains('repair') || c.contains('tech'))
      return installation;
    return general;
  }
}
