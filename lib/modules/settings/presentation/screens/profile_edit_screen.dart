import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/profile/application/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProfileEditScreen extends StatefulWidget {
  static const String routeName = 'SettingsProfileEdit';
  static const String route = '/settings/profile-edit';

  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final ProfileController _ctrl;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _email = '';
  String? _birthdate;
  String? _gender;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  static const _genderOptions = [
    ('male', 'Male'),
    ('female', 'Female'),
    ('prefer_not_to_say', 'Prefer not to say'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<ProfileController>();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    // If the controller already has a profile, use it immediately.
    var profile = _ctrl.profile;
    if (profile == null) {
      await _ctrl.loadProfile();
      profile = _ctrl.profile;
    }
    if (!mounted) return;
    if (profile == null) {
      context.pop();
      return;
    }
    setState(() {
      _nameCtrl.text = profile!.displayName;
      _email = profile.email;
      _phoneCtrl.text = profile.phoneNumber ?? '';
      _birthdate = profile.birthdate;
      _gender = profile.gender;
      _loading = false;
    });
  }

  static final _phoneRx = RegExp(r'^(\+63|0)9\d{9}$');

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Full name cannot be empty.');
      return;
    }
    if (name.length > 100) {
      setState(() => _error = 'Name cannot exceed 100 characters.');
      return;
    }
    if (phone.isNotEmpty && !_phoneRx.hasMatch(phone)) {
      setState(() => _error =
          'Enter a valid Philippine mobile number (e.g. +63 917 123 4567).');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });
    final ok = await _ctrl.updateProfile(
      fullname: name,
      mobileNumber: phone.isNotEmpty ? phone : null,
      birthdate: _birthdate,
      gender: _gender,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _saving = false;
        _saved = true;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.pop();
    } else {
      setState(() {
        _saving = false;
        _error = _ctrl.saveError ?? 'Failed to save. Please try again.';
      });
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthdate != null
        ? DateTime.tryParse(_birthdate!) ?? DateTime(now.year - 25)
        : DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 12),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: ColorPalette.primaryColorDark,
            onPrimary: Colors.white,
            surface: ColorPalette.secondaryBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _birthdate = DateFormat('yyyy-MM-dd').format(picked));
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
                            color:
                                ColorPalette.secondaryText.withOpacity(.55),
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
                const SizedBox(height: 20),
                _fieldLabel('Date of Birth'),
                const SizedBox(height: 6),
                Semantics(
                  label: 'Date of birth',
                  button: true,
                  hint: 'Opens date picker',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: _pickBirthdate,
                    child: Container(
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
                              _birthdate != null && _birthdate!.isNotEmpty
                                  ? _formatBirthdate(_birthdate!)
                                  : 'Select date of birth',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 15,
                                color: _birthdate != null && _birthdate!.isNotEmpty
                                    ? ColorPalette.secondaryText
                                    : ColorPalette.secondaryText.withOpacity(.35),
                              ),
                            ),
                          ),
                          Icon(Icons.calendar_today_outlined,
                              size: 16, color: ColorPalette.accentText),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _fieldLabel('Gender'),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: ColorPalette.secondaryBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ColorPalette.border(.45)),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _genderOptions.length; i++) ...[
                        _GenderOption(
                          value: _genderOptions[i].$1,
                          label: _genderOptions[i].$2,
                          selected: _gender == _genderOptions[i].$1,
                          onTap: () => setState(
                              () => _gender = _genderOptions[i].$1),
                          topRadius: i == 0,
                          bottomRadius: i == _genderOptions.length - 1,
                        ),
                        if (i < _genderOptions.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            color: ColorPalette.border(.35),
                          ),
                      ],
                    ],
                  ),
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

  String _formatBirthdate(String iso) {
    try {
      return DateFormat('MMMM d, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
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

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.topRadius,
    required this.bottomRadius,
  });

  final String value;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool topRadius;
  final bool bottomRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: topRadius ? const Radius.circular(14) : Radius.zero,
      topRight: topRadius ? const Radius.circular(14) : Radius.zero,
      bottomLeft: bottomRadius ? const Radius.circular(14) : Radius.zero,
      bottomRight: bottomRadius ? const Radius.circular(14) : Radius.zero,
    );
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
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
              if (selected)
                Icon(Icons.check_circle_rounded,
                    size: 20, color: ColorPalette.primaryColorDark)
              else
                Icon(Icons.circle_outlined,
                    size: 20,
                    color: ColorPalette.secondaryText.withOpacity(.3)),
            ],
          ),
        ),
      ),
    );
  }
}
