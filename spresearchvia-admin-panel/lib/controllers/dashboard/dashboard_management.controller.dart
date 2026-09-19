import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/dashboard.service.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';

class DashboardManagementController extends GetxController {
  final DashboardService _dashboardService = Get.find<DashboardService>();
  final StaffService _staffService = Get.find<StaffService>();

  var dashboardStats = <String, dynamic>{}.obs;
  var renewalsList = <Map<String, dynamic>>[].obs;
  var recentPayments = <Map<String, dynamic>>[].obs;
  var staffList = <StaffModel>[].obs;
  var staffPerformanceList = <Map<String, dynamic>>[].obs;
  var ordersList = <Map<String, dynamic>>[].obs;
  var totalSalesAmount = 0.0.obs;
  var totalOrders = 0.obs;
  var activeStaffCount = 0.obs;
  var avgOrderValue = 0.0.obs;
  var conversionRate = 0.obs;
  var topPerformingStaff = Rxn<Map<String, dynamic>>();
  var departmentSales = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  DateTime? _lastFetchTime;
  static const Duration _fetchThreshold = Duration(seconds: 30);

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData({
    bool force = false,
    Map<String, dynamic>? query,
  }) async {
    final now = DateTime.now();
    if (!force &&
        query == null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _fetchThreshold &&
        dashboardStats.isNotEmpty) {
      debugPrint(
        'DashboardManagementController: Skipping fetch, data is fresh.',
      );
      return;
    }

    if (isLoading.value && !force) {
      debugPrint(
        'DashboardManagementController: Fetch already in progress, skipping duplicate.',
      );
      return;
    }

    isLoading.value = true;
    _lastFetchTime = now;
    try {
      final stats = await _dashboardService.getDashboardStats(
        query: query,
        forceRefresh: force || query != null,
      );
      debugPrint('Controller received stats: $stats');
      dashboardStats.value = stats;

      totalSalesAmount.value = (stats['totalSalesAmount'] ?? 0).toDouble();
      totalOrders.value = (stats['totalOrders'] ?? 0) as int;
      activeStaffCount.value = (stats['activeStaffCount'] ?? 0) as int;
      avgOrderValue.value = (stats['avgOrderValue'] ?? 0).toDouble();
      conversionRate.value = (stats['conversionRate'] ?? 0) as int;
      topPerformingStaff.value = stats['topPerformingStaff'] != null
          ? Map<String, dynamic>.from(stats['topPerformingStaff'])
          : null;
      departmentSales.value = List<Map<String, dynamic>>.from(
        stats['departmentSales'] ?? [],
      );
      staffPerformanceList.value = List<Map<String, dynamic>>.from(
        stats['staffPerformanceList'] ?? [],
      );
      ordersList.value = List<Map<String, dynamic>>.from(
        stats['ordersList'] ?? [],
      );

      if (staffList.isEmpty || query == null) {
        final renewals = await _dashboardService.getRenewalsList();
        renewalsList.value = renewals;

        final payments = await _dashboardService.getRecentPayments();
        recentPayments.value = payments;

        final staff = await _staffService.getStaffList();
        if (Get.isRegistered<AuthController>()) {
          final auth = Get.find<AuthController>();
          final user = auth.user.value;
          if (user != null && !user.isAdmin) {
            if (staff.isNotEmpty) {
              staffList.value = staff;
            } else {
              staffList.value = [
                StaffModel(
                  id: user.id,
                  staffId: user.userId ?? user.id,
                  name: user.fullName,
                  email: user.email,
                  mobile: user.mobile,
                  role: user.subscriptionPlan,
                  status: 'Active',
                  department: user.subscriptionPlan,
                )
              ];
            }
          } else {
            staffList.value = staff;
          }
        } else {
          staffList.value = staff;
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      isLoading.value = false;
      debugPrint('Loading complete. Final stats: $dashboardStats');
    }
  }

  Future<bool> assignManager(String userId, String staffId) async {
    final success = await _staffService.assignStaff(userId, staffId);
    if (success) {
      // Refresh renewals list to show updated manager
      final renewals = await _dashboardService.getRenewalsList();
      renewalsList.value = renewals;
      Get.snackbar('Success', 'Manager assigned successfully');
    } else {
      Get.snackbar('Error', 'Failed to assign manager');
    }
    return success;
  }
}
