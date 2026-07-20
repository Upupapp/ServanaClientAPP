import 'package:flutter/material.dart';

/// Typed specification for one onboarding scene.
///
/// Content is stored here so copy, assets, and analytics IDs are never
/// scattered inside animation widgets.
@immutable
class WelcomeSceneSpec {
  const WelcomeSceneSpec({
    required this.id,
    required this.headline,
    required this.subtext,
    required this.backgroundAsset,
    required this.semanticDescription,
    required this.gradientStops,
    this.compactFocalPoint = Alignment.topCenter,
    this.standardFocalPoint = Alignment.center,
    this.tabletFocalPoint = Alignment.centerLeft,
    this.analyticsId = '',
  });

  /// Unique stable ID — used for analytics and Hero tags.
  final String id;

  /// Primary headline. Keep to one or two short lines.
  final String headline;

  /// Supporting body copy. Must not mention unsupported features.
  final String subtext;

  /// Bundle path to the background lifestyle photograph.
  final String backgroundAsset;

  /// Screen-reader description of the scene's visual content.
  final String semanticDescription;

  /// Three gradient stops for the bottom overlay (top→bottom).
  /// Interpolated continuously during swipe (no onPageChanged snap).
  final List<double> gradientStops;

  /// Focal point used to crop the background on compact phones (≤ 360 dp wide).
  final Alignment compactFocalPoint;

  /// Focal point used on standard phones.
  final Alignment standardFocalPoint;

  /// Focal point used on tablets.
  final Alignment tabletFocalPoint;

  /// Firebase Analytics screen_view event value for this scene.
  final String analyticsId;

  /// The three connected onboarding scenes.
  static const List<WelcomeSceneSpec> scenes = [
    WelcomeSceneSpec(
      id: 'scene_everyday',
      headline: 'Everyday services,\nall in one place.',
      subtext:
          'Find and book available home and personal services in one convenient app.',
      backgroundAsset: 'assets/images/welcome/page_1_bg.png',
      semanticDescription: 'Page 1 of 3: A Filipino customer using Servana at home',
      gradientStops: [0.058, 0.607, 0.738],
      compactFocalPoint: Alignment.topCenter,
      standardFocalPoint: Alignment.center,
      analyticsId: 'welcome_scene_everyday',
    ),
    WelcomeSceneSpec(
      id: 'scene_services',
      headline: 'Find the right\nservice for every need.',
      subtext:
          'Explore available aircon, beauty, wellness, and home-care services in a few taps.',
      backgroundAsset: 'assets/images/welcome/page_2_bg.png',
      semanticDescription:
          'Page 2 of 3: A range of Servana service professionals',
      gradientStops: [0.058, 0.552, 0.854],
      compactFocalPoint: Alignment.topCenter,
      standardFocalPoint: Alignment.center,
      analyticsId: 'welcome_scene_services',
    ),
    WelcomeSceneSpec(
      id: 'scene_booking',
      headline: 'Simple booking.\nClear updates. Better service.',
      subtext:
          'Choose your service, select a schedule, and manage everything from Servana.',
      backgroundAsset: 'assets/images/welcome/page_3_bg.png',
      semanticDescription:
          'Page 3 of 3: A booking confirmation and provider update',
      gradientStops: [0.058, 0.552, 0.854],
      compactFocalPoint: Alignment.topCenter,
      standardFocalPoint: Alignment.center,
      analyticsId: 'welcome_scene_booking',
    ),
  ];
}

/// Visual identifier for the in-scene icon illustration.
enum WelcomeSceneVisual { serviceCategories, serviceCards, bookingJourney }
