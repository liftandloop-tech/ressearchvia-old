import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  var kycStatusFilter = 'All'.obs;
  var dateFilter = ''.obs;

  var nameFilter = ''.obs;
  var phoneFilter = ''.obs;
  var sortBy = ''.obs;
  var sortOrder = ''.obs;

  static const String pageSizeKey = 'user_table_page_size';

  @override
  void onInit() {
    _userService = Get.find<UserService>();
    _staffService = Get.find<StaffService>();
    super.onInit();
    _loadPersistedPageSize();
    fetchUsers();
    fetchManagers();
  }

  void _loadPersistedPageSize() {
    try {
      if (Get.isRegistered<SharedPreferences>()) {
        final prefs = Get.find<SharedPreferences>();
        final savedSize = prefs.getInt(pageSizeKey);
        if (savedSize != null && [10, 15, 25, 50, 100].contains(savedSize)) {
          pageSize.value = savedSize;
        }
      } else {
        SharedPreferences.getInstance().then((prefs) {
          final savedSize = prefs.getInt(pageSizeKey);
          if (savedSize != null && [10, 15, 25, 50, 100].contains(savedSize)) {
            if (pageSize.value != savedSize) {
              setPageSize(savedSize);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading persisted page size: $e');
    }
  }

  Future<void> fetchManagers() async {
    try {
      final list = await _staffService.getStaffList();

      // If non-admin is logged in:
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        final currentUser = authController.user.value;
        if (currentUser != null && !currentUser.isAdmin) {
          if (currentUser.isDirector || currentUser.isManager || list.length > 1) {
            managers.value = list;
            return;
          } else {
            // Regular staff: only themselves in the manager dropdown
            final myStaff = list
                .where(
                  (s) =>
                      s.id == currentUser.id || s.name == currentUser.fullName,
                )
                .toList();
            managers.value = myStaff.isNotEmpty
                ? myStaff
                : [
                    StaffModel(
                      id: currentUser.id,
                      staffId: currentUser.userId ?? currentUser.id,
                      name: currentUser.fullName,
                      email: currentUser.email,
                      mobile: currentUser.mobile,
                      role: currentUser.subscriptionPlan,
                      status: 'Active',
                      department: currentUser.subscriptionPlan,
                    ),
                  ];
            managerFilter.value = currentUser.fullName;
            return;
          }
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
    int? pageSize,
    String? search,
    String? status,
    String? manager,
    String? planType,
    String? kycStatus,
    String? date,
    String? name,
    String? phone,
    String? sortBy,
    String? sortOrder,
  }) async {
    if (page != null) currentPage.value = page;
    if (pageSize != null) this.pageSize.value = pageSize;
    if (search != null) searchQuery.value = search;
    if (status != null) statusFilter.value = status;
    if (manager != null) managerFilter.value = manager;
    if (planType != null) planTypeFilter.value = planType;
    if (kycStatus != null) kycStatusFilter.value = kycStatus;
    if (date != null) dateFilter.value = date;
    if (name != null) nameFilter.value = name;
    if (phone != null) phoneFilter.value = phone;
    if (sortBy != null) this.sortBy.value = sortBy;
    if (sortOrder != null) this.sortOrder.value = sortOrder;

    isLoading.value = true;
    try {
      final result = await _userService.getUsers(
        page: currentPage.value,
        pageSize: this.pageSize.value,
        search: searchQuery.value,
        status: statusFilter.value,
        manager: managerFilter.value,
        planType: planTypeFilter.value,
        kycStatus: kycStatusFilter.value,
        date: dateFilter.value,
        name: nameFilter.value,
        phone: phoneFilter.value,
        sortBy: this.sortBy.value,
        sortOrder: this.sortOrder.value,
      );
      users.assignAll(result.users);
      totalCount.value = result.totalCount;
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setPageSize(int size) {
    pageSize.value = size;
    try {
      if (Get.isRegistered<SharedPreferences>()) {
        Get.find<SharedPreferences>().setInt(pageSizeKey, size);
      } else {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(pageSizeKey, size);
        });
      }
    } catch (e) {
      debugPrint('Error saving page size: $e');
    }
    fetchUsers(page: 1, pageSize: size);
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
