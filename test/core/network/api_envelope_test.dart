import 'dart:convert';

import 'package:client/core/network/api_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ApiEnvelope parse(String body) => ApiEnvelope.from(jsonDecode(body));

  group('payload extraction across all three envelopes', () {
    test('v1 {data, meta}', () {
      final e = parse('{"data":{"id":7},"meta":{}}');
      expect(e.asMap, <String, dynamic>{'id': 7});
    });

    test('legacy {success, message, data}', () {
      final e = parse('{"success":true,"message":"ok","data":{"id":7}}');
      expect(e.asMap, <String, dynamic>{'id': 7});
    });

    test('legacy {status, data}', () {
      final e = parse('{"status":"success","data":{"id":7}}');
      expect(e.asMap, <String, dynamic>{'id': 7});
    });

    test('a body with no wrapper is the payload itself', () {
      final e = parse('{"id":7}');
      expect(e.asMap, <String, dynamic>{'id': 7});
    });

    test('a bare list is the payload', () {
      final e = parse('[{"id":1},{"id":2}]');
      expect(e.listAt().length, 2);
    });
  });

  group('collections', () {
    test('reads an array nested under a domain key', () {
      // The legacy notifications route answers {data:{notifications:[…]}}.
      final e = parse('{"data":{"notifications":[{"a":1},{"a":2}]}}');
      expect(e.listAt('notifications').length, 2);
    });

    test('reads a bare array under data', () {
      final e = parse('{"data":[{"a":1}]}');
      expect(e.listAt('notifications').length, 1,
          reason: 'a missing key should fall through to the array itself');
    });

    test('a shape mismatch is empty, never a throw', () {
      // A malformed success body must not take down a screen that has cached
      // data to fall back on.
      expect(parse('{"data":{"notifications":"nope"}}').listAt('notifications'),
          isEmpty);
      expect(parse('{"data":null}').listAt(), isEmpty);
      expect(parse('{"data":42}').asMap, isEmpty);
    });

    test('non-map entries in a list are dropped rather than crashing', () {
      final e = parse('{"data":[{"a":1},"junk",null,{"a":2}]}');
      expect(e.listAt().length, 2);
    });
  });

  group('page meta', () {
    test('is parsed from meta.page', () {
      final e = parse(
          '{"data":[],"meta":{"page":{"limit":20,"offset":40,"total":100,"hasMore":true}}}');
      final m = e.meta!;
      expect(m.limit, 20);
      expect(m.offset, 40);
      expect(m.total, 100);
      expect(m.hasMore, isTrue);
      expect(m.nextOffset, 60);
    });

    test('nextOffset is null on the last page', () {
      final e = parse(
          '{"data":[],"meta":{"page":{"limit":20,"offset":40,"total":50,"hasMore":false}}}');
      expect(e.meta!.nextOffset, isNull);
    });

    test('a null total is preserved rather than coerced to zero', () {
      // The backend may decline to count; zero would be a different claim.
      final e = parse(
          '{"data":[],"meta":{"page":{"limit":20,"offset":0,"total":null,"hasMore":true}}}');
      expect(e.meta!.total, isNull);
      expect(e.meta!.hasMore, isTrue);
    });

    test('is null when the body is not paginated', () {
      expect(parse('{"data":[]}').meta, isNull);
      expect(parse('{"data":[],"meta":{}}').meta, isNull);
    });
  });

  group('Page', () {
    test('maps items while preserving meta', () {
      const meta = PageMeta(limit: 2, offset: 0, total: 4, hasMore: true);
      const page = Page<int>(items: <int>[1, 2], meta: meta);
      final mapped = page.map((i) => i * 10);
      expect(mapped.items, <int>[10, 20]);
      expect(mapped.hasMore, isTrue);
      expect(mapped.nextOffset, 2);
    });
  });
}
