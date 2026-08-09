import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for Colors
import 'package:get/get.dart';
import 'package:spresearch_web/services/auth.service.dart';
import 'package:spresearch_web/models/user.model.dart';
import 'package:spresearch_web/config/routes.config.dart';
import 'package:spresearch_web/config/theme.config.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  var user = Rxn<UserModel>();
  var isAuthenticated = false.obs;
  var isInitialized = false.obs;
  var authToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  @override
  void onClose() {
    print('AuthController DESTROYED!');
    super.onClose();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await _authService.getToken();
      final storedUser = await _authService.getUser();

      if (token != null && token.isNotEmpty && storedUser != null) {
        authToken.value = token;
        user.value = storedUser;
        isAuthenticated.value = true;
      }
    } finally {
      isInitialized.value = true;
      print(
        'Auth Initialization Complete. Authenticated: ${isAuthenticated.value}',
      );
    }
  }

  Future<({bool success, String? error})> login(
    String email,
    String password,
  ) async {
    try {
      final result = await _authService.login(email, password);

      if (result.user != null && result.token != null) {
        user.value = result.user;
        authToken.value = result.token!;
        isAuthenticated.value = true;

        if (result.user?.isResearcher == true) {
          Get.offAllNamed(AppRoutes.reports);
        } else {
          Get.offAllNamed(AppRoutes.dashboard);
        }

        return (success: true, error: null);
      } else {
        return (success: false, error: result.error ?? 'Login failed');
      }
    } catch (e) {
      return (success: false, error: 'An error occurred: $e');
    }
  }

  Future<String?> getToken() {
    return _authService.getToken();
  }

  Future<bool> forgotPassword(String email) async {
    try {
      return await _authService.forgotPassword(email);
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    try {
      return await _authService.resetPassword(newPassword);
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user.value = null;
    isAuthenticated.value = false;
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> staffLoginSuccess(UserModel staffUser, String token) async {
    final role = staffUser.subscriptionPlan.toLowerCase();
    print('Staff Login Success: ${staffUser.fullName} ($role)');

    if (role == 'manager') {
      print(
        'Access Denied: Managers are not allowed to log in to the admin panel.',
      );
      Get.snackbar(
        'Access Denied',
        'Managers are not allowed to access the admin panel.',
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
      // Log out to clear any saved credentials from AuthService
      await logout();
      return;
    }

    user.value = staffUser;
    authToken.value = token;
    isAuthenticated.value = true;

    if (staffUser.isResearcher) {
      print('Redirecting Researcher to Reports...');
      Get.offAllNamed(AppRoutes.reports);
    } else if (staffUser.isDirector) {
      print('Redirecting Director to Users...');
      Get.offAllNamed(AppRoutes.users);
    } else {
      print('Redirecting Staff to Dashboard...');
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }
}
