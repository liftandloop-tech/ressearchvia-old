import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth.controller.dart';
import '../core/routes/app_routes.dart';
import '../services/snackbar.service.dart';
import '../core/utils/validators.dart';

class CreateAccountController extends GetxController {
  final authController = Get.find<AuthController>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }

  Future<void> handleContinue(BuildContext context) async {
    final name = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    final nameError = Validators.validateName(name, fieldName: 'Full name');
    if (nameError != null) {
      SnackbarService.showError(nameError, context: context);
      return;
    }

    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) {
      SnackbarService.showError(phoneError, context: context);
      return;
    }

    if (email.isNotEmpty) {
      final emailError = Validators.validateEmail(email);
      if (emailError != null) {
        SnackbarService.showError(emailError, context: context);
        return;
      }
    }

    isLoading.value = true;

    try {
      final success = await authController.createUser(
        fullName: name,
        phone: phone,
        email: email,
      );

      if (success) {
        Get.toNamed(
          AppRoutes.otpVerification,
          arguments: {
            'phone': phone,
            'fullName': name,
            'email': email,
            'flow': 'signup',
          },
        );
      }
    } catch (e) {
      SnackbarService.showError('An error occurred. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
