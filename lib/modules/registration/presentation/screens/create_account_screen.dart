import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:overlay_tooltip/overlay_tooltip.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
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
  late TooltipController _toolTipController;
  String _firstName = '';
  String _lastName = '';
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    final bloc = BlocProvider.of<RegistrationBloc>(context);
    _toolTipController = TooltipController();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse('https://servana.com.ph/terms'));
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse('https://servana.com.ph/privacy'));

    final existing = (bloc.registration.ownerName ?? '').trim();
    if (existing.isNotEmpty) {
      final parts = existing.split(RegExp(r'\s+'));
      _firstName = parts.first;
      _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    if (!bloc.isToolTipShown) {
      bloc.isToolTipShown = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        _toolTipController.start();
      });
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
    _toolTipController.dispose();
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
                    "Create your Account",
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
              BlocConsumer<RegistrationBloc, RegistrationState>(
                listener: (context, state) async {
                  if (state is RegistrationLoadingState) {
                    context.loaderOverlay.show();
                    return;
                  }
                  context.loaderOverlay.hide();

                  if (state is RegistrationSubmittedState) {
                    await AwesomeDialog(
                            context: context,
                            dialogType: DialogType.success,
                            title: "Success",
                            headerAnimationLoop: false,
                            desc:
                                "Your account has been created successfully. Please sign in to continue.",
                            btnOkText: "Sign In")
                        .show();
                    // ignore: use_build_context_synchronously
                    context.goNamed(WelcomeScreen.routeName);
                  }
                  if (state is RegistrationSavedToCacheState) {
                    // ignore: use_build_context_synchronously
                    context.goNamed(WelcomeScreen.routeName);
                  }

                  if (state is RegistrationSubmittedFailedState) {
                    AwesomeDialog(
                            // ignore: use_build_context_synchronously
                            context: context,
                            dialogType: DialogType.error,
                            title: "Error",
                            headerAnimationLoop: false,
                            desc: state.error,
                            btnOkText: "Okay")
                        .show();
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
                            const SizedBox(
                              height: 20,
                            ),
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
