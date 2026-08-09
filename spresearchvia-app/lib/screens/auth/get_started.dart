import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app.config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/button.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueDark,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Icon(Icons.light, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'SP ResearchVia',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome to SP ResearchVia - Your Trusted Market Research Partner',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(child: Image.asset('assets/images/get_started.png')),
                const SizedBox(height: 20),
                const Text(
                  'Get Started',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Button(
                  title: 'Existing Customer - Login',
                  icon: Icons.login,
                  buttonType: ButtonType.blue,
                  onTap: () {
                    Get.toNamed(AppRoutes.login);
                  },
                ),
                const SizedBox(height: 10),
                Button(
                  title: 'New Customer - Sign Up',
                  icon: Icons.person_add,
                  buttonType: ButtonType.green,
                  onTap: () {
                    Get.toNamed(AppRoutes.createAccount);
                  },
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            if (await canLaunchUrl(AppConfig.policyURL)) {
                              await launchUrl(
                                AppConfig.policyURL,
                                mode: LaunchMode.inAppBrowserView,
                              );
                            }
                          },
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            if (await canLaunchUrl(AppConfig.policyURL)) {
                              await launchUrl(
                                AppConfig.policyURL,
                                mode: LaunchMode.inAppBrowserView,
                              );
                            }
                          },
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
