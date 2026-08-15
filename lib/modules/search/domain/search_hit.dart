/// One search hit, whatever level of the catalog it came from.
///
/// ## Why one model for three entity types
///
/// The canonical search returns Categories, Subcategories and Services in a
/// single ranked list. Modelling them as three arrays would push the "which
/// kind is this?" question into the widget layer, and the widget would answer it
/// by remembering which array it read from — an inference that breaks the moment
/// the response is merged, sorted or paged.
///
/// So type is carried as data, and identity is carried as a **qualified ref**.
///
/// ## The ref is the identity, not the integer
///
/// `services.id` 180 and `catalog_categories.id` 180 are both `180`. A bare
/// integer is therefore not a key: deduplicating, caching or list-keying on it
/// silently merges a Category into a Service. The backend already solved this —
/// every hit carries `ref` in the form `service:180` — and this model keeps that
/// qualified form as the identity, deriving the bare [id] from it rather than
/// the other way round.
///
/// This is the same ambiguity TAB 04 fixed for booking identity, in the one
/// place where three levels genuinely share a result set.
library;

/// The catalog levels search can return.
enum SearchEntityType {
  category('category'),
  subcategory('subcategory'),
  service('service');

  const SearchEntityType(this.wireName);

  final String wireName;

  static SearchEntityType? fromWire(String? raw) {
    if (raw == null) return null;
    for (final t in SearchEntityType.values) {
      if (t.wireName == raw) return t;
    }
    return null;
  }
}

class SearchHit {
  const SearchHit({
    required this.ref,
    required this.type,
    required this.id,
    required this.name,
    this.slug = '',
    this.context,
    this.imageUrl,
    this.bookable,
    this.basePrice,
    this.categoryId,
    this.subcategoryId,
    this.score = 0,
    this.matchedTerm,
  });

  /// Qualified canonical reference — `service:180`. The identity of this hit.
  final String ref;

  final SearchEntityType type;

  /// The canonical row id at this hit's own level. Only unique *within* [type],
  /// which is why [ref] and not this is the key.
  final int id;

  final String name;
  final String slug;

  /// One line of parent context, e.g. `Personal Care › Facial`.
  final String? context;

  final String? imageUrl;

  /// Null on a Category — a Category cannot be booked.
  final bool? bookable;

  final num? basePrice;
  final int? categoryId;
  final int? subcategoryId;

  /// Backend relevance: 4 exact · 3 name-prefix · 2 word-prefix · 1 contains.
  final int score;

  /// Which term produced the hit — the query itself, or the alias that widened
  /// it. Diagnostic: it explains a surprising result rather than driving one.
  final String? matchedTerm;

  /// True when this hit is a bookable Service. The only hit a booking flow may
  /// start from.
  bool get isBookableService =>
      type == SearchEntityType.service && (bookable ?? false);

  factory SearchHit.fromJson(Map<String, dynamic> json) {
    final type = SearchEntityType.fromWire(json['type'] as String?);
    if (type == null) {
      throw FormatException('Unknown search hit type: ${json['type']}');
    }
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return SearchHit(
      // Prefer the server's ref. Synthesised only if absent, so a response that
      // predates the qualified form still keys correctly instead of colliding.
      ref: (json['ref'] as String?)?.trim().isNotEmpty == true
          ? json['ref'] as String
          : '${type.wireName}:$id',
      type: type,
      id: id,
      name: (json['name'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      context: json['context'] as String?,
      imageUrl: json['imageUrl'] as String?,
      bookable: json['bookable'] as bool?,
      basePrice: json['basePrice'] as num?,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      subcategoryId: (json['subcategoryId'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      matchedTerm: json['matchedTerm'] as String?,
    );
  }
}

/// A whole ranked result set.
class SearchResults {
  const SearchResults({
    required this.query,
    required this.hits,
    this.expandedTerms = const <String>[],
    this.total = 0,
  });

  static const SearchResults empty =
      SearchResults(query: '', hits: <SearchHit>[]);

  final String query;
  final List<SearchHit> hits;

  /// Every term the query was widened to. `aircon` expanding to
  /// `air conditioning` is why a hit that contains neither literal appears.
  final List<String> expandedTerms;

  /// The server's pre-truncation total. [hits] may be shorter, because the
  /// server applies `limit` after counting.
  final int total;

  List<SearchHit> ofType(SearchEntityType type) =>
      hits.where((h) => h.type == type).toList(growable: false);

  /// True when the server ranked more than it returned, so the UI can say
  /// "showing 20 of 47" instead of implying the list is complete.
  bool get isTruncated => total > hits.length;

  bool get isEmpty => hits.isEmpty;

  /// Parses the canonical body and **deduplicates on the qualified ref**.
  ///
  /// The backend scores each row once across every expanded term and keeps the
  /// best, so it does not emit a row twice today. The dedupe is here anyway,
  /// and asserted by a test, because the acceptance gate is a property of what
  /// the customer sees rather than of the current server implementation: alias
  /// expansion is exactly the mechanism that would produce a duplicate if that
  /// scoring ever moved, and a doubled Service in a result list is both visible
  /// and confusing.
  ///
  /// The first occurrence wins, which preserves the server's ranking order.
  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final raw = json['hits'];
    final seen = <String>{};
    final hits = <SearchHit>[];

    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map) continue;
        final SearchHit hit;
        try {
          hit = SearchHit.fromJson(Map<String, dynamic>.from(entry));
        } on FormatException {
          // An entity type this build does not know about. Skipped, not fatal:
          // the catalog may grow a level before the app does, and refusing the
          // whole response would empty a search that otherwise worked.
          continue;
        }
        if (seen.add(hit.ref)) hits.add(hit);
      }
    }

    return SearchResults(
      query: (json['query'] as String?) ?? '',
      hits: hits,
      expandedTerms: (json['expandedTerms'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      // `total` counts pre-truncation hits, so it is taken from the server and
      // never recomputed from the deduplicated list.
      total: (json['total'] as num?)?.toInt() ?? hits.length,
    );
  }
}
