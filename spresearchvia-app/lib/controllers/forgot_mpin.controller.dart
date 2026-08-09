import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth.controller.dart';
import '../core/routes/app_routes.dart';
import '../services/snackbar.service.dart';

class ForgotMpinController extends GetxController {
  final authController = Get.find<AuthController>();
  final phoneController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone);
  }

  Future<void> handleContinue() async {
    final phone = phoneController.text.trim();

    if (!_isValidPhone(phone)) {
      SnackbarService.showError('Enter a valid 10-digit mobile number');
      return;
    }

    isLoading.value = true;

    final success = await authController.sendOtp(phone);

    isLoading.value = false;

    if (success) {
      Get.toNamed(
        AppRoutes.otpVerification,
        arguments: {'phone': phone, 'flow': 'forgot_mpin'},
      );
    }
  }
}
