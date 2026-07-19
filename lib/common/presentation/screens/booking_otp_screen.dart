import 'dart:async';
import 'dart:convert';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

/// Which flow launched the OTP screen — determines what happens on success.
enum BookingOtpFlow {
  /// Reached right after booking creation; on success advance to the
  /// confirmation screen.
  checkout,

  /// Reached from the booking detail screen to finish a `PENDING_OTP` booking;
  /// on success pop back to detail with a `true` result.
  resume,
}

/// Route arguments for [BookingOtpScreen], passed via `state.extra`.
class BookingOtpArgs {
  const BookingOtpArgs({
    required this.bookingId,
    required this.flow,
    this.confirmationRouteName,
  });

  /// Id of the freshly-created booking (status `PENDING_OTP`) to verify.
  final int bookingId;

  /// What launched this screen — drives the post-success navigation.
  final BookingOtpFlow flow;

  /// Confirmation route to advance to on success in [BookingOtpFlow.checkout]
  /// (ignored for resume). The target route MUST take no arguments — both
  /// confirmation screens are const and read their data from the MobX store.
  final String? confirmationRouteName;
}

/// OTP verification for a freshly-created (`PENDING_OTP`) booking. The customer
/// enters the 6-digit `otpCode` (delivered out-of-band) and we verify it via
/// `POST /api/:id/confirm-otp`. On success the checkout flow advances to the
/// confirmation screen; the resume flow pops back to booking detail. In both
/// flows the booking detail screen sits directly beneath, so a plain back
/// gesture returns there.
class BookingOtpScreen extends StatefulWidget {
  static const String routeName = 'BookingOtp';
  static const String route = 'BookingOtp';

  const BookingOtpScreen({
    super.key,
    required this.bookingId,
    required this.flow,
    this.confirmationRouteName,
  });

  final int bookingId;
  final BookingOtpFlow flow;
  final String? confirmationRouteName;

  @override
  State<BookingOtpScreen> createState() => _BookingOtpScreenState();
}

class _BookingOtpScreenState extends State<BookingOtpScreen> {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 60;

  final TextEditingController _controller = TextEditingController();
  String _code = '';
  bool _loading = false;
  String? _errorText;

  // Resend cooldown
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool get _canResend => _resendCountdown == 0 && !_loading;

  @override
  void dispose() {
    _controller.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_loading || _code.length < _otpLength) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final res = await dpLocator<ServanaApiClient>()
          .confirmOtp(bookingId: widget.bookingId, otp: _code);
      if (!mounted) return;
      if (res['success'] == false) {
        setState(() => _errorText =
            (res['message'] ?? 'Invalid code. Please try again.').toString());
        return;
      }
      if (widget.flow == BookingOtpFlow.checkout &&
          widget.confirmationRouteName != null) {
        // Replace OTP with the confirmation screen (detail stays beneath).
        context.pushReplacementNamed(widget.confirmationRouteName!);
      } else {
        // Resume flow: hand control back to the detail screen, which refreshes.
        context.pop(true);
      }
    } on ServanaApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = _messageFrom(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await dpLocator<ServanaApiClient>()
          .resendOtp(bookingId: widget.bookingId);
      if (!mounted) return;
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Could not resend code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startResendCooldown() {
    setState(() => _resendCountdown = _resendCooldownSeconds);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _resendCountdown = 0;
          t.cancel();
        }
      });
    });
  }

  String _messageFrom(ServanaApiException e) {
    try {
      final decoded = jsonDecode(e.body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'] ?? decoded['error'];
        if (msg != null) return msg.toString();
      }
    } catch (_) {}
    return 'Invalid code. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    // Compute cell width that fills the screen without overflowing at 360px.
    // Formula: (usable width − gap total) / cell count, clamped to [42, 56].
    const double horizontalPadding = 48; // 24dp each side
    const double gapBetweenCells = 8;
    const int gapCount = _otpLength - 1;
    final double usable =
        MediaQuery.of(context).size.width - horizontalPadding;
    final double pinWidth =
        ((usable - gapCount * gapBetweenCells) / _otpLength).clamp(42.0, 56.0);

    final defaultPinTheme = PinTheme(
      width: pinWidth,
      height: 56,
      textStyle: TextStyle(
        fontFamily: FontPalette.primaryFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ColorPalette.secondaryText,
      ),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errorText != null
              ? ColorPalette.danger
              : ColorPalette.secondaryBorder,
        ),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: (defaultPinTheme.decoration as BoxDecoration).copyWith(
        border: Border.all(color: ColorPalette.primaryColorDark, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        iconTheme: IconThemeData(color: ColorPalette.primaryText),
        title: Text(
          'Verify Booking',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            color: ColorPalette.primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Icon(
                Icons.sms_outlined,
                size: 56,
                color: ColorPalette.primaryColorDark,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter verification code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to the phone number on your account. '
                'Enter it below to confirm your booking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 13,
                  color: ColorPalette.accentText,
                ),
              ),
              const SizedBox(height: 28),
              Pinput(
                length: _otpLength,
                controller: _controller,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                keyboardType: TextInputType.number,
                enabled: !_loading,
                onChanged: (value) => setState(() {
                  _code = value;
                  _errorText = null;
                }),
                onCompleted: (value) {
                  _code = value;
                  _verify();
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: ColorPalette.primaryColorDark,
                        ),
                      )
                    : PrimaryButton(
                        text: 'Verify',
                        onClick: _code.length == _otpLength ? _verify : null,
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _canResend ? _resendOtp : null,
                child: Text(
                  _resendCountdown > 0
                      ? 'Resend code in ${_resendCountdown}s'
                      : 'Resend code',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: _canResend
                        ? ColorPalette.primaryColorDark
                        : ColorPalette.accentText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
