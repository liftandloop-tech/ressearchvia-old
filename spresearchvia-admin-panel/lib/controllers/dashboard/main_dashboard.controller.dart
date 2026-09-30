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
    final currentRoute = Get.currentRoute;

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
      isAllowed = user.canAccessDepartmentPage('Leads') && user.hasPermission('Leads', 'read');
    } else if (currentRoute.startsWith('/automated-trading')) {
      isAllowed = false;
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
      print('Access restricted for $currentRoute. Redirecting to dashboard...');
      Future.microtask(() => Get.offNamed(AppRoutes.dashboard));
    }
  }

  void _updateTab() {
    final currentRoute = Get.currentRoute;
    if (currentRoute == AppRoutes.registeredClients ||
        currentRoute == AppRoutes.userKyc ||
        currentRoute.startsWith('/registered-clients') ||
        currentRoute.startsWith('/approvals/kyc'))
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
    else if (currentRoute.startsWith('/applicants') ||
        currentRoute.startsWith('/applicant/'))
      selectedTab.value = 11;
    else if (currentRoute.startsWith('/attendance'))
      selectedTab.value = 12;
    else
      selectedTab.value = 0;
  }

  void changeTab(int index) {
    selectedTab.value = index;
    final currentUser = Get.find<AuthController>().user.value;
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
        if (currentUser?.canAccessDepartmentPage('Settings') ?? false) {
          Get.offNamed('/settings');
        } else {
          Get.offNamed('/dashboard');
        }
        break;
      case 7:
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
