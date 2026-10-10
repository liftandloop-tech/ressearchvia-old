import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/config/routes.config.dart';
import 'package:spresearch_web/controllers/auth/login.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import '../../widgets/custom_text_field.widget.dart';
import '../../widgets/login_password_field.widget.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  static const double cardWidth = 420;

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isAuthenticated.value && auth.user.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          auth.navigateToAuthorizedRoute();
        });
        return Scaffold(
          backgroundColor: AppTheme.loginBackground,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    }

    if (Get.isRegistered<LoginController>()) {
      Get.delete<LoginController>();
    }
    final controller = Get.put(LoginController());

    return SelectionArea(
      child: Scaffold(
        backgroundColor: AppTheme.loginBackground,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  if (!controller.isLoading.value) {
                    if (controller.isAdminTab.value) {
                      controller.adminLogin();
                    } else {
                      controller.staffLogin();
                    }
                  }
                },
                const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
                  if (!controller.isLoading.value) {
                    if (controller.isAdminTab.value) {
                      controller.adminLogin();
                    } else {
                      controller.staffLogin();
                    }
                  }
                },
              },
              child: Focus(
                autofocus: false,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: cardWidth),
                  width: double.infinity,
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
                      ? _buildAdminLogin(context, controller)
                      : _buildStaffLogin(context, controller),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => Get.toNamed('/apply'),
                      child: Text(
                        'Apply for Staff Roles',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    InkWell(
                      onTap: () => Get.toNamed('/continue-application'),
                      child: Text(
                        'Continue Application',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
    ),
  ),
),
);
}

  Widget _buildAdminLogin(BuildContext context, LoginController controller) {
    return AutofillGroup(
      child: Column(
        children: [
          Form(
            key: controller.adminFormKey,
            child: Column(
              children: [
                CustomTextField(
                  label: AppStrings.emailAddress,
                  hint: AppStrings.enterEmail,
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email, AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    if (controller.passwordController.text.trim().isEmpty) {
                      FocusScope.of(context).nextFocus();
                    } else if (!controller.isLoading.value) {
                      controller.adminLogin();
                    }
                  },
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
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!controller.isLoading.value) {
                      controller.adminLogin();
                    }
                  },
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
    ),
  );
  }

  Widget _buildStaffLogin(BuildContext context, LoginController controller) {
    return AutofillGroup(
      child: Column(
        children: [
          // Mode Switcher: Mobile + MPIN vs Email + Password
          Obx(
            () => Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => controller.toggleStaffMode(false),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !controller.isStaffPasswordMode.value ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: !controller.isStaffPasswordMode.value
                              ? [const BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Text(
                          'Mobile & MPIN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: !controller.isStaffPasswordMode.value ? FontWeight.w600 : FontWeight.w500,
                            color: !controller.isStaffPasswordMode.value ? AppTheme.primaryBlue : const Color(0xFF64748B),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => controller.toggleStaffMode(true),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: controller.isStaffPasswordMode.value ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: controller.isStaffPasswordMode.value
                              ? [const BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Text(
                          'Email & Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: controller.isStaffPasswordMode.value ? FontWeight.w600 : FontWeight.w500,
                            color: controller.isStaffPasswordMode.value ? AppTheme.primaryBlue : const Color(0xFF64748B),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Form(
            key: controller.staffFormKey,
            child: Obx(() {
              if (controller.isStaffPasswordMode.value) {
                return Column(
                  children: [
                    CustomTextField(
                      label: 'Staff Email',
                      hint: 'Enter your staff email',
                      controller: controller.staffEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email, AutofillHints.username],
                      textInputAction: TextInputAction.next,
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
                      controller: controller.staffPasswordController,
                      obscurePassword: controller.obscureStaffPassword,
                      onToggleVisibility: controller.toggleStaffPasswordVisibility,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!controller.isLoading.value) {
                          controller.staffLogin();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  CustomTextField(
                    label: 'Mobile No',
                    hint: 'Enter your mobile',
                    controller: controller.mobileController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      if (controller.mpinController.text.trim().isEmpty) {
                        FocusScope.of(context).nextFocus();
                      } else if (!controller.isLoading.value) {
                        controller.staffLogin();
                      }
                    },
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
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!controller.isLoading.value) {
                        controller.staffLogin();
                      }
                    },
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
              );
            }),
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
    ),
  );
  }
}
