import 'package:flutter/material.dart';

import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/presentation/category_campaign/category_campaign_accessible_view.dart';
import 'package:client/common/presentation/category_campaign/category_campaign_registry.dart';
import 'package:client/common/presentation/category_campaign/servana_category_campaign_popup.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_event.dart';
import 'package:client/core/analytics/events/category_campaign_events.dart';

/// Presents category campaign popups and reports what the customer did.
///
/// Owns exactly two things the visual component deliberately does not:
///
///  * the **single-instance guard**, so a double tap on a category card cannot
///    stack two modals; and
///  * **analytics**, so the funnel is emitted from one place rather than from
///    inside a widget that rebuilds.
///
/// It performs no navigation. [present] returns whether the customer chose the
/// call to action, and the caller — which already owns the category route and
/// any authentication gate — decides what that means.
class CategoryCampaignCoordinator {
  CategoryCampaignCoordinator({
    required AnalyticsCoordinator analytics,
  }) : _analytics = analytics;

  final AnalyticsCoordinator _analytics;

  /// True from the moment a presentation is claimed until its route has fully
  /// popped.
  ///
  /// Claimed synchronously, before the first `await`, because two taps can be
  /// dispatched in the same frame — an async check would let both through.
  bool _isOpen = false;

  @visibleForTesting
  bool get isOpen => _isOpen;

  /// Whether a campaign exists for [categoryKey].
  ///
  /// A category with no creative keeps its previous behaviour: the caller
  /// navigates straight through, exactly as before.
  static bool hasCampaignFor(String categoryKey) =>
      CategoryCampaignRegistry.forCategoryKey(categoryKey) != null;

  /// Shows the campaign for [categoryKey] and completes with true when the
  /// customer chose the call to action.
  ///
  /// Completes with false when the popup was dismissed, when another
  /// presentation is already in flight, or when the category has no campaign —
  /// all of which mean "do not navigate".
  Future<bool> present({
    required BuildContext context,
    required String categoryKey,
    String entrySource = 'home_category_grid',
  }) async {
    final campaign = CategoryCampaignRegistry.forCategoryKey(categoryKey);
    if (campaign == null) return false;

    // The guard, claimed before any await. Releasing it in `finally` means a
    // thrown route, a cancelled navigation or a disposed widget all reset it —
    // one failure must not lock the category for the rest of the session.
    if (_isOpen) return false;
    _isOpen = true;

    try {
      final outcome = await ServanaCategoryCampaignPopup.show(
        context: context,
        assetPath: campaign.assetPath,
        assetAspectRatio: campaign.aspectRatio,
        ctaRect: campaign.ctaRect,
        semanticSummary: campaign.semanticSummary,
        primaryActionLabel: campaign.primaryActionLabel,
        closeLabel: campaign.closeLabel,
        fallbackBuilder: (ctx, onExplore, onClose, onReady) =>
            _buildFallback(campaign, onExplore, onClose, onReady),
        onImpressionVerified: () => _track(
          CategoryCampaignOpenedEvent(
            campaignKey: campaign.campaignKey,
            categoryKey: campaign.categoryKey,
            entrySource: entrySource,
          ),
        ),
        onDisplayFailed: () => _track(
          CategoryCampaignDisplayFailedEvent(
            campaignKey: campaign.campaignKey,
            categoryKey: campaign.categoryKey,
          ),
        ),
      );

      switch (outcome) {
        case CategoryCampaignOutcome.cta:
          _track(CategoryCampaignCtaSelectedEvent(
            campaignKey: campaign.campaignKey,
            categoryKey: campaign.categoryKey,
          ));
          return true;
        case CategoryCampaignOutcome.close:
          _trackDismissal(campaign, CategoryCampaignDismissal.closeButton);
          return false;
        case CategoryCampaignOutcome.backOrBarrier:
        case null:
          // null means the route was popped by something this modal does not
          // control — treated as a back/barrier dismissal rather than silently
          // ignored, so the funnel still balances.
          _trackDismissal(campaign, CategoryCampaignDismissal.back);
          return false;
      }
    } finally {
      _isOpen = false;
    }
  }

  void _trackDismissal(CategoryCampaign campaign, String method) {
    _track(CategoryCampaignDismissedEvent(
      campaignKey: campaign.campaignKey,
      categoryKey: campaign.categoryKey,
      dismissalMethod: method,
    ));
  }

  void _track(AnalyticsEvent event) {
    // Fire-and-forget: analytics must never delay or block the customer.
    _analytics.track(event).ignore();
  }

  /// The native layout shown at large text scales or when the artwork fails.
  ///
  /// Copy mirrors what is painted into each creative, so a customer who never
  /// sees the image is told the same thing rather than a summary of it.
  Widget _buildFallback(
    CategoryCampaign campaign,
    VoidCallback onExplore,
    VoidCallback onClose,
    VoidCallback onReady,
  ) {
    final config = CategoryRegistry.forId(campaign.categoryId);

    return switch (campaign.categoryId) {
      ServiceCategoryId.beautyWellness => CategoryCampaignAccessibleView(
          heading: 'Beauty & Wellness',
          tagline: 'Feel refreshed, confident, and cared for.',
          body: 'Book beauty and wellness services from your phone, choose '
              'your schedule, and enjoy a smooth, secure experience.',
          services: const [
            'Facials and skin care',
            'Massage and body treatments',
            'Nail care',
            'Salon services',
          ],
          benefits: const [
            'Trusted beauty pros',
            'Easy scheduling',
            'Relaxing experience',
          ],
          primaryActionLabel: campaign.primaryActionLabel,
          closeLabel: campaign.closeLabel,
          accentColor: config.primaryColor,
          onExplore: onExplore,
          onClose: onClose,
          onReady: onReady,
        ),
      ServiceCategoryId.hairAndNails => CategoryCampaignAccessibleView(
          heading: 'Hair & Nails',
          tagline: 'Look your best, every day.',
          body: 'Book hair and nail services from your phone, choose your '
              'style, and enjoy a smooth, secure experience.',
          services: const [
            'Haircut and styling',
            'Hair treatments',
            'Manicure and pedicure',
            'Nail art and extensions',
          ],
          benefits: const [
            'Skilled professionals',
            'Easy booking',
            'Style that fits you',
          ],
          primaryActionLabel: campaign.primaryActionLabel,
          closeLabel: campaign.closeLabel,
          accentColor: config.primaryColor,
          onExplore: onExplore,
          onClose: onClose,
          onReady: onReady,
        ),
      ServiceCategoryId.massage => CategoryCampaignAccessibleView(
          heading: 'Massage & Wellness',
          tagline: 'Relax, recharge, and feel your best.',
          body: 'Book massage and wellness services from your phone, choose '
              'your schedule, and enjoy a smooth, secure experience.',
          services: const [
            'Full body massage',
            'Home spa and wellness',
            'Foot massage',
            'Aromatherapy session',
          ],
          benefits: const [
            'Trusted wellness pros',
            'Easy scheduling',
            'Relaxing experience',
          ],
          primaryActionLabel: campaign.primaryActionLabel,
          closeLabel: campaign.closeLabel,
          accentColor: config.primaryColor,
          onExplore: onExplore,
          onClose: onClose,
          onReady: onReady,
        ),
      ServiceCategoryId.aircon => CategoryCampaignAccessibleView(
          // Heading follows the creative ("Aircon Repair"), not the config
          // title ("Aircon Services"). A customer who reaches the fallback
          // should read the same words the artwork would have shown them.
          heading: 'Aircon Repair',
          tagline: 'Stay cool with fast, reliable help.',
          body: 'Book aircon services from your phone, choose your schedule, '
              'and enjoy a smooth, secure experience.',
          services: const [
            'AC cleaning',
            'Aircon repair',
            'Preventive maintenance',
            'Installation and checkup',
          ],
          benefits: const [
            'Trusted technicians',
            'Easy scheduling',
            'Cooler comfort',
          ],
          primaryActionLabel: campaign.primaryActionLabel,
          closeLabel: campaign.closeLabel,
          accentColor: config.primaryColor,
          onExplore: onExplore,
          onClose: onClose,
          onReady: onReady,
        ),
      // Every registry entry must have fallback copy. A campaign added without
      // it would otherwise ship an unreadable modal to large-text customers.
      _ => CategoryCampaignAccessibleView(
          heading: config.title,
          tagline: config.revealHeadline,
          body: config.revealSubtext,
          services: const [],
          benefits: const [],
          primaryActionLabel: campaign.primaryActionLabel,
          closeLabel: campaign.closeLabel,
          accentColor: config.primaryColor,
          onExplore: onExplore,
          onClose: onClose,
          onReady: onReady,
        ),
    };
  }
}
