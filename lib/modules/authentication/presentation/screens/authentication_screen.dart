import 'package:client/common/constants/servana_urls.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/authentication/data/identity_repository.dart';
import 'package:client/common/presentation/dialogs/servana_alert_dialog.dart';
import 'package:client/common/domain/auth/auth_identifier.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_state.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
import 'package:client/modules/registration/presentation/bloc/registration_bloc.dart';
import 'package:client/modules/registration/presentation/bloc/registration_events.dart';
import 'package:client/modules/registration/presentation/screens/create_account_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  static String routeName = "Authenticate";
  static String route = "Authenticate";

  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  String _identifier = '';
  String _password = '';
  bool _isPassVisible = false;

  // True while a login request is in-flight — prevents double-tap.
  bool _isSubmitting = false;

  // Whether the current identifier input looks like a mobile number.
  bool _isMobileInput = false;

  // True while a password-reset email request is in-flight.
  bool _isRequestingReset = false;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse(ServanaUrls.termsAndConditions));
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse(ServanaUrls.privacyPolicy));
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _onIdentifierChanged(String value) {
    setState(() {
      _identifier = value;
      _isMobileInput = AuthIdentifier.isMobileInput(value);
    });
  }

  void _submit(AuthenticationBloc bloc) {
    if (_isSubmitting) return;
    final id = _identifier.trim();
    if (id.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }
    // Backend only supports email auth; mobile detection means we gate early.
    if (_isMobileInput) {
      _showEmailRequired();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    bloc.add(AuthenticationInit(email: id, password: _password));
  }

  /// Tells the customer what to do, rather than promising a feature.
  ///
  /// This used to say mobile login was "coming soon". It is not scheduled:
  /// the canonical endpoint takes a Firebase phone credential rather than a
  /// number and an OTP, which is a redesign. Promising it sets a customer
  /// waiting for something no release is bringing, and an MVP is judged by
  /// what can be finished today.
  void _showEmailRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign in with your email address.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Requests a password reset email.
  ///
  /// This screen used to say "Password reset is coming soon", which was never
  /// true of the backend: `POST /api/auth/forgot-password` has been deployed
  /// and rate-limited throughout, and it emails a Firebase reset link. So a
  /// customer who forgot their password had no self-service recovery at all
  /// while the route to give them one was already there.
  ///
  /// The reset itself finishes in a browser on Firebase's hosted page — the
  /// app never receives the code, so there is no in-app reset screen to reach.
  /// Requesting the email is the whole of this app's part.
  Future<void> _requestPasswordReset() async {
    if (_isRequestingReset) return;

    final email = _identifier.trim();
    // Recovery needs an email. The identifier field also accepts a mobile
    // number, and there is no SMS sender on this platform, so asking for one
    // here would promise a message that never arrives.
    if (email.isEmpty || _isMobileInput || !email.contains('@')) {
      _showResetNotice('Enter your email address first, then tap Forgot '
          'password.');
      return;
    }

    setState(() => _isRequestingReset = true);
    try {
      await dpLocator<IdentityRepository>().forgotPassword(email);
    } on ApiFailure catch (failure) {
      // A transport failure is worth saying out loud; the OUTCOME is not.
      _showResetNotice(failure.safeMessage);
      return;
    } catch (_) {
      _showResetNotice('Could not reach Servana. Check your connection and '
          'try again.');
      return;
    } finally {
      if (mounted) setState(() => _isRequestingReset = false);
    }

    // Deliberately the same message whether or not the address is registered.
    // The backend answers neutrally for exactly this reason, and a client that
    // said "no account with that email" would hand back the account
    // enumeration the backend refused to give.
    _showResetNotice('If an account with that email exists, we have sent a '
        'reset link. Check your inbox and spam folder.');
  }

  void _showResetNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AuthenticationBloc>(context);

    return Scaffold(
      body: LoaderOverlay(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Go back',
                    onPressed: () {
                      context.goNamed(WelcomeScreen.routeName);
                    },
                    icon: Icon(
                      Icons.chevron_left,
                      size: 40,
                      color: ColorPalette.primaryColorDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 25),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 25),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Enter your email and password to sign in.',
                                      maxLines: 4,
                                      style: TextStyle(
                                        fontFamily:
                                            FontPalette.primaryFontFamily,
                                        color: ColorPalette.secondaryText,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 25),
                                ],
                              ),
                              const SizedBox(height: 25),

                              // Email / identifier field
                              CustomTextField(
                                label: 'Email',
                                inputType: TextInputType.emailAddress,
                                onChange: _onIdentifierChanged,
                              ),

                              // Mobile-login notice — shown only when user types a phone number
                              if (_isMobileInput)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 14,
                                        color: ColorPalette.primaryColorDark,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Sign in with your email address.',
                                          style: TextStyle(
                                            fontFamily:
                                                FontPalette.primaryFontFamily,
                                            fontSize: 12,
                                            color:
                                                ColorPalette.primaryColorDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // Password field — correct keyboard type
                              CustomTextField(
                                label: 'Password',
                                inputType: TextInputType.visiblePassword,
                                obscureText: !_isPassVisible,
                                trailing: Semantics(
                                  label: _isPassVisible
                                      ? 'Hide password'
                                      : 'Show password',
                                  button: true,
                                  excludeSemantics: true,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() =>
                                          _isPassVisible = !_isPassVisible);
                                    },
                                    child: _isPassVisible
                                        ? Icon(
                                            Icons.visibility_off_rounded,
                                            color:
                                                ColorPalette.primaryColorDark,
                                          )
                                        : Icon(
                                            Icons.visibility_rounded,
                                            color:
                                                ColorPalette.primaryColorDark,
                                          ),
                                  ),
                                ),
                                onChange: (value) {
                                  setState(() => _password = value);
                                },
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: Semantics(
                                  label: 'Forgot password',
                                  button: true,
                                  excludeSemantics: true,
                                  child: GestureDetector(
                                    onTap: _requestPasswordReset,
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 4),
                                      child: Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontFamily:
                                              FontPalette.primaryFontFamily,
                                          fontSize: 13,
                                          color: ColorPalette.primaryColorDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              BlocConsumer<AuthenticationBloc,
                                  AuthenticationState>(
                                listener: (context, state) {
                                  if (state is AuthenticationLoading) {
                                    context.loaderOverlay.show();
                                  } else {
                                    context.loaderOverlay.hide();
                                    setState(() => _isSubmitting = false);
                                  }

                                  if (state is AuthenticationAuthenticated) {
                                    context.goNamed(HomeScreen.routeName);
                                  }
                                  if (state is AuthenticationUnauthenticated) {
                                    final msg =
                                        (state.message ?? '').toLowerCase();
                                    final isUnverifiedEmail =
                                        msg.contains('verify') ||
                                            msg.contains('verified') ||
                                            msg.contains('verification') ||
                                            msg.contains('confirm');

                                    if (isUnverifiedEmail &&
                                        _identifier.isNotEmpty) {
                                      ServanaAlertDialog.show(
                                        context: context,
                                        type: ServanaAlertType.warning,
                                        title: 'Verify your email',
                                        message:
                                            'We sent a verification link to $_identifier. '
                                            'Open it from your inbox, then come back to sign in.',
                                        okText: 'Resend link',
                                        onOk: () {
                                          BlocProvider.of<RegistrationBloc>(
                                                  context)
                                              .add(
                                            ResendVerificationEmail(
                                                email: _identifier),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Verification link sent. Check your inbox.')),
                                          );
                                        },
                                        cancelText: 'Close',
                                      );
                                    } else {
                                      ServanaAlertDialog.show(
                                        context: context,
                                        type: ServanaAlertType.error,
                                        title: 'Sign In Failed',
                                        message: state.message ??
                                            'The email or password is incorrect.',
                                      );
                                    }
                                  }
                                },
                                builder: (context, state) {
                                  final isLoading =
                                      state is AuthenticationLoading;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      PrimaryButton(
                                        width: 250,
                                        text: 'Sign In',
                                        onClick: isLoading
                                            ? null
                                            : () => _submit(bloc),
                                      ),
                                      const SizedBox(height: 24),

                                      // Social sign-in divider
                                      Row(
                                        children: [
                                          const Expanded(child: Divider()),
                                          // Flexible: the two Expanded dividers
                                          // shrink to nothing at text scale
                                          // 2.0, but the label between them
                                          // still demanded its intrinsic width
                                          // and overflowed by 142px. It has to
                                          // be able to give as well.
                                          Flexible(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: Text(
                                                'or continue with',
                                                style: TextStyle(
                                                  fontFamily: FontPalette
                                                      .primaryFontFamily,
                                                  color: ColorPalette
                                                      .secondaryText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: Divider()),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Google sign-in button — disabled during loading
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: OutlinedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () =>
                                                  bloc.add(AuthGoogleSignIn()),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Colors.grey.shade400),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Google "G" logo
                                              Container(
                                                width: 22,
                                                height: 22,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF4285F4),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'G',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Flexible: this label overflowed
                                              // the button by 94px at 320x568
                                              // AT TEXT SCALE 1.0 — the default
                                              // — so it was clipped for every
                                              // customer on a small handset.
                                              Flexible(
                                                child: Text(
                                                  'Continue with Google',
                                                  style: TextStyle(
                                                    fontFamily: FontPalette
                                                        .primaryFontFamily,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Facebook sign-in button — disabled during loading
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: OutlinedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () => bloc
                                                  .add(AuthFacebookSignIn()),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                                color: Colors.grey.shade400),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.facebook,
                                                  color: Color(0xFF1877F2),
                                                  size: 24),
                                              const SizedBox(width: 10),
                                              // Flexible: this label overflowed
                                              // the button by 122px at 320x568
                                              // AT TEXT SCALE 1.0 — the default
                                              // — so it was clipped for every
                                              // customer on a small handset.
                                              Flexible(
                                                child: Text(
                                                  'Continue with Facebook',
                                                  style: TextStyle(
                                                    fontFamily: FontPalette
                                                        .primaryFontFamily,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                },
                              ),

                              // Sign up link
                              Semantics(
                                label: 'Create an account',
                                button: true,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  onTap: () => context
                                      .goNamed(CreateAccountScreen.routeName),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 4),
                                    child: Text.rich(
                                      TextSpan(
                                        text: "Don't have an account? ",
                                        style: TextStyle(
                                          fontFamily:
                                              FontPalette.primaryFontFamily,
                                          color: ColorPalette.secondaryText,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Sign up',
                                            style: TextStyle(
                                              fontFamily:
                                                  FontPalette.primaryFontFamily,
                                              color:
                                                  ColorPalette.primaryColorDark,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text.rich(
                                  TextSpan(
                                    text:
                                        'By giving your information, you agree to our ',
                                    style: TextStyle(
                                      fontFamily: FontPalette.primaryFontFamily,
                                      color: ColorPalette.secondaryText,
                                      fontSize: 12,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          color: ColorPalette.primaryColorDark,
                                        ),
                                        recognizer: _termsRecognizer,
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy.',
                                        style: TextStyle(
                                          color: ColorPalette.primaryColorDark,
                                        ),
                                        recognizer: _privacyRecognizer,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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
