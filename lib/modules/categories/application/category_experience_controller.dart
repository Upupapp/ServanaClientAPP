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

  String? _selectedChipLabel;
  String? get selectedChipLabel => _selectedChipLabel;

  List<ServiceOptionSummary> get visibleOptions {
    if (_selectedChipLabel == null || _selectedChipLabel == 'All') {
      return List.unmodifiable(_allOptions);
    }
    return _allOptions
        .where((o) => o.categoryKey == _selectedChipLabel)
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
    } catch (e) {
      _error = e.toString();
      _status = CategoryExperienceStatus.failure;
    }

    notifyListeners();
  }

  void selectChip(String? label) {
    _selectedChipLabel = label;
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
