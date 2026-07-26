import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/settings/application/settings_controller.dart';
import 'package:client/modules/settings/data/settings_local_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  // ── SettingsLocalDataSource (all-static API) ───────────────────────────────

  group('SettingsLocalDataSource', () {
    test('loadThemeMode returns system when no value stored', () async {
      expect(await SettingsLocalDataSource.loadThemeMode(), ThemeMode.system);
    });

    test('saveThemeMode + loadThemeMode round-trip light', () async {
      await SettingsLocalDataSource.saveThemeMode(ThemeMode.light);
      expect(await SettingsLocalDataSource.loadThemeMode(), ThemeMode.light);
    });

    test('saveThemeMode + loadThemeMode round-trip system', () async {
      await SettingsLocalDataSource.saveThemeMode(ThemeMode.system);
      expect(await SettingsLocalDataSource.loadThemeMode(), ThemeMode.system);
    });

    test('saveThemeMode + loadThemeMode round-trip dark', () async {
      await SettingsLocalDataSource.saveThemeMode(ThemeMode.dark);
      expect(await SettingsLocalDataSource.loadThemeMode(), ThemeMode.dark);
    });

    test('loadHapticsEnabled returns true by default', () async {
      expect(await SettingsLocalDataSource.loadHapticsEnabled(), isTrue);
    });

    test('saveHapticsEnabled false + loadHapticsEnabled returns false', () async {
      await SettingsLocalDataSource.saveHapticsEnabled(false);
      expect(await SettingsLocalDataSource.loadHapticsEnabled(), isFalse);
    });

    test('saveHapticsEnabled true after false returns true', () async {
      await SettingsLocalDataSource.saveHapticsEnabled(false);
      await SettingsLocalDataSource.saveHapticsEnabled(true);
      expect(await SettingsLocalDataSource.loadHapticsEnabled(), isTrue);
    });
  });

  // ── SettingsController ─────────────────────────────────────────────────────

  group('SettingsController', () {
    tearDown(() => AppHaptics.setEnabled(true)); // restore static state after each test
    test('themeMode defaults to system before load()', () {
      expect(SettingsController().themeMode, ThemeMode.system);
    });

    test('hapticsEnabled defaults to true before load()', () {
      expect(SettingsController().hapticsEnabled, isTrue);
    });

    test('isLoaded is false before load(), true after', () async {
      final ctrl = SettingsController();
      expect(ctrl.isLoaded, isFalse);
      await ctrl.load();
      expect(ctrl.isLoaded, isTrue);
    });

    test('load() reads theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'settings_theme_mode': 'light'});
      final ctrl = SettingsController();
      await ctrl.load();
      expect(ctrl.themeMode, ThemeMode.light);
    });

    test('load() reads haptics from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues(
          {'settings_haptics_enabled': false});
      final ctrl = SettingsController();
      await ctrl.load();
      expect(ctrl.hapticsEnabled, isFalse);
    });

    test('setThemeMode updates themeMode and notifies listeners', () async {
      final ctrl = SettingsController();
      var notified = false;
      ctrl.addListener(() => notified = true);
      await ctrl.setThemeMode(ThemeMode.light);
      expect(ctrl.themeMode, ThemeMode.light);
      expect(notified, isTrue);
    });

    test('setThemeMode persists to SharedPreferences', () async {
      await SettingsController().setThemeMode(ThemeMode.light);
      expect(await SettingsLocalDataSource.loadThemeMode(), ThemeMode.light);
    });

    test('setThemeMode is a no-op when value unchanged', () async {
      final ctrl = SettingsController();
      var notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      await ctrl.setThemeMode(ThemeMode.system); // same as default
      expect(notifyCount, 0);
    });

    test('setHapticsEnabled(false) updates and notifies', () async {
      final ctrl = SettingsController();
      var notified = false;
      ctrl.addListener(() => notified = true);
      await ctrl.setHapticsEnabled(false);
      expect(ctrl.hapticsEnabled, isFalse);
      expect(notified, isTrue);
    });

    test('setHapticsEnabled persists to SharedPreferences', () async {
      await SettingsController().setHapticsEnabled(false);
      expect(await SettingsLocalDataSource.loadHapticsEnabled(), isFalse);
    });

    test('setHapticsEnabled is a no-op when value unchanged', () async {
      final ctrl = SettingsController();
      var notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      await ctrl.setHapticsEnabled(true); // same as default
      expect(notifyCount, 0);
    });

    // GAP-001: dispose race guard
    test('load() completes without throw when controller disposed before awaits resolve', () async {
      final ctrl = SettingsController();
      ctrl.dispose();
      await expectLater(ctrl.load(), completes);
    });

    // GAP-004: AppHaptics wiring
    test('setHapticsEnabled(false) wires through to AppHaptics', () async {
      AppHaptics.setEnabled(true);
      final ctrl = SettingsController();
      await ctrl.setHapticsEnabled(false);
      expect(AppHaptics.isEnabled, isFalse);
    });

    test('load() with haptics=false wires AppHaptics on startup', () async {
      SharedPreferences.setMockInitialValues({'settings_haptics_enabled': false});
      AppHaptics.setEnabled(true);
      final ctrl = SettingsController();
      await ctrl.load();
      expect(AppHaptics.isEnabled, isFalse);
    });

    // GAP-006: concurrent load() idempotency
    test('concurrent load() calls fire notifyListeners exactly once', () async {
      final ctrl = SettingsController();
      var notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      await Future.wait([ctrl.load(), ctrl.load()]);
      expect(notifyCount, 1);
    });
  });
}
