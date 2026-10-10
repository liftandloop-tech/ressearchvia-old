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
                      const SizedBox(height: 24),

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
