import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/button.dart';
import '../../widgets/title_field.dart';
import '../../controllers/forgot_mpin.controller.dart';

class ForgotMpinScreen extends StatelessWidget {
  const ForgotMpinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotMpinController());
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Get.back(),
        ),
      ),
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
                    'Forgot MPIN',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ).copyWith(color: AppTheme.primaryBlueDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your registered mobile number to reset your MPIN.',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ).copyWith(color: AppTheme.textGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TitleField(
                    title: 'Mobile Number',
                    hint: 'Enter Mobile Number',
                    controller: controller.phoneController,
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
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
          child: Obx(
            () => Button(
              title: controller.isLoading.value ? 'Sending OTP...' : 'Send OTP',
              buttonType: ButtonType.blue,
              onTap: controller.isLoading.value ? null : controller.handleContinue,
              showLoading: controller.isLoading.value,
            ),
          ),
        ),
      ),
    );
  }
}
