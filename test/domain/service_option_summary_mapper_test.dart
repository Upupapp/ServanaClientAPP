import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceOptionSummaryMapper.fromMap', () {
    test('reads serviceOptionId as primary ID field', () {
      final o = <String, dynamic>{
        'serviceOptionId': 42,
        'name': 'Basic Facial',
        'level_2': 'facial',
      };
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.id, '42');
    });

    test('falls back to id when serviceOptionId missing', () {
      final o = <String, dynamic>{'id': '99', 'name': 'Manicure'};
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.id, '99');
    });

    test('reads basePrice as primary price field', () {
      final o = <String, dynamic>{
        'id': '1',
        'name': 'Hair Dry',
        'basePrice': 350.0,
      };
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.basePrice, 350.0);
      expect(summary.formattedPrice, '₱350');
    });

    test('falls back to price field', () {
      final o = <String, dynamic>{'id': '2', 'name': 'Foot Massage', 'price': 500};
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.basePrice, 500.0);
    });

    test('formats decimal price correctly', () {
      final o = <String, dynamic>{'id': '3', 'name': 'Drip', 'basePrice': 299.5};
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.formattedPrice, '₱299.50');
    });

    test('returns Price varies when no price field present', () {
      final o = <String, dynamic>{'id': '4', 'name': 'Unknown'};
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.formattedPrice, 'Price varies');
    });

    test('sets hasAddons true when addons is non-empty list', () {
      final o = <String, dynamic>{
        'id': '5',
        'name': 'Facial',
        'addons': [{'id': 1}],
      };
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.hasAddons, isTrue);
    });

    test('sets hasAddons false when addons is empty list', () {
      final o = <String, dynamic>{'id': '6', 'name': 'Facial', 'addons': []};
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.hasAddons, isFalse);
    });

    test('reads level_2 as categoryKey', () {
      final o = <String, dynamic>{'id': '7', 'name': 'Drip', 'level_2': 'drip'};
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.categoryKey, 'drip');
    });

    test('preserves rawData reference', () {
      final raw = <String, dynamic>{'id': '8', 'name': 'Massage'};
      final summary = ServiceOptionSummaryMapper.fromMap(raw);
      expect(summary.rawData, same(raw));
    });

    test('reads shortDescription field', () {
      final o = <String, dynamic>{
        'id': '9',
        'name': 'Facial',
        'shortDescription': 'A relaxing facial treatment',
      };
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.shortDescription, 'A relaxing facial treatment');
    });

    test('falls back to description when shortDescription missing', () {
      final o = <String, dynamic>{
        'id': '10',
        'name': 'Massage',
        'description': 'Full body massage',
      };
      final summary = ServiceOptionSummaryMapper.fromMap(o);
      expect(summary.shortDescription, 'Full body massage');
    });
  });
}
