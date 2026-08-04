import 'package:client/common/constants/servana_urls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';

class AccountPendingForApprovalScreen extends StatefulWidget {
  static String routeName = "AccountPendingForApproval";
  static String route = "/AccountPendingForApproval";

  const AccountPendingForApprovalScreen({super.key});

  @override
  State<AccountPendingForApprovalScreen> createState() =>
      _AccountPendingForApprovalScreenState();
}

class _AccountPendingForApprovalScreenState
    extends State<AccountPendingForApprovalScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    context.goNamed(WelcomeScreen.routeName);
                  },
                  icon: Icon(
                    Icons.logout,
                    size: 25,
                    color: ColorPalette.primaryColorDark,
                  ),
                  label: Text(
                    "Logout",
                    maxLines: 4,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      decoration: TextDecoration.underline,
                      color: ColorPalette.primaryColorDark,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(),
            ),
            Container(
              width: 200,
              margin: const EdgeInsets.all(20),
              child: Image.asset(
                "assets/images/pending.png",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Verifying your Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "We are currently processing you business credentials. This process will take 3-7 business days. You will may receive an sms or a call during the verification process.",
                maxLines: 4,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: ColorPalette.secondaryText,
                  fontSize: 15,
                ),
              ),
            ),
            Expanded(
              child: Container(),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Text.rich(
                TextSpan(
                  text: "By giving your information, you agree to our ",
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
    );
  }
}
