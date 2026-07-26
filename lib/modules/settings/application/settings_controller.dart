import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/settings/data/settings_local_data_source.dart';
import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _hapticsEnabled = true;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _themeMode = await SettingsLocalDataSource.loadThemeMode();
    _hapticsEnabled = await SettingsLocalDataSource.loadHapticsEnabled();
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
