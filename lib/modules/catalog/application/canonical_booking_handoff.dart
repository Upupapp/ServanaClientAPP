/// The bridge from canonical Service Detail into the existing booking flow.
///
/// ## What this guarantees
///
/// The booking payload's service identity is the canonical `services.id` the
/// customer selected — by construction, not by coincidence.
///
/// That distinction matters. Measured on production, `services.id` currently
/// EQUALS `service_options.id` for all 95 promoted rows, so the app has in fact
/// been sending the canonical id all along under the name `serviceOptionId`.
/// But that equality is an artefact of how the promotion migration assigned
/// ids, and it stops holding for the first Service created through the Admin
/// API — those take their id from `catalog_services_id_seq` and have no legacy
/// option at all. Seeding the store from the canonical Service means the app is
/// correct on both sides of that change; the backend's insert resolves the
/// column through `legacy_service_option_id` for the same reason.
///
/// ## What is deliberately still legacy
///
/// The booking stores, their checkout screens and the pricing quote are
/// unchanged. This seeds `selectedOption` with a canonical-derived map and
/// routes into the flow that already exists. Two things remain keyed on the
/// legacy family and are NOT solved here, because both need backend work
/// beyond the catalog read API:
///
///  - branch/slot selection (`GET /api/services/:familyId/branches`)
///  - coverage-geo serviceability (`/api/services/:familyId/coverage-geo`)
///
/// Neither is reachable from this handoff for a non-branch Service, which is
/// every Service in production today. See CLIENT_BOOKING_V2_CONTRACT.md.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_checkout_screen.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';

/// Which existing checkout flow a canonical Service belongs to.
///
/// Resolved from the canonical Category, which is a real backend entity with a
/// stable id — not from a name regex over `level_2`, which is what the legacy
/// `CategoryPresentationRegistry` did and why adding a category needed an app
/// release.
///
/// This is a presentation choice (which checkout screen to show), never an
/// identity claim. The Service id is canonical regardless of which branch it
/// takes.
enum CanonicalBookingFlow { aircon, beautyWellness }

/// Category ids measured in production: 1 Home Maintenance, 2 Home Services,
/// 3 Personal Care.
///
/// Home Services is the aircon flow; everything else uses the
/// Beauty & Wellness checkout, which is the generic one. Unknown ids fall to
/// that generic flow rather than failing — a new Category must be bookable the
/// day an admin creates it, without an app release.
CanonicalBookingFlow resolveBookingFlow(CatalogService service) =>
    switch (service.categoryId) {
      2 => CanonicalBookingFlow.aircon,
      _ => CanonicalBookingFlow.beautyWellness,
    };

/// The legacy option map the booking stores read.
///
/// Keys mirror what `/api/services/:id/options-with-addons` returns, because
/// that is what every downstream screen and `ServiceCardModel.extractPrice`
/// already parse. `id` is the canonical `services.id` and becomes the payload's
/// `serviceOptionId`.
@visibleForTesting
Map<String, dynamic> canonicalOptionMap(CatalogServiceDetail detail) {
  final service = detail.service;
  return <String, dynamic>{
    'id': service.id,
    'serviceOptionId': service.id,
    'level3': service.name,
    'unit': service.unit,
    'basePrice': service.basePrice,
    'durationMins': service.estimatedDurationMins,
    'description': detail.fullDescription ?? service.shortDescription,
    'inclusions': detail.inclusions,
    'exclusions': detail.exclusions,
    'addons': [
      for (final addon in detail.addons)
        {
          'id': addon.id,
          'level3': addon.name,
          'unit': addon.unit,
          'basePrice': addon.basePrice,
          'durationMins': addon.durationMins,
        },
    ],
    // Canonical hierarchy, carried as a booking-time snapshot so history can
    // render "Personal Care › Facial" without re-resolving a catalog that may
    // have moved since (§25, §42).
    'catalogServiceId': service.id,
    'catalogSubcategoryId': service.subcategoryId,
    'catalogSubcategoryName': service.subcategoryName,
    'catalogCategoryId': service.categoryId,
    'catalogCategoryName': service.categoryName,
  };
}

/// Seeds the booking store from the canonical Service and routes to checkout.
///
/// Refuses to start when the backend says the Service is unavailable. The CTA
/// is already disabled in that state; this is the second check, because a
/// disabled button is a UI affordance and not a guarantee.
void startCanonicalBooking({
  required BuildContext context,
  required CatalogServiceDetail detail,
  required Set<int> selectedAddonIds,
}) {
  if (!detail.available) return;

  final option = canonicalOptionMap(detail);
  final flow = resolveBookingFlow(detail.service);

  switch (flow) {
    case CanonicalBookingFlow.aircon:
      final store = dpLocator<AirconBookingStore>();
      store.selectOption(option);
      for (final id in selectedAddonIds) {
        store.toggleAddon(id);
      }
      context.pushNamed(AirconCheckoutScreen.routeName);
    case CanonicalBookingFlow.beautyWellness:
      final store = dpLocator<BwBookingStore>();
      store.selectOption(option);
      for (final id in selectedAddonIds) {
        store.toggleAddon(id);
      }
      context.pushNamed(BwCheckoutScreen.routeName);
  }
}
