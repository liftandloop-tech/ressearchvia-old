import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_continue_init.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';

class ApplicantContinueInitScreen extends StatelessWidget {
  const ApplicantContinueInitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantContinueInitController());

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 450,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gray200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Obx(() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Continue Application',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered email or mobile number to complete or resume your application.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  // Identifier
                  TextField(
                    controller: controller.identifierController,
                    enabled: !controller.isOtpSent.value,
                    decoration: const InputDecoration(
                      labelText: 'Email or Mobile Number *',
                      border: OutlineInputBorder(),
                      hintText: 'Enter registered mobile or email',
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (controller.isOtpSent.value) ...[
                    const Divider(height: 32),
                    Text(
                      'Verification Code Sent (${controller.otpType.value.toUpperCase()})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A5F)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter OTP *',
                        border: OutlineInputBorder(),
                        hintText: 'Enter 6-digit verification code',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (controller.isLoading.value)
                    const Center(child: CircularProgressIndicator())
                  else
                    Button(
                      title: controller.isOtpSent.value ? 'Verify & Continue' : 'Send Verification OTP',
                      buttonType: ButtonType.blue,
                      onTap: () {
                        if (controller.isOtpSent.value) {
                          controller.verifyOtpAndContinue();
                        } else {
                          controller.sendOtp();
                        }
                      },
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
