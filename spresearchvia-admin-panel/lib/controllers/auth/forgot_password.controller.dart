import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/routes.config.dart';
import 'auth.controller.dart';

class ForgotPasswordController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final isLoading = false.obs;

  Future<void> sendResetLink() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    final success = await _authController.forgotPassword(emailController.text);

    isLoading.value = false;

    if (success) {
      Get.snackbar(
        'Success',
        'Reset link sent to ${emailController.text}',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.toNamed(AppRoutes.resetPassword);
    } else {
      Get.snackbar(
        'Error',
        'Failed to send reset link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
