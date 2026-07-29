import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Provides static context properties attached to every analytics event.
// Initialized once at app startup.
class AnalyticsContextProvider {
  AnalyticsContextProvider._();

  static AnalyticsContextProvider? _instance;
  static AnalyticsContextProvider get instance {
    _instance ??= AnalyticsContextProvider._();
    return _instance!;
  }

  String _appVersion = '';
  String _buildNumber = '';
  String _platform = '';
  String _environment = '';
  bool _initialized = false;

  Future<void> init({required String environment}) async {
    if (_initialized) return;
    _environment = environment;
    _platform = _resolvePlatform();
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } catch (_) {
      _appVersion = 'unknown';
      _buildNumber = '0';
    }
    _initialized = true;
  }

  Map<String, Object?> get contextProperties => {
        'platform': _platform,
        'app_version': _appVersion,
        'build_number': _buildNumber,
        'environment': _environment,
      };

  static String _resolvePlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
