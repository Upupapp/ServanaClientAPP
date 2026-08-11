/// Canonical Catalog V2 — client contract tests.
///
/// Fixtures are the SHAPE of the production-certified `/api/catalog` response,
/// measured against the deployed backend rather than copied from a document.
///
/// Two of these guard defects that were found in production, not imagined:
///  - `level2` reaching a canonical payload via response-parity middleware
///  - Postgres timestamps (`2026-08-11 11:03:23.421016+00`) where ISO was
///    promised
library;

import 'package:client/common/domain/time/iso_timestamp.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _serviceJson({
  int id = 15,
  String name = 'Pimple Facial',
  String status = 'active',
  bool bookable = true,
  Object? basePrice = 1500,
  Object? updatedAt = '2026-08-11T11:03:23.421Z',
}) =>
    {
      'id': id,
      'subcategoryId': 7,
      'subcategoryName': 'Facial',
      'categoryId': 3,
      'categoryName': 'Personal Care',
      'name': name,
      'slug': 'pimple-facial-15',
      'shortDescription': null,
      'imageUrl': null,
      'status': status,
      'displayOrder': 0,
      'bookable': bookable,
      'basePrice': basePrice,
      'unit': 'per session',
      'basePriceSummary': '₱1,500 / per session',
      'estimatedDurationMins': null,
      'updatedAt': updatedAt,
    };

Map<String, dynamic> _catalogJson({List<Map<String, dynamic>>? services}) => {
      'categories': [
        {
          'id': 3,
          'name': 'Personal Care',
          'slug': 'personal-care',
          'description': null,
          'imageUrl': null,
          'displayOrder': 0,
          'subcategories': [
            {
              'id': 7,
              'categoryId': 3,
              'name': 'Facial',
              'slug': 'facial',
              'description': null,
              'imageUrl': null,
              'displayOrder': 0,
              'services': services ?? [_serviceJson()],
            },
          ],
        },
      ],
      'summary': {
        'categories': 3,
        'subcategories': 12,
        'services': 95,
        'lastUpdatedAt': '2026-08-11T13:55:16.634Z',
      },
    };

void main() {
  group('ISO 8601 timestamp guard', () {
    test('parses the canonical form', () {
      expect(
        parseBackendTimestamp('2026-08-11T11:03:23.421Z'),
        DateTime.utc(2026, 8, 11, 11, 3, 23, 421),
      );
    });

    test('reads the raw Postgres form legacy surfaces still emit', () {
      // `/api/services/:id/options-with-addons` returns this as `updatedAt`
      // while returning ISO as `createdAt` in the very same object.
      expect(
        parseBackendTimestamp('2026-07-15 02:51:24.993763+00'),
        DateTime.utc(2026, 7, 15, 2, 51, 24, 993, 763),
      );
    });

    test('pins that Dart itself already tolerates the Postgres form', () {
      // Recorded deliberately, because the backend's equivalent helper exists
      // for the opposite reason: JS `new Date()` REJECTS the bare `+00`, and a
      // Node fix repairing only the space silently returns NaN. It is easy to
      // assume Dart shares that hole. It does not.
      //
      // If a future SDK tightens its parser this test fails FIRST, which is the
      // signal that the repair path in parseBackendTimestamp has stopped being
      // belt-and-braces and become load-bearing.
      expect(
        DateTime.tryParse('2026-07-15 02:51:24.993763+00')?.toUtc(),
        DateTime.utc(2026, 7, 15, 2, 51, 24, 993, 763),
      );
    });

    test('the repair path handles a form Dart would reject', () {
      // Exercises the fallback directly rather than trusting it is reachable.
      // A doubled separator defeats DateTime.parse; the repair does not rescue
      // this either, and the contract is that it returns null rather than
      // throwing into a list builder.
      expect(DateTime.tryParse('2026-07-15  02:51:24+00'), isNull);
      expect(parseBackendTimestamp('2026-07-15  02:51:24+00'), isNull);
    });

    test('handles explicit offsets, null, empty and garbage', () {
      expect(
        parseBackendTimestamp('2026-08-11T19:03:23.421+08:00'),
        DateTime.utc(2026, 8, 11, 11, 3, 23, 421),
      );
      expect(parseBackendTimestamp(null), isNull);
      expect(parseBackendTimestamp(''), isNull);
      expect(parseBackendTimestamp('not a timestamp'), isNull);
    });

    test('a broken timestamp does not stop a Service from parsing', () {
      final service =
          CatalogService.fromJson(_serviceJson(updatedAt: 'garbage'));
      expect(service.id, 15);
      expect(service.updatedAt, isNull);
    });

    test('round-trips through the cache without moving the instant', () {
      final service = CatalogService.fromJson(_serviceJson());
      final restored = CatalogService.fromJson(service.toJson());
      expect(restored.updatedAt, service.updatedAt);
    });
  });

  group('level2 regression guard', () {
    test('the model exposes no level2/level3/serviceFamily surface', () {
      final json = CatalogService.fromJson(_serviceJson()).toJson();
      for (final banned in [
        'level2',
        'level_2',
        'level3',
        'level_3',
        'serviceFamily',
        'serviceName',
        'service_name',
      ]) {
        expect(json.containsKey(banned), isFalse,
            reason: '$banned must not exist on a canonical Service');
      }
    });

    test('Subcategory comes from subcategoryId, never from the Service name',
        () {
      final service = CatalogService.fromJson(_serviceJson());
      expect(service.name, 'Pimple Facial');
      expect(service.subcategoryName, 'Facial');
      expect(service.subcategoryName, isNot(service.name));
      expect(service.subcategoryId, 7);
      expect(service.hierarchyPath, 'Personal Care › Facial');
    });

    test('a payload that DOES carry a parity level2 is ignored, not absorbed',
        () {
      // Simulates the exact production defect: parity set level2 to the
      // Service's own name. Even if it reappears on the wire, nothing reads it.
      final poisoned = _serviceJson()
        ..['level2'] = 'Pimple Facial'
        ..['level_2'] = 'Pimple Facial';
      final service = CatalogService.fromJson(poisoned);
      expect(service.subcategoryName, 'Facial');
      expect(service.toJson().containsKey('level2'), isFalse);
    });
  });

  group('status and bookability', () {
    test('only active is visible', () {
      expect(CatalogStatus.parse('active').isVisible, isTrue);
      for (final s in ['draft', 'inactive', 'archived']) {
        expect(CatalogStatus.parse(s).isVisible, isFalse, reason: s);
      }
    });

    test('an unknown future status degrades to unavailable, never crashes', () {
      final service =
          CatalogService.fromJson(_serviceJson(status: 'seasonal_preview'));
      expect(service.status, CatalogStatus.unknown);
      expect(service.isBookable, isFalse);
    });

    test('a missing bookable key means NOT bookable', () {
      // Defaulting to true would let a contract change silently re-enable
      // booking on a withdrawn Service.
      final json = _serviceJson()..remove('bookable');
      expect(CatalogService.fromJson(json).bookable, isFalse);
    });

    test('active but not bookable is not bookable', () {
      expect(
        CatalogService.fromJson(_serviceJson(bookable: false)).isBookable,
        isFalse,
      );
    });
  });

  group('null safety on optional fields', () {
    test('parses a Service with every optional field absent', () {
      // This is production today: 0 of 95 Services have an image, a duration or
      // a full description, and only 41 have a short description.
      final service = CatalogService.fromJson({
        'id': 42,
        'subcategoryId': 7,
        'categoryId': 3,
        'name': 'Bare Service',
        'slug': 'bare',
        'status': 'active',
        'bookable': true,
      });
      expect(service.id, 42);
      expect(service.shortDescription, isNull);
      expect(service.imageUrl, isNull);
      expect(service.estimatedDurationMins, isNull);
      expect(service.basePrice, isNull);
      expect(service.displayOrder, 0);
      expect(service.categoryName, '');
    });

    test('empty strings normalise to null rather than blank UI', () {
      final service =
          CatalogService.fromJson(_serviceJson()..['shortDescription'] = '   ');
      expect(service.shortDescription, isNull);
    });

    test('a price arriving as a string still parses', () {
      // /options-with-addons returns "3190"; /services/full returns 3190. Both
      // spellings have been seen in production on the legacy surface.
      expect(
        CatalogService.fromJson(_serviceJson(basePrice: '1500')).basePrice,
        1500.0,
      );
    });
  });

  group('Catalog aggregate', () {
    test('parses the hierarchy and its counts', () {
      final catalog = Catalog.fromJson(_catalogJson());
      expect(catalog.categories, hasLength(1));
      final category = catalog.categories.single;
      expect(category.subcategoryCount, 1);
      expect(category.serviceCount, 1);
      expect(catalog.lastUpdatedAt, isNotNull);
    });

    test('resolves a Service by canonical id', () {
      final catalog = Catalog.fromJson(_catalogJson());
      expect(catalog.serviceById(15)?.name, 'Pimple Facial');
      expect(catalog.serviceById(999999), isNull);
      expect(catalog.subcategoryById(7)?.name, 'Facial');
      expect(catalog.categoryById(3)?.name, 'Personal Care');
    });

    test('an empty category is retained so its empty state can render', () {
      final json = _catalogJson();
      (json['categories'] as List).first['subcategories'] = [];
      final catalog = Catalog.fromJson(json);
      expect(catalog.categories, hasLength(1));
      expect(catalog.categories.single.serviceCount, 0);
    });

    test('survives an entirely empty catalog', () {
      final catalog = Catalog.fromJson({'categories': []});
      expect(catalog.isEmpty, isTrue);
      expect(catalog.allServices, isEmpty);
      expect(catalog.serviceById(1), isNull);
    });
  });

  group('Service detail and configuration', () {
    test('add-ons are configuration, carrying option ids not Service ids', () {
      final detail = CatalogServiceDetail.fromJson({
        ..._serviceJson(),
        'available': true,
        'fullDescription': 'Full copy',
        'inclusions': ['Consultation', ''],
        'exclusions': ['Products'],
        'addons': [
          {
            'id': 6,
            'name': 'Vitamin C',
            'unit': 'per session',
            'basePrice': 350,
            'basePriceSummary': '₱350 / per session',
            'durationMins': 15,
          },
        ],
      });

      expect(detail.service.id, 15);
      expect(detail.available, isTrue);
      // Blank entries dropped rather than rendered as empty bullets.
      expect(detail.inclusions, ['Consultation']);
      expect(detail.addons.single.id, 6);
      // The add-on id is a service_options.id. It must never be mistaken for
      // the bookable Service id.
      expect(detail.addons.single.id, isNot(detail.service.id));
    });

    test('an unavailable Service still parses so a deep link can land', () {
      final detail = CatalogServiceDetail.fromJson({
        ..._serviceJson(status: 'archived', bookable: false),
        'available': false,
      });
      expect(detail.service.id, 15);
      expect(detail.available, isFalse);
      expect(detail.addons, isEmpty);
    });

    test('available is read from the backend, never inferred locally', () {
      // The backend folds in the Subcategory's and Category's status too, so a
      // Service whose own row reads active can still be unavailable. A client
      // that recomputed this from `status` alone would disagree.
      final detail = CatalogServiceDetail.fromJson({
        ..._serviceJson(),
        'available': false,
      });
      expect(detail.service.status, CatalogStatus.active);
      expect(detail.service.bookable, isTrue);
      expect(detail.available, isFalse);
    });
  });
}
