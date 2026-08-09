import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/routes.config.dart';
import 'auth.controller.dart';

class ResetPasswordController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    final success = await _authController.resetPassword(
      newPasswordController.text,
    );

    isLoading.value = false;

    if (success) {
      Get.snackbar(
        'Success',
        'Password reset successful',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.snackbar(
        'Error',
        'Failed to reset password',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
