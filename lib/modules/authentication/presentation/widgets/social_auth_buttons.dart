import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';

/// Google and Facebook auth, shared by sign-in and sign-up.
///
/// Both screens need the same two buttons doing the same two things: social
/// auth upserts the account (`POST /api/auth/customer-firebase-login` creates
/// the row when it does not exist), so "sign up with Google" and "sign in with
/// Google" are one action with two labels.
///
/// Extracted rather than copied. The sign-up screen had no social option at
/// all, and duplicating ~100 lines of button markup to add it would have left
/// two implementations to keep in step — the second one would drift the first
/// time a provider is added or a brand guideline changes.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.isLoading,
    this.verb = 'Continue',
  });

  /// Disables both buttons while an auth request is in flight, so a second tap
  /// cannot start a competing sign-in.
  final bool isLoading;

  /// Leading word of each label. 'Continue' on sign-in, 'Sign up' on the
  /// create-account screen — the action is identical, the customer's intent is
  /// not, and the label should match what they think they are doing.
  final String verb;

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AuthenticationBloc>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        _SocialButton(
          // Semantics carry the full action; the row inside is decorative.
          label: '$verb with Google',
          onPressed: isLoading ? null : () => bloc.add(AuthGoogleSignIn()),
          icon: const _GoogleGlyph(),
        ),
        const SizedBox(height: 10),
        _SocialButton(
          label: '$verb with Facebook',
          onPressed: isLoading ? null : () => bloc.add(AuthFacebookSignIn()),
          icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        // 50 clears the 48pt minimum touch target.
        height: 50,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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

/// The Google "G", drawn rather than shipped as an asset so the button carries
/// no image decode and no extra file.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
