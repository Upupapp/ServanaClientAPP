import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:client/common/services/app_haptics.dart';
import 'package:client/core/accessibility/focus_coordinator.dart';

/// How a category campaign popup was dismissed.
///
/// The distinction matters for haptics and analytics: a deliberate tap earns
/// feedback and a specific event, a Back gesture or barrier tap does not.
enum CategoryCampaignOutcome {
  /// The customer tapped the artwork's primary call to action.
  cta,

  /// The customer tapped the native close control.
  close,

  /// Android Back, keyboard Escape, or a barrier tap.
  backOrBarrier,
}

/// A full-bleed promotional banner shown when a customer taps a category card.
///
/// This is the visual and interaction shell only. **It performs no
/// navigation** — the caller decides where the CTA leads, which keeps routing
/// with the category flow that already owns it and lets one component serve
/// every category.
///
/// ## Why the artwork needs this much machinery
///
/// The creatives carry their entire message as pixels: heading, service names,
/// benefit cards and the call to action are all painted into a single PNG.
/// That is fine for a designer and hostile to everyone else — rasterised text
/// cannot scale with the system text size, cannot be read aloud, cannot
/// reflow, and cannot be tapped. So this component adds back, in real widgets,
/// the three things the image cannot provide:
///
///  * a **real button** over the drawn CTA, with a touch target that meets the
///    48dp minimum even when the drawn pill renders smaller than that;
///  * **structured semantics**, so a screen reader announces one coherent
///    summary and two actions instead of "image";
///  * a **native fallback layout** that replaces the artwork entirely at large
///    text scales or when the asset fails to load.
class ServanaCategoryCampaignPopup {
  const ServanaCategoryCampaignPopup._();

  /// Presented card width cap. Past this the artwork gains nothing and the CTA
  /// drifts away from where a thumb rests.
  static const double maxCardWidth = 520;

  /// Text scale at which the native layout replaces the artwork.
  ///
  /// Matches [ServanaLaunchBenefitsModal.accessibleLayoutTextScale] so the two
  /// campaign surfaces switch over at the same point; a customer should not
  /// meet one accessible layout and one unreadable image in the same session.
  static const double accessibleLayoutTextScale = 1.3;

  /// Minimum effective height of the CTA touch target, in logical pixels.
  ///
  /// The drawn pill is about 5.7% of the artboard height. On a 360dp phone the
  /// card renders ~328dp wide, so that pill paints roughly **33dp** tall —
  /// well under the platform minimum. The target is therefore grown around the
  /// pill's centre until it reaches this height. The artwork does not move;
  /// only the invisible hit area does.
  static const double minCtaHeight = 48;

  /// Test seams. Semantics labels are what customers get; these are how a test
  /// addresses a control without depending on where its semantics box lands.
  static const ctaKey = ValueKey('category_campaign_cta');
  static const closeKey = ValueKey('category_campaign_close');
  static const artworkKey = ValueKey('category_campaign_artwork');
  static const fallbackKey = ValueKey('category_campaign_fallback');

  /// Shows the campaign and completes with how it was dismissed.
  ///
  /// Completes with null only if the route is popped by something this modal
  /// does not control; callers treat that as [CategoryCampaignOutcome.backOrBarrier].
  ///
  /// [ctaRect] is the drawn call-to-action's rectangle expressed as fractions
  /// of the artboard — measure it from the real PNG rather than estimating, or
  /// the button and the touch target drift apart on some screen widths.
  static Future<CategoryCampaignOutcome?> show({
    required BuildContext context,
    required String assetPath,
    required double assetAspectRatio,
    required Rect ctaRect,
    required String semanticSummary,
    required String primaryActionLabel,
    required String closeLabel,
    required Widget Function(BuildContext, VoidCallback onExplore,
            VoidCallback onClose, VoidCallback onReady)
        fallbackBuilder,
    required VoidCallback onImpressionVerified,
    VoidCallback? onDisplayFailed,
  }) {
    final priorFocus = FocusScope.of(context).focusedChild;
    final reduced = MediaQuery.disableAnimationsOf(context);

    return showGeneralDialog<CategoryCampaignOutcome>(
      context: context,
      // The barrier is an escape hatch, not a trap.
      barrierDismissible: true,
      // Deliberately NOT closeLabel. The barrier and the close button are two
      // different controls; giving them one name makes a screen reader
      // announce two identical "Close ... promotion" targets, and a test
      // looking for the button finds two candidates.
      barrierLabel: 'Dismiss promotion',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      // Root navigator, so the card sits above Home's bottom navigation.
      useRootNavigator: true,
      transitionDuration: reduced
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, _, __) => _CategoryCampaignPage(
        assetPath: assetPath,
        assetAspectRatio: assetAspectRatio,
        ctaRect: ctaRect,
        semanticSummary: semanticSummary,
        primaryActionLabel: primaryActionLabel,
        closeLabel: closeLabel,
        fallbackBuilder: fallbackBuilder,
        onImpressionVerified: onImpressionVerified,
        onDisplayFailed: onDisplayFailed,
      ),
      transitionBuilder: (context, animation, _, child) {
        // Restrained: fade plus a 3% scale on easeOutCubic. Reduced motion
        // drops the movement and keeps a short fade.
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
      // Focus must return to the category card, or a screen-reader user is
      // left pointing at a route that no longer exists.
      if (context.mounted) {
        FocusCoordinator.restoreToNode(priorFocus);
      }
    });
  }
}

class _CategoryCampaignPage extends StatefulWidget {
  const _CategoryCampaignPage({
    required this.assetPath,
    required this.assetAspectRatio,
    required this.ctaRect,
    required this.semanticSummary,
    required this.primaryActionLabel,
    required this.closeLabel,
    required this.fallbackBuilder,
    required this.onImpressionVerified,
    this.onDisplayFailed,
  });

  final String assetPath;
  final double assetAspectRatio;
  final Rect ctaRect;
  final String semanticSummary;
  final String primaryActionLabel;
  final String closeLabel;
  final Widget Function(BuildContext, VoidCallback, VoidCallback, VoidCallback)
      fallbackBuilder;
  final VoidCallback onImpressionVerified;
  final VoidCallback? onDisplayFailed;

  @override
  State<_CategoryCampaignPage> createState() => _CategoryCampaignPageState();
}

class _CategoryCampaignPageState extends State<_CategoryCampaignPage> {
  /// True once the artwork — or the native fallback — has actually painted.
  ///
  /// An impression counts only when the campaign was genuinely rendered.
  /// Counting at schedule time would report views of a modal nobody saw.
  bool _impressionRecorded = false;
  bool _imageFailed = false;

  void _recordImpressionOnce() {
    if (_impressionRecorded || !mounted) return;
    _impressionRecorded = true;
    widget.onImpressionVerified();
  }

  void _close(CategoryCampaignOutcome outcome) {
    switch (outcome) {
      case CategoryCampaignOutcome.cta:
        AppHaptics.medium();
      case CategoryCampaignOutcome.close:
        AppHaptics.light();
      case CategoryCampaignOutcome.backOrBarrier:
        // No haptic for a dismissal the customer did not deliberately tap.
        break;
    }
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1);
    final useFallback = _imageFailed ||
        textScale >= ServanaCategoryCampaignPopup.accessibleLayoutTextScale;

    // Never taller than ~90% of the viewport. The card scrolls inside that, so
    // a short device degrades to scrolling rather than clipping the CTA away.
    final maxHeight = media.size.height * 0.90;
    final width = media.size.width;
    final horizontalMargin = width < 360
        ? 14.0
        : width < 600
            ? 20.0
            : 24.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(CategoryCampaignOutcome.backOrBarrier);
      },
      child: Shortcuts(
        // Keyboard Escape, for external keyboards and switch access.
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                _close(CategoryCampaignOutcome.backOrBarrier);
                return null;
              },
            ),
          },
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            label: widget.semanticSummary,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ServanaCategoryCampaignPopup.maxCardWidth,
                      maxHeight: maxHeight,
                    ),
                    child: useFallback
                        ? KeyedSubtree(
                            key: ServanaCategoryCampaignPopup.fallbackKey,
                            child: widget.fallbackBuilder(
                              context,
                              () => _close(CategoryCampaignOutcome.cta),
                              () => _close(CategoryCampaignOutcome.close),
                              _recordImpressionOnce,
                            ),
                          )
                        : _ArtworkCard(
                            assetPath: widget.assetPath,
                            aspectRatio: widget.assetAspectRatio,
                            ctaRect: widget.ctaRect,
                            primaryActionLabel: widget.primaryActionLabel,
                            closeLabel: widget.closeLabel,
                            onReady: _recordImpressionOnce,
                            onImageFailed: () {
                              // Fall back rather than show a blank card. The
                              // impression is NOT recorded here — the fallback
                              // records it once it paints.
                              widget.onDisplayFailed?.call();
                              if (mounted) setState(() => _imageFailed = true);
                            },
                            onExplore: () =>
                                _close(CategoryCampaignOutcome.cta),
                            onClose: () =>
                                _close(CategoryCampaignOutcome.close),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The artwork, with a real button over the drawn call to action.
class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.assetPath,
    required this.aspectRatio,
    required this.ctaRect,
    required this.primaryActionLabel,
    required this.closeLabel,
    required this.onReady,
    required this.onImageFailed,
    required this.onExplore,
    required this.onClose,
  });

  final String assetPath;
  final double aspectRatio;
  final Rect ctaRect;
  final String primaryActionLabel;
  final String closeLabel;
  final VoidCallback onReady;
  final VoidCallback onImageFailed;
  final VoidCallback onExplore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Short devices scroll rather than crop. The artwork is never clipped.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  // Grow the touch target around the drawn pill's centre until
                  // it clears the platform minimum, then keep it inside the
                  // artwork. The painted button never moves.
                  final drawnHeight = ctaRect.height * h;
                  final targetHeight = drawnHeight
                      .clamp(ServanaCategoryCampaignPopup.minCtaHeight, h)
                      .toDouble();
                  final centreY = (ctaRect.top + ctaRect.height / 2) * h;
                  final top =
                      (centreY - targetHeight / 2).clamp(0.0, h - targetHeight);

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          assetPath,
                          key: ServanaCategoryCampaignPopup.artworkKey,
                          // contain, never cover: cover would crop the
                          // heading or the CTA depending on the viewport.
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          // The artwork is decorative here; the surrounding
                          // Semantics carries the message, so announcing the
                          // image too would duplicate it.
                          excludeFromSemantics: true,
                          frameBuilder: (context, child, frame, wasSyncLoaded) {
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
                      Positioned(
                        left: ctaRect.left * w,
                        width: ctaRect.width * w,
                        top: top,
                        height: targetHeight,
                        child: _PressableCta(
                          label: primaryActionLabel,
                          onTap: onExplore,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _CloseButton(label: closeLabel, onTap: onClose),
          ),
        ],
      ),
    );
  }
}

/// Transparent button over the drawn CTA, with a brief press scale.
class _PressableCta extends StatefulWidget {
  const _PressableCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PressableCta> createState() => _PressableCtaState();
}

class _PressableCtaState extends State<_PressableCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: widget.label,
      hint: 'Opens the available services',
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _down && !reduced ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ServanaCategoryCampaignPopup.ctaKey,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) => setState(() => _down = false),
            onTapCancel: () => setState(() => _down = false),
            borderRadius: BorderRadius.circular(40),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Native close control: 48dp target, high contrast against any artwork.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white24, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ServanaCategoryCampaignPopup.closeKey,
          onTap: onTap,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
