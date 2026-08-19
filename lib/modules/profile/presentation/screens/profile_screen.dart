import 'dart:convert';
import 'dart:io';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/drawer_placeholder_screens.dart'
    show
        LanguageScreen,
        SavedAddressesScreen,
        SettingsScreen,
        HelpSupportScreen;
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_state.dart';
import 'package:client/core/accessibility/focus_coordinator.dart';
import 'package:client/modules/homepage/presentation/dialogs/logout_dialog.dart';
import 'package:client/modules/profile/application/address_controller.dart';
import 'package:client/modules/profile/application/profile_controller.dart';
import 'package:client/modules/profile/domain/account_completeness.dart';
import 'package:client/modules/profile/domain/customer_profile.dart';
import 'package:client/modules/profile/presentation/screens/email_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  static String routeName = "Profile";
  static String route = "/Profile";
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _profileCtrl;
  late final AddressController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _profileCtrl = dpLocator<ProfileController>();
    _addressCtrl = dpLocator<AddressController>();
    // Eagerly load so the header shows real data on first paint.
    if (_profileCtrl.status == ProfileLoadStatus.initial) {
      _profileCtrl.loadProfile();
    }
    if (_addressCtrl.addresses.isEmpty && !_addressCtrl.isLoading) {
      _addressCtrl.loadAddresses();
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (picked == null || !mounted) return;
    final bytes = await File(picked.path).readAsBytes();
    final base64 = base64Encode(bytes);
    final ext = picked.path.split('.').last.toLowerCase();
    final dataUri = 'data:image/$ext;base64,$base64';
    if (mounted) {
      final ok = await _profileCtrl.uploadPhoto(dataUri);
      if (mounted && !ok && _profileCtrl.saveError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_profileCtrl.saveError!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      body: ListenableBuilder(
        listenable: _profileCtrl,
        builder: (context, _) {
          final profile = _profileCtrl.profile;
          final completeness = _profileCtrl.completeness;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  profile: profile,
                  isLoading: _profileCtrl.isLoading,
                  isUploadingPhoto: _profileCtrl.isUploadingPhoto,
                  onPhotoTap: _pickAndUploadPhoto,
                  onEditTap: () => context.pushNamed('SettingsProfileEdit'),
                  onVerifyEmailTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmailVerificationScreen(),
                    ),
                  ),
                ),
              ),
              if (completeness.score < 100) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _CompletenessCard(completeness: completeness),
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: _SectionLabel(label: 'My Account'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MenuGroup(
                    items: [
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () =>
                            context.pushNamed(SettingsScreen.routeName),
                      ),
                      _MenuItem(
                        icon: Icons.location_on_outlined,
                        label: 'Saved Addresses',
                        onTap: () =>
                            context.pushNamed(SavedAddressesScreen.routeName),
                      ),
                      _MenuItem(
                        icon: Icons.language_rounded,
                        label: 'Language',
                        onTap: () =>
                            context.pushNamed(LanguageScreen.routeName),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: _SectionLabel(label: 'Support'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MenuGroup(
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () =>
                            context.pushNamed(HelpSupportScreen.routeName),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    32,
                    16,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      BlocBuilder<AuthenticationBloc, AuthenticationState>(
                        builder: (context, state) {
                          final isLoading = state is AuthenticationLoading;
                          return SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ColorPalette.danger,
                                side: BorderSide(
                                    color: ColorPalette.danger.withOpacity(.5)),
                                disabledForegroundColor:
                                    ColorPalette.danger.withOpacity(.4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      LogoutDialog.showDialog(
                                        context: context,
                                        onConfirm: () {
                                          FocusCoordinator.clearStaleFocus(
                                              context);
                                          context
                                              .read<AuthenticationBloc>()
                                              .add(AuthLogout());
                                        },
                                      );
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ColorPalette.danger,
                                      ),
                                    )
                                  : Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        fontFamily:
                                            FontPalette.primaryFontFamily,
                                        fontWeight: FontWeight.w700,
                                        color: ColorPalette.danger,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isLoading,
    required this.isUploadingPhoto,
    required this.onPhotoTap,
    required this.onEditTap,
    required this.onVerifyEmailTap,
  });

  final CustomerProfile? profile;
  final bool isLoading;
  final bool isUploadingPhoto;
  final VoidCallback onPhotoTap;
  final VoidCallback onEditTap;
  final VoidCallback onVerifyEmailTap;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? '';
    final email = profile?.email ?? '';
    final phone = profile?.phoneNumber ?? '';
    final isEmailVerified = profile?.isEmailVerified ?? false;
    final photoUrl = profile?.photoUrl;
    final initials =
        profile?.initials ?? (name.isNotEmpty ? name[0].toUpperCase() : '?');

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorPalette.primaryColorDark,
            ColorPalette.primaryGradientEnd(),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo circle with camera overlay
          Semantics(
            label: 'Change profile photo',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onPhotoTap,
              child: Stack(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(.5), width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isUploadingPhoto
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                          )
                        : (photoUrl != null && photoUrl.isNotEmpty)
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _initialsWidget(initials),
                              )
                            : _initialsWidget(initials),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: isLoading && name.isEmpty
                          ? _shimmerLine(120, 18)
                          : Text(
                              name.isNotEmpty ? name : 'Your Name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: 'Edit profile',
                      child: GestureDetector(
                        onTap: onEditTap,
                        child: Container(
                          // 44pt minimum tap target
                          constraints:
                              const BoxConstraints(minWidth: 44, minHeight: 44),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 13,
                            color: Colors.white.withOpacity(.75),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isEmailVerified)
                        Semantics(
                          label: 'Email verified',
                          excludeSemantics: true,
                          child: const Icon(Icons.verified_rounded,
                              size: 14, color: Colors.white70),
                        )
                      else
                        Semantics(
                          button: true,
                          label: 'Verify email address',
                          child: GestureDetector(
                            onTap: onVerifyEmailTap,
                            child: Container(
                              // 44pt minimum tap target
                              constraints: const BoxConstraints(
                                  minWidth: 44, minHeight: 44),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.amber.shade300),
                                ),
                                child: Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontFamily: FontPalette.primaryFontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: Colors.amber.shade100,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: Colors.white.withOpacity(.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget(String initials) => Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      );

  Widget _shimmerLine(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.2),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

// ── Completeness card ─────────────────────────────────────────────────────────

class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.completeness});
  final AccountCompleteness completeness;

  @override
  Widget build(BuildContext context) {
    final score = completeness.score;
    final pendingList = completeness.pendingItems;
    final next = pendingList.isNotEmpty ? pendingList.first : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border(.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  completeness.label,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: ColorPalette.secondaryText,
                  ),
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: ColorPalette.border(.25),
              valueColor:
                  AlwaysStoppedAnimation<Color>(ColorPalette.primaryColorDark),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 10),
            Row(
              // crossAxisAlignment start, because once the hint wraps the icon
              // should stay beside its FIRST line rather than float to the
              // middle of a two-line block.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_circle_right_outlined,
                    size: 14, color: ColorPalette.accentText),
                const SizedBox(width: 6),
                // Expanded, or this Row demands the hint's full intrinsic
                // width and overflows: 107px at 320x568, 67 at 360x640, 37 at
                // 390x844 — all at text scale 2.0, which
                // AccessibilityTokens.maxRequiredTextScale declares supported.
                // In release that is silent clipping, and the text being cut
                // off is the one telling the customer what to do next.
                Expanded(
                  child: Text(
                    next,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: ColorPalette.accentText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section components ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: FontPalette.primaryFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: ColorPalette.secondaryText.withOpacity(.55),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border(.45)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                color: ColorPalette.border(.35),
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ColorPalette.primaryColorDark),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: ColorPalette.secondaryText,
                  ),
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
