import 'package:flutter/material.dart';

/// Stable ID for each top-level service category. Never derive identity from
/// display text, route names, or level_2 strings — use this enum exclusively.
enum ServiceCategoryId {
  beautyWellness,
  hairAndNails,
  massage,
  aircon,
  generic,
}

/// Visual and behavioral configuration for a single service category.
class CategoryConfig {
  const CategoryConfig({
    required this.id,
    required this.title,
    required this.revealHeadline,
    required this.revealSubtext,
    required this.primaryColor,
    required this.accentColor,
    required this.firstViewRevealDuration,
    required this.repeatViewRevealDuration,
    this.semanticAnnouncement,
  });

  final ServiceCategoryId id;
  final String title;
  final String revealHeadline;
  final String revealSubtext;
  final Color primaryColor;
  final Color accentColor;

  /// Full reveal duration for the first time a user enters this category per
  /// session. Includes content animation + hold time.
  final Duration firstViewRevealDuration;

  /// Compact entrance duration for subsequent visits. Minimal, non-blocking.
  final Duration repeatViewRevealDuration;

  /// Accessibility announcement spoken by screen readers on overlay mount.
  final String? semanticAnnouncement;
}

/// Canonical registry of every category's experience config.
/// Access via [CategoryRegistry.forId] or named getters.
abstract final class CategoryRegistry {
  static const CategoryConfig beautyWellness = CategoryConfig(
    id: ServiceCategoryId.beautyWellness,
    title: 'Beauty',
    revealHeadline: 'Feel your best.',
    revealSubtext: 'Premium Beauty & Wellness services, brought to you.',
    primaryColor: Color(0xFF3058C8),
    accentColor: Color(0xFFF89040),
    firstViewRevealDuration: Duration(milliseconds: 900),
    repeatViewRevealDuration: Duration(milliseconds: 300),
    semanticAnnouncement: 'Beauty and Wellness services',
  );

  static const CategoryConfig hairAndNails = CategoryConfig(
    id: ServiceCategoryId.hairAndNails,
    title: 'Hair & Nails',
    revealHeadline: 'Express yourself.',
    revealSubtext: 'Hair styling and nail care for every look.',
    primaryColor: Color(0xFF3058C8),
    accentColor: Color(0xFFF89040),
    firstViewRevealDuration: Duration(milliseconds: 750),
    repeatViewRevealDuration: Duration(milliseconds: 250),
    semanticAnnouncement: 'Hair and Nails services',
  );

  static const CategoryConfig massage = CategoryConfig(
    id: ServiceCategoryId.massage,
    title: 'Massage',
    revealHeadline: 'Rest and recover.',
    revealSubtext: 'Therapeutic massage services at your convenience.',
    primaryColor: Color(0xFF3D6B5F),
    accentColor: Color(0xFFB8D4CE),
    firstViewRevealDuration: Duration(milliseconds: 850),
    repeatViewRevealDuration: Duration(milliseconds: 300),
    semanticAnnouncement: 'Massage services',
  );

  static const CategoryConfig aircon = CategoryConfig(
    id: ServiceCategoryId.aircon,
    title: 'Aircon Services',
    revealHeadline: 'Stay cool.',
    revealSubtext:
        'Cleaning, installation, and repair by certified technicians.',
    primaryColor: Color(0xFF1A4A7C),
    accentColor: Color(0xFF7BB8D4),
    firstViewRevealDuration: Duration(milliseconds: 700),
    repeatViewRevealDuration: Duration(milliseconds: 250),
    semanticAnnouncement: 'Aircon services',
  );

  static const CategoryConfig generic = CategoryConfig(
    id: ServiceCategoryId.generic,
    title: 'Services',
    revealHeadline: 'Ready for you.',
    revealSubtext: 'Professional services on demand.',
    primaryColor: Color(0xFF3058C8),
    accentColor: Color(0xFFF89040),
    firstViewRevealDuration: Duration(milliseconds: 400),
    repeatViewRevealDuration: Duration.zero,
    semanticAnnouncement: 'Services',
  );

  static CategoryConfig forId(ServiceCategoryId id) => switch (id) {
        ServiceCategoryId.beautyWellness => beautyWellness,
        ServiceCategoryId.hairAndNails => hairAndNails,
        ServiceCategoryId.massage => massage,
        ServiceCategoryId.aircon => aircon,
        ServiceCategoryId.generic => generic,
      };
}
