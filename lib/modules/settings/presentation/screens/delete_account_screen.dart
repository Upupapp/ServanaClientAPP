import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Close the account, from inside the app.
///
/// ## Why this screen exists
///
/// App Store Review Guideline 5.1.1(v): an app that supports account creation
/// must also let a customer *initiate* account deletion. The submission on
/// 2026-08-22 was rejected against it. What stood here before was a tile
/// reading "Account deletion will be available in a future update" — which is
/// worse than nothing, because the reviewer found the exact control they were
/// looking for and it told them it did not work.
///
/// The endpoint existed the whole time. This screen is the wiring.
///
/// ## The two rules the flow has to respect
///
/// **Confirmation is allowed; customer service is not.** The guideline permits
/// steps that stop an accidental deletion, and forbids requiring a phone call
/// or an email to support. So there is a deliberate two-step confirm and **no
/// route out of this screen toward `privacy@servana.com.ph`.**
///
/// **Say what actually happens.** The backend records the request, anonymises
/// the identity columns, and keeps the financial trail — a hard delete would
/// violate a foreign key the moment the account has a booking, and the money
/// records must survive for accounting. Promising "everything is erased" would
/// be a lie a reviewer can check.
class DeleteAccountScreen extends StatefulWidget {
  static const String routeName = 'SettingsDeleteAccount';
  static const String route = '/settings/delete-account';

  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _understood = false;
  bool _submitting = false;
  String? _error;

  static const _removed = <String>[
    'Your name, email address and mobile number',
    'Your saved addresses',
    'Your conversations with providers',
  ];

  static const _retained = <String>[
    'Payment and invoice records, which we are required to keep',
    'Completed bookings, with your personal details removed from them',
  ];

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete your account?'),
            content: const Text(
              'This cannot be undone. You will be signed out and will not be '
              'able to sign in to this account again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep my account'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'Delete account',
                  style: TextStyle(color: ColorPalette.danger),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await dpLocator<ServanaApiClient>().requestAccountDeletion();
      if (!mounted) return;
      // Signing out IS part of deletion, not a courtesy: the customer-scoped
      // teardown that runs on logout is what removes this account's drafts,
      // cached inbox and tokens from the device. Leaving them behind would
      // mean the account is closed on the server and still readable here.
      context.read<AuthenticationBloc>().add(AuthLogout());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // A duplicate request is NOT a failure — the backend collapses a second
        // pending request into the first — but anything that reached this catch
        // did not get a 2xx, so it is reported rather than assumed benign.
        _error = 'We could not complete that just now. '
            'Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deleting your account closes it permanently and removes your '
                'personal details from Servana.',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              const _Section(title: 'What is removed', items: _removed),
              const SizedBox(height: 20),
              const _Section(title: 'What is kept', items: _retained),
              const SizedBox(height: 24),
              Text(
                'If you have a booking in progress, it will be cancelled.',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 14,
                  height: 1.45,
                  color: ColorPalette.accentText,
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _understood,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _understood = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I understand this cannot be undone',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                    color: ColorPalette.danger,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_understood && !_submitting) ? _confirmAndDelete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Delete my account',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 10),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ColorPalette.accentText,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    t,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 14,
                      height: 1.4,
                      color: ColorPalette.accentText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
