import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/config/routes.config.dart';
import 'package:spresearch_web/controllers/auth/login.controller.dart';
import '../../widgets/custom_text_field.widget.dart';
import '../../widgets/login_password_field.widget.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  static const double cardWidth = 420;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return SelectionArea(
      child: Scaffold(
        backgroundColor: AppTheme.loginBackground,
        body: Center(
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/sp_logo.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'SPRESEARCHVIA PVT. LTD.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Tab Bar
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.switchToAdminTab(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: controller.isAdminTab.value
                                      ? AppTheme.primaryBlue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Admin Login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: controller.isAdminTab.value
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: controller.isAdminTab.value
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.switchToStaffTab(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !controller.isAdminTab.value
                                      ? AppTheme.primaryBlue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Staff Login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: !controller.isAdminTab.value
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: !controller.isAdminTab.value
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Tab Content
                Obx(
                  () => controller.isAdminTab.value
                      ? _buildAdminLogin(controller)
                      : _buildStaffLogin(controller),
                ),

                const SizedBox(height: 24),
                Text(
                  AppStrings.copyrightText,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLogin(LoginController controller) {
    return Column(
      children: [
        Form(
          key: controller.adminFormKey,
          child: Column(
            children: [
              CustomTextField(
                label: AppStrings.emailAddress,
                hint: AppStrings.enterEmail,
                controller: controller.emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              LoginPasswordField(
                controller: controller.passwordController,
                obscurePassword: controller.obscurePassword,
                onToggleVisibility: controller.togglePasswordVisibility,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
              () => Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: controller.rememberMe.value,
                      onChanged: (value) => controller.toggleRememberMe(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.rememberMe,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.forgotPassword),
              child: Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.adminLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.login,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppTheme.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffLogin(LoginController controller) {
    return Column(
      children: [
        Form(
          key: controller.staffFormKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Mobile No',
                hint: 'Enter your mobile',
                controller: controller.mobileController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  if (value.length != 10) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'MPIN',
                hint: 'Enter MPIN',
                controller: controller.mpinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter MPIN';
                  }
                  if (value.length < 4) {
                    return 'MPIN must be at least 4 digits';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
              () => Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: controller.rememberMe.value,
                      onChanged: (value) => controller.toggleRememberMe(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.rememberMe,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.staffLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppTheme.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
