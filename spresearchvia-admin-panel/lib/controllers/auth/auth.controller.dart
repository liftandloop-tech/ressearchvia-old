import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/auth.service.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/models/user.model.dart';
import 'package:spresearch_web/config/routes.config.dart';
import 'package:spresearch_web/config/theme.config.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StaffService _staffService = Get.put(StaffService());

  var user = Rxn<UserModel>();
  var isAuthenticated = false.obs;
  var isInitialized = false.obs;
  var authToken = ''.obs;

  var isImpersonating = false.obs;
  var impersonatedStaffName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  @override
  void onClose() {
    print('AuthController DESTROYED!');
    super.onClose();
  }

  Future<void> checkAuth() async {
    try {
      final token = await _authService.getToken();
      final storedUser = await _authService.getUser();
      final hasBackup = await _authService.hasAdminBackup();

      if (token != null && token.isNotEmpty && storedUser != null) {
        authToken.value = token;
        user.value = storedUser;
        isAuthenticated.value = true;
        isImpersonating.value = hasBackup;
        if (hasBackup) {
          impersonatedStaffName.value = storedUser.fullName;
        }

        // Fresh profile sync: If staff member's role or permissions were updated by admin,
        // sync the latest profile from backend so the updated permissions take effect immediately.
        if (!storedUser.isAdmin && !hasBackup) {
          _staffService.getStaffProfileMe().then((freshStaff) async {
            if (freshStaff != null && freshStaff.rawJson != null) {
              final freshUser = UserModel.fromJson(freshStaff.rawJson!);
              user.value = freshUser;
              await _authService.saveUserData(freshStaff.rawJson!);
              debugPrint('Staff profile refreshed with role: ${freshUser.subscriptionPlan}');
            }
          }).catchError((e) {
            debugPrint('Failed to sync latest staff profile: $e');
          });
        }
      }
    } finally {
      isInitialized.value = true;
      print(
        'Auth Initialization Complete. Authenticated: ${isAuthenticated.value}, Impersonating: ${isImpersonating.value}',
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
        isImpersonating.value = false;

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

  Future<void> loginAsStaff(String staffId, String staffName) async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Save admin session backup first
      if (!isImpersonating.value) {
        final currentToken = authToken.value;
        final currentAdminData = user.value?.rawJson ?? {
          '_id': user.value?.id,
          'fullName': user.value?.fullName ?? 'Admin',
          'email': user.value?.email,
          'deparment': 'Admin',
          'userType': 'Admin',
        };
        await _authService.saveAdminBackup(currentToken, currentAdminData);
      }

      final res = await _staffService.impersonateStaff(staffId);

      // Close loading dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (res.token != null && res.staffData != null) {
        await _authService.setImpersonationSession(res.token!, res.staffData!);
        final staffUser = UserModel.fromJson(res.staffData!);

        user.value = staffUser;
        authToken.value = res.token!;
        isAuthenticated.value = true;
        isImpersonating.value = true;
        impersonatedStaffName.value = staffUser.fullName.isNotEmpty ? staffUser.fullName : staffName;

        Get.snackbar(
          'Impersonation Active',
          'Logged in as ${impersonatedStaffName.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFFF3CD),
          colorText: const Color(0xFF856404),
          duration: const Duration(seconds: 3),
        );

        if (staffUser.isResearcher) {
          Get.offAllNamed(AppRoutes.reports);
        } else {
          Get.offAllNamed(AppRoutes.dashboard);
        }
      } else {
        Get.snackbar(
          'Login As Failed',
          res.error ?? 'Could not switch to staff account',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.errorRed,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      Get.snackbar(
        'Error',
        'Impersonation error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
    }
  }

  Future<void> exitImpersonation() async {
    try {
      final restored = await _authService.restoreAdminBackup();
      if (restored != null && restored.user != null) {
        user.value = restored.user;
        authToken.value = restored.token ?? '';
        isAuthenticated.value = true;
        isImpersonating.value = false;
        impersonatedStaffName.value = '';

        Get.snackbar(
          'Returned to Admin',
          'You have exited staff view and returned to your Admin session.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryBlue,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        Get.offAllNamed(AppRoutes.staff);
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint('Error exiting impersonation: $e');
      await logout();
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
    if (isImpersonating.value) {
      await exitImpersonation();
      return;
    }

    await _authService.logout();
    user.value = null;
    isAuthenticated.value = false;
    isImpersonating.value = false;
    impersonatedStaffName.value = '';
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
    } else {
      print('Redirecting Staff to Dashboard...');
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }
}
