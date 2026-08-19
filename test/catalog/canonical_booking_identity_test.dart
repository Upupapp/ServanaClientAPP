/// The identity guarantee this whole migration exists to produce.
///
/// One canonical `services.id` from the catalog, through Service Detail, into
/// the booking payload — and therefore into `bookings.catalog_service_id` and
/// provider matching.
library;

import 'package:client/modules/catalog/application/canonical_booking_handoff.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogServiceDetail _detail({
  int id = 15,
  int categoryId = 3,
  String categoryName = 'Personal Care',
  bool available = true,
}) =>
    CatalogServiceDetail.fromJson({
      'id': id,
      'subcategoryId': 7,
      'subcategoryName': 'Facial',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'name': 'Pimple Facial',
      'slug': 'pimple-facial-15',
      'status': 'active',
      'displayOrder': 0,
      'bookable': true,
      'basePrice': 1500,
      'unit': 'per session',
      'available': available,
      'addons': [
        {'id': 6, 'name': 'Vitamin C', 'basePrice': 350},
      ],
    });

void main() {
  group('booking payload identity', () {
    test('serviceOptionId carries the canonical services.id', () {
      // The booking store reads `selectedOption['id']` and the payload sends it
      // as `serviceOptionId`; the backend resolves catalog_service_id from it.
      // This is the single assertion that the customer's selection and the
      // booking's service identity are the same integer.
      final option = canonicalOptionMap(_detail(id: 15));

      expect(option['id'], 15);
      expect(option['serviceOptionId'], 15);
      expect(option['catalogServiceId'], 15);
    });

    test('identity is taken from the Service, not from a legacy option lookup',
        () {
      // An Admin-created Service takes its id from catalog_services_id_seq and
      // has no legacy option at all. Nothing here consults service_options, so
      // an id well outside the promoted range still flows through unchanged.
      final option = canonicalOptionMap(_detail(id: 900001));
      expect(option['id'], 900001);
    });

    test('the hierarchy travels as a booking-time snapshot', () {
      // So history can render "Personal Care › Facial" later without
      // re-resolving a catalog that may have moved since (§25, §42).
      final option = canonicalOptionMap(_detail());
      expect(option['catalogSubcategoryId'], 7);
      expect(option['catalogSubcategoryName'], 'Facial');
      expect(option['catalogCategoryId'], 3);
      expect(option['catalogCategoryName'], 'Personal Care');
    });

    test('add-ons stay configuration and never become the service identity',
        () {
      final option = canonicalOptionMap(_detail(id: 15));
      final addons = option['addons'] as List;

      expect(addons, hasLength(1));
      expect((addons.single as Map)['id'], 6);
      // The add-on's option id must never be mistaken for the Service id.
      expect((addons.single as Map)['id'], isNot(option['id']));
    });

    test('the option map carries no legacy taxonomy keys', () {
      final option = canonicalOptionMap(_detail());
      for (final banned in ['level2', 'level_2', 'serviceFamily', 'category']) {
        expect(option.containsKey(banned), isFalse, reason: banned);
      }
      // `level3` IS present and is intentional: it is the key every existing
      // booking screen reads for the service's display name. It is a legacy
      // FIELD NAME carrying canonical data, not legacy taxonomy — the value is
      // services.name.
      expect(option['level3'], 'Pimple Facial');
    });
  });

  group('flow resolution', () {
    test('resolves from the canonical category id, not a name regex', () {
      expect(resolveBookingFlow(_detail(categoryId: 2).service),
          CanonicalBookingFlow.aircon);
      expect(resolveBookingFlow(_detail(categoryId: 3).service),
          CanonicalBookingFlow.beautyWellness);
    });

    test('an unknown category falls back to the generic flow, not a crash', () {
      // A Category an admin creates tomorrow must be bookable that day, without
      // an app release. The legacy registry required one.
      expect(
        resolveBookingFlow(
            _detail(categoryId: 99, categoryName: 'Pet Care').service),
        CanonicalBookingFlow.beautyWellness,
      );
    });
  });
}
