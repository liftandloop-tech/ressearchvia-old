import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/config/routes.config.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';

class MainDashboardController extends GetxController {
  var selectedTab = 0.obs;
  var expandedItem = ''.obs;

  @override
  void onInit() {
    super.onInit();

    final authController = Get.find<AuthController>();

    // Synchronize tab immediately
    syncTabWithRoute();

    // Perform initial check
    _checkRedirect();

    // Also listen for auth initialization or user changes
    everAll([authController.isInitialized, authController.user], (_) {
      _checkRedirect();
      syncTabWithRoute();
    });
  }

  void _checkRedirect() {
    String currentRoute = Get.currentRoute;
    if (kIsWeb) {
      try {
        final webPath = Uri.base.path;
        if (webPath.isNotEmpty && webPath != '/' && webPath != '/login') {
          currentRoute = webPath;
        }
      } catch (_) {}
    }
    if (currentRoute.contains('?')) {
      currentRoute = currentRoute.split('?').first;
    }

    // Public routes (/apply, /continue-application, /verify, etc.) are always allowed
    if (AppRoutes.isPublicRoute(currentRoute)) {
      return;
    }

    final authController = Get.find<AuthController>();
    final user = authController.user.value;

    if (!authController.isInitialized.value || user == null) return;

    print(
      'Controller Redirect Check. Route: $currentRoute, Auth: ${authController.isAuthenticated.value}, Role: ${user.subscriptionPlan}',
    );

    if (!authController.isAuthenticated.value) {
      if (currentRoute != AppRoutes.login && !AppRoutes.isPublicRoute(currentRoute)) {
        print('Not authenticated. Redirecting to login.');
        Future.microtask(() => Get.offAllNamed(AppRoutes.login));
      }
      return;
    }

    if (!user.isAdmin && user.isInactive) {
      print('Inactive user detected on route check. Logging out cleanly.');
      authController.logout();
      return;
    }

    if (currentRoute == AppRoutes.login || currentRoute == '/') {
      print('Authenticated user detected on login route. Redirecting to authorized route.');
      Future.microtask(() => authController.navigateToAuthorizedRoute());
      return;
    }

    if (user.needsJobAgreement) {
      if (currentRoute != AppRoutes.jobTermsAgreement) {
        print('Employee has not signed job terms agreement. Redirecting to agreement screen.');
        Future.microtask(() => Get.offAllNamed(AppRoutes.jobTermsAgreement));
        return;
      }
      return;
    }

    if (user.isAdmin) return;
    if (currentRoute == AppRoutes.dashboard) {
      if (!user.canAccessDepartmentPage('Dashboard')) {
        print('User department does not have access to Dashboard. Redirecting to authorized route.');
        Future.microtask(() => authController.navigateToAuthorizedRoute());
        return;
      }
      return;
    }
    if (currentRoute == AppRoutes.profile ||
        currentRoute.startsWith('/profile')) return;

    bool isAllowed = true;
    if (currentRoute.startsWith('/manage-user')) {
      isAllowed = user.canAccessDepartmentPage('Users') &&
          (user.has('subscriptions.view') ||
              user.has('subscriptions.activate') ||
              user.has('users.update') ||
              user.has('users.manage') ||
              user.hasPermission('Subscriptions', 'view') ||
              user.hasPermission('Subscriptions', 'activate') ||
              user.hasPermission('Users', 'update'));
    } else if (currentRoute.startsWith('/users') ||
        currentRoute.startsWith('/edit-user')) {
      isAllowed = user.canAccessDepartmentPage('Users') && user.hasPermission('Users', 'read');
    } else if (currentRoute.startsWith('/registered-clients') ||
        currentRoute.startsWith('/approvals/kyc') ||
        currentRoute.startsWith('/kyc')) {
      isAllowed = user.canAccessDepartmentPage('KYC') && user.hasPermission('KYC', 'read');
    } else if (currentRoute.startsWith('/approvals/payments')) {
      isAllowed = user.canAccessDepartmentPage('Payments') && user.hasPermission('Payments', 'read');
    } else if (currentRoute.startsWith('/staff') ||
        currentRoute.startsWith('/applicants') ||
        currentRoute.startsWith('/applicant/')) {
      isAllowed = user.canAccessDepartmentPage('Staff') && user.hasPermission('Staff', 'read');
    } else if (currentRoute.startsWith('/reports') ||
        currentRoute.startsWith('/upload-report')) {
      isAllowed = user.canAccessDepartmentPage('Reports') && user.hasPermission('Reports', 'read');
    } else if (currentRoute.startsWith('/notifications')) {
      isAllowed = user.canAccessDepartmentPage('Notifications') && user.hasPermission('Notifications', 'read');
    } else if (currentRoute.startsWith('/settings')) {
      isAllowed = user.canAccessDepartmentPage('Settings') && user.hasPermission('Settings', 'read');
    } else if (currentRoute.startsWith('/leads')) {
      isAllowed = user.isAdmin ||
          (user.canAccessDepartmentPage('Leads') &&
              (user.has('leads.view') ||
                  user.has('leads.view_all') ||
                  user.has('leads.view_assigned') ||
                  user.has('leads.pull') ||
                  user.hasPermission('Leads', 'read') ||
                  user.hasPermission('Leads', 'view')));
    } else if (currentRoute.startsWith('/automated-trading')) {
      isAllowed = user.isAdmin ||
          (user.canAccessDepartmentPage('AutomatedTrading') &&
              (user.has('automated_trading.view') || user.hasPermission('AutomatedTrading', 'read')));
    } else if (currentRoute.startsWith('/subscriptions')) {
      if (currentRoute.startsWith('/subscriptions/plans/create')) {
        isAllowed = user.isAdmin ||
            user.has('subscriptions.edit_correction') ||
            user.has('subscriptions.activate');
      } else {
        isAllowed = user.canAccessDepartmentPage('Subscriptions') && user.hasPermission('Subscriptions', 'read');
      }
    }

    if (!isAllowed) {
      print('Access restricted for $currentRoute. Redirecting to authorized route...');
      Future.microtask(() => authController.navigateToAuthorizedRoute());
    }
  }

  void syncTabWithRoute([String? route]) {
    String currentRoute = route ?? Get.currentRoute;
    if (kIsWeb) {
      try {
        final webPath = Uri.base.path;
        if (webPath.isNotEmpty && webPath != '/' && webPath != '/login') {
          currentRoute = webPath;
        }
      } catch (_) {}
    }
    if (currentRoute.contains('?')) {
      currentRoute = currentRoute.split('?').first;
    }
    if (currentRoute.endsWith('/') && currentRoute.length > 1) {
      currentRoute = currentRoute.substring(0, currentRoute.length - 1);
    }

    if (currentRoute == AppRoutes.registeredClients ||
        currentRoute == AppRoutes.userKyc ||
        currentRoute.startsWith('/registered-clients') ||
        currentRoute.startsWith('/approvals/kyc') ||
        currentRoute.startsWith('/kyc')) {
      selectedTab.value = 7;
      expandedItem.value = 'Clients';
    } else if (currentRoute == AppRoutes.pendingPayments ||
        currentRoute.startsWith('/approvals/payments') ||
        currentRoute.startsWith('/users/pending-transfers')) {
      selectedTab.value = 8;
      expandedItem.value = 'Clients';
    } else if (currentRoute.startsWith('/applicants') ||
        currentRoute.startsWith('/applicant/')) {
      selectedTab.value = 11;
    } else if (currentRoute.startsWith('/staff')) {
      selectedTab.value = 2;
    } else if (currentRoute.startsWith('/users') ||
        currentRoute.startsWith('/manage-user') ||
        currentRoute.startsWith('/edit-user')) {
      selectedTab.value = 1;
      expandedItem.value = 'Clients';
    } else if (currentRoute.startsWith('/subscriptions') ||
        currentRoute.startsWith('/manage-subscription')) {
      selectedTab.value = 3;
    } else if (currentRoute.startsWith('/reports') ||
        currentRoute.startsWith('/upload-report')) {
      selectedTab.value = 4;
    } else if (currentRoute.startsWith('/notifications')) {
      selectedTab.value = 5;
    } else if (currentRoute.startsWith('/settings')) {
      selectedTab.value = 6;
    } else if (currentRoute.startsWith('/automated-trading')) {
      selectedTab.value = 9;
    } else if (currentRoute.startsWith('/leads')) {
      selectedTab.value = 10;
    } else if (currentRoute.startsWith('/attendance')) {
      selectedTab.value = 12;
    } else if (currentRoute.startsWith('/dashboard')) {
      selectedTab.value = 0;
    } else {
      selectedTab.value = 0;
    }
  }

  void updateTab() => syncTabWithRoute();

  void changeTab(int index) {
    selectedTab.value = index;
    final currentUser = Get.find<AuthController>().user.value;
    switch (index) {
      case 0:
        Get.offNamed('/dashboard');
        break;
      case 1:
        if (Get.isRegistered<UsersNavigationController>()) {
          Get.find<UsersNavigationController>().navigationStack.clear();
        }
        Get.offNamed('/users');
        break;
      case 2:
        Get.offNamed('/staff');
        break;
      case 3:
        Get.offNamed('/subscriptions');
        break;
      case 4:
        Get.offNamed('/reports');
        break;
      case 5:
        Get.offNamed('/notifications');
        break;
      case 6:
        if (currentUser?.canAccessDepartmentPage('Settings') ?? false) {
          Get.offNamed('/settings');
        } else {
          Get.offNamed('/dashboard');
        }
        break;
      case 7:
        if (Get.isRegistered<UsersNavigationController>()) {
          Get.find<UsersNavigationController>().navigationStack.clear();
        }
        Get.offNamed(AppRoutes.registeredClients);
        break;
      case 8:
        Get.offNamed(AppRoutes.pendingPayments);
        break;
      case 9:
        Get.offNamed(AppRoutes.automatedTrading);
        break;
      case 10:
        Get.offNamed(AppRoutes.leads);
        break;
      case 11:
        Get.offNamed(AppRoutes.applicants);
        break;
      case 12:
        Get.offNamed(AppRoutes.attendance);
        break;
      default:
        Get.offNamed('/dashboard');
    }
  }
}
