import 'package:awesome_dialog/awesome_dialog.dart';
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

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse('https://servana.com.ph/terms'));
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse('https://servana.com.ph/privacy'));
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
      _showMobileComingSoon();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    bloc.add(AuthenticationInit(email: id, password: _password));
  }

  void _showMobileComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Mobile number login is coming soon. Use your email for now.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showForgotPasswordInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Password reset is coming soon. Contact support if needed.'),
        duration: Duration(seconds: 4),
      ),
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
                                          'Mobile number login coming soon — please use your email.',
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
                                trailing: InkWell(
                                  onTap: () {
                                    setState(
                                        () => _isPassVisible = !_isPassVisible);
                                  },
                                  child: _isPassVisible
                                      ? Icon(
                                          Icons.visibility_off_rounded,
                                          color: ColorPalette.primaryColorDark,
                                        )
                                      : Icon(
                                          Icons.visibility_rounded,
                                          color: ColorPalette.primaryColorDark,
                                        ),
                                ),
                                onChange: (value) {
                                  setState(() => _password = value);
                                },
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _showForgotPasswordInfo,
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
                                      AwesomeDialog(
                                        context: context,
                                        animType: AnimType.bottomSlide,
                                        headerAnimationLoop: false,
                                        dialogType: DialogType.warning,
                                        title: 'Verify your email',
                                        desc:
                                            'We sent a verification link to $_identifier. '
                                            'Open it from your inbox, then come back to sign in.',
                                        btnOkText: 'Resend link',
                                        btnOkOnPress: () {
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
                                        btnCancelText: 'Close',
                                        btnCancelOnPress: () {},
                                      ).show();
                                    } else {
                                      AwesomeDialog(
                                        context: context,
                                        animType: AnimType.bottomSlide,
                                        headerAnimationLoop: false,
                                        dialogType: DialogType.error,
                                        title: 'Sign In Failed',
                                        desc: state.message ??
                                            'The email or password is incorrect.',
                                        btnOkOnPress: () {},
                                      ).show();
                                    }
                                  }
                                },
                                builder: (context, state) {
                                  final isLoading =
                                      state is AuthenticationLoading;
                                  return PrimaryButton(
                                    width: 250,
                                    text: 'Sign In',
                                    onClick:
                                        isLoading ? null : () => _submit(bloc),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Sign up link
                              GestureDetector(
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
