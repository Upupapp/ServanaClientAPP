import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/categories/data/category_addon_filter.dart';
import 'package:client/modules/categories/domain/category_experience.dart';

class CategoryExperienceRepository {
  final ServanaApiClient _api;

  const CategoryExperienceRepository(this._api);

  /// Loads all non-add-on service options for [serviceId], applies the
  /// optional [level2AllowList] / [level2Pattern] filter, and maps to
  /// [ServiceOptionSummary].
  Future<List<ServiceOptionSummary>> loadOptions({
    required int serviceId,
    Set<String>? level2AllowList,
    String? level2Pattern,
  }) async {
    final res = await _api.listOptionsWithAddons(serviceId: serviceId);
    final raw = _extractList(res);

    final filtered = raw
        .whereType<Map<String, dynamic>>()
        .where(CategoryAddonFilter.isNotAddon)
        .where((o) => _matchesLevel2(o, level2AllowList, level2Pattern))
        .toList();

    return filtered.map(ServiceOptionSummaryMapper.fromMap).toList();
  }

  bool _matchesLevel2(
    Map<String, dynamic> option,
    Set<String>? allowList,
    String? pattern,
  ) {
    if (allowList == null && pattern == null) return true;
    final level2 = (option['level2'] ?? '').toString().toLowerCase();
    if (level2.isEmpty) return true; // include options with no category tag
    if (allowList != null) return allowList.contains(level2);
    if (pattern != null) return RegExp(pattern, caseSensitive: false).hasMatch(level2);
    return true;
  }

  List<dynamic> _extractList(Map<String, dynamic> res) {
    for (final key in ['data', 'items', 'branches', 'slots']) {
      final v = res[key];
      if (v is List) return v;
    }
    for (final v in res.values) {
      if (v is List) return v;
    }
    return [];
  }
}
