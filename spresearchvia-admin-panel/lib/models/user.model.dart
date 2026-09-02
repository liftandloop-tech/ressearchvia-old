class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final String kycStatus;
  final String registrationDate;
  final String? manager;
  final String? managerId;
  final String? expiryDate;
  final String? planPrice;
  final String? startDate;
  final String registrationStatus;
  final String registrationType;
  final String registrationSource;
  final String planSource;
  final List<String> plans; // List of active plan names
  final String? userId; // Display ID
  final Map<String, dynamic>? paymentIntent; // Added for Pending Approval logic
  final String panCard;
  final String userStatus; // ACTIVE or SUSPENDED
  final bool isViewOnly;
  final Map<String, dynamic>? rawJson;

  UserModel({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.kycStatus,
    required this.registrationDate,
    this.manager,
    this.managerId,
    this.expiryDate,
    this.planPrice,
    this.startDate,
    required this.registrationStatus,
    required this.registrationType,
    required this.registrationSource,
    required this.planSource,
    this.plans = const [],
    this.paymentIntent,
    this.panCard = '',
    this.userStatus = 'ACTIVE',
    this.isViewOnly = false,
    this.rawJson,
  });

  String get fullName => lastName.isEmpty ? firstName : '$firstName $lastName';
  String get createdAt => registrationDate;
  String get formattedPhone => mobile;

  bool get isAdmin {
    final dept = subscriptionPlan.toLowerCase();
    final roleStr = (rawJson?['role'] ?? '').toString().toLowerCase();
    final userTypeStr = (rawJson?['userType'] ?? '').toString().toLowerCase();
    String roleIdName = '';
    if (rawJson?['roleId'] is Map) {
      roleIdName = (rawJson!['roleId']['name'] ?? '').toString().toLowerCase();
    }
    return dept == 'admin' ||
        dept == 'super_admin' ||
        roleStr == 'admin' ||
        roleStr == 'super_admin' ||
        userTypeStr == 'admin' ||
        userTypeStr == 'super_admin' ||
        roleIdName == 'admin' ||
        roleIdName == 'super_admin';
  }

  bool get isResearcher => subscriptionPlan.toLowerCase() == 'researcher';

  bool get isDirector => subscriptionPlan.toLowerCase() == 'director';

  static String _parseMongoId(dynamic id) {
    if (id is Map && id.containsKey('\$oid'))
      return id['\$oid']?.toString() ?? '';
    return id?.toString() ?? '';
  }

  static String _parseMongoDate(dynamic date) {
    if (date is Map && date.containsKey('\$date'))
      return date['\$date']?.toString() ?? '';
    return date?.toString() ?? '';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userDetails = json['userDetails'] ?? {};
    return UserModel(
      id: _parseMongoId(json['_id'] ?? json['id']),
      firstName:
          json['fullName'] ?? json['username'] ?? userDetails['APP_NAME'] ?? '',
      lastName: '',
      email:
          json['email'] ??
          json['emailAddress'] ??
          userDetails['APP_EMAIL'] ??
          '',
      mobile:
          json['phone']?.toString() ??
          userDetails['APP_MOB_NO']?.toString() ??
          '',
      subscriptionPlan:
          json['packageName'] ??
          json['subscriptionPlan'] ??
          json['userType'] ??
          json['deparment'] ??
          json['department'] ??
          'N/A',
      subscriptionStatus:
          json['packagestatus'] ?? json['subscriptionStatus'] ?? 'N/A',
      kycStatus: json['kycStatus'] ?? 'N/A',
      registrationDate: _parseMongoDate(
        json['createdAt'] ?? json['registrationDate'],
      ),
      manager: json['Manager'] ?? json['managerName'] ?? json['manager'],
      managerId: json['ManagerId'] ?? json['managerId'],
      expiryDate: _parseMongoDate(
        json['subscriptionEndDate'] ??
            json['packageEndDate'] ??
            json['expiryDate'],
      ),
      planPrice: (json['packageAmount'] ?? json['planPrice'])?.toString(),
      startDate: _parseMongoDate(json['packageStartDate'] ?? json['startDate']),
      registrationStatus: json['registrationStatus'] ?? 'PENDING',
      registrationType: json['registrationType'] ?? 'N/A',
      registrationSource: json['registrationSource'] ?? 'APP',
      planSource: json['planSource'] ?? 'APP',
      plans:
          (json['plans'] as List?)
              ?.map((p) => p['packageName'].toString())
              .toList() ??
          (json['activePlans'] as List?)
              ?.map((p) => (p['packageName'] ?? 'N/A').toString())
              .toList() ??
          [],
      userId: json['userId'],
      paymentIntent: json['paymentIntent'] ?? json['paymentsIntent'],
      panCard:
          json['panCard'] ??
          json['panNumber'] ??
          userDetails['APP_PAN_NO'] ??
          '',
      userStatus: json['userStatus'] ?? 'ACTIVE',
      isViewOnly: json['isViewOnly'] ?? false,
      rawJson: json,
    );
  }

  bool hasPermission(String target, [String? optionalAction]) {
    if (isAdmin) return true; // System admins bypass permission checks
    if (rawJson == null) return false;

    final String requiredKey = optionalAction == null
        ? target.toLowerCase()
        : '${target.toLowerCase()}.${optionalAction.toLowerCase()}';

    // Check roleId
    final roleId = rawJson!['roleId'];
    if (roleId is Map) {
      final groups = roleId['permissionGroups'];
      if (groups is List) {
        for (var group in groups) {
          if (group is Map) {
            final permissionsList = group['permissions'];
            if (permissionsList is List) {
              for (var perm in permissionsList) {
                if (perm is Map) {
                  final actions = perm['actions'];
                  if (actions is List) {
                    final String permFeature = (perm['feature'] ?? '').toString().toLowerCase();
                    final List<String> actList = actions.map((a) => a.toString().toLowerCase()).toList();

                    // 1. Direct canonical key match
                    if (actList.contains(requiredKey)) {
                      return true;
                    }

                    // 2. Feature-based alias resolution for canonical view permissions
                    final reqFeature = requiredKey.split('.').first;
                    if (permFeature == reqFeature) {
                      if (requiredKey.startsWith('leads.view') &&
                          (actList.contains('read') || actList.contains('view') || actList.contains('leads.view_all') || actList.contains('leads.view_assigned'))) {
                        return true;
                      }
                      if (requiredKey.startsWith('users.view') &&
                          (actList.contains('read') || actList.contains('view') || actList.contains('users.view') || actList.contains('users.view_all') || actList.contains('users.view_assigned'))) {
                        return true;
                      }
                      if (requiredKey.startsWith('reports.view') &&
                          (actList.contains('read') || actList.contains('view') || actList.contains('reports.view'))) {
                        return true;
                      }
                      if (requiredKey.startsWith('kyc.view') &&
                          (actList.contains('read') || actList.contains('view') || actList.contains('kyc.view'))) {
                        return true;
                      }
                      if (requiredKey.startsWith('payments.view') &&
                          (actList.contains('read') || actList.contains('view') || actList.contains('payments.view_pending'))) {
                        return true;
                      }
                      if (requiredKey.startsWith('staff.view') &&
                          (actList.contains('read') || actList.contains('view') || actList.contains('staff.view'))) {
                        return true;
                      }
                      if (requiredKey.startsWith('settings.view') &&
                          (actList.contains('read') || actList.contains('view') || actList.contains('settings.view'))) {
                        return true;
                      }
                      if (requiredKey.startsWith('subscriptions') &&
                          (actList.contains('read') || actList.contains('view') || actList.contains('subscriptions.view') || actList.contains('subscriptions.activate'))) {
                        return true;
                      }
                    }

                    // Fallback check if feature and action were provided
                    if (optionalAction != null && permFeature == target.toLowerCase()) {
                      if (actList.contains(optionalAction.toLowerCase())) {
                        return true;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      return false; // Has roleId but permission not found in groups
    }

    return false;
  }

  bool has(String permissionKey) => hasPermission(permissionKey);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStatus': subscriptionStatus,
      'kycStatus': kycStatus,
      'registrationDate': registrationDate,
      'manager': manager,
      'managerId': managerId,
      'expiryDate': expiryDate,
      'planPrice': planPrice,
      'startDate': startDate,
      'registrationStatus': registrationStatus,
      'registrationType': registrationType,
      'registrationSource': registrationSource,
      'planSource': planSource,
      'paymentIntent': paymentIntent,
      'panCard': panCard,
    };
  }
}
