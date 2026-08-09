import 'package:get/get.dart';
import 'package:spresearch_web/ui/screens/subscription/subscription_tab.screen.dart';
import '../ui/screens/auth/login.screen.dart';
import '../ui/screens/auth/forgot_password.screen.dart';
import '../ui/screens/auth/reset_password.screen.dart';
import '../ui/screens/dashboard/main_dashboard.screen.dart';
import '../ui/screens/kyc/kyc_manager.screen.dart';

import '../ui/screens/users/manage_subscription.screen.dart';
import '../ui/screens/reports/reports.screen.dart';
import '../ui/screens/reports/upload_report.screen.dart';
import '../ui/screens/staff/staff.screen.dart';
import '../ui/screens/notifications/notifications.screen.dart';
import '../ui/screens/users/users.screen.dart';
import '../ui/layouts/dashboard_layout.widget.dart';
import '../ui/screens/users/create_user.screen.dart';
import '../ui/screens/subscription/create_plan.screen.dart';
import '../ui/screens/subscription/create_segment.screen.dart';
import '../ui/screens/users/details/user_details.screen.dart';
import '../ui/screens/staff/add_staff.screen.dart';
import '../ui/screens/users/edit_profile.screen.dart';
import '../ui/screens/subscription/pending_bank_transfers.screen.dart';
import '../ui/screens/subscription/hni_requests.screen.dart';
import '../ui/screens/settings/general_settings.screen.dart';
import '../ui/screens/dashboard/automated_trading_dashboard.screen.dart';
import '../ui/screens/leads/lead_management.screen.dart';
import '../ui/screens/attendance/attendance_monitoring.screen.dart';
import '../ui/screens/auth/applicant_registration.screen.dart';
import '../ui/screens/auth/applicant_profile.screen.dart';
import '../ui/screens/auth/applicant_onboard.screen.dart';
import '../ui/screens/auth/applicant_continue_init.screen.dart';
import '../ui/screens/staff/applicants_list.screen.dart';
import '../ui/screens/staff/staff_details.screen.dart';

import 'routes.config.dart';
export 'routes.config.dart';

final appPages = [
  GetPage(name: AppRoutes.login, page: () => const Login()),
  GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPassword()),
  GetPage(name: AppRoutes.resetPassword, page: () => const ResetPassword()),
  GetPage(name: AppRoutes.dashboard, page: () => const MainDashboard()),
  GetPage(name: AppRoutes.users, page: () => const UsersScreen()),
  GetPage(name: AppRoutes.kyc, page: () => const KycManager()),
  GetPage(name: AppRoutes.subscriptions, page: () => const SubscriptionTab()),
  GetPage(
    name: AppRoutes.manageSubscription,
    page: () => const ManageSubscriptionScreen(userId: ''),
  ),
  GetPage(name: AppRoutes.reports, page: () => const ReportsScreen()),
  GetPage(name: AppRoutes.uploadReport, page: () => UploadReportScreen()),
  GetPage(name: AppRoutes.reportDetails, page: () => const ReportsScreen()),
  GetPage(name: AppRoutes.staff, page: () => const StaffScreen()),
  GetPage(
    name: AppRoutes.notifications,
    page: () => const NotificationsScreen(),
  ),
  GetPage(
    name: '/users/pending-transfers',
    page: () => DashboardLayout(child: const PendingBankTransfersScreen()),
  ),
  GetPage(
    name: AppRoutes.pendingPayments,
    page: () => DashboardLayout(
      child: const PendingBankTransfersScreen(specificTab: 0),
    ),
  ),
  GetPage(
    name: AppRoutes.userKyc,
    page: () => DashboardLayout(
      child: const PendingBankTransfersScreen(specificTab: 1),
    ),
  ),
  GetPage(
    name: '/users/create',
    page: () => DashboardLayout(child: const CreateUserScreen()),
  ),
  GetPage(
    name: '/subscriptions/plans/create',
    page: () => DashboardLayout(child: const CreatePlanScreen()),
  ),
  GetPage(
    name: '/subscriptions/plans/edit/:id',
    page: () => DashboardLayout(
      child: const CreatePlanScreen(),
    ), // Controller will handle ID
  ),
  GetPage(
    name: '/subscriptions/segments/create',
    page: () => DashboardLayout(child: const CreateSegmentScreen()),
  ),
  GetPage(
    name: '/subscriptions/segments/edit/:id',
    page: () => DashboardLayout(
      child: const CreateSegmentScreen(),
    ), // Controller will handle ID
  ),
  GetPage(name: '/staff/create', page: () => const AddStaffScreen()),
  GetPage(name: '/staff/edit/:id', page: () => const AddStaffScreen()),
  GetPage(
    name: '/manage-user/:id',
    page: () => DashboardLayout(
      child: ManageSubscriptionScreen(userId: Get.parameters['id'] ?? ''),
    ),
  ),
  GetPage(
    name: '/edit-user/:id',
    page: () => DashboardLayout(
      child: EditUserProfile(userId: Get.parameters['id'] ?? ''),
    ),
  ),
  GetPage(
    name: AppRoutes.hniRequests,
    page: () => DashboardLayout(child: const HniRequestsScreen()),
  ),
  GetPage(name: AppRoutes.settings, page: () => const GeneralSettingsScreen()),
  GetPage(
    name: '/users/:id',
    page: () =>
        DashboardLayout(child: UserDetailsScreen(userId: Get.parameters['id'])),
  ),
  GetPage(
    name: AppRoutes.automatedTrading,
    page: () => const AutomatedTradingDashboardScreen(),
  ),
  GetPage(
    name: AppRoutes.leads,
    page: () => const LeadManagementScreen(),
  ),
  GetPage(
    name: AppRoutes.attendance,
    page: () => const AttendanceMonitoringScreen(),
  ),
  GetPage(
    name: '/apply',
    page: () => const ApplicantRegistrationScreen(),
  ),
  GetPage(
    name: '/applicants',
    page: () => const ApplicantsListScreen(),
  ),
  GetPage(
    name: '/staff/:id',
    page: () => const StaffDetailsScreen(),
  ),
  GetPage(
    name: '/applicant/:id',
    page: () => DashboardLayout(child: const ApplicantProfileScreen()),
  ),
  GetPage(
    name: '/apply/continue/:id',
    page: () => const ApplicantOnboardScreen(),
  ),
  GetPage(
    name: '/apply/continue',
    page: () => const ApplicantContinueInitScreen(),
  ),
];
