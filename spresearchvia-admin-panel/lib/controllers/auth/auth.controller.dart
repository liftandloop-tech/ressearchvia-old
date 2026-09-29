import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/auth.service.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/models/user.model.dart';
import 'package:spresearch_web/config/routes.config.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/services/api.service.dart';
import 'package:spresearch_web/services/inactivity.service.dart';
import '../users/user_management.controller.dart';
import '../users/user.controller.dart';
import '../dashboard/dashboard_management.controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StaffService _staffService = Get.put(StaffService());

  var user = Rxn<UserModel>();
  UserModel? get currentUser => user.value;
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
        // Check if session has expired from storage due to > 1 hour of inactivity
        if (Get.isRegistered<InactivityService>()) {
          final isExpired = await InactivityService.to.isSessionExpiredFromStorage();
          if (isExpired) {
            debugPrint('[AuthController] Session expired on app launch due to > 1 hr inactivity. Clearing auth.');
            await _authService.logout();
            await InactivityService.to.clearActivityRecord();
            user.value = null;
            authToken.value = '';
            isAuthenticated.value = false;
            isImpersonating.value = false;
            impersonatedStaffName.value = '';
            _clearSessionStateAndCache();
            Get.snackbar(
              'Session Expired',
              'You have been logged out due to 1 hour of inactivity.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppTheme.errorRed,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            return;
          }
        }

        authToken.value = token;
        user.value = storedUser;
        isAuthenticated.value = true;
        isImpersonating.value = hasBackup;
        if (hasBackup) {
          impersonatedStaffName.value = storedUser.fullName;
        }

        if (Get.isRegistered<InactivityService>()) {
          InactivityService.to.resetTimer();
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

        // Auto-redirect authenticated user away from login screen if restoring session
        final currentRoute = Get.currentRoute;
        final isPublic = AppRoutes.isPublicRoute(currentRoute);
        if (!isPublic && (currentRoute == AppRoutes.login || currentRoute == '/' || currentRoute.isEmpty)) {
          debugPrint('[AuthController] Authenticated session restored on login route ($currentRoute). Navigating to initial route.');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToInitialRoute(storedUser);
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

  void navigateToAuthorizedRoute() {
    final currentUser = user.value;
    if (currentUser != null) {
      _navigateToInitialRoute(currentUser);
    } else {
      Get.offAllNamed(AppRoutes.login);
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

        _clearSessionStateAndCache();
        if (Get.isRegistered<InactivityService>()) {
          InactivityService.to.resetTimer();
        }
        _navigateToInitialRoute(result.user!);

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

        _clearSessionStateAndCache();
        if (Get.isRegistered<InactivityService>()) {
          InactivityService.to.resetTimer();
        }
        _navigateToInitialRoute(staffUser);
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

        _clearSessionStateAndCache();

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

    if (Get.isRegistered<InactivityService>()) {
      await InactivityService.to.clearActivityRecord();
    }

    await _authService.logout();
    user.value = null;
    authToken.value = '';
    isAuthenticated.value = false;
    isImpersonating.value = false;
    impersonatedStaffName.value = '';
    _clearSessionStateAndCache();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> handleInactivityLogout() async {
    if (!isAuthenticated.value) return;

    debugPrint('[AuthController] Executing inactivity auto-logout (1 hour timeout)...');
    if (isImpersonating.value) {
      await _authService.clearAdminBackup();
    }

    if (Get.isRegistered<InactivityService>()) {
      await InactivityService.to.clearActivityRecord();
    }

    await _authService.logout();
    user.value = null;
    authToken.value = '';
    isAuthenticated.value = false;
    isImpersonating.value = false;
    impersonatedStaffName.value = '';
    _clearSessionStateAndCache();

    Get.snackbar(
      'Session Expired',
      'You have been automatically logged out due to 1 hour of inactivity.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.errorRed,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );

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

    _clearSessionStateAndCache();
    if (Get.isRegistered<InactivityService>()) {
      InactivityService.to.resetTimer();
    }
    _navigateToInitialRoute(staffUser);
  }

  void _clearSessionStateAndCache() {
    ApiService.clearAllCache();
    if (Get.isRegistered<UserController>()) {
      Get.delete<UserController>();
    }
    if (Get.isRegistered<UserManagementController>()) {
      final umc = Get.find<UserManagementController>();
      umc.resetState();
      umc.fetchUsers(page: 1);
      umc.fetchManagers();
    }
    if (Get.isRegistered<DashboardManagementController>()) {
      final dmc = Get.find<DashboardManagementController>();
      dmc.renewalsList.clear();
      dmc.fetchDashboardData(force: true);
    }
  }

  void _navigateToInitialRoute(UserModel user) {
    if (user.isAdmin || user.canAccessDepartmentPage('Dashboard')) {
      Get.offAllNamed(AppRoutes.dashboard);
      return;
    }
    if (user.canAccessDepartmentPage('Reports')) {
      Get.offAllNamed(AppRoutes.reports);
      return;
    }
    if (user.canAccessDepartmentPage('Users')) {
      Get.offAllNamed(AppRoutes.users);
      return;
    }
    if (user.canAccessDepartmentPage('KYC')) {
      Get.offAllNamed(AppRoutes.kyc);
      return;
    }
    if (user.canAccessDepartmentPage('Payments')) {
      Get.offAllNamed(AppRoutes.pendingPayments);
      return;
    }
    if (user.canAccessDepartmentPage('Leads')) {
      Get.offAllNamed(AppRoutes.leads);
      return;
    }
    if (user.canAccessDepartmentPage('Staff')) {
      Get.offAllNamed(AppRoutes.staff);
      return;
    }
    if (user.canAccessDepartmentPage('Subscriptions')) {
      Get.offAllNamed(AppRoutes.subscriptions);
      return;
    }
    if (user.canAccessDepartmentPage('Notifications')) {
      Get.offAllNamed(AppRoutes.notifications);
      return;
    }
    if (user.canAccessDepartmentPage('Settings')) {
      Get.offAllNamed(AppRoutes.settings);
      return;
    }
    if (user.canAccessDepartmentPage('Attendance')) {
      Get.offAllNamed(AppRoutes.attendance);
      return;
    }
    Get.offAllNamed(AppRoutes.profile);
  }
}
