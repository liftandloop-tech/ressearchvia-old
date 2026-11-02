import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/applicant.service.dart';

class ApplicantContinueInitController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Forgot password / Set password flow
  final isForgotPasswordMode = false.obs;
  final resetStep = 1.obs; // 1: Email input, 2: OTP & New Password input
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var isSendingOtp = false.obs;
  var isResetting = false.obs;
  var obscurePassword = true.obs;
  var obscureNewPassword = true.obs;
  var obscureConfirmPassword = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void openForgotPassword() {
    isForgotPasswordMode.value = true;
    resetStep.value = 1;
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  void cancelForgotPassword() {
    isForgotPasswordMode.value = false;
    resetStep.value = 1;
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  Future<void> sendForgotOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar('Valid Email Required', 'Please enter your registered email address to receive OTP',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    isSendingOtp.value = true;
    try {
      final res = await _applicantService.sendForgotPasswordOtp(email);
      if (res.success) {
        resetStep.value = 2;
        Get.snackbar(
          'Verification Code Sent',
          res.message ?? 'An OTP has been dispatched to your email address.',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green.shade900,
        );
      } else {
        Get.snackbar('Request Failed', res.message ?? 'Could not find application with this email.',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> submitResetPassword() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;

    if (otp.isEmpty) {
      Get.snackbar('OTP Required', 'Please enter the 4-digit code sent to your email',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (newPass.isEmpty || newPass.length < 6) {
      Get.snackbar('Invalid Password', 'New password must be at least 6 characters long',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (newPass != confirmPass) {
      Get.snackbar('Password Mismatch', 'New password and confirmation do not match',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    isResetting.value = true;
    try {
      final res = await _applicantService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPass,
      );

      if (res.success && res.applicant != null) {
        final applicantData = res.applicant!;
        final step = res.currentStep;

        Get.offAllNamed('/apply', arguments: {
          'applicant': applicantData,
          'token': res.token,
          'step': step,
        });

        Get.snackbar(
          'Password Set Successfully',
          'Your password has been updated and your application is restored.',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green.shade900,
        );
      } else {
        Get.snackbar('Verification Failed', res.message ?? 'Invalid or expired OTP code',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isResetting.value = false;
    }
  }

  Future<void> loginAndContinue() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please enter your registered Email Address',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (!email.contains('@')) {
      Get.snackbar('Invalid Input', 'Please enter a valid Email Address',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (password.isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please enter your Password',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.continueLogin(email, password);
      if (res.success && res.applicant != null) {
        final applicantData = res.applicant!;
        final step = res.currentStep;

        Get.offAllNamed('/apply', arguments: {
          'applicant': applicantData,
          'token': res.token,
          'step': step,
        });

        Get.snackbar('Welcome Back', 'Application draft restored successfully.',
            backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green.shade900);
      } else {
        final msg = res.message ?? 'Invalid email or password';
        Get.snackbar('Login Failed', msg,
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
        // If password is not set (previous applicant), automatically prompt to set password!
        if (msg.toLowerCase().contains('password not set')) {
          openForgotPassword();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
