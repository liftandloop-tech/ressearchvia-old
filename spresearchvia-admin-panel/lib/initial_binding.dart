import 'package:get/get.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import 'package:spresearch_web/controllers/reports/report_management.controller.dart';
import 'package:spresearch_web/controllers/subscription/subscription_management.controller.dart';
import 'package:spresearch_web/controllers/kyc/kyc_management.controller.dart';
import 'package:spresearch_web/controllers/staff/staff_management.controller.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard_management.controller.dart';
import 'package:spresearch_web/services/auth.service.dart';
import 'package:spresearch_web/services/user.service.dart';
import 'package:spresearch_web/services/report.service.dart';
import 'package:spresearch_web/services/subscription.service.dart';
import 'package:spresearch_web/services/kyc.service.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/services/dashboard.service.dart';
import 'package:spresearch_web/services/segment.service.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/controllers/reports/reports_navigation.controller.dart';
import 'package:spresearch_web/controllers/subscription/subscription_navigation.controller.dart';
import 'package:spresearch_web/services/user_details.service.dart';
import 'package:spresearch_web/services/user_payment.service.dart';
import 'package:spresearch_web/services/notification.service.dart';
import 'package:spresearch_web/services/acquisition.service.dart';
import 'package:spresearch_web/services/settings.service.dart';
import 'package:spresearch_web/services/lead.service.dart';
import 'package:spresearch_web/services/permission_service.dart';
import 'package:spresearch_web/services/refund.service.dart';

import 'package:spresearch_web/services/api.service.dart';
import 'package:spresearch_web/controllers/notifications/research_notification.controller.dart';
import 'package:spresearch_web/controllers/dashboard/main_dashboard.controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put(ApiService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(UserService(), permanent: true);
    Get.put(ReportService(), permanent: true);
    Get.put(SubscriptionService(), permanent: true);
    Get.put(KycService(), permanent: true);
    Get.put(StaffService(), permanent: true);
    Get.put(DashboardService(), permanent: true);
    Get.put(SegmentService(), permanent: true);
    Get.put(UserDetailsService(), permanent: true);
    Get.put(UserPaymentService(), permanent: true);
    Get.put(RefundService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.put(AcquisitionService(), permanent: true);
    Get.put(SettingsService(), permanent: true);
    Get.put(LeadService(), permanent: true);
    Get.put(PermissionService(), permanent: true);

    // Controllers (Permanent singletons for zero-lag tab transitions & instant caching)
    Get.put(AuthController(), permanent: true);
    Get.put(MainDashboardController(), permanent: true);
    Get.put(DashboardManagementController(), permanent: true);
    Get.put(UserManagementController(), permanent: true);
    Get.put(StaffManagementController(), permanent: true);
    Get.put(SubscriptionManagementController(), permanent: true);
    Get.put(ReportManagementController(), permanent: true);
    Get.put(KycManagementController(), permanent: true);
    Get.put(ResearchNotificationController(), permanent: true);

    // Navigation Controllers
    Get.put(UsersNavigationController(), permanent: true);
    Get.put(ReportsNavigationController(), permanent: true);
    Get.put(SubscriptionNavigationController(), permanent: true);
  }
}
