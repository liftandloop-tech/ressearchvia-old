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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 500;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 24 : 48,
                horizontal: isMobile ? 12 : 16,
              ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: isMobile ? 24 : 32,
                ),
                child: Obx(() {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Continue Application',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your registered email or mobile number to complete or resume your application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: isMobile ? 12 : 13),
                      ),
                      const SizedBox(height: 24),

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
                      const SizedBox(height: 20),

                      if (controller.isOtpSent.value) ...[
                        const Divider(height: 28),
                        Text(
                          'Verification Code Sent (${controller.otpType.value.toUpperCase()})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E3A5F)),
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
                        const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'New applicant? ',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          InkWell(
                            onTap: () => Get.toNamed('/apply'),
                            child: const Text(
                              'Submit Walk-In Application',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}
