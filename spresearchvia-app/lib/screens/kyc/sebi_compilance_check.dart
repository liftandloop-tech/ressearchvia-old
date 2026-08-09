import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/app_webview.dart';
import '../../widgets/button.dart';
import 'digio_connect_screen.dart';
import 'kyc_fallback_form_screen.dart';
import '../../controllers/user.controller.dart';
import 'kyc_intro.dart';
import '../../controllers/auth.controller.dart';

class SebiComplianceCheck extends StatelessWidget {
  const SebiComplianceCheck({super.key});

  @override
  Widget build(BuildContext context) {
    void continueToNext() {
      // Refresh auth status to get the next step (Dashboard or Registration)
      Get.find<AuthController>().checkAuthStatus();
    }

    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xff111827),
            size: 18,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'SEBI Verification',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xffEAF9EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Color(0xff10B981),
                      size: 35,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'KYC Submitted Successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Color(0xff11416B),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Your KYC has been submitted successfully.\n\nOur team will verify your details and get back to you soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xff6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffECFDF3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xff10B981),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'SEBI Compliant Account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xff065F46),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const FeatureCard(
                icon: Icons.show_chart,
                title: 'Real-time Trading',
                subtitle:
                    'Access live market data and execute trades\ninstantly',
              ),
              const SizedBox(height: 12),
              const FeatureCard(
                icon: Icons.analytics_outlined,
                title: 'Research Backed Analysis',
                subtitle: 'Expert insights for informed decision making',
              ),
              const SizedBox(height: 12),
              const FeatureCard(
                icon: Icons.school_outlined,
                title: 'Learning Resources',
                subtitle: 'Educational content to improve your trading skills',
              ),

            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                title: 'Continue',
                onTap: continueToNext,
                buttonType: ButtonType.green,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xff6B7280),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'By continuing, you agree to our ',
                      ),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: AppTheme.primaryBlue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(() => const AppWebView(
                                  url:
                                      'https://researchvia.in/terms-and-conditions',
                                  title: 'Terms of Service',
                                ));
                          },
                      ),
                      const TextSpan(
                        text: ', ',
                      ),
                      TextSpan(
                        text: 'Refund Policy',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: AppTheme.primaryBlue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(() => const AppWebView(
                                  url: 'https://researchvia.in/refund-policy/',
                                  title: 'Refund Policy',
                                ));
                          },
                      ),
                      const TextSpan(
                        text: ' and ',
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: AppTheme.primaryBlue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(() => const AppWebView(
                                  url: 'https://researchvia.in/privacy-policy/',
                                  title: 'Privacy Policy',
                                ));
                          },
                      ),
                    ],
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

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 243, 248, 255),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xffEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xff0B3A70)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xff0B3A70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xff6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
