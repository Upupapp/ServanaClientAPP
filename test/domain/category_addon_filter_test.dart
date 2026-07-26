import 'package:client/modules/categories/data/category_addon_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryAddonFilter.isAddon', () {
    test('returns false for a normal option', () {
      final option = {'name': 'Basic Facial', 'optionType': 'SERVICE'};
      expect(CategoryAddonFilter.isAddon(option), isFalse);
    });

    test('detects ADD_ON via optionType', () {
      final option = {'name': 'Extra Serum', 'optionType': 'ADD_ON'};
      expect(CategoryAddonFilter.isAddon(option), isTrue);
    });

    test('detects add-on via isAddon=true', () {
      final option = {'name': 'Extra Serum', 'isAddon': true};
      expect(CategoryAddonFilter.isAddon(option), isTrue);
    });

    test('detects add-on via is_addon=true', () {
      final option = {'name': 'Extra Serum', 'is_addon': true};
      expect(CategoryAddonFilter.isAddon(option), isTrue);
    });

    test('isAddon=false does not flag as add-on', () {
      final option = {
        'name': 'Basic Facial',
        'optionType': 'SERVICE',
        'isAddon': false,
        'is_addon': false,
      };
      expect(CategoryAddonFilter.isAddon(option), isFalse);
    });

    test('isNotAddon is the inverse of isAddon', () {
      final addon = {'optionType': 'ADD_ON'};
      final service = {'optionType': 'SERVICE'};
      expect(CategoryAddonFilter.isNotAddon(addon), isFalse);
      expect(CategoryAddonFilter.isNotAddon(service), isTrue);
    });
  });
}
