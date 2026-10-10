import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/auth.service.dart';
import 'auth.controller.dart';

class LoginController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();

  // Form keys
  final adminFormKey = GlobalKey<FormState>();
  final staffFormKey = GlobalKey<FormState>();

  // Admin login controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Staff login controllers
  final mobileController = TextEditingController();
  final mpinController = TextEditingController();
  final staffEmailController = TextEditingController();
  final staffPasswordController = TextEditingController();

  // Observable states
  var isAdminTab = true.obs;
  var isStaffPasswordMode = false.obs;
  var rememberMe = false.obs;
  var obscurePassword = true.obs;
  var obscureStaffPassword = true.obs;
  var isLoading = false.obs;

  void switchToAdminTab() {
    isAdminTab.value = true;
    _resetStaffForm();
  }

  void switchToStaffTab() {
    isAdminTab.value = false;
    _resetAdminForm();
  }

  void toggleStaffMode(bool usePassword) {
    isStaffPasswordMode.value = usePassword;
    staffFormKey.currentState?.reset();
  }

  void _resetAdminForm() {
    emailController.clear();
    passwordController.clear();
    adminFormKey.currentState?.reset();
  }

  void _resetStaffForm() {
    mobileController.clear();
    mpinController.clear();
    staffEmailController.clear();
    staffPasswordController.clear();
    staffFormKey.currentState?.reset();
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleStaffPasswordVisibility() {
    obscureStaffPassword.value = !obscureStaffPassword.value;
  }

  Future<void> adminLogin() async {
    if (!adminFormKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    final result = await _authController.login(
      emailController.text,
      passwordController.text,
    );

    isLoading.value = false;

    if (!result.success) {
      Get.snackbar(
        'Login Failed',
        result.error ?? 'Invalid email or password',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      TextInput.finishAutofillContext(shouldSave: true);
    }
  }

  Future<void> staffLogin() async {
    if (!staffFormKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    final result = isStaffPasswordMode.value
        ? await _authService.staffEmailPasswordLogin(
            staffEmailController.text,
            staffPasswordController.text,
          )
        : await _authService.staffMpinLogin(
            mobileController.text,
            mpinController.text,
          );

    isLoading.value = false;

    if (result.user != null && result.token != null) {
      TextInput.finishAutofillContext(shouldSave: true);
      await _authController.staffLoginSuccess(result.user!, result.token!);

      Get.snackbar(
        'Success',
        'Staff login successful!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Login Failed',
        result.error ?? (isStaffPasswordMode.value ? 'Invalid Email or Password' : 'Invalid Mobile or MPIN'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      if (!isStaffPasswordMode.value) {
        mpinController.clear();
      }
    }
  }

}
