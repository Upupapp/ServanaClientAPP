import 'package:awesome_dialog/awesome_dialog.dart';
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
  State<AuthenticationScreen> createState() => _AuthenticationScreebState();
}

class _AuthenticationScreebState extends State<AuthenticationScreen> {
  String? emailString;
  String? passwordString;
  bool isPassVisible = false;

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
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 25,
                  ),
                  Text(
                    "Login",
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
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
                            children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                "Enter your email and password to sign in.",
                                maxLines: 4,
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  color: ColorPalette.secondaryText,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 25,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        CustomTextField(
                          label: "Email",
                          inputType: TextInputType.emailAddress,
                          onChange: (value) {
                            setState(() {
                              emailString = value;
                            });
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CustomTextField(
                          label: "Password",
                          inputType: TextInputType.emailAddress,
                          obscureText: !isPassVisible,
                          trailing: InkWell(
                              onTap: () {
                                setState(() {
                                  isPassVisible = !isPassVisible;
                                });
                              },
                              child: isPassVisible
                                  ? Icon(
                                      Icons.visibility_off_rounded,
                                      color: ColorPalette.primaryColorDark,
                                    )
                                  : Icon(
                                      Icons.visibility_rounded,
                                      color: ColorPalette.primaryColorDark,
                                    )),
                          onChange: (value) {
                            setState(() {
                              passwordString = value;
                            });
                          },
                        ),
                        const Spacer(),
                        BlocConsumer<AuthenticationBloc, AuthenticationState>(
                            listener: (context, state) {
                          if (state is AuthenticationLoading) {
                            context.loaderOverlay.show();
                          } else {
                            context.loaderOverlay.hide();
                          }

                          if (state is AuthenticationAuthenticated) {
                            context.goNamed(HomeScreen.routeName);
                          }
                          if (state is AuthenticationUnauthenticated) {
                            final msg = (state.message ?? '').toLowerCase();
                            final isUnverifiedEmail =
                                msg.contains('verify email') ||
                                    msg.contains('not verified') ||
                                    msg.contains('unverified') ||
                                    msg.contains('email verification');

                            if (isUnverifiedEmail &&
                                (emailString?.isNotEmpty ?? false)) {
                              AwesomeDialog(
                                context: context,
                                animType: AnimType.bottomSlide,
                                headerAnimationLoop: false,
                                dialogType: DialogType.warning,
                                title: 'Verify your email',
                                desc:
                                    'We sent a verification link to $emailString. '
                                    'Open it from your inbox, then come back to log in.',
                                btnOkText: 'Resend link',
                                btnOkOnPress: () {
                                  BlocProvider.of<RegistrationBloc>(context).add(
                                    ResendVerificationEmail(
                                        email: emailString!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                title: 'Login Failed',
                                desc: state.message ?? "Invalid Credentials",
                                btnOkOnPress: () {},
                              ).show();
                            }
                          }
                        }, builder: (context, state) {
                          return PrimaryButton(
                            width: 250,
                            text: "Login",
                            onClick: () {
                              bloc.add(
                                AuthenticationInit(
                                  email: emailString ?? '',
                                  password: passwordString ?? '',
                                ),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 16),
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
                                  fontFamily: FontPalette.primaryFontFamily,
                                  color: ColorPalette.secondaryText,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Sign up",
                                    style: TextStyle(
                                      fontFamily: FontPalette.primaryFontFamily,
                                      color: ColorPalette.primaryColorDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text.rich(
                            TextSpan(
                              text:
                                  "By giving your information, you agree to our ",
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                color: ColorPalette.secondaryText,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: "Terms & Conditions",
                                  style: TextStyle(
                                    color: ColorPalette.primaryColorDark,
                                  ),
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy Policy.",
                                  style: TextStyle(
                                    color: ColorPalette.primaryColorDark,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
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
