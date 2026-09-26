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
    if (id is Map && id.containsKey('\$oid')) {
      return id['\$oid']?.toString() ?? '';
    }
    return id?.toString() ?? '';
  }

  static String _parseMongoDate(dynamic date) {
    if (date is Map && date.containsKey('\$date')) {
      return date['\$date']?.toString() ?? '';
    }
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

  Map? get departmentData {
    if (rawJson?['departmentId'] is Map) return rawJson!['departmentId'] as Map;
    if (rawJson?['department'] is Map) return rawJson!['department'] as Map;
    if (rawJson?['roleId'] is Map && rawJson!['roleId']['departmentId'] is Map) {
      return rawJson!['roleId']['departmentId'] as Map;
    }
    return null;
  }

  /// Checks whether the user's assigned department has access to the specified page.
  /// If the department is global or user is admin, returns true.
  /// If the department specifies assignedPages, only pages in that list return true.
  bool canAccessDepartmentPage(String pageKey) {
    if (isAdmin) return true;

    final dept = departmentData;
    if (dept != null) {
      if (dept['isGlobal'] == true) return true;

      final dynamic rawPages = dept['assignedPages'];
      if (rawPages is List) {
        final Set<String> assigned = rawPages
            .map((p) => p.toString().toLowerCase().trim())
            .toSet();

        final key = pageKey.toLowerCase().trim();

        // Direct match
        if (assigned.contains(key)) return true;

        // Alias matching for page names
        if ((key == 'users' || key == 'clients' || key == 'all clients') && assigned.contains('users')) {
          return true;
        }
        if ((key == 'kyc' || key == 'registered clients' || key == 'user kyc') && (assigned.contains('kyc') || assigned.contains('users'))) {
          return true;
        }
        if ((key == 'payments') && (assigned.contains('payments') || assigned.contains('subscriptions'))) {
          return true;
        }
        if ((key == 'subscriptions' || key == 'plans' || key == 'segments') && assigned.contains('subscriptions')) {
          return true;
        }
        if ((key == 'leads' || key == 'lead') && assigned.contains('leads')) {
          return true;
        }
        if ((key == 'reports' || key == 'report') && assigned.contains('reports')) {
          return true;
        }
        if ((key == 'notifications' || key == 'notification') && assigned.contains('notifications')) {
          return true;
        }
        if ((key == 'staff' || key == 'applicants') && assigned.contains('staff')) {
          return true;
        }
        if ((key == 'settings') && assigned.contains('settings')) {
          return true;
        }
        if ((key == 'attendance') && (assigned.contains('attendance') || assigned.contains('staff'))) {
          return true;
        }

        // The department explicitly configured assignedPages and this page is not in them
        return false;
      }
    }

    return true;
  }

  String? _getDepartmentPageForFeature(String feature) {
    final f = feature.toLowerCase().trim();
    if (f == 'leads' || f == 'lead') return 'Leads';
    if (f == 'users' || f == 'user' || f == 'client' || f == 'clients') return 'Users';
    if (f == 'kyc') return 'KYC';
    if (f == 'payments' || f == 'payment') return 'Payments';
    if (f == 'subscriptions' || f == 'subscription' || f == 'plans' || f == 'segments') return 'Subscriptions';
    if (f == 'reports' || f == 'report') return 'Reports';
    if (f == 'notifications' || f == 'notification') return 'Notifications';
    if (f == 'staff' || f == 'applicant' || f == 'applicants') return 'Staff';
    if (f == 'settings' || f == 'roles' || f == 'permissiongroups') return 'Settings';
    if (f == 'attendance') return 'Attendance';
    return null;
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

    // Department page gate: If department specifies assignedPages, ensure the feature belongs to an assigned page
    final String? deptPage = _getDepartmentPageForFeature(targetFeature);
    if (deptPage != null && !canAccessDepartmentPage(deptPage)) {
      return false;
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
    bool hasConfiguredRole = false;
    if (rawJson != null) {
      Map? roleMap;
      if (rawJson!['roleId'] is Map) {
        roleMap = rawJson!['roleId'] as Map;
      } else if (rawJson!['role'] is Map) {
        roleMap = rawJson!['role'] as Map;
      }

      final dynamic groups = roleMap?['permissionGroups'] ?? rawJson!['permissionGroups'];
      if (roleMap != null || groups != null || rawJson!['roleId'] != null) {
        hasConfiguredRole = true;
      }

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

    // If the user has an assigned Role with permission groups, permissions MUST come from
    // the assigned permission groups. Do NOT fall back to legacy substring heuristics!
    if (hasConfiguredRole) {
      return false;
    }

    // 4. Fallback for legacy role assignments if permissionGroups are empty
    if (isResearcher && (targetFeature == 'reports' || targetFeature == 'notifications')) {
      return isReadIntent || targetAction == 'create' || targetAction == 'update' || targetAction == 'publish';
    }

    if (isManager) {
      if (t.startsWith('automated') || t.startsWith('trading') || t.startsWith('subscription') || t.startsWith('settings')) {
        return false;
      }
      if (t.startsWith('staff') && (action == 'delete' || action == 'create')) {
        return false;
      }
      return isReadIntent || targetAction == 'update';
    }

    // 5. Department-based fallback if permission groups are empty or unassigned
    // Strictly basic read/standard permissions ONLY - NO elevated permissions like view_pools or bulk operations
    final dept = subscriptionPlan.toLowerCase();
    if (dept.contains('sales') || dept.contains('executive') || dept.contains('advisory') || dept.contains('support')) {
      if (t == 'leads' || t == 'leads.view' || t == 'leads.pull' || t == 'leads.follow_up' || t == 'leads.view_assigned') {
        return true;
      }
      if (t == 'users' || t == 'users.view' || t == 'users.view_assigned') {
        return true;
      }
      if (isReadIntent && (targetFeature == 'leads' || targetFeature == 'users')) {
        return true;
      }
    }
    if (dept.contains('research')) {
      if (isReadIntent && targetFeature == 'reports') {
        return true;
      }
    }
    if (dept.contains('compliance') || dept.contains('operations')) {
      if (isReadIntent && (targetFeature == 'kyc' || targetFeature == 'users' || targetFeature == 'payments')) {
        return true;
      }
    }
    if (dept.contains('hr') || dept.contains('human')) {
      if (isReadIntent && (targetFeature == 'staff' || targetFeature == 'attendance')) {
        return true;
      }
    }
    if (dept.contains('back office') || dept.contains('office')) {
      if (isReadIntent && (targetFeature == 'users' || targetFeature == 'payments' || targetFeature == 'kyc' || targetFeature == 'subscriptions')) {
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
