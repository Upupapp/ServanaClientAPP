import 'package:client/common/constants/servana_urls.dart';
import 'package:client/common/presentation/dialogs/servana_alert_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:client/modules/authentication/presentation/widgets/social_auth_buttons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/authentication/presentation/screens/authentication_screen.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
import 'package:client/modules/profile/presentation/screens/email_verification_screen.dart';
import 'package:client/modules/registration/presentation/bloc/registration_bloc.dart';
import 'package:client/modules/registration/presentation/bloc/registration_events.dart';
import 'package:client/modules/registration/presentation/bloc/registration_states.dart';
import 'package:client/modules/registration/data/resources/form_state.dart'
    as reg;

class CreateAccountScreen extends StatefulWidget {
  static String routeName = "CreateAccount";
  static String route = "/CreateAccount";

  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // The overlay_tooltip machinery that used to live here is gone. It could
  // never have worked: the screen registered no OverlayTooltipItem and the app
  // has no OverlayTooltipScaffold anywhere, so `controller.start()` hit the
  // package's own `playWidgetLength == 0` guard and THREW — 500ms after every
  // new customer opened the sign-up screen. The tour never appeared; the only
  // thing it produced was an unhandled async error.
  //
  // `CustomToolTip`, the widget written to render it, has no callers at all.
  // Left in place rather than deleted, in case the intent is to finish it.
  String _firstName = '';
  String _lastName = '';
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    final bloc = BlocProvider.of<RegistrationBloc>(context);
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse(ServanaUrls.termsAndConditions));
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse(ServanaUrls.privacyPolicy));

    final existing = (bloc.registration.ownerName ?? '').trim();
    if (existing.isNotEmpty) {
      final parts = existing.split(RegExp(r'\s+'));
      _firstName = parts.first;
      _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    super.initState();
  }

  void _syncName(RegistrationBloc bloc) {
    bloc.registration = bloc.registration.copyWith(
      ownerName: '$_firstName $_lastName'.trim(),
    );
  }

  @override
  void dispose() {
    final bloc = dpLocator<RegistrationBloc>();
    bloc.add(const ValidationReset());
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 25,
                  ),
                  // Expanded: this heading overflowed by 90px at 320x568 AT
                  // TEXT SCALE 1.0 — the default — so the sign-up screen's own
                  // title was clipped for every customer on a small handset.
                  // Identical to the defect on SelectPaymentMethodScreen.
                  Expanded(
                    child: Text(
                      "Create your Account",
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              BlocConsumer<RegistrationBloc, RegistrationState>(
                listener: (context, state) async {
                  if (state is RegistrationLoadingState) {
                    context.loaderOverlay.show();
                    return;
                  }
                  context.loaderOverlay.hide();

                  if (state is RegistrationSubmittedState) {
                    final email = state.registration?.ownerEmail?.trim() ?? '';
                    await ServanaAlertDialog.show(
                      context: context,
                      type: ServanaAlertType.success,
                      title: "Success",
                      message:
                          "Your account has been created. Enter the verification code sent to $email.",
                      okText: "Verify Email",
                    );
                    // ignore: use_build_context_synchronously
                    context.goNamed(
                      EmailVerificationScreen.routeName,
                      extra: SignupEmailVerificationArgs(email: email),
                    );
                  }
                  if (state is RegistrationSubmittedFailedState) {
                    ServanaAlertDialog.show(
                      // ignore: use_build_context_synchronously
                      context: context,
                      type: ServanaAlertType.error,
                      title: "Error",
                      message: state.error,
                      okText: "Okay",
                    );
                  }
                },
                builder: (context, state) {
                  final bloc = BlocProvider.of<RegistrationBloc>(context);
                  final isLoading = state is RegistrationLoadingState;
                  reg.FormState? formState;

                  if (state.formState is reg.FormInvalid) {
                    formState = state.formState;
                  }

                  return Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "Enter your personal information to create your account.",
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: "First Name",
                                    inputType: TextInputType.name,
                                    enabled: !isLoading,
                                    error: formState?.formError?.ownerName,
                                    value:
                                        _firstName.isEmpty ? null : _firstName,
                                    onChange: (value) {
                                      _firstName = value;
                                      _syncName(bloc);
                                      bloc.add(
                                        ValidationReset(
                                          errorModel:
                                              formState?.formError?.copyWith(
                                            ownerName: null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    label: "Last Name",
                                    inputType: TextInputType.name,
                                    enabled: !isLoading,
                                    value: _lastName.isEmpty ? null : _lastName,
                                    onChange: (value) {
                                      _lastName = value;
                                      _syncName(bloc);
                                      bloc.add(
                                        ValidationReset(
                                          errorModel:
                                              formState?.formError?.copyWith(
                                            ownerName: null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            CustomTextField(
                              label: "Email",
                              inputType: TextInputType.emailAddress,
                              enabled: !isLoading,
                              error: formState?.formError?.ownerEmail,
                              value: bloc.registration.ownerEmail,
                              onChange: (value) {
                                bloc.add(
                                  ValidationReset(
                                    errorModel: formState?.formError?.copyWith(
                                      ownerEmail: null,
                                    ),
                                  ),
                                );
                                bloc.registration = bloc.registration
                                    .copyWith(ownerEmail: value);
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: "Mobile Number (optional)",
                              inputType: TextInputType.phone,
                              enabled: !isLoading,
                              value: bloc.registration.ownerPhoneNo,
                              onChange: (value) {
                                bloc.registration = bloc.registration
                                    .copyWith(ownerPhoneNo: value.trim());
                              },
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            CustomTextField(
                              label: "Password",
                              inputType: TextInputType.visiblePassword,
                              obscureText: !bloc.isPassVisible,
                              enabled: !isLoading,
                              error: formState?.formError?.ownerPassword,
                              value: bloc.registration.ownerPassword,
                              trailing: InkWell(
                                  onTap: () {
                                    bloc.add(PassVisibilityToggled(
                                        isVisible: bloc.isPassVisible));
                                  },
                                  child: bloc.isPassVisible
                                      ? Icon(
                                          Icons.visibility_off_rounded,
                                          color: ColorPalette.primaryColorDark,
                                        )
                                      : Icon(
                                          Icons.visibility_rounded,
                                          color: ColorPalette.primaryColorDark,
                                        )),
                              onChange: (value) {
                                bloc.add(
                                  ValidationReset(
                                    errorModel: formState?.formError?.copyWith(
                                      ownerPassword: null,
                                    ),
                                  ),
                                );
                                bloc.registration = bloc.registration
                                    .copyWith(ownerPassword: value);
                              },
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            CustomTextField(
                              label: "Confirm Password",
                              inputType: TextInputType.visiblePassword,
                              obscureText: !bloc.isConfirmPassVisible,
                              enabled: !isLoading,
                              error: formState?.formError?.ownerConfirmPassword,
                              value: bloc.registration.ownerConfirmPassword,
                              trailing: InkWell(
                                  onTap: () {
                                    bloc.add(ConfirmPassVisibilityToggled(
                                        isVisible: bloc.isConfirmPassVisible));
                                  },
                                  child: bloc.isConfirmPassVisible
                                      ? Icon(
                                          Icons.visibility_off_rounded,
                                          color: ColorPalette.primaryColorDark,
                                        )
                                      : Icon(
                                          Icons.visibility_rounded,
                                          color: ColorPalette.primaryColorDark,
                                        )),
                              onChange: (value) {
                                bloc.add(
                                  ValidationReset(
                                    errorModel: formState?.formError?.copyWith(
                                      ownerConfirmPassword: null,
                                    ),
                                  ),
                                );
                                bloc.registration = bloc.registration
                                    .copyWith(ownerConfirmPassword: value);
                              },
                            ),
                            const SizedBox(
                              height: 25,
                            ),
                            PrimaryButton(
                              width: 250,
                              text: "Signup",
                              onClick: isLoading
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();
                                      bloc.add(
                                        SubmitRegistrationForm(
                                          registration: bloc.registration,
                                          step: 1,
                                        ),
                                      );
                                    },
                            ),
                            const SizedBox(height: 20),

                            // Social sign-up. The sign-in screen has offered
                            // Google and Facebook since it was written and this
                            // screen never did, so a customer who signs up
                            // socially had to first tap "Sign in" — on a screen
                            // titled Create your Account. Same widget, same
                            // events; social auth upserts the account, so
                            // signing up and signing in are one action.
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: SocialAuthButtons(
                                isLoading: isLoading,
                                verb: 'Sign up',
                              ),
                            ),

                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () => context
                                  .goNamed(AuthenticationScreen.routeName),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 4),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(
                                      fontFamily: FontPalette.primaryFontFamily,
                                      color: ColorPalette.secondaryText,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign in',
                                        style: TextStyle(
                                          fontFamily:
                                              FontPalette.primaryFontFamily,
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
                            const SizedBox(height: 8),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
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
                                      recognizer: _termsRecognizer,
                                    ),
                                    const TextSpan(text: " and "),
                                    TextSpan(
                                      text: "Privacy Policy.",
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
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
