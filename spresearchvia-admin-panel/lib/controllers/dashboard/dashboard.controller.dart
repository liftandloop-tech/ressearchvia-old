import 'package:get/get.dart';
// Force refresh
import 'dashboard_management.controller.dart';

class DashboardController extends GetxController {
  final DashboardManagementController _dashboardManagementController =
      Get.find<DashboardManagementController>();

  var selectedRenewalStatus = 'All'.obs; // Order Status filter
  var selectedDateFilter = 'All Time'.obs;
  var selectedCustomDate = Rxn<DateTime>();
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  var selectedManagerFilter = 'All Staff'.obs;
  var selectedDepartmentFilter = 'All Departments'.obs;
  var searchQuery = ''.obs;
  var activeTab = 0.obs; // 0: Staff Performance Leaderboard, 1: Staff Orders

  @override
  void onInit() {
    super.onInit();
    debounce(
      searchQuery,
      (_) => fetchFilteredData(),
      time: const Duration(milliseconds: 350),
    );
    ever(selectedManagerFilter, (_) => fetchFilteredData());
    ever(selectedDepartmentFilter, (_) => fetchFilteredData());
    ever(startDate, (_) => fetchFilteredData());
    ever(endDate, (_) => fetchFilteredData());
    ever(selectedRenewalStatus, (_) => fetchFilteredData());
  }

  void fetchFilteredData() {
    final query = <String, dynamic>{};
    if (searchQuery.value.trim().isNotEmpty) {
      query['search'] = searchQuery.value.trim();
    }
    if (selectedManagerFilter.value != 'All Staff' &&
        selectedManagerFilter.value != 'All Managers') {
      query['staffMember'] = selectedManagerFilter.value;
    }
    if (selectedDepartmentFilter.value != 'All Departments') {
      query['department'] = selectedDepartmentFilter.value;
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
      force: true,
      query: query.isNotEmpty ? query : null,
    );
  }

  List<Map<String, dynamic>> get renewalsList =>
      _dashboardManagementController.renewalsList;

  List<Map<String, dynamic>> get filteredRenewalsList =>
      renewalsList;

  List<String> get managerFilterItems {
    final staff = _dashboardManagementController.staffList
        .map((e) => e.name)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    staff.sort();
    return ['All Staff', ...staff];
  }

  List<String> get departmentFilterItems {
    final depts = _dashboardManagementController.staffList
        .map((e) => e.department)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    depts.sort();
    return ['All Departments', ...depts];
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

    if (selectedManagerFilter.value != 'All Staff' &&
        selectedManagerFilter.value != 'All Managers') {
      list = list
          .where((item) => item['name'] == selectedManagerFilter.value)
          .toList();
    }

    if (selectedDepartmentFilter.value != 'All Departments') {
      list = list
          .where((item) =>
              (item['department'] ?? '').toString().toLowerCase() ==
              selectedDepartmentFilter.value.toLowerCase())
          .toList();
    }

    return list;
  }

  List<Map<String, dynamic>> get filteredStaffOrders {
    var list = List<Map<String, dynamic>>.from(ordersList);

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

    if (selectedManagerFilter.value != 'All Staff' &&
        selectedManagerFilter.value != 'All Managers') {
      list = list
          .where((item) => item['staffName'] == selectedManagerFilter.value)
          .toList();
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
    selectedRenewalStatus.value = 'All';
    selectedDateFilter.value = 'All Time';
    selectedCustomDate.value = null;
    startDate.value = null;
    endDate.value = null;
    selectedManagerFilter.value = 'All Staff';
    selectedDepartmentFilter.value = 'All Departments';
    searchQuery.value = '';
    _dashboardManagementController.fetchDashboardData(force: true);
  }

  void refreshData() {
    _dashboardManagementController.fetchDashboardData(force: true);
  }
}
