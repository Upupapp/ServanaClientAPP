import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/address_form_screen.dart';
import 'package:client/modules/profile/application/address_controller.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/settings/presentation/screens/about_screen.dart';
import 'package:client/modules/settings/presentation/screens/appearance_screen.dart';
import 'package:client/modules/settings/presentation/screens/permissions_screen.dart';
import 'package:client/modules/settings/presentation/screens/privacy_legal_screen.dart';
import 'package:client/modules/settings/presentation/screens/profile_edit_screen.dart';
import 'package:client/modules/settings/application/settings_controller.dart';
import 'package:client/modules/settings/presentation/screens/security_screen.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart'
    show LatLong;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class RewardsScreen extends StatelessWidget {
  static String routeName = "Rewards";
  static String route = "/Rewards";
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Rewards",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColorDark.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.stars_rounded,
                  size: 36,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Rewards coming soon",
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: ColorPalette.secondaryText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Earn points on every completed booking and redeem them for service vouchers and discounts. We're setting it up now.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 13,
                  color: ColorPalette.secondaryText.withOpacity(.65),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavouritesScreen extends StatefulWidget {
  static String routeName = "Favourites";
  static String route = "/Favourites";
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Favourites",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: ColorPalette.secondaryText.withOpacity(.3),
                size: 56,
              ),
              const SizedBox(height: 14),
              Text(
                "No favourites yet",
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.secondaryText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Browse services and tap the heart icon to save them here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 13,
                  color: ColorPalette.secondaryText.withOpacity(.6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedAddressesScreen extends StatefulWidget {
  static String routeName = "SavedAddresses";
  static String route = "/SavedAddresses";
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _api = dpLocator<ServanaApiClient>();
  late final AddressController _addrCtrl;
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _addrCtrl = dpLocator<AddressController>();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.getAllUserAddresses();
      final raw = res['data'] ?? res['items'] ?? res;
      if (raw is List) {
        _addresses = raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
    // Keep the controller in sync so ProfileController.completeness is accurate.
    _addrCtrl.loadAddresses().ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Saved Addresses",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _onAddAddress,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: ColorPalette.primaryColorDark,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_rounded,
                          size: 48, color: ColorPalette.accentText),
                      const SizedBox(height: 12),
                      Text(
                        "No saved addresses yet",
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.secondaryText.withOpacity(.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _onAddAddress,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Address'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.primaryColorDark,
                          foregroundColor: ColorPalette.primaryText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final addr = _addresses[i];
                      final addrId =
                          (addr['addressId'] ?? addr['id'] ?? '').toString();
                      return _SavedAddressCard(
                        address: _SavedAddress(
                          id: addrId,
                          label: (addr['label'] ?? '').toString(),
                          addressLine: (addr['addressOne'] ?? '').toString(),
                          cityLine: (addr['postTown'] ?? '').toString(),
                          note: (addr['addressTwo'] ?? '').toString(),
                          isDefault: addr['isPrimary'] == true,
                        ),
                        onSetDefault: () => _setDefault(addrId),
                        onEdit: () => _onEditAddress(addr),
                        onDelete: () => _onDeleteAddress(addrId),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _onAddAddress() async {
    final result = await Navigator.of(context).push<AddressFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddressFormScreen(
          title: 'Add Address',
          actionLabel: 'Save Address',
          showGps: true,
        ),
      ),
    );
    if (result == null || !mounted) return;

    try {
      final session = await SessionService.getSession();
      final userId = session?.customerID ?? '';
      final lat = result.location.latitude;
      final lon = result.location.longitude;

      await _api.addUserAddress(payload: {
        'userId': userId,
        'locationId': 'loc_${lat.toStringAsFixed(6)}_${lon.toStringAsFixed(6)}',
        'addressOne': result.address,
        'addressTwo':
            [result.unit, result.street].where((s) => s.isNotEmpty).join(', '),
        'zipCode': '',
        'postTown': result.city.isNotEmpty ? result.city : result.province,
        'country': 'Philippines',
        'lat': lat,
        'lon': lon,
        'label': result.landmark.isNotEmpty
            ? result.landmark
            : (result.barangay.isNotEmpty ? result.barangay : 'Home'),
        'isPrimary': _addresses.isEmpty,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved!')),
      );
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    }
  }

  Future<void> _onEditAddress(Map<String, dynamic> existing) async {
    final addrId = (existing['addressId'] ?? existing['id'] ?? '').toString();
    final oldLat = (existing['lat'] as num?)?.toDouble() ?? 0.0;
    final oldLon = (existing['lon'] as num?)?.toDouble() ?? 0.0;

    final result = await Navigator.of(context).push<AddressFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddressFormScreen(
          title: 'Edit Address',
          actionLabel: 'Save Changes',
          initialAddress: (existing['addressOne'] ?? '').toString(),
          initialCity: (existing['postTown'] ?? '').toString(),
          initialLandmark: (existing['label'] ?? '').toString(),
          initialLocation:
              (oldLat != 0 || oldLon != 0) ? LatLong(oldLat, oldLon) : null,
          showGps: true,
        ),
      ),
    );
    if (result == null || !mounted) return;

    try {
      final session = await SessionService.getSession();
      final userId = session?.customerID ?? '';
      final lat = result.location.latitude;
      final lon = result.location.longitude;
      final useLat = (lat == 0 && lon == 0) ? oldLat : lat;
      final useLon = (lat == 0 && lon == 0) ? oldLon : lon;
      final wasPrimary = existing['isPrimary'] == true;

      // Delete the old address, then create the updated one
      await _api.deleteAddress(addressId: addrId);
      await _api.addUserAddress(payload: {
        'userId': userId,
        'locationId':
            'loc_${useLat.toStringAsFixed(6)}_${useLon.toStringAsFixed(6)}',
        'addressOne': result.address,
        'addressTwo':
            [result.unit, result.street].where((s) => s.isNotEmpty).join(', '),
        'zipCode': '',
        'postTown': result.city.isNotEmpty ? result.city : result.province,
        'country': (existing['country'] ?? 'Philippines').toString(),
        'lat': useLat,
        'lon': useLon,
        'label': result.landmark.isNotEmpty
            ? result.landmark
            : (result.barangay.isNotEmpty ? result.barangay : 'Home'),
        'isPrimary': wasPrimary,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated!')),
      );
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update address: $e')),
      );
    }
  }

  Future<void> _setDefault(String addressId) async {
    final ok = await _addrCtrl.setPrimaryAddress(addressId);
    if (!mounted) return;
    if (ok) {
      await _loadAddresses();
    } else if (_addrCtrl.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_addrCtrl.error!)),
      );
    }
  }

  Future<void> _onDeleteAddress(String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: ColorPalette.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _addrCtrl.deleteAddress(addressId);
      await _loadAddresses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }
}

class SettingsScreen extends StatelessWidget {
  static String routeName = "Settings";
  static String route = "/Settings";
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        title: Text(
          'Settings',
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
          _SettingsSectionLabel('Account'),
          _SettingsGroup(children: [
            _SettingsNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              subtitle: 'Update your name and phone number',
              onTap: () {
                AppHaptics.selection();
                context.pushNamed(ProfileEditScreen.routeName);
              },
            ),
          ]),
          _SettingsSectionLabel('Preferences'),
          _SettingsGroup(children: [
            _SettingsNavItem(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              subtitle: 'Theme and haptic feedback',
              onTap: () {
                AppHaptics.selection();
                context.pushNamed(AppearanceScreen.routeName);
              },
            ),
            _SettingsNavItem(
              icon: Icons.language_rounded,
              label: 'Language',
              subtitle: 'English',
              onTap: () {
                AppHaptics.selection();
                context.pushNamed(LanguageScreen.routeName);
              },
            ),
          ]),
          _SettingsSectionLabel('Permissions'),
          _SettingsGroup(children: [
            _SettingsNavItem(
              icon: Icons.tune_rounded,
              label: 'App Permissions',
              subtitle: 'Location, notifications, camera',
              onTap: () {
                AppHaptics.selection();
                context.pushNamed(PermissionsScreen.routeName);
              },
            ),
          ]),
          _SettingsSectionLabel('Security'),
          _SettingsGroup(children: [
            _SettingsNavItem(
              icon: Icons.lock_outline_rounded,
              label: 'Password & Security',
              onTap: () {
                AppHaptics.selection();
                context.pushNamed(SecurityScreen.routeName);
              },
            ),
          ]),
          _SettingsSectionLabel('Legal & Info'),
          _SettingsGroup(children: [
            _SettingsNavItem(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy & Legal',
              onTap: () {
                AppHaptics.selection();
                context.pushNamed(PrivacyLegalScreen.routeName);
              },
            ),
            _SettingsNavItem(
              icon: Icons.info_outline_rounded,
              label: 'About Servana',
              onTap: () {
                AppHaptics.selection();
                context.pushNamed(AboutScreen.routeName);
              },
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Settings local layout helpers (used only here) ────────────────────────────

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: ColorPalette.accentText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorPalette.border(.45)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  color: ColorPalette.border(.3),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ColorPalette.primaryColorDark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 12,
                          color: ColorPalette.accentText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: ColorPalette.secondaryText.withOpacity(.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageScreen extends StatefulWidget {
  static String routeName = "Language";
  static String route = "/Language";
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'English';

  static const _options = [
    _LanguageOption('English', 'EN', available: true),
    _LanguageOption('Filipino', 'FIL', available: false),
    _LanguageOption('Cebuano', 'CEB', available: false),
  ];

  @override
  void initState() {
    super.initState();
    // Read current value from SettingsController so it stays in sync.
    _selected = dpLocator<SettingsController>().language;
  }

  Future<void> _select(String name) async {
    if (!mounted) return;
    setState(() => _selected = name);
    await dpLocator<SettingsController>().setLanguage(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        title: Text(
          'Language',
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Choose your preferred language',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.secondaryText.withOpacity(.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ..._options.map((option) {
            final isSelected = option.name == _selected && option.available;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Opacity(
                opacity: option.available ? 1.0 : 0.55,
                child: InkWell(
                  onTap: option.available
                      ? () {
                          AppHaptics.selection();
                          _select(option.name);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ColorPalette.secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? ColorPalette.primaryColorDark
                            : ColorPalette.border(.55),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorPalette.primaryColorDark.withOpacity(.15)
                                : ColorPalette.primaryColor.withOpacity(.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              option.code,
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.primaryColorDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.name,
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.secondaryText,
                            ),
                          ),
                        ),
                        if (!option.available)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ColorPalette.accentText.withOpacity(.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Soon',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.accentText,
                              ),
                            ),
                          )
                        else
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? ColorPalette.primaryColorDark
                                : ColorPalette.secondaryText.withOpacity(.4),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Additional languages are being added in a future update.',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.secondaryText.withOpacity(.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatefulWidget {
  static String routeName = "HelpSupport";
  static String route = "/HelpSupport";
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // Replaced by SupportHomeScreen — redirect immediately on first frame.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.push('/support');
    });
  }

  int? _expanded;

  static const _faqs = [
    _Faq(
      q: 'How do I cancel a booking?',
      a: 'Open your booking from the Bookings tab and tap "Cancel Booking" at the bottom of the detail screen. '
          'Cancellations must be made at least 2 hours before the scheduled time.',
    ),
    _Faq(
      q: 'How is payment processed?',
      a: 'Payments are handled securely via PayMongo. '
          'You will be redirected to a payment page after your booking is confirmed. '
          'Servana never stores your card details.',
    ),
    _Faq(
      q: 'What happens if a provider does not show up?',
      a: 'If your provider is more than 30 minutes late or does not arrive, '
          'contact our support team immediately via the chat below. '
          'We will rebook or refund you within 24 hours.',
    ),
    _Faq(
      q: 'Can I reschedule a booking?',
      a: 'Rescheduling is currently handled by our support team. '
          'Please reach out via the Contact Support option and include your booking number.',
    ),
    _Faq(
      q: 'How do I update my address?',
      a: 'Go to Profile → Saved Addresses to add, edit, or remove addresses. '
          'You can also set a default address for quicker checkout.',
    ),
    _Faq(
      q: 'Is my personal information safe?',
      a: 'Yes. Servana uses industry-standard encryption for all data in transit and at rest. '
          'We do not sell or share your personal information with third parties.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Frequently asked questions',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_faqs.length, (i) {
            final faq = _faqs[i];
            final open = _expanded == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: ColorPalette.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => setState(() => _expanded = open ? null : i),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq.q,
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: ColorPalette.secondaryText,
                                ),
                              ),
                            ),
                            Icon(
                              open
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color:
                                  ColorPalette.secondaryText.withOpacity(.45),
                              size: 20,
                            ),
                          ],
                        ),
                        if (open) ...[
                          const SizedBox(height: 10),
                          Text(
                            faq.a,
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontSize: 13,
                              color:
                                  ColorPalette.secondaryText.withOpacity(.75),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Still need help?',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'Contact Support via email',
            child: Material(
              color: ColorPalette.primaryColorDark.withOpacity(.07),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse('mailto:support@servana.com.ph'),
                  mode: LaunchMode.externalApplication,
                ),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryColorDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Support',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: ColorPalette.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'support@servana.com.ph',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 12,
                                color:
                                    ColorPalette.secondaryText.withOpacity(.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: ColorPalette.secondaryText.withOpacity(.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  const _Faq({required this.q, required this.a});
  final String q;
  final String a;
}

class _LanguageOption {
  const _LanguageOption(this.name, this.code, {required this.available});
  final String name;
  final String code;
  final bool available;
}

class _SavedAddress {
  const _SavedAddress({
    this.id = '',
    required this.label,
    required this.addressLine,
    required this.cityLine,
    required this.note,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String addressLine;
  final String cityLine;
  final String note;
  final bool isDefault;
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final _SavedAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border(.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorPalette.primaryColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: ColorPalette.primaryColorDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.label,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryColor.withOpacity(.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Default",
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.primaryColorDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address.addressLine,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.secondaryText.withOpacity(.8),
                  ),
                ),
                Text(
                  address.cityLine,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.secondaryText.withOpacity(.7),
                    fontSize: 12,
                  ),
                ),
                if (address.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    address.note,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.secondaryText.withOpacity(.6),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: onSetDefault,
                      child: const Text("Set default"),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: onEdit,
                      child: const Text("Edit"),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: onDelete,
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
