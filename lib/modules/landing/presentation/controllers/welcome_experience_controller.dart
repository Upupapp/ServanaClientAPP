import 'package:client/modules/landing/domain/welcome_motion_mode.dart';
import 'package:flutter/widgets.dart';

/// Single source of truth for the WelcomeScreen animation and navigation state.
///
/// Owned by [WelcomeScreen] and passed down via [InheritedWidget] or listened
/// to directly with [ListenableBuilder]. Holding it in the screen's State
/// ensures it is disposed when the screen leaves the tree.
///
/// Responsibilities:
///   - Owns the [PageController] so every child reacts to the same source.
///   - Exposes continuous [pageProgress] (fractional page position) so layers
///     can drive parallax, ribbon, and indicator animations every frame.
///   - Manages [_navigationLocked] to prevent rapid double-taps.
///   - Never touches BuildContext directly — navigation is done via callbacks
///     supplied by the screen.
class WelcomeExperienceController extends ChangeNotifier {
  WelcomeExperienceController({required WelcomeMotionMode motionMode})
      : _motionMode = motionMode {
    _pageController = PageController();
    _pageController.addListener(_onScroll);
  }

  // ── PageController ─────────────────────────────────────────────────────────

  late final PageController _pageController;
  PageController get pageController => _pageController;

  // ── Page progress ──────────────────────────────────────────────────────────

  /// Fractional page offset driven every scroll frame by [PageController].
  /// Widgets using this must call [notifyListeners] through [ListenableBuilder]
  /// or [AnimatedBuilder(animation: controller)].
  double _pageProgress = 0.0;
  double get pageProgress => _pageProgress;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  // ── Motion ─────────────────────────────────────────────────────────────────

  final WelcomeMotionMode _motionMode;
  WelcomeMotionMode get motionMode => _motionMode;

  // ── Navigation lock ────────────────────────────────────────────────────────

  /// True while an async navigation action is in-flight. Prevents double-taps
  /// and shows disabled state on CTAs.
  bool _navigationLocked = false;
  bool get navigationLocked => _navigationLocked;

  void lock() {
    if (_navigationLocked) return;
    _navigationLocked = true;
    notifyListeners();
  }

  void unlock() {
    if (!_navigationLocked) return;
    _navigationLocked = false;
    notifyListeners();
  }

  // ── Scroll listener ────────────────────────────────────────────────────────

  void _onScroll() {
    if (!_pageController.hasClients) return;
    final newProgress = _pageController.page ?? _currentPage.toDouble();
    if ((newProgress - _pageProgress).abs() > 0.0001) {
      _pageProgress = newProgress;
      notifyListeners();
    }
  }

  void onPageChanged(int page) {
    _currentPage = page;
    // pageProgress already updated by _onScroll; notify for currentPage change.
    notifyListeners();
  }

  // ── Parallax helpers ───────────────────────────────────────────────────────

  /// The parallax translation for a layer at [pageIndex] with a given depth
  /// [factor] (0 = stationary, 1 = moves with the page).
  ///
  /// Returns a horizontal translation in logical pixels. At [factor] = 0.15
  /// the background barely moves; at 0.65 foreground cards move prominently.
  double parallaxOffset(int pageIndex, double factor, double screenWidth) {
    final delta = _pageProgress - pageIndex;
    // Negative: layer moves left as the page scrolls left (parallax convention).
    return -delta * screenWidth * factor;
  }

  /// Clamps [pageProgress] to the interval [fromPage, toPage] and returns
  /// a 0→1 normalized fraction for that segment. Used by traveling elements
  /// to know how far they are between two anchor points.
  double travelProgress(int fromPage, int toPage) {
    assert(toPage > fromPage);
    final t = (_pageProgress - fromPage) / (toPage - fromPage);
    return t.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  String toString() =>
      'WelcomeExperienceController(page=$_currentPage, progress=$_pageProgress, '
      'mode=$_motionMode, locked=$_navigationLocked)';
}
