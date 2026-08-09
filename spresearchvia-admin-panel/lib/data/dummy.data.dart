class DummyData {
  static const String appName = 'SPResearchVia Admin Panel';
  static const String version = '1.0.0';
  static const String copyrightText =
      '© 2025 Research Via. All rights reserved.';

  static const String welcomeBackText = 'Welcome back, Admin 👋';
  static const String todayDateText = 'Today is Monday, September 8, 2025';
  static const String adminLoginText = 'Admin Login';
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';
  static const String emailHint = 'Enter your email address';
  static const String passwordHint = 'Enter your password';
  static const String rememberMeText = 'Remember Me';
  static const String forgotPasswordText = 'Forgot Password?';
  static const String loginButtonText = 'Login';
  static const String reportsAnalyticsTitle = 'Reports Analytics';
  static const String subscriptionPlansTitle = 'Subscription Plans';
  static const String userManagementTitle = 'User Management';
  static const String userManagementSubtitle =
      'Manage and monitor all user accounts';
  static const String createNewPlanText = 'Create New Plan';
  static const String createNewPlanSubtitle =
      'Set up a new subscription plan with pricing and features';
  static const String planDetailsText = 'Plan Details';
  static const String planNameLabel = 'Plan Name *';
  static const String planTypeLabel = 'Plan Type *';
  static const String durationLabel = 'Duration';
  static const String priceLabel = 'Price *';
  static const String descriptionLabel = 'Description';
  static const String planFeaturesText = 'Plan Features';
  static const String addFeatureText = 'Add Feature';
  static const String featureNameHint = 'Feature name';
  static const String savePlanText = 'Save Plan';
  static const String cancelText = 'Cancel';
  static const String backToPlansText = 'Back to Plans';
  static const String exportPlansText = 'Export Plans';
  static const String applyFiltersText = 'Apply Filters';
  static const String resetText = 'Reset';
  static const String selectAllText = 'Select All';
  static const String selectedText = 'selected';
  static const String exportText = 'Export';
  static const String notifyText = 'Notify';
  static const String deleteText = 'Delete';

  static const Map<String, dynamic> currentUser = {
    'id': 'USR-2024-001',
    'name': 'Sarah Johnson',
    'email': 'sarah.johnson@example.com',
    'mobile': '+1 234 567 8900',
    'avatar': 'S',
    'subscriptionPlan': 'Premium Annual',
    'subscriptionStatus': 'Active',
    'kycStatus': 'Verified',
    'registrationDate': '2024-03-15T00:00:00.000Z',
    'subscriptionExpiry': '2025-03-15T00:00:00.000Z',
    'planPrice': '₹299/year',
    'startDate': 'Mar 15, 2024',
    'expiryDate': 'Mar 15, 2025',
    'autoRenew': true,
  };

  static const List<Map<String, dynamic>> users = [
    {
      'id': 'USR-001',
      'name': 'John Smith',
      'email': 'john.smith@email.com',
      'mobile': '+1 234 567 8900',
      'avatar': 'J',
      'subscriptionPlan': 'Monthly Premium',
      'subscriptionStatus': 'Active',
      'kycStatus': 'Verified',
      'registrationDate': '2024-01-15T00:00:00.000Z',
      'subscriptionExpiry': '2024-12-15T00:00:00.000Z',
    },
    {
      'id': 'USR-002',
      'name': 'Sarah Johnson',
      'email': 'sarah.j@email.com',
      'mobile': '+1 234 567 8901',
      'avatar': 'S',
      'subscriptionPlan': 'Annual Basic',
      'subscriptionStatus': 'Expired',
      'kycStatus': 'Pending',
      'registrationDate': '2024-02-20T00:00:00.000Z',
      'subscriptionExpiry': '2024-11-20T00:00:00.000Z',
    },
  ];

  static const Map<String, dynamic> dashboardStats = {
    'totalUsers': '24,847',
    'activeSubscriptions': '18,392',
    'revenue': '₹847,293',
    'pendingKyc': '127',
  };

  static const List<Map<String, dynamic>> recentPayments = [
    {
      'user': 'Sarah Johnson',
      'amount': '₹49.99',
      'plan': 'Premium',
      'status': 'Completed',
      'avatar': 'S',
    },
    {
      'user': 'Michael Chen',
      'amount': '₹29.99',
      'plan': 'Basic',
      'status': 'Pending',
      'avatar': 'M',
    },
    {
      'user': 'Emma Wilson',
      'amount': '₹99.99',
      'plan': 'Enterprise',
      'status': 'Completed',
      'avatar': 'E',
    },
    {
      'user': 'David Brown',
      'amount': '₹39.99',
      'plan': 'Standard',
      'status': 'Completed',
      'avatar': 'D',
    },
    {
      'user': 'Lisa Anderson',
      'amount': '₹59.99',
      'plan': 'Premium',
      'status': 'Completed',
      'avatar': 'L',
    },
    {
      'user': 'James Taylor',
      'amount': '₹19.99',
      'plan': 'Basic',
      'status': 'Pending',
      'avatar': 'J',
    },
    {
      'user': 'Maria Garcia',
      'amount': '₹79.99',
      'plan': 'Premium',
      'status': 'Completed',
      'avatar': 'M',
    },
    {
      'user': 'Robert Martinez',
      'amount': '₹89.99',
      'plan': 'Enterprise',
      'status': 'Completed',
      'avatar': 'R',
    },
    {
      'user': 'Jennifer Lee',
      'amount': '₹24.99',
      'plan': 'Basic',
      'status': 'Pending',
      'avatar': 'J',
    },
    {
      'user': 'William Davis',
      'amount': '₹69.99',
      'plan': 'Premium',
      'status': 'Completed',
      'avatar': 'W',
    },
  ];

  static const List<Map<String, dynamic>> pendingKyc = [
    {'user': 'David Brown', 'document': 'Passport', 'avatar': 'D'},
    {'user': 'Lisa Garcia', 'document': 'ID Card', 'avatar': 'L'},
    {'user': 'James Miller', 'document': 'Driver License', 'avatar': 'J'},
  ];

  static const List<Map<String, dynamic>> renewalsList = [
    {
      'clientName': 'Rahul Verma',
      'mobile': '+91 98765 43210',
      'plan': 'Index Option – Spark',
      'expiryDate': '05-Nov-2025',
      'renewalDate': '—',
      'status': 'Not Renewed',
      'daysLeft': '3 Days',
      'manager': 'Rohit Sharma',
    },
    {
      'clientName': 'Sneha Mehta',
      'mobile': '+91 87654 32109',
      'plan': 'Stock Future – Splendid',
      'expiryDate': '08-Nov-2025',
      'renewalDate': '03-Nov-2025',
      'status': 'Renewed',
      'daysLeft': '+365d',
      'manager': 'Kavya Singh',
    },
    {
      'clientName': 'Arjun Rao',
      'mobile': '+91 76543 21098',
      'plan': 'Equity Cash',
      'expiryDate': '10-Nov-2025',
      'renewalDate': '—',
      'status': 'Expiring Soon',
      'daysLeft': '5 Days',
      'manager': 'Unassigned',
    },
    {
      'clientName': 'Priya Sharma',
      'mobile': '+91 65432 10987',
      'plan': 'Commodity Plus',
      'expiryDate': '12-Nov-2025',
      'renewalDate': '—',
      'status': 'Expiring Soon',
      'daysLeft': '7 Days',
      'manager': 'Aman Verma',
    },
    {
      'clientName': 'Vikash Kumar',
      'mobile': '+91 54321 09876',
      'plan': 'Currency Pro',
      'expiryDate': '15-Nov-2025',
      'renewalDate': '10-Nov-2025',
      'status': 'Renewed',
      'daysLeft': '+365d',
      'manager': 'Priya Nair',
    },
    {
      'clientName': 'Amit Patel',
      'mobile': '+91 98123 45678',
      'plan': 'Index Future – Premium',
      'expiryDate': '18-Nov-2025',
      'renewalDate': '—',
      'status': 'Not Renewed',
      'daysLeft': '2 Days',
      'manager': 'Rohit Sharma',
    },
    {
      'clientName': 'Neha Gupta',
      'mobile': '+91 87654 98765',
      'plan': 'Equity Option – Gold',
      'expiryDate': '20-Nov-2025',
      'renewalDate': '15-Nov-2025',
      'status': 'Renewed',
      'daysLeft': '+365d',
      'manager': 'Kavya Singh',
    },
    {
      'clientName': 'Rajesh Singh',
      'mobile': '+91 76543 87654',
      'plan': 'Commodity Future',
      'expiryDate': '22-Nov-2025',
      'renewalDate': '—',
      'status': 'Expiring Soon',
      'daysLeft': '8 Days',
      'manager': 'Aman Verma',
    },
    {
      'clientName': 'Kavita Reddy',
      'mobile': '+91 65432 76543',
      'plan': 'Currency Option',
      'expiryDate': '25-Nov-2025',
      'renewalDate': '—',
      'status': 'Expiring Soon',
      'daysLeft': '10 Days',
      'manager': 'Priya Nair',
    },
    {
      'clientName': 'Suresh Nair',
      'mobile': '+91 54321 65432',
      'plan': 'Stock Cash – Elite',
      'expiryDate': '28-Nov-2025',
      'renewalDate': '20-Nov-2025',
      'status': 'Renewed',
      'daysLeft': '+365d',
      'manager': 'Rohit Sharma',
    },
  ];

  static const List<Map<String, dynamic>> paymentHistory = [
    {
      'transactionId': 'TXN-2024-001',
      'amount': '₹999',
      'method': 'Credit Card',
      'date': '01/12/2024',
      'status': 'Success',
    },
    {
      'transactionId': 'TXN-2024-002',
      'amount': '₹999',
      'method': 'UPI',
      'date': '01/11/2024',
      'status': 'Success',
    },
    {
      'transactionId': 'TXN-2024-003',
      'amount': '₹999',
      'method': 'Net Banking',
      'date': '01/10/2024',
      'status': 'Failed',
    },
  ];

  static const List<Map<String, dynamic>> subscriptionPlans = [
    {
      'id': 'PLAN-001',
      'name': 'Basic Monthly',
      'price': '₹29/month',
      'value': 'basic_monthly',
      'features': ['Basic Reports', 'Email Support'],
      'isActive': true,
    },
    {
      'id': 'PLAN-002',
      'name': 'Premium Annual',
      'price': '₹299/year',
      'value': 'premium_annual',
      'features': ['All Reports', 'Priority Support'],
      'isActive': true,
    },
  ];

  static const List<Map<String, dynamic>> reports = [
    {
      'id': 'RPT-001',
      'title': 'Q3 2024 Equity Market Analysis',
      'category': 'Equity Research',
      'status': 'Published',
      'downloads': 2847,
      'publishDate': '2024-10-15T00:00:00.000Z',
      'author': 'Research Team',
    },
  ];

  static const Map<String, dynamic> analyticsData = {
    'totalReports': 1247,
    'publishedReports': 892,
    'draftReports': 355,
  };

  static const Map<String, dynamic> revenueChartData = {
    'xLabels': ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    'yLabels': [40.0, 50.0, 60.0, 70.0, 80.0],
    'data': [45.0, 52.0, 48.0, 61.0, 58.0, 67.0, 72.0],
  };

  static const List<Map<String, dynamic>> reportsByCategoryData = [
    {'label': 'Equity', 'count': 420.0},
    {'label': 'Commodity', 'count': 300.0},
    {'label': 'Derivatives', 'count': 180.0},
    {'label': 'Others', 'count': 320.0},
  ];

  static const List<Map<String, dynamic>> reportsOverTimeData = [
    {"date": "Jan 1", "value": 12.0},
    {"date": "Jan 2", "value": 8.0},
    {"date": "Jan 3", "value": 15.0},
    {"date": "Jan 4", "value": 22.0},
    {"date": "Jan 5", "value": 18.0},
    {"date": "Jan 6", "value": 25.0},
    {"date": "Jan 7", "value": 19.0},
  ];

  static const List<Map<String, dynamic>> mostDownloadedReports = [
    {
      'rank': '1',
      'title': 'Q3 2024 Equity Market Analysis',
      'category': 'Equity Research',
      'downloads': '2,847\ndownloads',
    },
    {
      'rank': '2',
      'title': 'Commodity Price Trends 2024',
      'category': 'Commodity Research',
      'downloads': '1,923\ndownloads',
    },
    {
      'rank': '3',
      'title': 'Derivatives Market Outlook',
      'category': 'Derivatives Research',
      'downloads': '1,654\ndownloads',
    },
    {
      'rank': '4',
      'title': 'ESG Investment Strategies',
      'category': 'ESG Research',
      'downloads': '1,432\ndownloads',
    },
    {
      'rank': '5',
      'title': 'Tech Sector Deep Dive',
      'category': 'Sector Analysis',
      'downloads': '1,287\ndownloads',
    },
  ];

  static const Map<String, dynamic> chartConfig = {
    'marginLeft': 40.0,
    'marginBottom': 20.0,
    'marginTop': 10.0,
    'marginRight': 20.0,
    'yAxisTitle': 'Reports Published',
    'xAxisTitle': 'Published Reports',
    'lineChartYMin': 5.0,
    'lineChartYMax': 30.0,
    'lineChartYTicks': [5.0, 10.0, 15.0, 20.0, 25.0, 30.0],
  };

  static const List<Map<String, dynamic>> extensionTypes = [
    {'name': 'Add Days', 'value': 'add_days'},
    {'name': 'Add Months', 'value': 'add_months'},
    {'name': 'Add Years', 'value': 'add_years'},
  ];

  static const List<String> planTypes = [
    'All Types',
    'Basic',
    'Premium',
    'Enterprise',
  ];
  static const List<String> statusOptions = [
    'All Status',
    'Active',
    'Inactive',
  ];
  static const List<String> subscriptionStatuses = [
    'All Statuses',
    'Active',
    'Expired',
  ];
  static const List<String> kycStatuses = [
    'All Statuses',
    'Verified',
    'Pending',
  ];
  static const List<String> timePeriods = ['7 days', '30 days', 'Custom'];
  static const List<String> durationTypes = ['Days', 'Months', 'Years'];

  static const List<String> userTableHeaders = [
    '',
    'User ID',
    'Name',
    'Email',
    'Mobile No.',
    'Subscription Plan',
    'Subscription Status',
    'KYC Status',
    'Actions',
  ];

  static const List<String> plansTableHeaders = [
    'Plan ID',
    'Plan Name',
    'Duration',
    'Price',
    'Status',
    'Created Date',
    'Actions',
  ];

  static const List<String> paymentsTableHeaders = [
    'User',
    'Amount',
    'Plan',
    'Status',
  ];

  static const List<String> kycTableHeaders = ['User', 'Document', 'Action'];

  static const List<Map<String, dynamic>> dashboardActionCards = [
    {
      'title': 'Upload Report',
      'subtitle': 'Upload and manage reports',
      'icon': 'upload_file',
      'color': 'blue',
    },
    {
      'title': 'Create Notification',
      'subtitle': 'Send notifications to users',
      'icon': 'notifications',
      'color': 'green',
    },
    {
      'title': 'Support Tickets',
      'subtitle': 'View and manage tickets',
      'icon': 'headset_mic',
      'color': 'darkBlue',
    },
  ];

  static const Map<String, String> formLabels = {
    'planName': 'Plan Name *',
    'planType': 'Plan Type *',
    'duration': 'Duration',
    'price': 'Price *',
    'description': 'Description',
    'planFeatures': 'Plan Features',
    'addFeature': 'Add Feature',
    'featureName': 'Feature name',
    'savePlan': 'Save Plan',
    'cancel': 'Cancel',
    'backToPlans': 'Back to Plans',
    'exportPlans': 'Export Plans',
    'applyFilters': 'Apply Filters',
    'reset': 'Reset',
    'selectAll': 'Select All',
    'export': 'Export',
    'notify': 'Notify',
    'delete': 'Delete',
  };

  static const Map<String, String> formHints = {
    'planName': 'Enter plan name',
    'duration': '12',
    'price': '₹ 29.99',
    'description': 'Describe what\'s included in this plan...',
    'featureName': 'Feature name',
    'dateFormat': 'mm/dd/yyyy',
  };

  static const Map<String, String> validationMessages = {
    'emailRequired': 'Please enter your email',
    'passwordRequired': 'Please enter your password',
  };

  static const Map<String, String> statusLabels = {
    'active': 'Active',
    'inactive': 'Inactive',
    'verified': 'Verified',
    'pending': 'Pending',
    'completed': 'Completed',
    'expired': 'Expired',
    'published': 'Published',
    'draft': 'Draft',
    'success': 'Success',
    'failed': 'Failed',
  };

  static const Map<String, String> navigationLabels = {
    'dashboard': 'Dashboard',
    'reports': 'Reports',
    'analytics': 'Analytics',
    'users': 'Users',
    'subscriptions': 'Subscriptions',
    'kyc': 'KYC',
    'communication': 'Communication',
    'settings': 'Settings',
  };

  static const String paginationShowingText = 'Showing 1 to 10 of 247 entries';
  static const String paginationPreviousText = 'Previous';
  static const String paginationNextText = 'Next';
  static const String userTablePaginationText =
      'Showing 1 to 10 of 247 entries';
}
