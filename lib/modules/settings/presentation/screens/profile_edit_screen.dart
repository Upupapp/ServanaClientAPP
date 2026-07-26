import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  static const String routeName = 'SettingsProfileEdit';
  static const String route = '/settings/profile-edit';

  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _api = dpLocator<ServanaApiClient>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _email = '';

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final s = await SessionService.getSession();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = s?.fullname ?? '';
      _email = s?.emailAddress ?? '';
      _phoneCtrl.text = s?.mobileNumber ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Full name cannot be empty.');
      return;
    }
    setState(() { _saving = true; _error = null; _saved = false; });
    try {
      await _api.updateProfile(payload: {
        'fullname': name,
        'mobileNumber': phone,
      });
      // Patch the local session so the profile header reflects the change.
      final session = await SessionService.getSession();
      if (session != null) {
        await SessionService.saveSession(
          session.copyWith(fullname: name, mobileNumber: phone),
        );
      }
      if (!mounted) return;
      setState(() { _saving = false; _saved = true; });
      // Brief success delay, then pop back.
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Failed to save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        title: Text(
          'Edit Profile',
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                _fieldLabel('Full Name'),
                const SizedBox(height: 6),
                _textField(
                  controller: _nameCtrl,
                  hint: 'Your full name',
                  inputType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                _fieldLabel('Email Address'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: ColorPalette.secondaryBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ColorPalette.border(.45)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _email.isEmpty ? '—' : _email,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 15,
                            color: ColorPalette.secondaryText.withOpacity(.55),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: ColorPalette.accentText,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Email cannot be changed here.',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 11,
                      color: ColorPalette.accentText,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _fieldLabel('Mobile Number'),
                const SizedBox(height: 6),
                _textField(
                  controller: _phoneCtrl,
                  hint: '+63 9XX XXX XXXX',
                  inputType: TextInputType.phone,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                      color: ColorPalette.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _saved
                          ? Colors.green.shade600
                          : ColorPalette.primaryColorDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _saving || _saved ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : _saved
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Saved!',
                                    style: TextStyle(
                                      fontFamily: FontPalette.primaryFontFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: ColorPalette.secondaryText.withOpacity(.7),
          letterSpacing: 0.2,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required TextInputType inputType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool autofocus = false,
  }) =>
      TextField(
        controller: controller,
        keyboardType: inputType,
        textCapitalization: textCapitalization,
        autofocus: autofocus,
        style: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          fontSize: 15,
          color: ColorPalette.secondaryText,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            color: ColorPalette.secondaryText.withOpacity(.35),
          ),
          filled: true,
          fillColor: ColorPalette.secondaryBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: ColorPalette.border(.45)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: ColorPalette.border(.45)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: ColorPalette.primaryColorDark, width: 1.5),
          ),
        ),
      );
}
