/// Unwraps a successful response body into its payload.
///
/// The v1 success shape is `{ "data": <T>, "meta"?: { … } }` and carries no
/// `status`/`success` flag on purpose — the backend's reasoning is that the
/// HTTP status already says whether it worked, and a second independently
/// settable signal is how `{success:true}` bodies end up on 500s.
///
/// The two legacy shapes DO carry that flag, and the app has to keep reading
/// them until every route it calls has a deployed canonical successor. So this
/// unwrapper accepts all three and returns the payload, and callers above it
/// never learn which one they got.
library;

/// Pagination metadata. Mirrors the backend's `PageMeta`.
class PageMeta {
  const PageMeta({
    required this.limit,
    required this.offset,
    required this.hasMore,
    this.total,
  });

  final int limit;
  final int offset;

  /// Null when the backend declines to count — `hasMore` is then the only
  /// signal, which is why it is non-nullable and `total` is not.
  final int? total;
  final bool hasMore;

  /// Offset for the next page, or null when this is the last one.
  int? get nextOffset => hasMore ? offset + limit : null;

  static const PageMeta empty =
      PageMeta(limit: 0, offset: 0, total: 0, hasMore: false);

  static PageMeta? tryParse(Object? meta) {
    if (meta is! Map) return null;
    final page = meta['page'];
    if (page is! Map) return null;
    final p = Map<String, dynamic>.from(page);
    final limit = _int(p['limit']);
    final offset = _int(p['offset']);
    if (limit == null || offset == null) return null;
    return PageMeta(
      limit: limit,
      offset: offset,
      total: _int(p['total']),
      hasMore: p['hasMore'] == true,
    );
  }

  static int? _int(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));
}

/// One page of already-mapped domain objects.
class Page<T> {
  const Page({required this.items, required this.meta});

  final List<T> items;
  final PageMeta meta;

  bool get hasMore => meta.hasMore;
  int? get nextOffset => meta.nextOffset;

  Page<R> map<R>(R Function(T) f) =>
      Page<R>(items: items.map(f).toList(growable: false), meta: meta);
}

/// A decoded success body: its payload and, when paginated, its page meta.
class ApiEnvelope {
  const ApiEnvelope({required this.data, this.meta});

  /// The payload. `Map`, `List`, scalar or null — callers assert the shape.
  final Object? data;
  final PageMeta? meta;

  /// Reads a v1 or legacy success body.
  ///
  /// Order matters. v1 is checked first by looking for `data` on a body with
  /// no legacy flag, because a legacy `{success:true, data:{…}}` would
  /// otherwise be mistaken for it — harmless today, since both then yield the
  /// same payload, but it stops being harmless if the two ever diverge.
  factory ApiEnvelope.from(Object? decoded) {
    if (decoded is! Map) {
      // A bare list or scalar is the payload itself.
      return ApiEnvelope(data: decoded);
    }
    final map = Map<String, dynamic>.from(decoded);
    final meta = PageMeta.tryParse(map['meta']);

    if (map.containsKey('data')) {
      return ApiEnvelope(data: map['data'], meta: meta);
    }
    // helpers/status.ts sometimes nests under 'result'; the hand-built
    // responses put the payload at the root.
    if (map.containsKey('result')) {
      return ApiEnvelope(data: map['result'], meta: meta);
    }
    return ApiEnvelope(data: map, meta: meta);
  }

  /// The payload as a map, or an empty map. Never throws — a shape mismatch is
  /// an empty result, not a crash, because a malformed success body must not
  /// take down a screen that has cached data to fall back on.
  Map<String, dynamic> get asMap {
    final d = data;
    return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
  }

  /// The payload as a list of maps, or empty.
  ///
  /// Accepts both a bare list and `{ "<key>": [ … ] }`, because the legacy
  /// routes wrap their collections under a domain key
  /// (`{data:{notifications:[…]}}`) and v1 returns the array directly.
  List<Map<String, dynamic>> listAt([String? key]) {
    Object? node = data;
    if (key != null && node is Map && node.containsKey(key)) {
      node = node[key];
    }
    if (node is! List) return const <Map<String, dynamic>>[];
    return node
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
}
