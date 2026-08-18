/// Drives Home's category row from the composition transport.
///
/// ## Why this exists
///
/// `HomeCompositionRepository` was registered in the injector and the only
/// thing that ever touched it was a `CleanupStep('homeComposition')` calling
/// `.clear()` on logout — the app cleared a cache nothing ever filled, and
/// `V1Capability.home` was inert because the object that reads the flag had no
/// callers. This is the caller.
///
/// ## What it does and does not own
///
/// Only the **categories** section. That is the one section the compatibility
/// transport can actually produce today — it reads the canonical Catalog V2
/// hierarchy, so Home and the catalog cannot disagree about what exists — and
/// the rest arrive as `HomeSectionAbsent` until `/api/v1/home` deploys.
/// Merchants, bookings and search stay on `HomeStore`. Claiming the whole page
/// here would be the `⚠ mixed` state the backend's own parity matrix warns
/// about.
///
/// ## Failure is a state, not an exception
///
/// The repository serves the last good composition when a load fails and only
/// rethrows when there is no cache at all. Both outcomes land in [state]
/// rather than propagating: Home has always rendered its categories from a
/// hardcoded list, so a failure here must leave the screen no worse than it
/// was, never blank.
library;

import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/homepage/data/home_composition_repository.dart';
import 'package:client/modules/homepage/domain/home_composition.dart';
import 'package:flutter/foundation.dart';

/// One category as Home needs to draw it.
@immutable
class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.serviceCount,
  });

  /// `catalog_categories.id` — what the catalog browse route is keyed on.
  ///
  /// NOT the slug. `CatalogRoutes.categoryPath` takes an id precisely so a
  /// rename cannot break a saved link, and `CatalogRoutes.parseId` rejects
  /// anything that is not a positive integer.
  final int id;

  final String name;

  /// The backend's slug, for recognising a category rather than routing to it.
  ///
  /// Kept because it is the only stable way to tell whether a catalog category
  /// is one Home already draws a curated card for — and the two vocabularies
  /// do not match. `slugify` on the backend produces HYPHENS
  /// (`beauty-wellness`); this app's routing keys and its category campaign
  /// registry use UNDERSCORES (`beauty_wellness`). Feeding a backend slug into
  /// either would fail silently: `forCategoryKey` returns null, no popup
  /// shows, and nothing throws.
  final String slug;

  final int? serviceCount;

  /// The curated key this category corresponds to, if any.
  String get curatedKey => slug.replaceAll('-', '_');
}

/// What Home should show for its categories right now.
sealed class HomeCategoriesState {
  const HomeCategoriesState();
}

/// Nothing has been asked for yet, or a load is in flight and there is no
/// previous answer to keep showing.
class HomeCategoriesLoading extends HomeCategoriesState {
  const HomeCategoriesLoading();
}

/// The catalog answered.
class HomeCategoriesReady extends HomeCategoriesState {
  const HomeCategoriesReady(this.categories, {required this.isStale});

  final List<HomeCategory> categories;

  /// True when these came from the last good composition rather than this
  /// load. Surfaced so the screen can say so instead of implying it is live.
  final bool isStale;
}

/// The catalog could not be read and there is nothing cached.
///
/// Home still renders — its curated categories are presentation, not backend
/// truth — so this is a signal to fall back, not an error screen.
class HomeCategoriesUnavailable extends HomeCategoriesState {
  const HomeCategoriesUnavailable(this.failure);

  final ApiFailure? failure;
}

class HomeCompositionController extends ChangeNotifier {
  HomeCompositionController(this._repository);

  final HomeCompositionRepository _repository;

  HomeCategoriesState _state = const HomeCategoriesLoading();
  HomeCategoriesState get state => _state;

  bool _loading = false;

  /// True when Home's categories are being composed by `/api/v1/home`.
  /// Diagnostics only — no screen branches on it.
  bool get isCanonical => _repository.isCanonical;

  /// Loads the composition once per session unless [force] is set.
  ///
  /// Home rebuilds often — tab switches, returning from a booking flow — and
  /// re-composing on every build would put the catalog behind a request the
  /// customer did not ask for.
  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _state is HomeCategoriesReady) return;

    _loading = true;
    try {
      final composition = await _repository.load();
      _publish(composition);
    } on ApiFailure catch (failure) {
      _set(HomeCategoriesUnavailable(failure));
    } catch (_) {
      // The repository only rethrows when it has no cache to fall back on.
      // Whatever it was, Home is not the place to surface it.
      _set(const HomeCategoriesUnavailable(null));
    } finally {
      _loading = false;
    }
  }

  void _publish(HomeComposition composition) {
    final section = composition.sections[HomeSectionType.categories];

    switch (section) {
      case HomeSectionLoaded(items: final items):
        final categories = items
            .map(_toCategory)
            .whereType<HomeCategory>()
            .toList(growable: false);
        // An empty catalog is not a catalog. Falling back keeps Home usable
        // rather than rendering a heading with nothing under it.
        if (categories.isEmpty) {
          _set(const HomeCategoriesUnavailable(null));
          return;
        }
        _set(
          HomeCategoriesReady(
            categories,
            isStale: section.origin == HomeSectionOrigin.cached,
          ),
        );
      case HomeSectionFailed(failure: final failure):
        _set(HomeCategoriesUnavailable(failure));
      case _:
        // Absent: this transport does not offer the section at all. Not a
        // failure, and nothing to retry.
        _set(const HomeCategoriesUnavailable(null));
    }
  }

  /// A row becomes a category only if it has both a canonical id and a name.
  static HomeCategory? _toCategory(Map<String, dynamic> row) {
    final rawId = row['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse('${rawId ?? ''}');
    final name = row['name']?.toString().trim();
    final slug = (row['slug'] ?? '').toString().trim();

    // No id routes nowhere and no name is a blank tile. Dropping the row is
    // better than drawing something that cannot be tapped.
    if (id == null || id <= 0) return null;
    if (name == null || name.isEmpty) return null;

    final count = row['serviceCount'];
    return HomeCategory(
      id: id,
      name: name,
      slug: slug,
      serviceCount: count is num ? count.toInt() : null,
    );
  }

  void _set(HomeCategoriesState next) {
    _state = next;
    notifyListeners();
  }
}
