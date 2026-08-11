import 'package:flutter/foundation.dart';
import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/modules/categories/data/category_experience_repository.dart';
import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:flutter/material.dart';

enum CategoryExperienceStatus { idle, loading, success, failure }

class CategoryExperienceController extends ChangeNotifier {
  final CategoryExperienceRepository _repository;

  CategoryExperienceController(this._repository);

  CategoryExperienceStatus _status = CategoryExperienceStatus.idle;
  CategoryExperienceStatus get status => _status;

  String? _error;

  /// Cause of the most recent load failure. Diagnostic only — never rendered.
  String? _lastFailureDiagnostic;
  String? get lastFailureDiagnostic => _lastFailureDiagnostic;
  String? get error => _error;

  List<ServiceOptionSummary> _allOptions = [];
  List<ServiceOptionSummary> get allOptions => List.unmodifiable(_allOptions);

  /// Display label of the active chip (e.g. 'Drip', 'All'). Used by the UI to
  /// render the selected state. Null = 'All'.
  String? _selectedChipLabel;
  String? get selectedChipLabel => _selectedChipLabel;

  /// API-level level_2 value to filter by (e.g. 'drip', 'facial'). Null = show all.
  String? _selectedLevel2Value;

  List<ServiceOptionSummary> get visibleOptions {
    if (_selectedLevel2Value == null) return List.unmodifiable(_allOptions);
    final needle = _selectedLevel2Value!.toLowerCase();
    // Substring, for the same reason the repository's allow-list uses one: the
    // chip carries a short key ('drip') and categoryKey is the full level_2
    // label ('Beauty Drip'). Equality meant the Drip chip selected nothing and
    // the screen showed its empty state over ten live treatments.
    return _allOptions
        .where((o) => o.categoryKey.toLowerCase().contains(needle))
        .toList();
  }

  Future<void> load({
    required ServiceCategoryId categoryId,
    required CategoryPresentationConfig config,
    required bool reducedMotion,
  }) async {
    if (_status == CategoryExperienceStatus.loading) return;

    _status = CategoryExperienceStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final options = await _repository.loadOptions(
        serviceId: config.serviceId,
        level2AllowList: config.level2AllowList,
        level2Pattern: config.level2Pattern,
      );
      _allOptions = options;
      _status = CategoryExperienceStatus.success;
    } catch (e, s) {
      // The message shown to the customer is unchanged and stays generic —
      // raw exception text must never reach the UI.
      //
      // But swallowing the cause entirely made "Could not load services"
      // undiagnosable from a real device: every category failed and the only
      // evidence was a screenshot. The endpoint, the service ids, the auth
      // headers, the decode and the price mapper were all verified healthy
      // against production while this was `catch (_)`, and none of them
      // explained it — because the actual exception had already been thrown
      // away. Keep the cause.
      _lastFailureDiagnostic = '$e';
      debugPrint('[CategoryExperience] load failed for '
          'serviceId=${config.serviceId} category=$categoryId: $e\n$s');
      _error = 'Unable to load services.';
      _status = CategoryExperienceStatus.failure;
    }

    notifyListeners();
  }

  /// [label] is the display label (shown in chip UI); [level2Value] is the
  /// API-level filter value (e.g. 'drip'). Pass both null to reset to 'All'.
  void selectChip({String? label, String? level2Value}) {
    _selectedChipLabel = label;
    _selectedLevel2Value = level2Value;
    notifyListeners();
  }

  void retry({
    required ServiceCategoryId categoryId,
    required CategoryPresentationConfig config,
    required bool reducedMotion,
  }) {
    _allOptions = [];
    _status = CategoryExperienceStatus.idle;
    load(categoryId: categoryId, config: config, reducedMotion: reducedMotion);
  }
}
