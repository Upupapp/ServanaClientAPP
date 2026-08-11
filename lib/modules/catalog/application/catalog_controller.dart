/// Hierarchy browse state.
///
/// The whole tree arrives in one fetch, which has a useful consequence:
/// selecting a Category or Subcategory is a pure local read, so the
/// stale-response race §96 is about — slow response for Category A overwriting
/// Category B — cannot occur on this screen. It is guarded on Service Detail,
/// where a real per-id request does happen.
library;

import 'package:flutter/foundation.dart';

import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';

enum CatalogLoadStatus { idle, loading, refreshing, success, empty, failure }

class CatalogController extends ChangeNotifier {
  CatalogController(this._repository);

  final CatalogRepository _repository;

  CatalogLoadStatus _status = CatalogLoadStatus.idle;
  CatalogLoadStatus get status => _status;

  Catalog _catalog = Catalog.empty;
  Catalog get catalog => _catalog;

  bool _fromCache = false;

  /// True when what is on screen came from disk rather than this fetch. Drives
  /// the "showing saved services" affordance; booking still revalidates.
  bool get isShowingCachedData => _fromCache;

  /// Diagnostic only. Never rendered — §21 and §50 both mean the customer sees
  /// a safe message, not a decoded exception.
  String? _lastFailureDiagnostic;
  String? get lastFailureDiagnostic => _lastFailureDiagnostic;

  /// Generation counter. `load` can be re-entered by a pull-to-refresh landing
  /// on top of an in-flight cold start; only the newest may write state.
  int _generation = 0;

  bool get isLoading =>
      _status == CatalogLoadStatus.loading ||
      _status == CatalogLoadStatus.refreshing;

  Future<void> load({bool forceRefresh = false}) async {
    final generation = ++_generation;

    _status = _catalog.isEmpty
        ? CatalogLoadStatus.loading
        : CatalogLoadStatus.refreshing;
    _lastFailureDiagnostic = null;
    notifyListeners();

    try {
      final snapshot = await _repository.load(forceRefresh: forceRefresh);
      if (generation != _generation) return;

      _catalog = snapshot.catalog;
      _fromCache = snapshot.fromCache;
      _status = _catalog.categories.isEmpty
          ? CatalogLoadStatus.empty
          : CatalogLoadStatus.success;
    } catch (error) {
      if (generation != _generation) return;
      _lastFailureDiagnostic = error.toString();
      // Keep whatever is already on screen. Replacing a rendered catalog with
      // an error state on a failed background refresh is a worse outcome than
      // showing slightly old data.
      _status = _catalog.isEmpty
          ? CatalogLoadStatus.failure
          : CatalogLoadStatus.success;
    }
    notifyListeners();
  }

  Future<void> refresh() => load(forceRefresh: true);

  CatalogCategory? categoryById(int id) => _catalog.categoryById(id);
  CatalogSubcategory? subcategoryById(int id) => _catalog.subcategoryById(id);
  CatalogService? serviceById(int id) => _catalog.serviceById(id);
}
