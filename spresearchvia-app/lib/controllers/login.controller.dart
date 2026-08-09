import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth.controller.dart';

import '../core/constants/app_strings.dart';
import '../services/snackbar.service.dart';
import '../services/secure_storage.service.dart';


class LoginController extends GetxController {
  final authController = Get.find<AuthController>();
  final phoneOrMailController = TextEditingController();
  final mpinController = TextEditingController();
  final isLoading = false.obs;
  final _storage = SecureStorageService();

  @override
  void onInit() {
    super.onInit();
    authController.resetOtpState();

    Future.microtask(_prefillFromStorage);
  }

  Future<void> _prefillFromStorage() async {
    try {
      final userData = await _storage.getUserData();
      if (userData != null) {
        final userObject = userData['userObject'] as Map<String, dynamic>?;
        
        final String? phone = (userData['phone'] ?? userObject?['APP_MOB_NO'])?.toString();


        if (isClosed) return;

        if (phone != null && phone.isNotEmpty) {
          final normalized = (phone.startsWith('+91') && phone.length == 13)
              ? phone.substring(3)
              : (phone.startsWith('91') && phone.length == 12)
                  ? phone.substring(2)
                  : phone;
          phoneOrMailController.text = normalized;
        }

        mpinController.clear();
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    phoneOrMailController.dispose();
    mpinController.dispose();
    super.onClose();
  }

  Future<void> handleLogin() async {
    final String input = phoneOrMailController.text.trim();
    final String mpin = mpinController.text.trim();

    if (input.isEmpty || mpin.isEmpty) {
      SnackbarService.showError(AppStrings.pleaseEnterCredentials);
      return;
    }

    if (mpin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(mpin)) {
      SnackbarService.showError('MPIN must be exactly 4 digits');
      return;
    }

    final bool isPhone = RegExp(r'^\d{10}$').hasMatch(input);

    if (!isPhone) {
      SnackbarService.showError(AppStrings.invalidPhoneAndEmail);
      return;
    }

    final String processedInput = input;

    isLoading.value = true;

    try {
      final success = await authController.login(
        phone: processedInput,
        mPin: mpin,
      );

      if (success) {
        await _storage.clearSubscriptionCache();
        // Update content plan status for later use - helpful for background sync
        await authController.hasActiveSubscription(forceRefresh: true);
        
        // Navigation is already handled by AuthController.login based on backend response
      }
    } catch (e) {
      SnackbarService.showError('Login failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
