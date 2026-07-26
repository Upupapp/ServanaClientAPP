import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  static const String routeName = 'SettingsAbout';
  static const String route = '/settings/about';

  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        title: Text(
          'About Servana',
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

          // App identity
          SettingsSectionHeader('Application'),
          SettingsGroup(children: [
            SettingsValueTile(
              icon: Icons.smartphone_rounded,
              title: 'App Name',
              value: _info?.appName ?? 'Servana',
            ),
            SettingsValueTile(
              icon: Icons.tag_rounded,
              title: 'Version',
              value: _info != null ? _info!.version : '—',
            ),
            SettingsValueTile(
              icon: Icons.build_circle_outlined,
              title: 'Build',
              value: _info != null ? _info!.buildNumber : '—',
            ),
          ]),

          // Links
          SettingsSectionHeader('Links'),
          SettingsGroup(children: [
            SettingsNavTile(
              icon: Icons.language_rounded,
              title: 'Official Website',
              subtitle: 'servana.com.ph',
              onTap: () => _launch('https://servana.com.ph'),
            ),
            SettingsNavTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => _launch('https://servana.com.ph/terms'),
            ),
            SettingsNavTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _launch('https://servana.com.ph/privacy'),
            ),
          ]),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '© ${DateTime.now().year} Servana. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                color: ColorPalette.accentText.withOpacity(.6),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
