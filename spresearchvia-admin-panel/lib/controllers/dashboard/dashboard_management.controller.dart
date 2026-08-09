import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/dashboard.service.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/models/staff.model.dart';

class DashboardManagementController extends GetxController {
  final DashboardService _dashboardService = Get.find<DashboardService>();
  final StaffService _staffService = Get.find<StaffService>();

  var dashboardStats = <String, dynamic>{}.obs;
  var renewalsList = <Map<String, dynamic>>[].obs;
  var recentPayments = <Map<String, dynamic>>[].obs;
  var staffList = <StaffModel>[].obs;
  var isLoading = false.obs;

  DateTime? _lastFetchTime;
  static const Duration _fetchThreshold = Duration(seconds: 30);

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _fetchThreshold &&
        dashboardStats.isNotEmpty) {
      debugPrint(
        'DashboardManagementController: Skipping fetch, data is fresh.',
      );
      return;
    }

    isLoading.value = true;
    _lastFetchTime = now;
    try {
      final stats = await _dashboardService.getDashboardStats();
      debugPrint('Controller received stats: $stats');
      dashboardStats.value = stats;
      debugPrint('Controller dashboardStats after assignment: $dashboardStats');

      final renewals = await _dashboardService.getRenewalsList();
      renewalsList.value = renewals;

      final payments = await _dashboardService.getRecentPayments();
      recentPayments.value = payments;

      final staff = await _staffService.getStaffList();
      if (staff.isNotEmpty) {
        debugPrint(
          'First staff role check: ${staff.first.name} - ${staff.first.role}',
        );
      }
      staffList.value = staff;
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
