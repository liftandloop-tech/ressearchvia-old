import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/config/routes.config.dart';

class MainDashboardController extends GetxController {
  var selectedTab = 0.obs;
  var expandedItem = ''.obs;

  @override
  void onInit() {
    super.onInit();

    final authController = Get.find<AuthController>();

    // Perform initial check
    _checkRedirect();

    // Also listen for auth initialization or user changes
    everAll([authController.isInitialized, authController.user], (_) {
      _checkRedirect();
    });

    _updateTab();
  }

  void _checkRedirect() {
    final authController = Get.find<AuthController>();
    final user = authController.user.value;
    final currentRoute = Get.currentRoute;

    if (!authController.isInitialized.value) return;

    print(
      'Controller Redirect Check. Route: $currentRoute, Auth: ${authController.isAuthenticated.value}, Role: ${user?.subscriptionPlan}',
    );

    if (!authController.isAuthenticated.value) {
      if (currentRoute != AppRoutes.login) {
        print('Not authenticated. Redirecting to login.');
        Future.microtask(() => Get.offAllNamed(AppRoutes.login));
      }
      return;
    }

    if (user?.isResearcher == true) {
      if (!currentRoute.startsWith('/reports')) {
        print('Researcher access restricted. Redirecting...');
        Future.microtask(() => Get.offAllNamed(AppRoutes.reports));
        return;
      }
    }

    if (user?.isDirector == true) {
      final hasPaymentsPermission = user?.hasPermission('Payments', 'read') ?? false;
      final allowedPrefixes = [
        '/users',
        '/staff',
        '/reports',
        '/manage-user',
        '/edit-user',
        '/approvals/kyc',
        if (hasPaymentsPermission) '/approvals/payments',
      ];
      final blockedRoutes = [
        '/users/create',
        '/users/pending-transfers',
        if (!hasPaymentsPermission) '/approvals/payments',
      ];

      bool isAllowed = allowedPrefixes.any(
        (prefix) => currentRoute.startsWith(prefix),
      );
      bool isBlocked = blockedRoutes.any((route) => currentRoute == route);

      if (!isAllowed || isBlocked) {
        print('Director access restricted for $currentRoute. Redirecting...');
        Future.microtask(() => Get.offAllNamed(AppRoutes.users));
        return;
      }
    }
  }

  void _updateTab() {
    final currentRoute = Get.currentRoute;
    if (currentRoute == AppRoutes.userKyc)
      selectedTab.value = 7;
    else if (currentRoute == AppRoutes.pendingPayments)
      selectedTab.value = 8;
    else if (currentRoute.startsWith('/users') ||
        currentRoute.startsWith('/manage-user') ||
        currentRoute.startsWith('/edit-user'))
      selectedTab.value = 1;
    else if (currentRoute.startsWith('/staff'))
      selectedTab.value = 2;
    else if (currentRoute.startsWith('/subscriptions'))
      selectedTab.value = 3;
    else if (currentRoute.startsWith('/reports'))
      selectedTab.value = 4;
    else if (currentRoute.startsWith('/notifications'))
      selectedTab.value = 5;
    else if (currentRoute.startsWith('/settings'))
      selectedTab.value = 6;
    else if (currentRoute.startsWith('/automated-trading'))
      selectedTab.value = 9;
    else if (currentRoute.startsWith('/leads'))
      selectedTab.value = 10;
    else if (currentRoute.startsWith('/attendance'))
      selectedTab.value = 11;
    else if (currentRoute.startsWith('/applicants'))
      selectedTab.value = 12;
    else
      selectedTab.value = 0;
  }

  void changeTab(int index) {
    selectedTab.value = index;
    switch (index) {
      case 0:
        Get.offNamed('/dashboard');
        break;
      case 1:
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
        Get.offNamed('/settings');
        break;
      case 7:
        Get.offNamed(AppRoutes.userKyc);
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
        Get.offNamed(AppRoutes.attendance);
        break;
      case 12:
        Get.offNamed('/applicants');
        break;
      default:
        Get.offNamed('/dashboard');
    }
  }
}
