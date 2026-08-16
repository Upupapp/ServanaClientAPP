import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_repository.dart';
import 'package:client/modules/bookings/domain/booking_otp_state.dart';
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

  final TextEditingController _controller = TextEditingController();
  String _code = '';
  bool _loading = false;
  String? _errorText;

  BookingLifecycleRepository get _bookings =>
      dpLocator<BookingLifecycleRepository>();

  /// The code's state as the BACKEND describes it, when the transport can say.
  ///
  /// This screen used to hold a private `_resendCooldownSeconds = 60`, count it
  /// down locally, and know nothing else. That number was a copy of an operator
  /// policy the server also holds, and the copy was never checked against the
  /// original — so it was wrong the moment the policy changed, it reset when
  /// the screen was disposed (granting a resend the server then refused), and
  /// it could not express the two limits the client never modelled at all.
  ///
  /// `GET /api/v1/bookings/:id/otp/status` exists so a client renders "resend
  /// in 42s" and "2 attempts left" from the backend. Under the legacy transport
  /// there is no such route, so [BookingOtpState.local] supplies the same 60
  /// seconds — now named as a client assumption rather than passing for policy,
  /// and flagged `isBackendDerived: false` so this screen does not claim
  /// precision it does not have.
  BookingOtpState? _otp;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  bool get _canResend =>
      _resendCountdown == 0 && !_loading && (_otp?.canRequest ?? true);

  @override
  void initState() {
    super.initState();
    _loadOtpState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  /// Reads the code's state without spending an attempt.
  ///
  /// Failure is deliberately silent. This call only enriches the resend
  /// affordance; a customer who has the code in front of them must still be
  /// able to type it if the status route is unreachable, so an error here
  /// leaves the screen exactly as it was before this tab.
  Future<void> _loadOtpState() async {
    try {
      final state = await _bookings.otpStatus('${widget.bookingId}');
      if (!mounted) return;
      setState(() => _otp = state);
      if (state.resendAvailableInSeconds > 0) {
        _startResendCooldown(state.resendAvailableInSeconds);
      }
    } catch (_) {
      // Leave _otp null; the resend button stays enabled and the server
      // remains the authority on whether the resend is permitted.
    }
  }

  Future<void> _verify() async {
    if (_loading || _code.length < _otpLength) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await _bookings.verifyOtp(
        bookingId: '${widget.bookingId}',
        code: _code,
      );
      if (!mounted) return;
      if (widget.flow == BookingOtpFlow.checkout &&
          widget.confirmationRouteName != null) {
        // Replace OTP with the confirmation screen (detail stays beneath).
        context.pushReplacementNamed(widget.confirmationRouteName!);
      } else {
        // Resume flow: hand control back to the detail screen, which refreshes.
        context.pop(true);
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      // `safeMessage` is the only string either transport may render, and it is
      // already the backend's own wording when that wording is customer-safe.
      // The legacy `{success:false, message}` shape reaches here as a
      // ValidationFailure carrying the same text, so the two paths produce the
      // same screen.
      setState(() => _errorText = failure.safeMessage);
      // A refused attempt spends one. Re-read rather than decrementing a local
      // counter, which would be a third copy of the budget.
      unawaited(_loadOtpState());
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
      final issued = await _bookings.requestOtp('${widget.bookingId}');
      if (!mounted) return;

      // Prefer the instant the SERVER says a resend becomes available. Falling
      // back to the local constant only when it said nothing keeps the legacy
      // path behaving exactly as it does today.
      final serverSeconds = issued.resendInSeconds(DateTime.now());
      _startResendCooldown(serverSeconds > 0
          ? serverSeconds
          : BookingOtpState.legacyResendCooldownSeconds);

      unawaited(_loadOtpState());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent.')),
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _errorText = failure.safeMessage);
      // BOOKING_OTP_RESEND_COOLDOWN carries Retry-After, which the mapper puts
      // on the failure. Honouring it is what stops the button re-offering
      // itself into a refusal the server already explained.
      final retryAfter =
          failure is RateLimitFailure ? failure.retryAfter?.inSeconds : null;
      if (retryAfter != null && retryAfter > 0) {
        _startResendCooldown(retryAfter);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Could not resend code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startResendCooldown(int seconds) {
    if (seconds <= 0) return;
    setState(() => _resendCountdown = seconds);
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

  /// "2 attempts left", or nothing.
  ///
  /// Rendered only when the backend supplied a number. A client that guesses
  /// this is worse than one that stays quiet: the customer would budget their
  /// typing against a figure the server does not share.
  String? get _attemptsLine {
    final remaining = _otp?.attemptsRemaining;
    if (remaining == null) return null;
    if (remaining <= 0) return 'No attempts left on this code.';
    return remaining == 1 ? '1 attempt left' : '$remaining attempts left';
  }

  @override
  Widget build(BuildContext context) {
    // Compute cell width that fills the screen without overflowing at 360px.
    // Formula: (usable width − gap total) / cell count, clamped to [42, 56].
    const double horizontalPadding = 48; // 24dp each side
    const double gapBetweenCells = 8;
    const int gapCount = _otpLength - 1;
    final double usable = MediaQuery.of(context).size.width - horizontalPadding;
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
              // Shown only when the backend supplied the number — never on the
              // legacy transport, which does not know it.
              if (_attemptsLine != null) ...[
                const SizedBox(height: 8),
                Text(
                  _attemptsLine!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.accentText,
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
