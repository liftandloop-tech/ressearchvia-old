import 'package:spresearchvia/core/config/app.config.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';
import 'package:spresearchvia/widgets/app_logo.dart';
import 'package:spresearchvia/widgets/button.dart';
import 'package:spresearchvia/widgets/title_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../controllers/create_account.controller.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateAccountController());
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: double.maxFinite,
                    height: 60,
                    child: AppLogo(),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Create Your Account',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ).copyWith(color: AppTheme.primaryBlueDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your details to get started.',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ).copyWith(color: AppTheme.textGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowLight,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TitleField(
                            title: 'Full Name',
                            hint: 'Enter your full name',
                            controller: controller.fullNameController,
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                          ),
                          const SizedBox(height: 20),
                          TitleField(
                            title: 'Email Address',
                            hint: 'Enter your email address',
                            controller: controller.emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          TitleField(
                            title: 'Mobile Number',
                            hint: 'Enter your mobile number',
                            controller: controller.phoneController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textGrey,
                      ),
                      children: [
                        const TextSpan(
                          text: 'By continuing, you agree to our ',
                        ),
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => Button(
                  title: controller.isLoading.value
                      ? 'Sending OTP...'
                      : 'Continue',
                  buttonType: ButtonType.green,
                  onTap: controller.isLoading.value
                      ? null
                      : () => controller.handleContinue(context),
                  showLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 10),
              Button(
                title: AppStrings.back,
                buttonType: ButtonType.greyBorder,
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
