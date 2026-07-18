import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/domain/auth/auth_return_intent.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/authentication/presentation/screens/authentication_screen.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
import 'package:client/modules/registration/presentation/screens/create_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Full-screen authentication gate shown when a guest attempts a
/// protected action (booking confirm, messages, profile, etc.).
///
/// Passes [returnIntent] through to the auth screen so the user is
/// returned to the correct destination after signing in.
class AuthenticationGateScreen extends StatelessWidget {
  static const String routeName = 'AuthGate';
  static const String route = '/auth-gate';

  const AuthenticationGateScreen({super.key, this.returnIntent});

  final AuthReturnIntent? returnIntent;

  @override
  Widget build(BuildContext context) {
    return _AuthGateSheet(returnIntent: returnIntent);
  }
}

/// Bottom-sheet-style gate — can also be used as a modal via
/// [showAuthGateSheet].
class _AuthGateSheet extends StatelessWidget {
  const _AuthGateSheet({this.returnIntent});
  final AuthReturnIntent? returnIntent;

  @override
  Widget build(BuildContext context) {
    final reason = returnIntent?.displayReason ?? 'to continue';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Close / back
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  tooltip: 'Close',
                  icon: Icon(
                    Icons.close_rounded,
                    color: ColorPalette.primaryColorDark,
                    size: 28,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(WelcomeScreen.routeName);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Branding mark
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F44F2).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF1F44F2),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Headline
              Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: const Color(0xFF111827),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Context copy
              Text(
                'Sign in or create an account $reason.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 15,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Sign In
              _GateButton(
                label: 'Sign In',
                filled: true,
                onTap: () {
                  AppHaptics.selection();
                  context.goNamed(AuthenticationScreen.routeName);
                },
              ),
              const SizedBox(height: 12),

              // Create Account
              _GateButton(
                label: 'Create Account',
                filled: false,
                onTap: () {
                  AppHaptics.selection();
                  context.goNamed(CreateAccountScreen.routeName);
                },
              ),
              const SizedBox(height: 16),

              // Continue browsing
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.goNamed(WelcomeScreen.routeName);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Continue Browsing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 14,
                      color: ColorPalette.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateButton extends StatelessWidget {
  const _GateButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F44F2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F44F2),
                side: const BorderSide(color: Color(0xFF1F44F2), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
    );
  }
}

/// Shows the auth gate as a modal bottom sheet.
/// Returns true if the user authenticated, false/null if they dismissed.
Future<bool?> showAuthGateSheet(
  BuildContext context, {
  AuthReturnIntent? intent,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: _AuthGateSheet(returnIntent: intent),
      ),
    ),
  );
}
