class AppRoutes {
  static const String login = '/';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String userManagement = '/users';
  static const String userDetails = '/users/details';
  static const String userProfileEdit = '/user-profile-edit';
  static const String kyc = '/kyc';
  static const String kycManager = '/kyc-manager';
  static const String subscriptions = '/subscriptions';
  static const String manageSubscription = '/manage-subscription';
  static const String reports = '/reports';
  static const String uploadReport = '/upload-report';
  static const String reportDetails = '/reports/details';
  static const String staff = '/staff';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String rolesPermissions = '/settings/roles-permissions';
  static const String pendingPayments = '/approvals/payments';
  static const String userKyc = '/registered-clients';
  static const String registeredClients = '/registered-clients';
  static const String automatedTrading = '/automated-trading';
  static const String strategyConfig = '/automated-trading/strategy-config';
  static const String leads = '/leads';
  static const String attendance = '/attendance';
  static const String profile = '/profile';
  static const String apply = '/apply';
  static const String applyContinue = '/apply/continue';
  static const String applyContinueWithId = '/apply/continue/:id';
  static const String continueApplication = '/continue-application';
  static const String continueApplicationWithId = '/continue-application/:id';
  static const String verifyStaffWithId = '/verify/staff/:id';
  static const String verifyWithId = '/verify/:id';

  /// Returns true if the given [route] is a public page that does not require authentication.
  static bool isPublicRoute(String? route) {
    if (route == null || route.isEmpty) return false;
    // Strip query parameters and hashes for comparison
    var path = route;
    if (path.contains('#')) {
      path = path.split('#').last;
    }
    if (path.contains('?')) {
      path = path.split('?').first;
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    if (path == login ||
        path == forgotPassword ||
        path == resetPassword ||
        path == apply ||
        path.startsWith('/apply/') ||
        path.startsWith('/apply') ||
        path == continueApplication ||
        path.startsWith('/continue-application') ||
        path == '/continue' ||
        path.startsWith('/continue/') ||
        path == '/verify' ||
        path.startsWith('/verify/')) {
      return true;
    }
    return false;
  }
}
