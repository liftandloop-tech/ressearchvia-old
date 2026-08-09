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

import 'package:spresearch_web/services/api.service.dart';

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
    Get.put(NotificationService(), permanent: true);
    Get.put(AcquisitionService(), permanent: true);
    Get.put(SettingsService(), permanent: true);

    // Controllers
    Get.put(AuthController(), permanent: true); // Keep AuthController active
    Get.lazyPut(() => UserManagementController(), fenix: true);
    Get.lazyPut(() => ReportManagementController(), fenix: true);
    Get.lazyPut(() => SubscriptionManagementController(), fenix: true);
    Get.lazyPut(() => KycManagementController(), fenix: true);
    Get.lazyPut(() => StaffManagementController(), fenix: true);
    Get.lazyPut(() => DashboardManagementController(), fenix: true);

    // Navigation Controllers
    Get.lazyPut(() => UsersNavigationController(), fenix: true);
    Get.lazyPut(() => ReportsNavigationController(), fenix: true);
    Get.lazyPut(() => SubscriptionNavigationController(), fenix: true);
  }
}
