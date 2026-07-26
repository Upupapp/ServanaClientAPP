import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/modules/categories/application/category_experience_controller.dart';
import 'package:client/modules/categories/data/category_experience_repository.dart';
import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:client/modules/categories/domain/category_reveal_policy.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends CategoryExperienceRepository {
  final List<ServiceOptionSummary> _options;
  final Exception? _error;

  _FakeRepo({List<ServiceOptionSummary>? options, Exception? error})
      : _options = options ?? const [],
        _error = error,
        super(ServanaApiClient(baseUrl: 'http://fake.test'));

  @override
  Future<List<ServiceOptionSummary>> loadOptions({
    required int serviceId,
    Set<String>? level2AllowList,
    String? level2Pattern,
  }) async {
    if (_error != null) throw _error;
    return List.of(_options);
  }
}

ServiceOptionSummary _opt(String id, {String categoryKey = ''}) =>
    ServiceOptionSummaryMapper.fromMap(
        <String, dynamic>{'id': id, 'name': 'Option $id', 'level2': categoryKey});

void main() {
  setUp(CategoryRevealPolicy.reset);

  group('CategoryExperienceController.load()', () {
    test(
        'H1: success sets status=success, populates allOptions, marks category seen',
        () async {
      final opts = [_opt('1'), _opt('2')];
      final ctrl = CategoryExperienceController(_FakeRepo(options: opts));

      await ctrl.load(
        categoryId: ServiceCategoryId.beautyWellness,
        config: CategoryPresentationRegistry.forId(
            ServiceCategoryId.beautyWellness),
        reducedMotion: true,
      );

      expect(ctrl.status, CategoryExperienceStatus.success);
      expect(ctrl.allOptions.length, 2);
      expect(CategoryRevealPolicy.hasSeen(ServiceCategoryId.beautyWellness),
          isTrue);
    });

    test('H2: failure sets status=failure and exposes a non-null error', () async {
      final ctrl = CategoryExperienceController(
          _FakeRepo(error: Exception('network error')));

      await ctrl.load(
        categoryId: ServiceCategoryId.massage,
        config:
            CategoryPresentationRegistry.forId(ServiceCategoryId.massage),
        reducedMotion: true,
      );

      expect(ctrl.status, CategoryExperienceStatus.failure);
      expect(ctrl.error, isNotNull);
      expect(ctrl.error, isNotEmpty);
    });

    test('load() is a no-op when already status=loading', () async {
      final ctrl = CategoryExperienceController(_FakeRepo());
      // Drive it into loading state synchronously by checking the guard.
      // We verify the guard by checking the controller's status is idle before
      // load starts, and that a second call while loading doesn't change anything.
      expect(ctrl.status, CategoryExperienceStatus.idle);
      final future = ctrl.load(
        categoryId: ServiceCategoryId.aircon,
        config: CategoryPresentationRegistry.forId(ServiceCategoryId.aircon),
        reducedMotion: true,
      );
      // Immediately after calling load (before awaiting), status is loading.
      expect(ctrl.status, CategoryExperienceStatus.loading);
      // Calling load again while loading should be a no-op (returns synchronously).
      final future2 = ctrl.load(
        categoryId: ServiceCategoryId.aircon,
        config: CategoryPresentationRegistry.forId(ServiceCategoryId.aircon),
        reducedMotion: true,
      );
      await Future.wait([future, future2]);
      // Exactly one load completed — status reaches success.
      expect(ctrl.status, CategoryExperienceStatus.success);
    });
  });

  group('CategoryExperienceController.visibleOptions', () {
    test(
        'H4: returns all allOptions when no chip selected (null selectedLevel2Value)',
        () async {
      final opts = [
        _opt('1', categoryKey: 'drip'),
        _opt('2', categoryKey: 'facial'),
        _opt('3', categoryKey: ''),
      ];
      final ctrl = CategoryExperienceController(_FakeRepo(options: opts));
      await ctrl.load(
        categoryId: ServiceCategoryId.beautyWellness,
        config: CategoryPresentationRegistry.forId(
            ServiceCategoryId.beautyWellness),
        reducedMotion: true,
      );

      expect(ctrl.visibleOptions.length, 3);
    });

    test(
        'H3: selectChip filters by level2Value case-insensitively, not by display label',
        () async {
      final opts = [
        _opt('1', categoryKey: 'drip'),
        _opt('2', categoryKey: 'facial'),
        _opt('3', categoryKey: 'drip'),
      ];
      final ctrl = CategoryExperienceController(_FakeRepo(options: opts));
      await ctrl.load(
        categoryId: ServiceCategoryId.beautyWellness,
        config: CategoryPresentationRegistry.forId(
            ServiceCategoryId.beautyWellness),
        reducedMotion: true,
      );

      ctrl.selectChip(label: 'IV Drip', level2Value: 'drip');

      final visible = ctrl.visibleOptions;
      expect(visible.length, 2);
      expect(visible.every((o) => o.categoryKey == 'drip'), isTrue);
    });

    test(
        'REGRESSION: label and level2Value that differ — filter uses level2Value, not label',
        () async {
      // Regression for the P0 bug where the chip label (e.g. "Beauty Drip")
      // was used as the filter key instead of level2Value ("drip"), resulting
      // in zero matches.
      final opts = [
        _opt('1', categoryKey: 'drip'),
        _opt('2', categoryKey: 'facial'),
      ];
      final ctrl = CategoryExperienceController(_FakeRepo(options: opts));
      await ctrl.load(
        categoryId: ServiceCategoryId.beautyWellness,
        config: CategoryPresentationRegistry.forId(
            ServiceCategoryId.beautyWellness),
        reducedMotion: true,
      );

      // label "Beauty Drip" differs from level2Value "drip".
      ctrl.selectChip(label: 'Beauty Drip', level2Value: 'drip');

      // With the old label-based filter: no option has categoryKey="beauty drip",
      // so visibleOptions would be empty. With the fix it returns 1 option.
      expect(ctrl.visibleOptions.length, 1);
      expect(ctrl.visibleOptions.first.categoryKey, 'drip');
    });
  });

  group('CategoryExperienceController.selectChip()', () {
    test('H5: stores label and level2Value as separate fields', () async {
      final ctrl = CategoryExperienceController(
          _FakeRepo(options: [_opt('1', categoryKey: 'drip')]));
      await ctrl.load(
        categoryId: ServiceCategoryId.beautyWellness,
        config: CategoryPresentationRegistry.forId(
            ServiceCategoryId.beautyWellness),
        reducedMotion: true,
      );

      ctrl.selectChip(label: 'IV Drip', level2Value: 'drip');

      expect(ctrl.selectedChipLabel, 'IV Drip');
      // level2Value is private — confirm via filter: chip label ≠ level2Value
      // so any label-based filter would return 0 results
      expect(ctrl.visibleOptions.length, 1);
    });

    test('selectChip(null, null) resets to show all', () async {
      final opts = [
        _opt('1', categoryKey: 'drip'),
        _opt('2', categoryKey: 'facial'),
      ];
      final ctrl = CategoryExperienceController(_FakeRepo(options: opts));
      await ctrl.load(
        categoryId: ServiceCategoryId.beautyWellness,
        config: CategoryPresentationRegistry.forId(
            ServiceCategoryId.beautyWellness),
        reducedMotion: true,
      );
      ctrl.selectChip(label: 'Drip', level2Value: 'drip');
      expect(ctrl.visibleOptions.length, 1);

      ctrl.selectChip(label: null, level2Value: null);

      expect(ctrl.selectedChipLabel, isNull);
      expect(ctrl.visibleOptions.length, 2);
    });
  });

  group('CategoryExperienceController.dismissOverlay()', () {
    test('sets showOverlay to false', () async {
      final ctrl = CategoryExperienceController(_FakeRepo(options: [_opt('1')]));
      await ctrl.load(
        categoryId: ServiceCategoryId.beautyWellness,
        config: CategoryPresentationRegistry.forId(
            ServiceCategoryId.beautyWellness),
        reducedMotion: false,
      );

      ctrl.dismissOverlay();

      expect(ctrl.showOverlay, isFalse);
    });
  });
}
