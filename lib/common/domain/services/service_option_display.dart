abstract final class ServiceOptionDisplay {
  static String level2(Map<String, dynamic> option) =>
      (option['level2'] ?? option['level_2'] ?? '').toString().trim();

  static String level3(Map<String, dynamic> option) =>
      (option['level3'] ?? option['level_3'] ?? '').toString().trim();

  static String name(
    Map<String, dynamic> option, {
    String fallback = 'Service',
  }) {
    for (final value in [
      option['level3'],
      option['level_3'],
      option['name'],
      option['optionName'],
      option['option_name'],
    ]) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static String searchableText(Map<String, dynamic> option) => [
        option['level2'],
        option['level_2'],
        option['level3'],
        option['level_3'],
        option['name'],
        option['optionName'],
        option['option_name'],
      ]
          .whereType<Object>()
          .map((value) => value.toString())
          .join(' ')
          .toLowerCase();

  static bool matchesAny(Map<String, dynamic> option, Iterable<String> terms) {
    final text = searchableText(option);
    return terms.any((term) => text.contains(term.toLowerCase()));
  }

  static String categoryFor(
    Map<String, dynamic> option,
    Map<String, Iterable<String>> categories,
  ) {
    for (final entry in categories.entries) {
      if (matchesAny(option, entry.value)) return entry.key;
    }
    return level2(option);
  }
}
