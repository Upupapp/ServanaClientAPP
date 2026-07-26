import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/modules/categories/data/category_experience_repository.dart';
import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:client/modules/categories/domain/category_reveal_policy.dart';
import 'package:flutter/material.dart';

enum CategoryExperienceStatus { idle, loading, success, failure }

class CategoryExperienceController extends ChangeNotifier {
  final CategoryExperienceRepository _repository;

  CategoryExperienceController(this._repository);

  CategoryExperienceStatus _status = CategoryExperienceStatus.idle;
  CategoryExperienceStatus get status => _status;

  String? _error;
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
    return _allOptions
        .where((o) => o.categoryKey.toLowerCase() == needle)
        .toList();
  }

  RevealDecision _revealDecision = RevealDecision.skipReveal;
  RevealDecision get revealDecision => _revealDecision;

  bool _overlayDismissed = false;
  bool get showOverlay =>
      !_overlayDismissed &&
      _revealDecision != RevealDecision.skipReveal &&
      _status == CategoryExperienceStatus.success;

  Future<void> load({
    required ServiceCategoryId categoryId,
    required CategoryPresentationConfig config,
    required bool reducedMotion,
  }) async {
    if (_status == CategoryExperienceStatus.loading) return;

    _revealDecision = CategoryRevealPolicy.decide(
      categoryId: categoryId,
      reducedMotion: reducedMotion,
    );

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
      if (_revealDecision != RevealDecision.skipReveal) {
        CategoryRevealPolicy.markSeen(categoryId);
      }
    } catch (_) {
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

  void dismissOverlay() {
    _overlayDismissed = true;
    notifyListeners();
  }

  void retry({
    required ServiceCategoryId categoryId,
    required CategoryPresentationConfig config,
    required bool reducedMotion,
  }) {
    _allOptions = [];
    _overlayDismissed = false;
    _status = CategoryExperienceStatus.idle;
    load(categoryId: categoryId, config: config, reducedMotion: reducedMotion);
  }
}
