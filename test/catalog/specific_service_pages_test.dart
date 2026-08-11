import 'dart:io';

import 'package:client/common/domain/services/service_option_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('service-specific catalog matching', () {
    test('matches category terms across level 2, level 3, and name aliases',
        () {
      expect(
        ServiceOptionDisplay.matchesAny(
          {'level_2': 'Grooming', 'level_3': 'Gel Manicure'},
          {'nail', 'manicure'},
        ),
        isTrue,
      );
      expect(
        ServiceOptionDisplay.matchesAny(
          {'level_2': 'Wellness', 'name': 'Swedish Massage'},
          {'massage'},
        ),
        isTrue,
      );
      expect(
        ServiceOptionDisplay.matchesAny(
          {'level_2': 'IV Therapy', 'optionName': 'Vitamin Drip'},
          {'drip', 'facial'},
        ),
        isTrue,
      );
    });

    test('normalizes display categories without mutating source payload', () {
      final option = <String, dynamic>{
        'id': 12,
        'level_2': 'Manicure services',
        'level_3': 'Classic manicure',
      };
      final before = Map<String, dynamic>.from(option);
      final category = ServiceOptionDisplay.categoryFor(option, const {
        'Hair': ['hair'],
        'Nails': ['nail', 'manicure', 'pedicure'],
      });
      expect(category, 'Nails');
      expect(option, before);
    });

    test('reads current camelCase and legacy snake_case option contracts', () {
      expect(
        ServiceOptionDisplay.name(
          {'level3': 'Camel service', 'level2': 'Camel category'},
        ),
        'Camel service',
      );
      expect(
        ServiceOptionDisplay.name(
          {'level_3': 'Snake service', 'level_2': 'Snake category'},
        ),
        'Snake service',
      );
      expect(
        ServiceOptionDisplay.level2({'level_2': 'Snake category'}),
        'Snake category',
      );
      expect(
        ServiceOptionDisplay.matchesAny(
          {'level2': 'Beauty Drip', 'level3': 'Vitamin C'},
          {'drip'},
        ),
        isTrue,
      );
    });
  });

  // Retargeted 2026-08-11. This used to read the four per-category screens
  // (aircon_repair / beauty_wellness / hair_nails / massage), which have been
  // deleted: the router built CategoryExperienceScreen for all four of their
  // routes and never called their build() methods. The guarantee is unchanged
  // and now asserted against the screen that actually runs.
  test('the live category screen clears selection and selects the option', () {
    final source = File(
      'lib/modules/categories/presentation/screens/category_experience_screen.dart',
    ).readAsStringSync();
    expect(source, contains('clearSelectionOnly();'));
    expect(source, contains('selectOption('));
    // Both booking stores must be handled, not just one.
    expect(source, contains('BwBookingStore'));
    expect(source, contains('AirconBookingStore'));
  });

  test('the four category route names are preserved as a deep-link contract',
      () {
    final source = File(
      'lib/common/presentation/routes/category_routes.dart',
    ).readAsStringSync();
    // Renaming any of these breaks existing deep links and notification
    // payloads, which is why they outlived the widgets that declared them.
    expect(source, contains("aircon = 'AirconRepair'"));
    expect(source, contains("beautyWellness = 'BeautyWellness'"));
    expect(source, contains("hairNails = 'HairNails'"));
    expect(source, contains("massage = 'Massage'"));
  });

  test('shared service grid exposes accessible controls and recovery', () {
    final source = File(
      'lib/common/presentation/widgets/service_category_list_screen.dart',
    ).readAsStringSync();
    expect(source, contains("tooltip: 'Back'"));
    expect(source, contains("tooltip: 'Notifications'"));
    expect(source, contains("tooltip: 'Clear search'"));
    expect(source, contains('height: 44'));
    expect(source, contains('selected: selected'));
    expect(source, contains('Icons.check_rounded'));
    expect(source, contains('Clear search and filters'));
    expect(source, contains('estimated price'));
    expect(source, contains('BookingLoadingState'));
  });
}
