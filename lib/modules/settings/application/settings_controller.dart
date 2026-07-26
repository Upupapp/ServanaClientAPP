import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/settings/data/settings_local_data_source.dart';
import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _hapticsEnabled = true;
  bool _loaded = false;
  bool _loading = false;
  bool _disposed = false;

  ThemeMode get themeMode => _themeMode;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get isLoaded => _loaded;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_loaded || _loading) return;
    _loading = true;
    _themeMode = await SettingsLocalDataSource.loadThemeMode();
    _hapticsEnabled = await SettingsLocalDataSource.loadHapticsEnabled();
    if (_disposed) return;
    AppHaptics.setEnabled(_hapticsEnabled);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await SettingsLocalDataSource.saveThemeMode(mode);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    if (_hapticsEnabled == enabled) return;
    _hapticsEnabled = enabled;
    AppHaptics.setEnabled(enabled);
    notifyListeners();
    await SettingsLocalDataSource.saveHapticsEnabled(enabled);
  }
}
