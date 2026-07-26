import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyLegalScreen extends StatelessWidget {
  static const String routeName = 'SettingsPrivacy';
  static const String route = '/settings/privacy';

  const PrivacyLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        title: Text(
          'Privacy & Legal',
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

          SettingsSectionHeader('Legal Documents'),
          SettingsGroup(children: [
            SettingsNavTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Effective January 1, 2024',
              onTap: () => _launch(context, 'https://servana.com.ph/terms'),
            ),
            SettingsNavTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we use your data',
              onTap: () => _launch(context, 'https://servana.com.ph/privacy'),
            ),
            SettingsNavTile(
              icon: Icons.cancel_outlined,
              title: 'Cancellation Policy',
              onTap: () =>
                  _launch(context, 'https://servana.com.ph/cancellation'),
            ),
            SettingsNavTile(
              icon: Icons.payments_outlined,
              title: 'Refund Policy',
              onTap: () => _launch(context, 'https://servana.com.ph/refunds'),
            ),
          ]),

          SettingsSectionHeader('Marketing'),
          SettingsGroup(children: [
            SettingsUnavailableTile(
              icon: Icons.campaign_outlined,
              title: 'Marketing Preferences',
              reason: 'Consent management is coming in a future update',
            ),
          ]),

          SettingsSectionHeader('Your Data'),
          SettingsGroup(children: [
            SettingsUnavailableTile(
              icon: Icons.download_outlined,
              title: 'Export My Data',
              reason: 'Data export requires a backend update',
            ),
            SettingsUnavailableTile(
              icon: Icons.person_off_outlined,
              title: 'Delete Account',
              reason:
                  'Account deletion will be available in a future update',
            ),
          ]),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'For privacy requests or questions about your data, contact us at '
              'privacy@servana.com.ph',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                color: ColorPalette.accentText.withOpacity(.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }
}
