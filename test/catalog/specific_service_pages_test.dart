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

  test('all specific service pages clear selection and preserve API routes',
      () {
    for (final path in [
      'lib/modules/aircon_booking/presentation/screens/aircon_repair_screen.dart',
      'lib/modules/bw_booking/presentation/screens/beauty_wellness_screen.dart',
      'lib/modules/bw_booking/presentation/screens/hair_nails_screen.dart',
      'lib/modules/bw_booking/presentation/screens/massage_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('store.clearSelectionOnly();'), reason: path);
      expect(source, contains('store.ensureOptionsLoaded'), reason: path);
      expect(source, contains('store.selectOption'), reason: path);
    }
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
