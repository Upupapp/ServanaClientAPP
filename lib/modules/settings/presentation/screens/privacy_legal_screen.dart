import 'package:client/common/constants/servana_urls.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_consent.dart';
import 'package:client/modules/settings/presentation/screens/delete_account_screen.dart';
import 'package:client/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyLegalScreen extends StatefulWidget {
  static const String routeName = 'SettingsPrivacy';
  static const String route = '/settings/privacy';

  const PrivacyLegalScreen({super.key});

  @override
  State<PrivacyLegalScreen> createState() => _PrivacyLegalScreenState();
}

class _PrivacyLegalScreenState extends State<PrivacyLegalScreen> {
  bool _analyticsEnabled = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConsentState();
  }

  Future<void> _loadConsentState() async {
    final consent = await AnalyticsConsent.load();
    if (!mounted) return;
    setState(() {
      _analyticsEnabled = consent.allows(ConsentCategory.analytics);
      _loading = false;
    });
  }

  Future<void> _onAnalyticsToggled(bool value) async {
    setState(() => _saving = true);
    final consent = value
        ? AnalyticsConsent.fullConsent()
        : AnalyticsConsent.defaultConsent();
    await dpLocator<AnalyticsCoordinator>().setConsent(consent);
    if (!mounted) return;
    setState(() {
      _analyticsEnabled = value;
      _saving = false;
    });
  }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),
                const SettingsSectionHeader('Analytics & Diagnostics'),
                SettingsGroup(children: [
                  SettingsToggleTile(
                    icon: Icons.analytics_outlined,
                    title: 'Usage Analytics & Crash Reports',
                    subtitle:
                        'Helps us improve the app. No personal data is shared.',
                    value: _analyticsEnabled,
                    saving: _saving,
                    onChanged: _onAnalyticsToggled,
                  ),
                ]),
                const SettingsSectionHeader('Legal Documents'),
                SettingsGroup(children: [
                  SettingsNavTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Effective January 1, 2024',
                    onTap: () =>
                        _launch(context, ServanaUrls.termsAndConditions),
                  ),
                  SettingsNavTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we use your data',
                    onTap: () => _launch(context, ServanaUrls.privacyPolicy),
                  ),
                  SettingsNavTile(
                    icon: Icons.cancel_outlined,
                    title: 'Cancellation Policy',
                    onTap: () =>
                        _launch(context, ServanaUrls.cancellationPolicy),
                  ),
                  SettingsNavTile(
                    icon: Icons.payments_outlined,
                    title: 'Refund Policy',
                    onTap: () => _launch(context, ServanaUrls.refundPolicy),
                  ),
                ]),
                const SettingsSectionHeader('Your Data'),
                SettingsGroup(children: [
                  const SettingsUnavailableTile(
                    icon: Icons.download_outlined,
                    title: 'Export My Data',
                    reason: 'Data export requires a backend update',
                  ),
                  // Was a SettingsUnavailableTile reading "Account deletion will
                  // be available in a future update" — the dead end App Store
                  // Review rejected under Guideline 5.1.1(v) on 2026-08-22. The
                  // endpoint existed the whole time; only the wiring was absent.
                  SettingsDestructiveTile(
                    icon: Icons.person_off_outlined,
                    title: 'Delete Account',
                    onTap: () =>
                        context.pushNamed(DeleteAccountScreen.routeName),
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
