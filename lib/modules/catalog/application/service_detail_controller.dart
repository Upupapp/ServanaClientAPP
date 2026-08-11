/// Service Detail state, keyed on canonical `services.id`.
///
/// Always fetches. §67 requires price, availability and configuration
/// revalidated before a customer can commit to them, so the cached hierarchy is
/// used only to paint breadcrumbs and a title while the request is in flight —
/// never to answer "is this bookable".
library;

import 'package:flutter/foundation.dart';

import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';

enum ServiceDetailStatus {
  idle,
  loading,
  success,
  unavailable,
  notFound,
  failure
}

class ServiceDetailController extends ChangeNotifier {
  ServiceDetailController(this._repository);

  final CatalogRepository _repository;

  ServiceDetailStatus _status = ServiceDetailStatus.idle;
  ServiceDetailStatus get status => _status;

  CatalogServiceDetail? _detail;
  CatalogServiceDetail? get detail => _detail;

  /// Hierarchy known before the fetch resolves, so the breadcrumb does not pop
  /// in. Null on a cold deep link, which is the case the UI must tolerate.
  CatalogService? _preview;
  CatalogService? get preview => _preview;

  String? _lastFailureDiagnostic;
  String? get lastFailureDiagnostic => _lastFailureDiagnostic;

  final Set<int> _selectedAddonIds = <int>{};

  /// Selected configuration. Add-on ids are `service_options.id` and are NOT
  /// Service ids — they never become the booking's service identity (§8, §70).
  Set<int> get selectedAddonIds => Set.unmodifiable(_selectedAddonIds);

  int _generation = 0;

  /// The Service currently on screen, if any. Canonical id.
  int? get serviceId => _detail?.service.id ?? _preview?.id;

  Future<void> load(int serviceId) async {
    final generation = ++_generation;

    _status = ServiceDetailStatus.loading;
    _preview = _repository.cachedCatalog?.serviceById(serviceId);
    _detail = null;
    _selectedAddonIds.clear();
    _lastFailureDiagnostic = null;
    notifyListeners();

    try {
      final detail = await _repository.serviceDetail(serviceId);
      // A slower request for a previously opened Service must not overwrite the
      // one the customer is looking at now.
      if (generation != _generation) return;

      _detail = detail;
      _status = detail.available
          ? ServiceDetailStatus.success
          : ServiceDetailStatus.unavailable;
    } catch (error) {
      if (generation != _generation) return;
      _lastFailureDiagnostic = error.toString();
      _status = _isNotFound(error)
          ? ServiceDetailStatus.notFound
          : ServiceDetailStatus.failure;
    }
    notifyListeners();
  }

  /// A retired Service and a broken link are different outcomes and get
  /// different copy: one offers alternatives, the other offers retry.
  bool _isNotFound(Object error) {
    final text = error.toString().toUpperCase();
    return text.contains('NOT_FOUND') || text.contains('404');
  }

  void toggleAddon(int addonId) {
    if (!_selectedAddonIds.remove(addonId)) _selectedAddonIds.add(addonId);
    notifyListeners();
  }

  /// Total including selected add-ons, in pesos. Null when the Service has no
  /// base price — "Get a quote" rather than a fabricated zero.
  double? get estimatedTotal {
    final base = _detail?.service.basePrice;
    if (base == null) return null;
    var total = base;
    for (final addon in _detail?.addons ?? const <CatalogAddon>[]) {
      if (_selectedAddonIds.contains(addon.id)) total += addon.basePrice ?? 0;
    }
    return total;
  }

  /// Only a Service the backend says is available may start a booking.
  bool get canStartBooking =>
      _status == ServiceDetailStatus.success && (_detail?.available ?? false);
}
