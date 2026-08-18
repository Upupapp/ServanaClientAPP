import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:client/modules/categories/domain/service_booking_entry.dart';
import 'package:flutter_test/flutter_test.dart';

ServiceOptionSummary optionFrom(Map<String, dynamic> raw) =>
    ServiceOptionSummaryMapper.fromMap(raw);

void main() {
  final config =
      CategoryPresentationRegistry.forId(ServiceCategoryId.beautyWellness);

  group('canonical identity is read, never guessed', () {
    test('an explicitly canonical key populates canonicalServiceId', () {
      final option = optionFrom(<String, dynamic>{
        'id': 77,
        'level_3': 'Swedish Massage',
        'catalogServiceId': 901,
      });
      expect(option.canonicalServiceId, 901);
      expect(option.bookableIdentity, 901);
    });

    test('serviceId is accepted as the canonical key too', () {
      final option = optionFrom(<String, dynamic>{
        'id': 77,
        'level_3': 'X',
        'serviceId': 902,
      });
      expect(option.canonicalServiceId, 902);
    });

    test('a legacy-only payload yields NULL, not the option id', () {
      // services.id equals service_options.id for the rows the promotion
      // migration created, and stops equalling it for the first Service an
      // admin creates through the catalog API. Treating the legacy id as
      // canonical would be right today and silently wrong later.
      final option = optionFrom(<String, dynamic>{
        'serviceOptionId': 77,
        'level_3': 'Swedish Massage',
      });
      expect(option.canonicalServiceId, isNull);
      expect(option.id, '77');
      // The backend resolves this via services.legacy_service_option_id.
      expect(option.bookableIdentity, '77');
    });

    test('a string canonical id is parsed to an int', () {
      final option = optionFrom(<String, dynamic>{
        'id': 1,
        'level_3': 'X',
        'catalogServiceId': '903',
      });
      expect(option.canonicalServiceId, 903);
    });
  });

  group('navigation payload', () {
    test('carries the canonical id when it is known', () {
      final option = optionFrom(<String, dynamic>{
        'id': 77,
        'level_3': 'X',
        'catalogServiceId': 901,
      });
      final extra = ServiceBookingEntryResolver.extraFor(
        flowType: BookingFlowType.bwAddOns,
        option: option,
        config: config,
      )!;
      expect(extra['canonicalServiceId'], 901);
    });

    test('omits the key entirely when unknown, rather than sending null', () {
      // An absent key is handled by the backend's own resolution; a wrong or
      // null one would not be.
      final option = optionFrom(<String, dynamic>{
        'serviceOptionId': 77,
        'level_3': 'X',
      });
      final extra = ServiceBookingEntryResolver.extraFor(
        flowType: BookingFlowType.bwAddOns,
        option: option,
        config: config,
      )!;
      expect(extra.containsKey('canonicalServiceId'), isFalse);
    });

    test('still carries the family serviceId that selects the flow', () {
      // The family id chooses WHICH checkout runs; it is not what is booked.
      final option = optionFrom(<String, dynamic>{'id': 1, 'level_3': 'X'});
      final extra = ServiceBookingEntryResolver.extraFor(
        flowType: BookingFlowType.airconOptions,
        option: option,
        config: CategoryPresentationRegistry.forId(ServiceCategoryId.aircon),
      )!;
      expect(extra['serviceId'], isA<int>());
      expect(extra.containsKey('option'), isTrue);
    });

    test('both aircon and bw flows carry the same identity keys', () {
      final option = optionFrom(<String, dynamic>{
        'id': 5,
        'level_3': 'X',
        'catalogServiceId': 500,
      });
      final bw = ServiceBookingEntryResolver.extraFor(
        flowType: BookingFlowType.bwAddOns,
        option: option,
        config: config,
      )!;
      final aircon = ServiceBookingEntryResolver.extraFor(
        flowType: BookingFlowType.airconOptions,
        option: option,
        config: config,
      )!;
      expect(bw.keys.toSet(), aircon.keys.toSet());
      expect(bw['canonicalServiceId'], 500);
      expect(aircon['canonicalServiceId'], 500);
    });
  });

  group('presentation boundary — no Level 2/3 in customer-facing text', () {
    test('filter chips carry a curated label, never the level_2 value', () {
      for (final category in ServiceCategoryId.values) {
        final config = CategoryPresentationRegistry.forId(category);
        for (final chip in config.filterChips) {
          expect(chip.label, isNotEmpty);
          final label = chip.label.toLowerCase();
          expect(label, isNot(contains('level')));
          expect(label, isNot(contains('level_2')));
          expect(label, isNot(contains('level_3')));
        }
      }
    });

    test('the customer-facing headline never names a migration level', () {
      for (final category in ServiceCategoryId.values) {
        final config = CategoryPresentationRegistry.forId(category);
        final text = '${config.revealHeadline} ${config.revealSubtext} '
                '${config.displayTitle}'
            .toLowerCase();
        expect(text, isNot(contains('level 2')));
        expect(text, isNot(contains('level 3')));
        expect(text, isNot(contains('level_2')));
        expect(text, isNot(contains('service family')));
      }
    });

    test('categoryKey exists for filtering and is not a display field', () {
      // It holds the raw level_2 value. The guard is that chips render
      // CategoryFilterChip.label instead — asserted above.
      final option = optionFrom(<String, dynamic>{
        'id': 1,
        'level_3': 'Facial Treatment',
        'level_2': 'Beauty Drip Add Ons',
      });
      expect(option.categoryKey, 'Beauty Drip Add Ons');
      expect(option.name, 'Facial Treatment',
          reason: 'the displayed name comes from the service, not level_2');
    });
  });
}
