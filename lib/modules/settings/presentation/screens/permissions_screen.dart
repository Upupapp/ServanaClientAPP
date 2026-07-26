import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/notifications/application/notification_permission_coordinator.dart';
import 'package:client/modules/notifications/domain/notification_permission_state.dart';
import 'package:client/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PermissionsScreen extends StatefulWidget {
  static const String routeName = 'SettingsPermissions';
  static const String route = '/settings/permissions';

  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  PermissionStatus _locationStatus = PermissionStatus.notDetermined;
  PermissionStatus _notificationStatus = PermissionStatus.notDetermined;
  late final NotificationPermissionCoordinator _notifPermCoord;

  @override
  void initState() {
    super.initState();
    _notifPermCoord = dpLocator<NotificationPermissionCoordinator>();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _checkNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh after the user returns from system settings.
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
      _checkNotificationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final status = await Geolocator.checkPermission();
      if (!mounted) return;
      setState(() {
        _locationStatus = switch (status) {
          LocationPermission.always ||
          LocationPermission.whileInUse =>
            PermissionStatus.allowed,
          LocationPermission.denied => PermissionStatus.notDetermined,
          LocationPermission.deniedForever => PermissionStatus.denied,
          _ => PermissionStatus.notDetermined,
        };
      });
    } catch (_) {
      if (mounted) setState(() => _locationStatus = PermissionStatus.unavailable);
    }
  }

  Future<void> _checkNotificationPermission() async {
    final state = await _notifPermCoord.currentState();
    if (!mounted) return;
    setState(() {
      _notificationStatus = switch (state) {
        NotificationPermissionState.authorized ||
        NotificationPermissionState.provisional =>
          PermissionStatus.allowed,
        NotificationPermissionState.denied ||
        NotificationPermissionState.restricted =>
          PermissionStatus.denied,
        NotificationPermissionState.notDetermined =>
          PermissionStatus.notDetermined,
      };
    });
  }

  Future<void> _requestNotificationPermission() async {
    final state = await _notifPermCoord.requestPermission();
    if (!mounted) return;
    setState(() {
      _notificationStatus = switch (state) {
        NotificationPermissionState.authorized ||
        NotificationPermissionState.provisional =>
          PermissionStatus.allowed,
        NotificationPermissionState.denied ||
        NotificationPermissionState.restricted =>
          PermissionStatus.denied,
        NotificationPermissionState.notDetermined =>
          PermissionStatus.notDetermined,
      };
    });
  }

  Future<void> _openSystemSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        title: Text(
          'Permissions',
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

          SettingsSectionHeader('Location'),
          SettingsGroup(children: [
            SettingsPermissionTile(
              icon: Icons.location_on_outlined,
              title: 'Location',
              purpose: 'Used to assist with address entry and coverage',
              status: _locationStatus,
              onOpenSettings:
                  _locationStatus == PermissionStatus.denied ||
                          _locationStatus == PermissionStatus.restricted
                      ? _openSystemSettings
                      : null,
            ),
          ]),

          if (_locationStatus == PermissionStatus.denied)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Location access is permanently denied. '
                'Open Settings → Servana → Location to re-enable.',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 12,
                  color: ColorPalette.accentText.withOpacity(.7),
                  height: 1.5,
                ),
              ),
            ),

          SettingsSectionHeader('Notifications'),
          SettingsGroup(children: [
            SettingsPermissionTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              purpose: 'Booking updates, provider assignments',
              status: _notificationStatus,
              onOpenSettings: _notificationStatus == PermissionStatus.denied
                  ? _openSystemSettings
                  : null,
              onRequest: _notificationStatus == PermissionStatus.notDetermined
                  ? _requestNotificationPermission
                  : null,
            ),
          ]),
          if (_notificationStatus == PermissionStatus.denied)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Notifications are permanently denied. '
                'Open Settings → Servana → Notifications to re-enable.',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 12,
                  color: ColorPalette.accentText.withOpacity(.7),
                  height: 1.5,
                ),
              ),
            ),

          SettingsSectionHeader('Camera & Photos'),
          SettingsGroup(children: [
            SettingsNavTile(
              icon: Icons.camera_alt_outlined,
              title: 'Camera & Photos',
              subtitle: 'Used for profile photo',
              trailingValue: 'Device Settings',
              onTap: _openSystemSettings,
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Camera and photo access is requested only when you update your '
              'profile photo. Manage it any time in your device settings.',
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
}
