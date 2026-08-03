import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/settings/application/settings_controller.dart';
import 'package:client/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';

class AppearanceScreen extends StatelessWidget {
  static const String routeName = 'SettingsAppearance';
  static const String route = '/settings/appearance';

  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = dpLocator<SettingsController>();
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: ColorPalette.primaryBackground,
          appBar: AppBar(
            backgroundColor: ColorPalette.primaryColorDark,
            title: Text(
              'Appearance',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: ListView(
            children: [
              const SizedBox(height: 8),
              SettingsSectionHeader('Theme'),
              SettingsGroup(children: [
                _ThemeOption(
                  icon: Icons.brightness_auto_rounded,
                  label: 'System Default',
                  description: 'Follows your device setting',
                  selected: ctrl.themeMode == ThemeMode.system,
                  onTap: () {
                    AppHaptics.selection();
                    ctrl.setThemeMode(ThemeMode.system);
                  },
                ),
                _ThemeOption(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Light',
                  description: 'Always use light mode',
                  selected: ctrl.themeMode == ThemeMode.light,
                  onTap: () {
                    AppHaptics.selection();
                    ctrl.setThemeMode(ThemeMode.light);
                  },
                ),
                SettingsUnavailableTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark',
                  reason: 'Dark mode is being added in a future update',
                ),
              ]),
              SettingsSectionHeader('Interaction'),
              SettingsGroup(children: [
                SettingsToggleTile(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic Feedback',
                  subtitle: 'Feel confirmation taps when navigating',
                  value: ctrl.hapticsEnabled,
                  onChanged: (v) {
                    ctrl.setHapticsEnabled(v);
                    if (v) AppHaptics.selection();
                  },
                ),
              ]),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Haptic feedback applies to navigation and interaction cues. '
                  'Accessibility feedback from your device is never affected.',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.accentText.withOpacity(.7),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? ColorPalette.primaryColorDark
                    : ColorPalette.accentText,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 15,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 12,
                        color: ColorPalette.accentText,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? ColorPalette.primaryColorDark
                        : ColorPalette.border(.6),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorPalette.primaryColorDark,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
