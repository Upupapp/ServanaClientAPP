/// Canonical Catalog V2 domain models — Category → Subcategory → Service.
///
/// `CatalogService.id` IS the bookable entity. It is `services.id` on the
/// backend, and the same integer that provider capability
/// (`catalog_provider_services.service_id`) and the booking's
/// `catalog_service_id` resolve to. One id from catalog creation through to
/// matching.
///
/// ## What these models deliberately do NOT carry
///
/// No `level2`, no `level3`, no `serviceFamily`. Those belong to the legacy
/// `service_options` taxonomy. A Subcategory is reached through
/// [CatalogService.subcategoryId] and never derived from a name field — the
/// backend's response-parity middleware used to map `name` → `level2`, so a
/// canonical Service arrived claiming its own name as its Subcategory. The
/// public catalog route is exempt from that middleware, and
/// `catalog_level2_regression_test.dart` fails if the key ever reappears.
///
/// ## Identifier type
///
/// Every catalog id is a Dart `int`, matching the backend's integer primary
/// keys. There is no `String serviceId` anywhere in this module; mixing the two
/// for one concept is what §16 of the migration brief forbids.
library;

import 'package:client/common/domain/time/iso_timestamp.dart';

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String? _asNonEmptyString(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Backend `status` domain: `draft` · `active` · `inactive` · `archived`.
///
/// [unknown] is not a backend value — it is where any status this build has
/// never heard of lands. A future backend enum must degrade to "unavailable"
/// rather than crash the catalog (§59), so parsing never throws and callers
/// branch on [CatalogStatus.isVisible] instead of comparing strings.
enum CatalogStatus {
  draft,
  active,
  inactive,
  archived,
  unknown;

  static CatalogStatus parse(Object? raw) => switch (raw?.toString()) {
        'draft' => CatalogStatus.draft,
        'active' => CatalogStatus.active,
        'inactive' => CatalogStatus.inactive,
        'archived' => CatalogStatus.archived,
        _ => CatalogStatus.unknown,
      };

  /// Only `active` is customer-visible. An unknown future value is treated as
  /// not visible: withholding a real service is recoverable, showing an
  /// unbookable one is not.
  bool get isVisible => this == CatalogStatus.active;
}

/// A Specific Service — the canonical bookable entity.
class CatalogService {
  const CatalogService({
    required this.id,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.slug,
    required this.status,
    required this.displayOrder,
    required this.bookable,
    this.shortDescription,
    this.imageUrl,
    this.basePrice,
    this.unit,
    this.basePriceSummary,
    this.estimatedDurationMins,
    this.updatedAt,
  });

  /// `services.id`. The canonical bookable identity.
  final int id;

  final int subcategoryId;
  final String subcategoryName;
  final int categoryId;
  final String categoryName;

  final String name;
  final String slug;
  final CatalogStatus status;
  final int displayOrder;

  /// Backend's own verdict on whether this Service can be booked. Independent
  /// of [status]: a Service can be active and listed but not yet bookable.
  final bool bookable;

  final String? shortDescription;

  /// Null for every Service in production today — the canonical catalog has no
  /// imagery at all. The app supplies its own art via `ServiceThumbnail`'s
  /// keyword map, which is why this being null is a normal case and not a
  /// degraded one.
  final String? imageUrl;

  final double? basePrice;
  final String? unit;

  /// Backend-formatted, e.g. `₱1,500 / per session`. Preferred over formatting
  /// [basePrice] locally so currency and unit wording stay consistent with
  /// Admin and the web portal.
  final String? basePriceSummary;

  /// Null for every Service in production today.
  final int? estimatedDurationMins;

  final DateTime? updatedAt;

  /// Can a customer start a booking for this Service right now?
  ///
  /// Deliberately conservative: both the lifecycle status and the explicit
  /// bookable flag must agree. Availability for a given address is a separate,
  /// backend-authoritative question answered at checkout.
  bool get isBookable => status.isVisible && bookable;

  /// `Personal Care › Facial` — hierarchy context for cards and search results.
  String get hierarchyPath => '$categoryName › $subcategoryName';

  factory CatalogService.fromJson(Map<String, dynamic> json) => CatalogService(
        id: _asInt(json['id']) ?? 0,
        subcategoryId: _asInt(json['subcategoryId']) ?? 0,
        subcategoryName: _asNonEmptyString(json['subcategoryName']) ?? '',
        categoryId: _asInt(json['categoryId']) ?? 0,
        categoryName: _asNonEmptyString(json['categoryName']) ?? '',
        name: _asNonEmptyString(json['name']) ?? '',
        slug: _asNonEmptyString(json['slug']) ?? '',
        status: CatalogStatus.parse(json['status']),
        displayOrder: _asInt(json['displayOrder']) ?? 0,
        // Absent `bookable` means not bookable. Defaulting to true would let a
        // contract change silently re-enable booking on withdrawn services.
        bookable: json['bookable'] == true,
        shortDescription: _asNonEmptyString(json['shortDescription']),
        imageUrl: _asNonEmptyString(json['imageUrl']),
        basePrice: _asDouble(json['basePrice']),
        unit: _asNonEmptyString(json['unit']),
        basePriceSummary: _asNonEmptyString(json['basePriceSummary']),
        estimatedDurationMins: _asInt(json['estimatedDurationMins']),
        updatedAt: parseBackendTimestamp(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subcategoryId': subcategoryId,
        'subcategoryName': subcategoryName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'name': name,
        'slug': slug,
        'status': status.name,
        'displayOrder': displayOrder,
        'bookable': bookable,
        'shortDescription': shortDescription,
        'imageUrl': imageUrl,
        'basePrice': basePrice,
        'unit': unit,
        'basePriceSummary': basePriceSummary,
        'estimatedDurationMins': estimatedDurationMins,
        'updatedAt': formatBackendTimestamp(updatedAt),
      };
}

/// A configuration add-on beneath a Service. Never a Service itself.
class CatalogAddon {
  const CatalogAddon({
    required this.id,
    required this.name,
    this.unit,
    this.basePrice,
    this.basePriceSummary,
    this.durationMins,
  });

  /// `service_options.id` of an `ADD_ON` row. This is configuration identity,
  /// NOT a bookable Service id — never route to Service Detail with it.
  final int id;
  final String name;
  final String? unit;
  final double? basePrice;
  final String? basePriceSummary;
  final int? durationMins;

  factory CatalogAddon.fromJson(Map<String, dynamic> json) => CatalogAddon(
        id: _asInt(json['id']) ?? 0,
        name: _asNonEmptyString(json['name']) ?? '',
        unit: _asNonEmptyString(json['unit']),
        basePrice: _asDouble(json['basePrice']),
        basePriceSummary: _asNonEmptyString(json['basePriceSummary']),
        durationMins: _asInt(json['durationMins']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'basePrice': basePrice,
        'basePriceSummary': basePriceSummary,
        'durationMins': durationMins,
      };
}

/// A Service plus everything Service Detail renders.
class CatalogServiceDetail {
  const CatalogServiceDetail({
    required this.service,
    required this.available,
    this.fullDescription,
    this.inclusions = const [],
    this.exclusions = const [],
    this.addons = const [],
  });

  final CatalogService service;

  /// The backend's verdict, folding in the Subcategory's and Category's status
  /// as well as the Service's own. Computed server-side so the client cannot
  /// drift from it — a Service under a deactivated Category is unavailable even
  /// though its own row still reads `active`.
  final bool available;

  final String? fullDescription;
  final List<String> inclusions;
  final List<String> exclusions;

  /// Configuration, never alternative Services (§8, §70).
  final List<CatalogAddon> addons;

  factory CatalogServiceDetail.fromJson(Map<String, dynamic> json) =>
      CatalogServiceDetail(
        service: CatalogService.fromJson(json),
        available: json['available'] == true,
        fullDescription: _asNonEmptyString(json['fullDescription']),
        inclusions: _stringList(json['inclusions']),
        exclusions: _stringList(json['exclusions']),
        addons: (json['addons'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => CatalogAddon.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  static List<String> _stringList(Object? raw) =>
      (raw as List<dynamic>? ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
}

class CatalogSubcategory {
  const CatalogSubcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.displayOrder,
    required this.services,
    this.description,
    this.imageUrl,
  });

  final int id;
  final int categoryId;
  final String name;
  final String slug;
  final int displayOrder;
  final String? description;
  final String? imageUrl;
  final List<CatalogService> services;

  /// Counted from what this build can actually show, not from the backend's
  /// `serviceCount`. The two agree today; if a future contract sends a count
  /// that includes rows this build filters out, the visible list is the honest
  /// number to put on a card.
  int get serviceCount => services.length;

  factory CatalogSubcategory.fromJson(Map<String, dynamic> json) =>
      CatalogSubcategory(
        id: _asInt(json['id']) ?? 0,
        categoryId: _asInt(json['categoryId']) ?? 0,
        name: _asNonEmptyString(json['name']) ?? '',
        slug: _asNonEmptyString(json['slug']) ?? '',
        displayOrder: _asInt(json['displayOrder']) ?? 0,
        description: _asNonEmptyString(json['description']),
        imageUrl: _asNonEmptyString(json['imageUrl']),
        services: (json['services'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => CatalogService.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'slug': slug,
        'displayOrder': displayOrder,
        'description': description,
        'imageUrl': imageUrl,
        'services': services.map((s) => s.toJson()).toList(),
      };
}

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayOrder,
    required this.subcategories,
    this.description,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String slug;
  final int displayOrder;
  final String? description;
  final String? imageUrl;
  final List<CatalogSubcategory> subcategories;

  int get subcategoryCount => subcategories.length;
  int get serviceCount => subcategories.fold(0, (n, s) => n + s.serviceCount);

  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      CatalogCategory(
        id: _asInt(json['id']) ?? 0,
        name: _asNonEmptyString(json['name']) ?? '',
        slug: _asNonEmptyString(json['slug']) ?? '',
        displayOrder: _asInt(json['displayOrder']) ?? 0,
        description: _asNonEmptyString(json['description']),
        imageUrl: _asNonEmptyString(json['imageUrl']),
        subcategories: (json['subcategories'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) =>
                CatalogSubcategory.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'displayOrder': displayOrder,
        'description': description,
        'imageUrl': imageUrl,
        'subcategories': subcategories.map((s) => s.toJson()).toList(),
      };
}

/// The whole customer-visible catalog, as one cacheable value.
class Catalog {
  const Catalog({
    required this.categories,
    this.fetchedAt,
    this.lastUpdatedAt,
  });

  final List<CatalogCategory> categories;

  /// When this build fetched it — drives cache TTL.
  final DateTime? fetchedAt;

  /// The backend's `MAX(services.updated_at)` — drives revalidation.
  final DateTime? lastUpdatedAt;

  static const empty = Catalog(categories: []);

  bool get isEmpty => categories.isEmpty;

  /// Flattened Services, ordered as the backend ordered them.
  List<CatalogService> get allServices => [
        for (final c in categories)
          for (final s in c.subcategories) ...s.services,
      ];

  CatalogCategory? categoryById(int id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  CatalogSubcategory? subcategoryById(int id) {
    for (final c in categories) {
      for (final s in c.subcategories) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  /// Resolve a Service by canonical id. Identity is never reconstructed from a
  /// name (§35).
  CatalogService? serviceById(int id) {
    for (final c in categories) {
      for (final s in c.subcategories) {
        for (final svc in s.services) {
          if (svc.id == id) return svc;
        }
      }
    }
    return null;
  }

  factory Catalog.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    return Catalog(
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => CatalogCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      lastUpdatedAt: summary is Map
          ? parseBackendTimestamp(summary['lastUpdatedAt'])
          : null,
      fetchedAt: parseBackendTimestamp(json['fetchedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'categories': categories.map((c) => c.toJson()).toList(),
        'summary': {'lastUpdatedAt': formatBackendTimestamp(lastUpdatedAt)},
        'fetchedAt': formatBackendTimestamp(fetchedAt),
      };

  Catalog copyWith({DateTime? fetchedAt}) => Catalog(
        categories: categories,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        lastUpdatedAt: lastUpdatedAt,
      );
}
