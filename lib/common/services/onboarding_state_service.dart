import 'package:hive_flutter/hive_flutter.dart';

enum OnboardingStatus {
  notSeen,
  inProgress,
  completed,
  skippedToBrowse,
}

/// Persists whether the user has already seen the welcome/onboarding flow so
/// the splash screen can skip straight to Home on repeat launches.
///
/// Uses an unencrypted Hive box — onboarding completion is not private data.
abstract final class OnboardingStateService {
  static const _boxName = 'servana_onboarding';
  static const _statusKey = 'status';

  static Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<String>(_boxName);
    return Hive.openBox<String>(_boxName);
  }

  static Future<OnboardingStatus> getStatus() async {
    try {
      final box = await _box();
      final raw = box.get(_statusKey) ?? OnboardingStatus.notSeen.name;
      return OnboardingStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => OnboardingStatus.notSeen,
      );
    } catch (_) {
      return OnboardingStatus.notSeen;
    }
  }

  static Future<void> setStatus(OnboardingStatus status) async {
    try {
      final box = await _box();
      await box.put(_statusKey, status.name);
    } catch (_) {}
  }

  /// Returns true when the welcome flow should be skipped on the next launch.
  static Future<bool> hasCompletedOrSkipped() async {
    final s = await getStatus();
    return s == OnboardingStatus.completed ||
        s == OnboardingStatus.skippedToBrowse;
  }
}
