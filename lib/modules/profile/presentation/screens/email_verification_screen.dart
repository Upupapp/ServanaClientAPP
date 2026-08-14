import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/network/api_error_mapper.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/authentication/domain/auth_failure_copy.dart';
import 'package:client/modules/authentication/presentation/screens/authentication_screen.dart';
import 'package:client/modules/profile/application/profile_controller.dart';
import 'package:client/modules/authentication/data/identity_repository.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SignupEmailVerificationArgs {
  const SignupEmailVerificationArgs({required this.email});

  final String email;
}

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    this.signupEmail,
    this.codeAlreadySent = false,
  });

  static const routeName = 'SignupEmailVerification';
  static const route = '/signup/verify-email';

  final String? signupEmail;
  final bool codeAlreadySent;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _otpCtrl = TextEditingController();

  /// Authentication concerns — proving ownership of a contact channel.
  ///
  /// Separated from [_profileCtrl] deliberately (TAB 03): verifying an email
  /// is an identity operation, and "have they filled in their last name" is a
  /// profile one. They used to share `ProfileRepository`, which is why a
  /// verification failure and a profile-load failure were indistinguishable.
  final _identity = dpLocator<IdentityRepository>();

  /// Profile concerns — refreshed after verification so the badge appears.
  final _profileCtrl = dpLocator<ProfileController>();

  bool _isSending = false;
  bool _isVerifying = false;
  late bool _otpSent;
  bool _verified = false;
  String? _error;

  /// What the customer should do next about [_error].
  ///
  /// Held alongside the message so the screen can offer the right affordance —
  /// an expired code needs "Resend", a wrong one needs "try again", and a rate
  /// limit needs neither until the countdown ends.
  AuthRecovery? _recovery;

  /// Seconds remaining before "Resend code" is offered again.
  ///
  /// Two things drive it: a fixed cooldown after every successful send, and a
  /// server-supplied `Retry-After` when the backend rate-limits us. The server
  /// always wins when it says something, because it knows the real budget.
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  /// Matches the backend's OTP resend budget closely enough to stop the
  /// obvious double-tap, without pretending to know the server's exact window.
  static const int _defaultCooldownSeconds = 30;

  bool get _isSignup => widget.signupEmail != null;

  bool get _canResend => !_isSending && _resendCooldown == 0;

  @override
  void initState() {
    super.initState();
    _otpSent = widget.codeAlreadySent;
    // Arriving with a code already sent means one was just issued, so the
    // cooldown starts here too — otherwise the first thing the screen offers
    // is a resend that the backend will refuse.
    if (_otpSent) _startCooldown(_defaultCooldownSeconds);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    if (seconds <= 0) {
      if (mounted) setState(() => _resendCooldown = 0);
      return;
    }
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  /// Turns any thrown object into copy plus a recovery.
  ///
  /// Replaces `e.toString().contains('400')`, which could not tell an invalid
  /// code from an expired one — the two need different buttons.
  void _applyFailure(Object error) {
    const mapper = ApiErrorMapper();
    // IdentityRepository always throws ApiFailure. The other two branches
    // cover the profile refresh inside _verify, which still goes through the
    // legacy client and can raise ServanaApiException.
    final failure = switch (error) {
      ApiFailure f => f,
      ServanaApiException e =>
        mapper.fromResponse(status: e.statusCode, body: e.body),
      _ => mapper.fromTransport(error),
    };
    final copy = AuthFailureCopy.of(failure);
    setState(() {
      _error = copy.message;
      _recovery = copy.recovery;
    });
    if (copy.recovery == AuthRecovery.wait) {
      _startCooldown(copy.retryAfter?.inSeconds ?? _defaultCooldownSeconds);
    }
  }

  /// The address the OTP is tied to.
  ///
  /// The backend looks the OTP row up BY EMAIL — these routes are
  /// unauthenticated by necessity, since an unverified customer cannot sign in
  /// to obtain a token. Sending the code without it is what made in-app
  /// verification impossible.
  String get _email => widget.signupEmail ?? _profileCtrl.profile?.email ?? '';

  Future<void> _sendOtp() async {
    final email = _email;
    if (email.isEmpty) {
      setState(() => _error =
          'We could not read your email address. Please reopen this screen.');
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
      _recovery = null;
    });
    try {
      await _identity.resendEmailVerification(email);
      if (mounted) {
        setState(() {
          _isSending = false;
          _otpSent = true;
        });
        _startCooldown(_defaultCooldownSeconds);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _applyFailure(e);
      }
    }
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) {
      setState(
          () => _error = 'Please enter the full 6-digit verification code.');
      return;
    }
    final email = _email;
    if (email.isEmpty) {
      setState(() => _error =
          'We could not read your email address. Please reopen this screen.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
      _recovery = null;
    });
    try {
      await _identity.verifyEmail(email: email, otp: otp);
      if (!_isSignup) {
        // Refresh the profile so the verification badge appears.
        await _profileCtrl.loadProfile();
      }
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _verified = true;
        });
      }
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        if (_isSignup) {
          context.goNamed(WelcomeScreen.routeName);
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        _applyFailure(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _email;
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: ColorPalette.secondaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verify Email',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        children: [
          Icon(Icons.mark_email_unread_outlined,
              size: 56, color: ColorPalette.primaryColorDark),
          const SizedBox(height: 20),
          Text(
            'Verify your email address',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            email.isNotEmpty
                ? 'We\'ll send a verification code to\n$email'
                : 'We\'ll send a verification code to your email address.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 14,
              color: ColorPalette.accentText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (_verified) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email verified successfully!',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (!_otpSent) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColorDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSending ? null : _sendOtp,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Send Verification Code',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ] else ...[
              Text(
                'Enter verification code',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: ColorPalette.secondaryText.withOpacity(.7),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: ColorPalette.secondaryText,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: ColorPalette.secondaryText.withOpacity(.25),
                    letterSpacing: 6,
                  ),
                  filled: true,
                  fillColor: ColorPalette.secondaryBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColorDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isVerifying ? null : _verify,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Verify Email',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Same TextButton as before; it now states WHY it is disabled.
              // A dead "Resend code" with no explanation reads as a broken
              // screen, and the customer taps it repeatedly into a rate limit.
              TextButton(
                onPressed: _canResend ? _sendOtp : null,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend code in ${_resendCooldown}s'
                      : 'Resend code',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: _canResend
                        ? ColorPalette.primaryColorDark
                        : ColorPalette.primaryColorDark.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 13,
                  color: ColorPalette.danger,
                ),
              ),
              // Session-expired is the one failure this screen cannot recover
              // from in place: the customer has to sign in again, and without
              // a way out they are left staring at an error with no action.
              if (_recovery == AuthRecovery.reauthenticate) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      context.goNamed(AuthenticationScreen.routeName),
                  child: Text(
                    'Sign in again',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.primaryColorDark,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
