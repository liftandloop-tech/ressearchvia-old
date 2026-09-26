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
    if (rawJson?['isAdmin'] == true) return true;
    if (isDirector || isResearcher) return false;
    final dept = subscriptionPlan.toLowerCase();
    final roleStr = (rawJson?['role'] ?? '').toString().toLowerCase();
    final userTypeStr = (rawJson?['userType'] ?? '').toString().toLowerCase();
    String roleIdName = '';
    if (rawJson?['roleId'] is Map) {
      roleIdName = (rawJson!['roleId']['name'] ?? '').toString().toLowerCase();
    }
    return dept == 'admin' ||
        dept == 'super_admin' ||
        dept == 'administration' ||
        dept.contains('admin') ||
        roleStr == 'admin' ||
        roleStr == 'super_admin' ||
        userTypeStr == 'admin' ||
        userTypeStr == 'super_admin' ||
        roleIdName == 'admin' ||
        roleIdName == 'super_admin';
  }

  bool get isResearcher {
    final dept = subscriptionPlan.toLowerCase();
    final roleStr = (rawJson?['role'] ?? '').toString().toLowerCase();
    final userTypeStr = (rawJson?['userType'] ?? '').toString().toLowerCase();
    String roleIdName = '';
    if (rawJson?['roleId'] is Map) {
      roleIdName = (rawJson!['roleId']['name'] ?? '').toString().toLowerCase();
    }
    return dept.contains('research') ||
        roleStr.contains('research') ||
        userTypeStr.contains('research') ||
        roleIdName.contains('research');
  }

  bool get isDirector {
    final dept = subscriptionPlan.toLowerCase();
    final roleStr = (rawJson?['role'] ?? '').toString().toLowerCase();
    final userTypeStr = (rawJson?['userType'] ?? '').toString().toLowerCase();
    String roleIdName = '';
    if (rawJson?['roleId'] is Map) {
      roleIdName = (rawJson!['roleId']['name'] ?? '').toString().toLowerCase();
    }
    return dept.contains('director') ||
        roleStr.contains('director') ||
        userTypeStr.contains('director') ||
        roleIdName.contains('director');
  }

  bool get isManager {
    final dept = subscriptionPlan.toLowerCase();
    final roleStr = (rawJson?['role'] ?? '').toString().toLowerCase();
    final userTypeStr = (rawJson?['userType'] ?? '').toString().toLowerCase();
    String roleIdName = '';
    if (rawJson?['roleId'] is Map) {
      roleIdName = (rawJson!['roleId']['name'] ?? '').toString().toLowerCase();
    }
    return dept.contains('manager') ||
        roleStr.contains('manager') ||
        userTypeStr.contains('manager') ||
        roleIdName.contains('manager');
  }

  bool get isSupervisor => isDirector || isManager;

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

    final t = target.trim().toLowerCase();
    final action = (optionalAction ?? '').trim().toLowerCase();

    // 1. Director role: operational authority across users, staff, leads, reports, kyc, notifications
    // Settings, Automated Trading, and Plan Creation are strictly ADMIN-ONLY.
    // Payment approval, rejection, revert, and subscription modification actions are strictly ADMIN-ONLY.
    // Directors are permitted to VIEW payments and subscriptions only.
    if (isDirector) {
      if (t.startsWith('automated') ||
          t.startsWith('trading') ||
          t.contains('plans.create') ||
          t.startsWith('setting')) {
        return false;
      }
      if (t.startsWith('payment') || t.startsWith('subscription')) {
        if (action == 'view' || action == 'read' || (action.isEmpty && (t.contains('view') || t.contains('read')))) {
          return true;
        }
        return false;
      }
      return true;
    }

    // Determine targetFeature and targetAction
    String targetFeature;
    String targetAction;

    if (action.isNotEmpty) {
      targetFeature = t;
      targetAction = action;
    } else if (t.contains('.')) {
      final parts = t.split('.');
      targetFeature = parts.first;
      targetAction = parts.sublist(1).join('.');
    } else if (t.contains(':')) {
      final parts = t.split(':');
      targetFeature = parts.first;
      targetAction = parts.sublist(1).join(':');
    } else {
      targetFeature = t;
      targetAction = '';
    }

    // Normalize feature name aliases
    if (targetFeature == 'client' || targetFeature == 'clients') {
      targetFeature = 'users';
    }

    final String requiredKey = targetAction.isNotEmpty 
        ? '$targetFeature.$targetAction' 
        : targetFeature;

    // Normalize read/view intent
    final bool isReadIntent = targetAction == 'read' || targetAction == 'view' || targetAction.isEmpty;

    // Check direct permissions array on user if present (e.g. ['*'] for admin)
    if (rawJson != null) {
      final directPerms = rawJson!['permissions'];
      if (directPerms is List) {
        final List<String> pList = directPerms.map((p) => p.toString().toLowerCase()).toList();
        if (pList.contains('*') || pList.contains('all') || pList.contains(requiredKey)) {
          return true;
        }
        if (isReadIntent && pList.any((p) => p.startsWith('$targetFeature.') || p == targetFeature)) {
          return true;
        }
      }
    }

    // Granular database-configured Role and Permission Groups check
    if (rawJson != null) {
      Map? roleMap;
      if (rawJson!['roleId'] is Map) {
        roleMap = rawJson!['roleId'] as Map;
      } else if (rawJson!['role'] is Map) {
        roleMap = rawJson!['role'] as Map;
      }

      final dynamic groups = roleMap?['permissionGroups'] ?? rawJson!['permissionGroups'];
      if (groups is List && groups.isNotEmpty) {
        for (var group in groups) {
          if (group is! Map) continue;
          final permissionsList = group['permissions'];
          if (permissionsList is! List) continue;

          for (var perm in permissionsList) {
            if (perm is! Map) continue;
            final actions = perm['actions'];
            if (actions is! List) continue;

            final String permFeatureRaw = (perm['feature'] ?? '').toString().toLowerCase();
            final String permFeature = (permFeatureRaw == 'client' || permFeatureRaw == 'clients') ? 'users' : permFeatureRaw;
            final List<String> actList = actions.map((a) => a.toString().toLowerCase()).toList();

            // 1. Direct canonical action or wildcard match
            if (actList.contains('*') || actList.contains('all') || actList.contains(requiredKey)) {
              return true;
            }

            // 2. Feature-matching permission check
            if (permFeature == targetFeature) {
              // If targetAction is empty or read/view, any valid permission in this feature grants view access
              if (isReadIntent && actList.isNotEmpty) {
                return true;
              }

              // Specific action checks
              if (actList.contains(targetAction)) {
                return true;
              }

              // Write/Edit aliases
              if ((targetAction == 'update' || targetAction == 'edit' || targetAction == 'write') &&
                  (actList.contains('update') || actList.contains('edit') || actList.contains('write') ||
                   actList.contains('$targetFeature.update') || actList.contains('$targetFeature.edit'))) {
                return true;
              }

              // Create/Add aliases
              if ((targetAction == 'create' || targetAction == 'add') &&
                  (actList.contains('create') || actList.contains('add') ||
                   actList.contains('$targetFeature.create') || actList.contains('$targetFeature.add'))) {
                return true;
              }

              // Delete/Remove aliases
              if ((targetAction == 'delete' || targetAction == 'remove') &&
                  (actList.contains('delete') || actList.contains('remove') ||
                   actList.contains('$targetFeature.delete'))) {
                return true;
              }
            }

            // 3. Cross-feature alias resolution matching accessMiddleware.js
            // Leads
            if (targetFeature == 'leads') {
              if (isReadIntent || requiredKey == 'leads.view_all' || requiredKey == 'leads.view_assigned') {
                if (actList.contains('leads.view') ||
                    actList.contains('leads.view_all') ||
                    actList.contains('leads.view_assigned') ||
                    actList.contains('leads.pull') ||
                    actList.contains('leads.create') ||
                    actList.contains('read') ||
                    actList.contains('view')) {
                  return true;
                }
              }
              if (requiredKey == 'leads.update_all' || requiredKey == 'leads.update_assigned' || requiredKey == 'leads.update') {
                if (actList.contains('leads.update') || actList.contains('leads.update_all') || actList.contains('leads.update_assigned')) {
                  return true;
                }
              }
              if (requiredKey == 'leads.follow_up_all' || requiredKey == 'leads.follow_up_assigned' || requiredKey == 'leads.follow_up') {
                if (actList.contains('leads.follow_up') || actList.contains('leads.follow_up_all') || actList.contains('leads.follow_up_assigned')) {
                  return true;
                }
              }
            }

            // Users / Clients
            if (targetFeature == 'users') {
              if (isReadIntent || requiredKey == 'users.view_all' || requiredKey == 'users.view_assigned') {
                if (actList.contains('users.view') ||
                    actList.contains('users.view_all') ||
                    actList.contains('users.view_assigned') ||
                    actList.contains('read') ||
                    actList.contains('view')) {
                  return true;
                }
              }
            }

            // KYC
            if (targetFeature == 'kyc') {
              if (isReadIntent) {
                if (actList.contains('kyc.view') || actList.contains('read') || actList.contains('view')) {
                  return true;
                }
              }
            }

            // Payments
            if (targetFeature == 'payments') {
              if (isReadIntent) {
                if (actList.contains('payments.view_pending') || actList.contains('payments.export') || actList.contains('read') || actList.contains('view')) {
                  return true;
                }
              }
            }

            // Reports
            if (targetFeature == 'reports') {
              if (isReadIntent) {
                if (actList.contains('reports.view') || actList.contains('reports.trading_call_popup') || actList.contains('read') || actList.contains('view')) {
                  return true;
                }
              }
              if (requiredKey == 'reports.trading_call_popup' &&
                  (actList.contains('reports.trading_call_popup') || actList.contains('trading_call_popup'))) {
                return true;
              }
            }

            // Notifications
            if (targetFeature == 'notifications') {
              if (isReadIntent) {
                if (actList.contains('notifications.view') || actList.contains('notifications.preview') || actList.contains('notifications.send') || actList.contains('read') || actList.contains('view')) {
                  return true;
                }
              }
            }

            // Staff
            if (targetFeature == 'staff') {
              if (isReadIntent) {
                if (actList.contains('staff.view') || actList.contains('staff.assignment') || actList.contains('staff.view_applicants') || actList.contains('read') || actList.contains('view')) {
                  return true;
                }
              }
              if (requiredKey == 'staff.reset' &&
                  (actList.contains('staff.reset_mpin') || actList.contains('staff.update') || actList.contains('staff.reset'))) {
                return true;
              }
            }

            // Settings
            if (targetFeature == 'settings') {
              if (isReadIntent) {
                if (actList.contains('settings.view') || actList.contains('read') || actList.contains('view')) {
                  return true;
                }
              }
            }

            // Subscriptions
            if (targetFeature == 'subscriptions') {
              if (isReadIntent) {
                if (actList.contains('subscriptions.view') || actList.contains('subscriptions.activate') || actList.contains('read') || actList.contains('view')) {
                  return true;
                }
              }
            }

            // Attendance
            if (targetFeature == 'attendance') {
              if (isReadIntent) {
                if (actList.contains('attendance.view') || actList.contains('attendance.mark') || actList.contains('read') || actList.contains('view')) {
                  return true;
                }
              }
            }
          }
        }
      }
    }

    // 4. Fallback for legacy role assignments if permissionGroups are empty
    if (isResearcher && (targetFeature == 'reports' || targetFeature == 'notifications')) {
      return true;
    }

    if (isManager) {
      if (t.startsWith('automated') || t.startsWith('trading') || t.startsWith('subscription') || t.startsWith('settings')) {
        return false;
      }
      if (t.startsWith('staff') && (action == 'delete' || action == 'create')) {
        return false;
      }
      return true;
    }

    // 5. Department-based fallback if permission groups are empty or unassigned
    final dept = subscriptionPlan.toLowerCase();
    if (dept.contains('sales') || dept.contains('executive') || dept.contains('advisory') || dept.contains('support')) {
      if (t.startsWith('lead') || t.startsWith('user') || t.startsWith('notification') || t.startsWith('kyc') || t.startsWith('attendance') || t.startsWith('report')) {
        return true;
      }
    }
    if (dept.contains('research')) {
      if (t.startsWith('report') || t.startsWith('notification')) {
        return true;
      }
    }
    if (dept.contains('compliance') || dept.contains('operations')) {
      if (t.startsWith('kyc') || t.startsWith('report') || t.startsWith('user') || t.startsWith('notification') || t.startsWith('payment')) {
        return true;
      }
    }
    if (dept.contains('hr') || dept.contains('human')) {
      if (t.startsWith('staff') || t.startsWith('attendance') || t.startsWith('notification')) {
        return true;
      }
    }
    if (dept.contains('back office') || dept.contains('office')) {
      if (t.startsWith('user') || t.startsWith('payment') || t.startsWith('kyc') || t.startsWith('subscription')) {
        return true;
      }
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
