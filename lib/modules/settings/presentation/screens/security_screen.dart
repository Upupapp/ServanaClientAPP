import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';

class SecurityScreen extends StatelessWidget {
  static const String routeName = 'SettingsSecurity';
  static const String route = '/settings/security';

  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        title: Text(
          'Password & Security',
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

          SettingsSectionHeader('Sign-In'),
          SettingsGroup(children: [
            SettingsUnavailableTile(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              reason: 'Password change is coming in a future update',
            ),
            SettingsUnavailableTile(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric Login',
              reason: 'Biometric authentication is coming in a future update',
            ),
          ]),

          SettingsSectionHeader('Sessions'),
          SettingsGroup(children: [
            SettingsUnavailableTile(
              icon: Icons.devices_rounded,
              title: 'Active Sessions',
              reason: 'Session management requires a future backend update',
            ),
          ]),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColorLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: ColorPalette.primaryColorDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your account is secured with an email and password. '
                      'Additional security options such as biometrics and session '
                      'management will be available in a future update.',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 13,
                        color: ColorPalette.primaryColorDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
