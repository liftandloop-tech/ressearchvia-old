import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/user.service.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/models/user.model.dart';
import 'package:spresearch_web/models/staff.model.dart';

class UserManagementController extends GetxController {
  late final UserService _userService;
  late final StaffService _staffService;

  var users = <UserModel>[].obs;
  var managers = <StaffModel>[].obs;
  var isLoading = false.obs;
  var totalCount = 0.obs;
  var currentPage = 1.obs;
  var pageSize = 15.obs;
  var searchQuery = ''.obs;
  var statusFilter = 'All Statuses'.obs;
  var managerFilter = 'All Managers'.obs;
  var planTypeFilter = 'All Plans'.obs;
  var dateFilter = ''.obs;

  @override
  void onInit() {
    _userService = Get.find<UserService>();
    _staffService = Get.find<StaffService>();
    super.onInit();
    fetchUsers();
    fetchManagers();
  }

  Future<void> fetchManagers() async {
    try {
      final list = await _staffService.getStaffList();

      // If a Director is logged in, show their managers or unassigned managers/staff
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        final currentUser = authController.user.value;
        if (currentUser != null && currentUser.isDirector) {
          managers.value = list
              .where(
                (s) =>
                    s.department.trim().toLowerCase().contains('manager') &&
                    (s.assignedDirector == currentUser.id || s.assignedDirector == null || s.assignedDirector!.isEmpty),
              )
              .toList();
          if (managers.isEmpty) {
            managers.value = list;
          }
          return;
        }
      }

      managers.value = list;
    } catch (e) {
      debugPrint('Error fetching managers: $e');
    }
  }

  Future<bool> assignManager(String userId, String staffId) async {
    try {
      final success = await _staffService.assignStaff(userId, staffId);
      if (success) {
        // Refresh users to get updated manager name
        fetchUsers();
      }
      return success;
    } catch (e) {
      debugPrint('Error assigning manager: $e');
      return false;
    }
  }

  Future<void> fetchUsers({
    int? page,
    String? search,
    String? status,
    String? manager,
    String? planType,
    String? date,
  }) async {
    if (page != null) currentPage.value = page;
    if (search != null) searchQuery.value = search;
    if (status != null) statusFilter.value = status;
    if (manager != null) managerFilter.value = manager;
    if (planType != null) planTypeFilter.value = planType;
    if (date != null) dateFilter.value = date;

    isLoading.value = true;
    try {
      final result = await _userService.getUsers(
        page: currentPage.value,
        pageSize: pageSize.value,
        search: searchQuery.value,
        status: statusFilter.value,
        manager: managerFilter.value,
        planType: planTypeFilter.value,
        date: dateFilter.value,
      );
      users.assignAll(result.users);
      totalCount.value = result.totalCount;
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final success = await _userService.updateUser(userId, data);
      if (success) {
        // Option 1: Refetch all (Easiest)
        await fetchUsers();

        // Option 2: Local patch (More complex with Map)
        /*
        final index = users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          // Creates a new model with updated fields... complicated to map Map to Model dynamically without copyWith
          // users[index] = users[index].copyWith(...); 
        }
        */
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> suspendUser(String userId, {String? reason}) async {
    try {
      final success = await _userService.suspendUser(userId, reason: reason);
      if (success) {
        Get.snackbar(
          'Success',
          'User account suspended successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Update local state
        await fetchUsers();
      } else {
        Get.snackbar(
          'Error',
          'Failed to suspend user account',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      final success = await _userService.activateUser(userId);
      if (success) {
        Get.snackbar(
          'Success',
          'User account activated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchUsers();
      } else {
        Get.snackbar(
          'Error',
          'Failed to activate user account',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    return await suspendUser(userId);
  }
}
