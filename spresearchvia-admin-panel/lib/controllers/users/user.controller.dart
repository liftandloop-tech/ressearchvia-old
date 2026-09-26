import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/models/user.model.dart';
import 'user_management.controller.dart';

class UserController extends GetxController {
  late final UserManagementController _userManagementController;

  var filteredUsers = <UserModel>[].obs;
  var selectedUsers = <String>[].obs;

  var subscriptionStatusFilter = 'All Statuses'.obs;
  var planTypeFilter = 'All Statuses'.obs;
  var kycStatusFilter = 'All'.obs;
  var registrationDateFilter = ''.obs;
  var searchQuery = ''.obs;
  var managerFilter = 'All Managers'.obs;
  var nameFilter = ''.obs;
  var mobileFilter = ''.obs;

  var sortColumn = RxnString();
  var sortAscending = true.obs;

  final TextEditingController searchController = TextEditingController();

  // Expose isLoading from service controller
  bool get isLoading => _userManagementController.isLoading.value;

  @override
  void onInit() {
    _userManagementController = Get.find<UserManagementController>();
    super.onInit();

    // 1. Read URL Parameters
    final params = Get.parameters;
    if (params['status'] != null) {
      subscriptionStatusFilter.value = params['status']!;
    }
    if (params['plan'] != null) {
      planTypeFilter.value = params['plan']!;
    }
    if (params['kyc_status'] != null) {
      kycStatusFilter.value = params['kyc_status']!;
    }
    if (params['date'] != null) {
      registrationDateFilter.value = params['date']!;
    }
    if (params['search'] != null) {
      searchQuery.value = params['search']!;
      searchController.text = params['search']!;
    }

    // Sync search controller with query
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });

    // 2. Fetch Data based on parameters (or defaults)
    _userManagementController.fetchUsers(
      page: 1,
      status: subscriptionStatusFilter.value,
      planType: planTypeFilter.value,
      kycStatus: kycStatusFilter.value,
      date: registrationDateFilter.value,
      search: searchQuery.value,
    );

    // 3. Listen for changes
    _filterLocalUsers(_userManagementController.users);
    ever(_userManagementController.users, (users) {
      _filterLocalUsers(users);
    });

    // React to search query debounce
    debounce(searchQuery, (query) {
      _userManagementController.fetchUsers(
        page: 1,
        status: subscriptionStatusFilter.value,
        planType: planTypeFilter.value,
        kycStatus: kycStatusFilter.value,
        manager: managerFilter.value,
        date: registrationDateFilter.value,
        search: query,
      );
    }, time: const Duration(milliseconds: 500));

    // Trigger fetch on any filter change across the whole database, resetting to page 1
    everAll(
      [
        subscriptionStatusFilter,
        planTypeFilter,
        kycStatusFilter,
        registrationDateFilter,
        managerFilter,
        nameFilter,
        mobileFilter,
      ],
      (_) {
        fetchFilteredUsers(page: 1);
      },
    );
  }

  void fetchFilteredUsers({int page = 1}) {
    _userManagementController.fetchUsers(
      page: page,
      status: subscriptionStatusFilter.value,
      planType: planTypeFilter.value,
      kycStatus: kycStatusFilter.value,
      manager: managerFilter.value,
      date: registrationDateFilter.value,
      search: searchQuery.value,
      name: nameFilter.value,
      phone: mobileFilter.value,
      sortBy: sortColumn.value ?? 'createdAt',
      sortOrder: sortAscending.value ? 'asc' : 'desc',
    );
  }

  void toggleSort(String column) {
    if (sortColumn.value == column) {
      if (sortAscending.value) {
        sortAscending.value = false;
      } else {
        sortColumn.value = null;
        sortAscending.value = true;
      }
    } else {
      sortColumn.value = column;
      sortAscending.value = true;
    }
    fetchFilteredUsers(page: 1);
  }

  void _filterLocalUsers(List<UserModel> users) {
    filteredUsers.assignAll(users);
  }

  void applyFilters() {
    // Update URL to persist filters
    // This will reload the route, re-init controller, and trigger onInit -> fetch
    Get.offNamed(
      '/users',
      parameters: {
        'status': subscriptionStatusFilter.value,
        'plan': planTypeFilter.value,
        'kyc_status': kycStatusFilter.value,
        'date': registrationDateFilter.value,
        'search': searchQuery.value,
      },
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void resetFilters() {
    subscriptionStatusFilter.value = 'All Statuses';
    planTypeFilter.value = 'All Statuses';
    kycStatusFilter.value = 'All';
    registrationDateFilter.value = '';
    searchQuery.value = '';
    searchController.clear();
    _userManagementController.fetchUsers(
      page: 1,
      status: 'All Statuses',
      planType: 'All Statuses',
      kycStatus: 'All',
      date: '',
      search: '',
    );
  }

  void toggleUserSelection(String userId) {
    if (selectedUsers.contains(userId)) {
      selectedUsers.remove(userId);
    } else {
      selectedUsers.add(userId);
    }
  }

  void toggleSelectAll() {
    if (selectedUsers.length == filteredUsers.length) {
      selectedUsers.clear();
    } else {
      selectedUsers.value = filteredUsers.map((u) => u.id).toList();
    }
  }

  void exportUsers() {
    // Implement export logic using _userManagementController or local data
  }

  void sendNotification() {
    // Implement notification logic
  }

  void suspendUsers(String reason) {
    // Implement suspend logic using _userManagementController
    for (var userId in selectedUsers) {
      _userManagementController.suspendUser(userId, reason: reason);
    }
    selectedUsers.clear();
  }

  void activateUsers() {
    // Implement activate logic using _userManagementController
    for (var userId in selectedUsers) {
      _userManagementController.activateUser(userId);
    }
    selectedUsers.clear();
  }

  void updateUserManager(String userId, String newManager) {
    final userIndex = _userManagementController.users.indexWhere(
      (u) => u.id == userId,
    );
    if (userIndex != -1) {
      final user = _userManagementController.users[userIndex];
      final updatedUser = UserModel(
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        mobile: user.mobile,
        subscriptionPlan: user.subscriptionPlan,
        subscriptionStatus: user.subscriptionStatus,
        kycStatus: user.kycStatus,
        registrationDate: user.registrationDate,
        manager: newManager,
        expiryDate: user.expiryDate,
        planPrice: user.planPrice,
        startDate: user.startDate,
        registrationStatus: user.registrationStatus,
        registrationType: user.registrationType,
        registrationSource: user.registrationSource,
        planSource: user.planSource,
      );
      _userManagementController.users[userIndex] = updatedUser;
      applyFilters();
    }
  }
}
