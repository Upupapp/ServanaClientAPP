import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/core/accessibility/focus_coordinator.dart';
import 'package:client/modules/homepage/presentation/widgets/servana_launch_benefits_accessible_view.dart';

/// How the customer left the campaign (LAUNCHBANNER+ §6).
///
/// [backOrBarrier] is deliberately separate from [close]: both dismiss, but
/// only Close is an explicit rejection. Treating a reflexive back-swipe as
/// "never show again" silently destroys reach, so it maps to remind-later
/// behaviour while remaining distinguishable in analytics.
enum LaunchBannerOutcome { cta, close, remindLater, backOrBarrier }

/// The Servana launch-benefits campaign modal.
///
/// Presentation rules that are not obvious from the code:
///
/// * The artwork is shown with [BoxFit.contain] inside its true aspect ratio,
///   never [BoxFit.cover] — §10 forbids cropping the headline, the CTA or the
///   footer, and cover crops whichever axis is tighter.
/// * The CTA is a real button positioned over the pill drawn in the artwork,
///   with its rectangle derived from artboard fractions. Making the whole image
///   tappable would be ambiguous; hard-coding screen pixels would break on
///   every other device.
/// * Above a text scale of 1.3, or when the image fails, the modal renders
///   [ServanaLaunchBenefitsAccessibleView] instead. Rasterised text cannot
///   scale, so past that point the image is actively worse than real widgets.
class ServanaLaunchBenefitsModal {
  const ServanaLaunchBenefitsModal._();

  /// Artboard-relative CTA rectangle, measured from the 941x1672 source rather
  /// than estimated. The pill occupies x 194..769, y 1467..1580.
  static const double ctaLeftFraction = 0.2062;
  static const double ctaTopFraction = 0.8774;
  static const double ctaRightFraction = 0.8183;
  static const double ctaBottomFraction = 0.9456;

  /// Text scale past which the native layout replaces the artwork (§33).
  static const double accessibleLayoutTextScale = 1.3;

  /// Presented card width cap (§9). Beyond this the artwork gains nothing and
  /// the CTA drifts uncomfortably far from the thumb.
  static const double maxCardWidth = 520;

  /// Test seams. Semantics labels are what customers get; these are how tests
  /// address a control without depending on where its semantics box lands.
  static const ctaKey = ValueKey('launch_banner_cta');
  static const closeKey = ValueKey('launch_banner_close');
  static const remindKey = ValueKey('launch_banner_remind');

  /// Shows the campaign and completes with the customer's choice.
  ///
  /// Returns null only if the route is popped by something other than this
  /// modal's own controls — treated by the caller as a back/barrier dismissal.
  static Future<LaunchBannerOutcome?> show({
    required BuildContext context,
    required String assetPath,
    required double assetAspectRatio,
    required VoidCallback onImpressionVerified,
    VoidCallback? onDisplayFailed,
  }) {
    final priorFocus = FocusScope.of(context).focusedChild;
    final reduced = MediaQuery.disableAnimationsOf(context);

    return showGeneralDialog<LaunchBannerOutcome>(
      context: context,
      // §18: the barrier is an escape hatch, not a trap.
      barrierDismissible: true,
      barrierLabel: 'Dismiss launch banner',
      barrierColor: Colors.black.withOpacity(0.62),
      // Root navigator so the card sits above Home's bottom navigation (§9).
      useRootNavigator: true,
      transitionDuration: reduced
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, __) => _LaunchBannerPage(
        assetPath: assetPath,
        assetAspectRatio: assetAspectRatio,
        onImpressionVerified: onImpressionVerified,
        onDisplayFailed: onDisplayFailed,
      ),
      transitionBuilder: (context, animation, _, child) {
        // §19: restrained. Fade plus a 3% scale, easeOutCubic. Reduced motion
        // drops the movement entirely and keeps only a short fade.
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        if (reduced) {
          return FadeTransition(opacity: curved, child: child);
        }
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ).whenComplete(() {
      // §34: focus must come back to Home, or a screen-reader user is left
      // pointing at a route that no longer exists.
      if (context.mounted) {
        FocusCoordinator.restoreToNode(priorFocus);
      }
    });
  }
}

class _LaunchBannerPage extends StatefulWidget {
  const _LaunchBannerPage({
    required this.assetPath,
    required this.assetAspectRatio,
    required this.onImpressionVerified,
    this.onDisplayFailed,
  });

  final String assetPath;
  final double assetAspectRatio;
  final VoidCallback onImpressionVerified;
  final VoidCallback? onDisplayFailed;

  @override
  State<_LaunchBannerPage> createState() => _LaunchBannerPageState();
}

class _LaunchBannerPageState extends State<_LaunchBannerPage> {
  /// True once the artwork (or the native fallback) has actually painted.
  ///
  /// §28: an impression counts only when the campaign was genuinely rendered.
  /// Counting at schedule time would spend the customer's three-impression
  /// budget on modals they never saw.
  bool _impressionRecorded = false;
  bool _imageFailed = false;

  void _recordImpressionOnce() {
    if (_impressionRecorded || !mounted) return;
    _impressionRecorded = true;
    widget.onImpressionVerified();
  }

  void _close(LaunchBannerOutcome outcome) {
    switch (outcome) {
      case LaunchBannerOutcome.cta:
        AppHaptics.medium();
      case LaunchBannerOutcome.close:
      case LaunchBannerOutcome.remindLater:
        AppHaptics.light();
      case LaunchBannerOutcome.backOrBarrier:
        // §20: no haptic for a dismissal the customer did not deliberately tap.
        break;
    }
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1);
    final useAccessibleLayout = _imageFailed ||
        textScale >= ServanaLaunchBenefitsModal.accessibleLayoutTextScale;

    // §9: never taller than ~90% of the viewport, and the card is scrollable
    // inside that, so a short device degrades to scrolling rather than
    // clipping the CTA off the bottom.
    final maxHeight = media.size.height * 0.90;
    final horizontalMargin = media.size.width < 360 ? 16.0 : 20.0;

    return PopScope(
      // §18: Back is allowed, but it means "remind me later", not "never".
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(LaunchBannerOutcome.backOrBarrier);
      },
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        label: 'Servana launch banner',
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ServanaLaunchBenefitsModal.maxCardWidth,
                  maxHeight: maxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: useAccessibleLayout
                          ? _AccessibleCard(
                              assetPath: widget.assetPath,
                              onReady: _recordImpressionOnce,
                              onExplore: () => _close(LaunchBannerOutcome.cta),
                              onRemindLater: () =>
                                  _close(LaunchBannerOutcome.remindLater),
                              onClose: () => _close(LaunchBannerOutcome.close),
                            )
                          : _ArtworkCard(
                              assetPath: widget.assetPath,
                              aspectRatio: widget.assetAspectRatio,
                              onReady: _recordImpressionOnce,
                              onImageFailed: () {
                                // Fall back rather than show a blank card
                                // (§29). The impression is NOT recorded here —
                                // the accessible layout records it once it
                                // paints.
                                widget.onDisplayFailed?.call();
                                if (mounted) {
                                  setState(() => _imageFailed = true);
                                }
                              },
                              onExplore: () => _close(LaunchBannerOutcome.cta),
                              onClose: () => _close(LaunchBannerOutcome.close),
                            ),
                    ),
                    const SizedBox(height: 12),
                    // §15: a real, clearly-worded secondary action. "Maybe
                    // later" would be untrue — this schedules a return.
                    _RemindLaterButton(
                      key: ServanaLaunchBenefitsModal.remindKey,
                      onPressed: () => _close(LaunchBannerOutcome.remindLater),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The artwork presentation, with a real button over the drawn CTA.
class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.assetPath,
    required this.aspectRatio,
    required this.onReady,
    required this.onImageFailed,
    required this.onExplore,
    required this.onClose,
  });

  final String assetPath;
  final double aspectRatio;
  final VoidCallback onReady;
  final VoidCallback onImageFailed;
  final VoidCallback onExplore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // NOT scrollable, deliberately.
    //
    // An earlier version wrapped this in a SingleChildScrollView. Because the
    // creative is very tall (941x1672), the content then exceeded the viewport
    // on an ordinary 390x844 phone — the scroll view measured 480pt against
    // 622pt of artwork — and the "Explore Services" pill sat 60pt BELOW the
    // fold. The campaign rendered perfectly and its primary action was
    // invisible unless the customer thought to scroll a picture.
    //
    // AspectRatio honours the incoming maxHeight, so letting it size itself
    // inside the bounded box shrinks the whole creative to fit and keeps the
    // CTA on screen at every size. §32 wants scrolling as a fallback for short
    // devices, not the normal case.
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              // §13: derived from artboard fractions and scaled with the
              // rendered image, never hard-coded in screen pixels.
              final left = w * ServanaLaunchBenefitsModal.ctaLeftFraction;
              final top = h * ServanaLaunchBenefitsModal.ctaTopFraction;
              final ctaWidth = w *
                  (ServanaLaunchBenefitsModal.ctaRightFraction -
                      ServanaLaunchBenefitsModal.ctaLeftFraction);
              final drawnHeight = h *
                  (ServanaLaunchBenefitsModal.ctaBottomFraction -
                      ServanaLaunchBenefitsModal.ctaTopFraction);
              // §13 floor: the drawn pill can render shorter than 56pt on a
              // small screen, but the touch target must not.
              final ctaHeight = drawnHeight < 56.0 ? 56.0 : drawnHeight;
              // Grow around the drawn centre so the enlarged target stays
              // visually aligned with the pill.
              final ctaTop = top - ((ctaHeight - drawnHeight) / 2);

              return Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: Image.asset(
                        assetPath,
                        // §10: contain, never cover — cover crops the headline
                        // or the CTA depending on which axis is tighter.
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        frameBuilder: (_, child, frame, wasSyncLoaded) {
                          if (wasSyncLoaded || frame != null) {
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) => onReady());
                          }
                          return child;
                        },
                        errorBuilder: (_, __, ___) {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) => onImageFailed());
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),

                  // §17: one semantic summary for the whole creative, rather
                  // than the reader guessing at rasterised words.
                  Positioned.fill(
                    child: Semantics(
                      label: 'Servana offers beauty, wellness, aircon, '
                          'appliance and home-repair services in one app.',
                      child: const SizedBox.expand(),
                    ),
                  ),

                  Positioned(
                    left: left,
                    top: ctaTop,
                    width: ctaWidth,
                    height: ctaHeight,
                    child: _CtaHotspot(
                      key: ServanaLaunchBenefitsModal.ctaKey,
                      onPressed: onExplore,
                    ),
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CloseButton(
                      key: ServanaLaunchBenefitsModal.closeKey,
                      onPressed: onClose,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Transparent, accessible button laid over the CTA drawn in the artwork.
/// Transparent, accessible button laid over the CTA drawn in the artwork.
///
/// Built on [Material] + [InkWell] rather than a bare [GestureDetector]. A
/// GestureDetector whose child paints nothing is not reliably hit-testable —
/// an earlier version wrapped an AnimatedContainer with a null colour, and
/// taps fell straight through to the modal barrier and dismissed the campaign
/// instead of opening services. InkWell is hit-testable by construction and
/// supplies the press feedback §13 asks for.
class _CtaHotspot extends StatelessWidget {
  const _CtaHotspot({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: 'Explore Servana services',
      hint: 'Opens the Servana services catalogue',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          // The pill is already drawn in the artwork, so the feedback only has
          // to acknowledge the touch — a full ripple would fight the creative.
          splashColor: reduced ? Colors.transparent : Colors.white24,
          highlightColor: Colors.white10,
          // ColoredBox, not SizedBox: a box that paints NOTHING is not
          // hit-testable, so taps fell through to the modal barrier and
          // dismissed the campaign instead of opening services. A transparent
          // colour still paints, and therefore still receives pointers.
          child: const ColoredBox(
            color: Colors.transparent,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// §12: a real close control, not an X baked into the image.
class _CloseButton extends StatelessWidget {
  const _CloseButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close launch banner',
      excludeSemantics: true,
      child: Material(
        color: Colors.black.withOpacity(0.45),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            // Comfortably past the 48pt minimum.
            width: 48,
            height: 48,
            child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Native card used at large text scales and when the artwork fails (§16).
class _AccessibleCard extends StatefulWidget {
  const _AccessibleCard({
    required this.assetPath,
    required this.onReady,
    required this.onExplore,
    required this.onRemindLater,
    required this.onClose,
  });

  final String assetPath;
  final VoidCallback onReady;
  final VoidCallback onExplore;
  final VoidCallback onRemindLater;
  final VoidCallback onClose;

  @override
  State<_AccessibleCard> createState() => _AccessibleCardState();
}

class _AccessibleCardState extends State<_AccessibleCard> {
  @override
  void initState() {
    super.initState();
    // This layout is pure widgets, so it is on screen as soon as it builds —
    // there is no decode to wait for.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.secondaryBackground,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leaves room for the close control without the heading
                // sliding underneath it.
                const SizedBox(height: 28),
                ServanaLaunchBenefitsAccessibleView(
                  onExplore: widget.onExplore,
                  onRemindLater: widget.onRemindLater,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'Explore Servana services',
                    hint: 'Opens the Servana services catalogue',
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: widget.onExplore,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: ColorPalette.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'Explore Services',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Semantics(
              button: true,
              label: 'Close launch banner',
              excludeSemantics: true,
              child: IconButton(
                onPressed: widget.onClose,
                iconSize: 22,
                // iconSize alone does not make a 48pt target.
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.close_rounded,
                    color: ColorPalette.secondaryText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// §15: the secondary action, outside the card and above the scrim.
class _RemindLaterButton extends StatelessWidget {
  const _RemindLaterButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remind me later',
      hint: 'Hides this for seven days',
      excludeSemantics: true,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(120, 48),
          foregroundColor: Colors.white,
        ),
        child: Text(
          'Remind me later',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            // The scrim behind this is dark but the artwork is not uniform;
            // a shadow keeps it legible wherever it lands.
            shadows: const [
              Shadow(
                  color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
