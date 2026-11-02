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
                constraints: const BoxConstraints(maxWidth: 450),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gray200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                  final isForgot = controller.isForgotPasswordMode.value;
                  final step = controller.resetStep.value;

                  if (isForgot) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: controller.cancelForgotPassword,
                              tooltip: 'Back to Login',
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step == 1 ? 'Reset or Set Password' : 'Enter OTP & New Password',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A5F),
                                ),
                              ),
                            ),
                            const SizedBox(width: 28), // balance back button
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step == 1
                              ? 'Enter your registered email address to receive an OTP code.'
                              : 'We sent a verification code to ${controller.emailController.text.trim()}. Enter it below to set your password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: isMobile ? 12 : 13),
                        ),
                        const SizedBox(height: 24),

                        if (step == 1) ...[
                          // Step 1: Email Address
                          TextField(
                            controller: controller.emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Registered Email Address *',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                              border: OutlineInputBorder(),
                              hintText: 'Enter your registered email',
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (controller.isSendingOtp.value)
                            const Center(child: CircularProgressIndicator())
                          else
                            Button(
                              title: 'Send Verification OTP',
                              buttonType: ButtonType.blue,
                              onTap: controller.sendForgotOtp,
                            ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: controller.cancelForgotPassword,
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Back to Login'),
                            ),
                          ),
                        ] else ...[
                          // Step 2: OTP and New Password
                          TextField(
                            controller: controller.otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, letterSpacing: 4, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              labelText: 'Email OTP Code *',
                              prefixIcon: Icon(Icons.pin_outlined, size: 20),
                              border: OutlineInputBorder(),
                              counterText: '',
                              hintText: 'Enter 4 or 6-digit OTP',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // New Password
                          Obx(
                            () => TextField(
                              controller: controller.newPasswordController,
                              obscureText: controller.obscureNewPassword.value,
                              decoration: InputDecoration(
                                labelText: 'New Password *',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                border: const OutlineInputBorder(),
                                hintText: 'Enter new password (min 6 characters)',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.obscureNewPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: controller.toggleNewPasswordVisibility,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          Obx(
                            () => TextField(
                              controller: controller.confirmPasswordController,
                              obscureText: controller.obscureConfirmPassword.value,
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password *',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                border: const OutlineInputBorder(),
                                hintText: 'Re-enter your new password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.obscureConfirmPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: controller.toggleConfirmPasswordVisibility,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (controller.isResetting.value)
                            const Center(child: CircularProgressIndicator())
                          else
                            Button(
                              title: 'Verify OTP & Set Password',
                              buttonType: ButtonType.blue,
                              onTap: controller.submitResetPassword,
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: controller.sendForgotOtp,
                                child: const Text('Resend OTP'),
                              ),
                              TextButton(
                                onPressed: controller.cancelForgotPassword,
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  }

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
                        'Enter your registered email and password to resume your job application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: isMobile ? 12 : 13),
                      ),
                      const SizedBox(height: 24),

                      // Email Address
                      TextField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(),
                          hintText: 'Enter your registered email',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      Obx(
                        () => TextField(
                          controller: controller.passwordController,
                          obscureText: controller.obscurePassword.value,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            border: const OutlineInputBorder(),
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Forgot Password / First time login link
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: controller.openForgotPassword,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Forgot Password? / First-time login?',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      if (controller.isLoading.value)
                        const Center(child: CircularProgressIndicator())
                      else
                        Button(
                          title: 'Login & Continue Application',
                          buttonType: ButtonType.blue,
                          onTap: controller.loginAndContinue,
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
                              'Create Application Account',
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
