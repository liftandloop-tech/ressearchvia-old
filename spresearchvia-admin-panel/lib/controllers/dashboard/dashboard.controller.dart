import 'package:get/get.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/models/user.model.dart';
import 'dashboard_management.controller.dart';

class DashboardController extends GetxController {
  final DashboardManagementController _dashboardManagementController =
      Get.find<DashboardManagementController>();

  AuthController? get _authController =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
  UserModel? get currentUser => _authController?.user.value;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  /// True if user manages a team (Admin or user with subordinates in their scoped hierarchy)
  bool get hasTeamMembers {
    if (isAdmin) return true;
    final staffList = _dashboardManagementController.staffList;
    if (staffList.length > 1) return true;
    return false;
  }

  /// True ONLY for individual regular staff with no subordinates
  bool get isSingleStaff => currentUser != null && !isAdmin && !hasTeamMembers;
  bool get isRegularStaff => isSingleStaff; // backwards-compatible alias

  var selectedRenewalStatus = 'All'.obs; // Order Status filter
  var selectedDateFilter = 'All Time'.obs;
  var selectedCustomDate = Rxn<DateTime>();
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  var selectedManagerFilter = 'All Staff'.obs;
  var selectedDepartmentFilter = 'All Departments'.obs;
  var searchQuery = ''.obs;
  var activeTab = 0.obs; // 0: Staff Performance Leaderboard, 1: Staff Orders
  bool _isFilterSyncing = false;

  @override
  void onInit() {
    super.onInit();
    startDate.value = null;
    endDate.value = null;
    _syncFilterDefaults();

    if (_authController != null) {
      ever(_authController!.user, (_) {
        _syncFilterDefaults();
      });
    }

    ever(_dashboardManagementController.staffList, (_) {
      _syncFilterDefaults();
    });

    debounce(
      searchQuery,
      (_) {
        if (!_isFilterSyncing) fetchFilteredData();
      },
      time: const Duration(milliseconds: 350),
    );
    ever(selectedManagerFilter, (_) {
      if (!_isFilterSyncing) fetchFilteredData();
    });
    ever(selectedDepartmentFilter, (_) {
      if (!_isFilterSyncing) fetchFilteredData();
    });
    ever(startDate, (_) {
      if (!_isFilterSyncing) fetchFilteredData();
    });
    ever(endDate, (_) {
      if (!_isFilterSyncing) fetchFilteredData();
    });
    ever(selectedRenewalStatus, (_) {
      if (!_isFilterSyncing) fetchFilteredData();
    });
    ever(selectedDateFilter, (val) {
      if (!_isFilterSyncing) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (val == 'Today') {
          startDate.value = DateTime(today.year, today.month, today.day, 0, 0, 0);
          endDate.value = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
        } else if (val == 'This Week') {
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          startDate.value = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          endDate.value = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59, 999);
        } else if (val == 'This Month') {
          startDate.value = DateTime(now.year, now.month, 1, 0, 0, 0);
          endDate.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        } else if (val == 'All Time') {
          startDate.value = null;
          endDate.value = null;
        }
        fetchFilteredData();
      }
    });
  }

  void _syncFilterDefaults() {
    _isFilterSyncing = true;
    try {
      if (isSingleStaff) {
        final myName = currentUser?.fullName.trim();
        final targetManager = (myName != null && myName.isNotEmpty) ? myName : 'My Profile';
        if (selectedManagerFilter.value != targetManager) {
          selectedManagerFilter.value = targetManager;
        }
        final myDept = (currentUser?.departmentName ?? '').trim();
        final targetDept = (myDept.isNotEmpty && myDept != 'N/A')
            ? myDept
            : (departmentFilterItems.length > 1 ? departmentFilterItems[1] : 'All Departments');
        if (selectedDepartmentFilter.value != targetDept) {
          selectedDepartmentFilter.value = targetDept;
        }
      } else {
        if (!managerFilterItems.contains(selectedManagerFilter.value)) {
          selectedManagerFilter.value = 'All Staff';
        }
        if (!departmentFilterItems.contains(selectedDepartmentFilter.value)) {
          selectedDepartmentFilter.value = 'All Departments';
        }
      }
    } finally {
      _isFilterSyncing = false;
    }
  }

  void fetchFilteredData({bool force = false}) {
    final query = <String, dynamic>{};
    if (searchQuery.value.trim().isNotEmpty) {
      query['search'] = searchQuery.value.trim();
    }

    if (isSingleStaff) {
      query['staffId'] = currentUser?.id;
      final name = currentUser?.fullName.trim();
      if (name != null && name.isNotEmpty) {
        query['staffMember'] = name;
      }
      final dept = (currentUser?.departmentName ?? '').trim();
      if (dept.isNotEmpty && dept != 'N/A') {
        query['department'] = dept;
      }
    } else {
      if (selectedManagerFilter.value != 'All Staff' &&
          selectedManagerFilter.value != 'All Managers') {
        query['staffMember'] = selectedManagerFilter.value;
      }
      if (selectedDepartmentFilter.value != 'All Departments') {
        query['department'] = selectedDepartmentFilter.value;
      }
    }

    if (startDate.value != null) {
      query['startDate'] = startDate.value!.toIso8601String();
    }
    if (endDate.value != null) {
      query['endDate'] = endDate.value!.toIso8601String();
    }
    if (selectedRenewalStatus.value != 'All') {
      query['status'] = selectedRenewalStatus.value;
    }

    _dashboardManagementController.fetchDashboardData(
      force: force || query.isNotEmpty,
      query: query.isNotEmpty ? query : null,
    );
  }

  List<Map<String, dynamic>> get renewalsList =>
      _dashboardManagementController.renewalsList;

  List<Map<String, dynamic>> get filteredRenewalsList {
    var list = List<Map<String, dynamic>>.from(renewalsList);

    if (isSingleStaff) {
      final myId = (currentUser?.id ?? '').toLowerCase();
      final myName = (currentUser?.fullName ?? '').trim().toLowerCase();

      list = list.where((item) {
        final mId = (item['managerId'] ?? item['staffId'] ?? '').toString().toLowerCase();
        final managerName = (item['manager'] ?? item['staffName'] ?? '').toString().trim().toLowerCase();
        return (myId.isNotEmpty && mId == myId) ||
            (myName.isNotEmpty && managerName == myName);
      }).toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();
      list = list.where((item) {
        final clientName = (item['name'] ?? item['clientName'] ?? '').toString().toLowerCase();
        final email = (item['email'] ?? '').toString().toLowerCase();
        final phone = (item['phone'] ?? item['mobile'] ?? '').toString().toLowerCase();
        final manager = (item['manager'] ?? item['staffName'] ?? '').toString().toLowerCase();
        return clientName.contains(q) || email.contains(q) || phone.contains(q) || manager.contains(q);
      }).toList();
    }

    if (!isSingleStaff) {
      if (selectedManagerFilter.value != 'All Staff' &&
          selectedManagerFilter.value != 'All Managers') {
        final targetManager = selectedManagerFilter.value.trim().toLowerCase();
        list = list.where((item) {
          final manager = (item['manager'] ?? item['staffName'] ?? '').toString().trim().toLowerCase();
          return manager == targetManager;
        }).toList();
      }
    }

    if (selectedRenewalStatus.value != 'All') {
      final filterStatus = selectedRenewalStatus.value.trim().toLowerCase();
      list = list.where((item) {
        final status = (item['kycStatus'] ?? item['status'] ?? '').toString().trim().toLowerCase();
        return status == filterStatus;
      }).toList();
    }

    return list;
  }

  List<String> get managerFilterItems {
    if (isSingleStaff) {
      final name = currentUser?.fullName.trim();
      if (name != null && name.isNotEmpty) {
        return [name];
      }
      return ['My Profile'];
    }

    final myName = currentUser?.fullName.trim() ?? '';
    final staffNames = <String>{};
    for (final s in _dashboardManagementController.staffList) {
      if (s.status.toLowerCase() == 'active') {
        final n = s.name.trim();
        if (n.isNotEmpty) staffNames.add(n);
      }
    }
    for (final p in _dashboardManagementController.staffPerformanceList) {
      final st = (p['status'] ?? 'active').toString().toLowerCase();
      if (st == 'active') {
        final n = (p['name'] ?? p['staffName'] ?? '').toString().trim();
        if (n.isNotEmpty) staffNames.add(n);
      }
    }
    final sortedStaff = staffNames.toList()..sort();

    return {'All Staff', if (myName.isNotEmpty) myName, ...sortedStaff}.toList();
  }

  List<String> get departmentFilterItems {
    if (isSingleStaff) {
      final dept = (currentUser?.departmentName ?? '').trim();
      if (dept.isNotEmpty && dept != 'N/A') {
        return [dept];
      }
      return ['Sales'];
    }
    final depts = <String>{};
    for (final s in _dashboardManagementController.staffList) {
      final d = s.department.trim();
      if (d.isNotEmpty) depts.add(d);
    }
    for (final d in _dashboardManagementController.departmentSales) {
      final name = (d['department'] ?? d['name'] ?? '').toString().trim();
      if (name.isNotEmpty) depts.add(name);
    }
    for (final s in _dashboardManagementController.staffPerformanceList) {
      final dept = (s['department'] ?? '').toString().trim();
      if (dept.isNotEmpty) depts.add(dept);
    }
    final sortedDepts = depts.toList()..sort();
    return ['All Departments', ...sortedDepts];
  }

  double get totalSalesAmount =>
      _dashboardManagementController.totalSalesAmount.value;
  int get totalOrders => _dashboardManagementController.totalOrders.value;
  int get totalPurchases => totalOrders;
  int get activeStaffCount =>
      _dashboardManagementController.activeStaffCount.value;
  double get avgOrderValue =>
      _dashboardManagementController.avgOrderValue.value;
  int get conversionRate =>
      _dashboardManagementController.conversionRate.value;
  Map<String, dynamic>? get topPerformingStaff =>
      _dashboardManagementController.topPerformingStaff.value;
  List<Map<String, dynamic>> get departmentSales =>
      _dashboardManagementController.departmentSales;

  List<Map<String, dynamic>> get staffPerformanceList =>
      _dashboardManagementController.staffPerformanceList;
  List<Map<String, dynamic>> get ordersList =>
      _dashboardManagementController.ordersList;

  List<Map<String, dynamic>> get filteredStaffPerformance {
    var list = List<Map<String, dynamic>>.from(staffPerformanceList);

    // Only show active staff on dashboard
    list = list.where((item) {
      final st = (item['status'] ?? 'active').toString().toLowerCase();
      return st == 'active';
    }).toList();

    if (isSingleStaff) {
      final myId = (currentUser?.id ?? '').toLowerCase();
      final myName = (currentUser?.fullName ?? '').trim().toLowerCase();
      final myEmail = (currentUser?.email ?? '').trim().toLowerCase();

      list = list.where((item) {
        final id = (item['id'] ?? item['staffId'] ?? '').toString().toLowerCase();
        final name = (item['name'] ?? '').toString().trim().toLowerCase();
        final email = (item['email'] ?? '').toString().trim().toLowerCase();

        return (myId.isNotEmpty && id == myId) ||
            (myName.isNotEmpty && name == myName) ||
            (myEmail.isNotEmpty && email == myEmail);
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final email = (item['email'] ?? '').toString().toLowerCase();
        final dept = (item['department'] ?? '').toString().toLowerCase();
        final id = (item['staffId'] ?? '').toString().toLowerCase();
        return name.contains(q) ||
            email.contains(q) ||
            dept.contains(q) ||
            id.contains(q);
      }).toList();
    }

    if (!isSingleStaff) {
      if (selectedManagerFilter.value != 'All Staff' &&
          selectedManagerFilter.value != 'All Managers') {
        list = list
            .where((item) => (item['name'] ?? '').toString().trim().toLowerCase() == selectedManagerFilter.value.trim().toLowerCase())
            .toList();
      }

      if (selectedDepartmentFilter.value != 'All Departments') {
        list = list
            .where((item) =>
                (item['department'] ?? '').toString().toLowerCase() ==
                selectedDepartmentFilter.value.toLowerCase())
            .toList();
      }
    }

    return list;
  }

  List<Map<String, dynamic>> get filteredStaffOrders {
    var list = List<Map<String, dynamic>>.from(ordersList);

    if (isSingleStaff) {
      final myId = (currentUser?.id ?? '').toLowerCase();
      final myName = (currentUser?.fullName ?? '').trim().toLowerCase();

      list = list.where((item) {
        final sId = (item['staffId'] ?? '').toString().toLowerCase();
        final staffName = (item['staffName'] ?? '').toString().trim().toLowerCase();

        return (myId.isNotEmpty && sId == myId) ||
            (myName.isNotEmpty && staffName == myName);
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((item) {
        final client = (item['clientName'] ?? '').toString().toLowerCase();
        final phone = (item['clientPhone'] ?? '').toString().toLowerCase();
        final plan = (item['packageName'] ?? '').toString().toLowerCase();
        final staff = (item['staffName'] ?? '').toString().toLowerCase();
        final orderId = (item['orderId'] ?? '').toString().toLowerCase();
        return client.contains(q) ||
            phone.contains(q) ||
            plan.contains(q) ||
            staff.contains(q) ||
            orderId.contains(q);
      }).toList();
    }

    if (!isSingleStaff) {
      if (selectedManagerFilter.value != 'All Staff' &&
          selectedManagerFilter.value != 'All Managers') {
        list = list
            .where((item) => (item['staffName'] ?? '').toString().trim().toLowerCase() == selectedManagerFilter.value.trim().toLowerCase())
            .toList();
      }

      if (selectedDepartmentFilter.value != 'All Departments') {
        list = list
            .where((item) =>
                (item['department'] ?? '').toString().toLowerCase() ==
                selectedDepartmentFilter.value.toLowerCase())
            .toList();
      }
    }

    if (selectedRenewalStatus.value != 'All') {
      final filterStatus = selectedRenewalStatus.value.toLowerCase();
      list = list.where((item) {
        return (item['status'] ?? '').toString().toLowerCase() == filterStatus;
      }).toList();
    }

    if (startDate.value != null || endDate.value != null) {
      final start = startDate.value != null
          ? DateTime(startDate.value!.year, startDate.value!.month, startDate.value!.day, 0, 0, 0)
          : null;
      final end = endDate.value != null
          ? DateTime(endDate.value!.year, endDate.value!.month, endDate.value!.day, 23, 59, 59, 999)
          : null;

      list = list.where((item) {
        final dateStr = item['createdAt'];
        if (dateStr == null || dateStr == '-') return false;

        DateTime? date;
        try {
          date = DateTime.tryParse(dateStr.toString());
        } catch (e) {
          return false;
        }

        if (date == null) return false;
        date = date.toLocal();

        if (start != null && date.isBefore(start)) {
          return false;
        }
        if (end != null && date.isAfter(end)) {
          return false;
        }
        return true;
      }).toList();
    } else if (selectedCustomDate.value != null) {
      final target = selectedCustomDate.value!;
      final targetDay = DateTime(target.year, target.month, target.day);

      list = list.where((item) {
        final dateStr = item['createdAt'];
        if (dateStr == null || dateStr == '-') return false;

        DateTime? date;
        try {
          date = DateTime.tryParse(dateStr.toString());
        } catch (e) {
          return false;
        }

        if (date == null) return false;
        date = date.toLocal();
        final orderDay = DateTime(date.year, date.month, date.day);
        return orderDay.isAtSameMomentAs(targetDay);
      }).toList();
    } else if (selectedDateFilter.value != 'All Time') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      list = list.where((item) {
        final dateStr = item['createdAt'];
        if (dateStr == null || dateStr == '-') return false;

        DateTime? date;
        try {
          date = DateTime.tryParse(dateStr.toString());
        } catch (e) {
          return false;
        }

        if (date == null) return false;
        date = date.toLocal();
        final orderDay = DateTime(date.year, date.month, date.day);

        if (selectedDateFilter.value == 'Today') {
          return orderDay.isAtSameMomentAs(today);
        } else if (selectedDateFilter.value == 'This Week') {
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          return !orderDay.isBefore(startOfWeek) && orderDay.isBefore(endOfWeek);
        } else if (selectedDateFilter.value == 'This Month') {
          return orderDay.year == today.year && orderDay.month == today.month;
        }
        return true;
      }).toList();
    }

    return list;
  }

  Map<String, dynamic> get dashboardStats =>
      _dashboardManagementController.dashboardStats;
  List<Map<String, dynamic>> get recentPayments =>
      _dashboardManagementController.recentPayments;
  bool get isLoading => _dashboardManagementController.isLoading.value;

  void applyFilters() {
    update();
  }

  void resetFilters() {
    _isFilterSyncing = true;
    try {
      selectedRenewalStatus.value = 'All';
      selectedDateFilter.value = 'All Time';
      selectedCustomDate.value = null;
      startDate.value = null;
      endDate.value = null;
      searchQuery.value = '';
      activeTab.value = 0;
      if (isSingleStaff) {
        final myName = currentUser?.fullName.trim();
        selectedManagerFilter.value =
            (myName != null && myName.isNotEmpty) ? myName : 'My Profile';
        final myDept = (currentUser?.departmentName ?? '').trim();
        selectedDepartmentFilter.value = (myDept.isNotEmpty && myDept != 'N/A')
            ? myDept
            : (departmentFilterItems.length > 1
                ? departmentFilterItems[1]
                : 'All Departments');
      } else {
        selectedManagerFilter.value = 'All Staff';
        selectedDepartmentFilter.value = 'All Departments';
      }
    } finally {
      _isFilterSyncing = false;
    }
    // Force a fresh data fetch with no filters applied
    fetchFilteredData(force: true);
  }

  void refreshData() {
    _dashboardManagementController.fetchDashboardData(force: true);
  }
}
