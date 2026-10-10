import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/applicant.service.dart';

class ApplicantContinueInitController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var obscurePassword = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> loginAndContinue() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please enter your registered Email Address',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }

    if (!email.contains('@')) {
      Get.snackbar('Invalid Input', 'Please enter a valid Email Address',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }

    if (password.isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please enter your Password',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.continueLogin(email, password);
      if (res.success && res.applicant != null) {
        final applicantData = res.applicant!;
        final appId = applicantData['_id']?.toString() ?? applicantData['id']?.toString() ?? '';
        final step = res.currentStep;

        Get.offAllNamed('/apply', arguments: {
          'applicant': applicantData,
          'token': res.token,
          'step': step,
        });

        Get.snackbar('Welcome Back', 'Application draft restored successfully.',
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade900);
      } else {
        Get.snackbar('Login Failed', res.message ?? 'Invalid email or password',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
