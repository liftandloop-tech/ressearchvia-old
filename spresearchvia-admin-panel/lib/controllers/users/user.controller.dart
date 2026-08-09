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

  final TextEditingController searchController = TextEditingController();

  // Expose isLoading from service controller
  bool get isLoading => _userManagementController.isLoading.value;

  @override
  void onInit() {
    _userManagementController = Get.find<UserManagementController>();
    super.onInit();

    // 1. Read URL Parameters
    final params = Get.parameters;
    if (params['status'] != null)
      subscriptionStatusFilter.value = params['status']!;
    if (params['plan'] != null) planTypeFilter.value = params['plan']!;
    if (params['kyc_status'] != null)
      kycStatusFilter.value = params['kyc_status']!;
    if (params['date'] != null) registrationDateFilter.value = params['date']!;
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
        date: registrationDateFilter.value,
        search: query,
      );
    }, time: const Duration(milliseconds: 500));

    // Also trigger fetch on other filter changes for consistency (server-side filtering)
    // We use debounce or ever? Ever is instant. Debounce is safer if rapid changes.
    // Let's use ever but call fetchUsers to support server-side filtering for everything.
    everAll(
      [
        subscriptionStatusFilter,
        planTypeFilter,
        kycStatusFilter,
        registrationDateFilter,
      ],
      (_) {
        _userManagementController.fetchUsers(
          page: 1,
          status: subscriptionStatusFilter.value,
          planType: planTypeFilter.value,
          date: registrationDateFilter.value,
          search: searchQuery.value,
        );
      },
    );
  }

  void _filterLocalUsers(List<UserModel> users) {
    // If we just fetched from server, users list respects the search query already.
    // So we don't strictly need to filter by search query again unless we want highlighting.
    // However, if we do keep it, it's fine as long as it's consistent.
    // Since fetchUsers updates 'users', this will run.

    final filteredList = users.where((user) {
      // Local Search Filter (optional if server handles search, but good for immediate feedback if list is static)
      // Since we fetch from server on search, we can comment this out or keep it as a double-check.
      // Keeping it ensures consistency if fetch hasn't happened yet.

      bool matchesSearch = true;
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        final name = user.fullName.toLowerCase();
        final email = user.email.toLowerCase();
        final phone = user.mobile.toLowerCase();
        final pan = (user.panCard ?? '').toLowerCase();

        matchesSearch =
            name.contains(query) ||
            email.contains(query) ||
            phone.contains(query) ||
            pan.contains(query);
      }
      if (!matchesSearch) return false;

      // Status Filter
      if (subscriptionStatusFilter.value != 'All Statuses') {
        final filterStatus = subscriptionStatusFilter.value.toLowerCase();
        final userStatus = user.subscriptionStatus.toLowerCase();

        // Map UI status to backend status if needed
        // UI: Active, Expired, Cancelled
        // Backend: active, expired, failed, pending

        if (filterStatus == 'active' && userStatus != 'active') return false;
        if (filterStatus == 'expired' && userStatus != 'expired') return false;
        if (filterStatus == 'cancelled' &&
            (userStatus != 'cancelled' && userStatus != 'failed')) {
          return false;
        }
      }

      // Registration Status Filter (using planTypeFilter variable)
      if (planTypeFilter.value != 'All Statuses') {
        final registrationStatus = _getRegistrationPlanStatus(user);
        if (registrationStatus != planTypeFilter.value) return false;
      }

      // KYC Status Filter
      if (kycStatusFilter.value != 'All') {
        if (user.kycStatus.toLowerCase() !=
            kycStatusFilter.value.toLowerCase()) {
          return false;
        }
      }

      // Date Filter
      if (registrationDateFilter.value.isNotEmpty) {
        try {
          final userDate = DateTime.parse(user.registrationDate);
          final normalizedUserDate = DateTime(
            userDate.year,
            userDate.month,
            userDate.day,
          );

          // Custom date format: D/M/YYYY
          final filterParts = registrationDateFilter.value.split('/');
          if (filterParts.length == 3) {
            final filterDate = DateTime(
              int.parse(filterParts[2]), // Year
              int.parse(filterParts[1]), // Month
              int.parse(filterParts[0]), // Day
            );

            if (!normalizedUserDate.isAtSameMomentAs(filterDate)) {
              return false;
            }
          }
        } catch (e) {
          // If parsing fails, exclude this user
          return false;
        }
      }

      return true;
    }).toList();

    filteredUsers.assignAll(filteredList);
  }

  String _getRegistrationPlanStatus(UserModel user) {
    final type = user.registrationType.toLowerCase();

    // 1. Check for confirmed Silver or Gold registration
    if (type.contains('yearly')) {
      return 'Silver';
    } else if (type.contains('lifetime')) {
      return 'Gold';
    }

    // 2. Check for Pending Approval
    final paymentIntent = user.paymentIntent;

    if (paymentIntent != null) {
      final purchaseType =
          paymentIntent['purchaseType']?.toString().toLowerCase() ?? '';
      final status = paymentIntent['status']?.toString().toLowerCase() ?? '';

      if ((purchaseType == 'registration' || purchaseType == 'plan') &&
          status != 'paid') {
        return 'Pending for Approval';
      }
    }

    // 3. Default to Not Registered
    return 'Not Registered';
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
    applyFilters(); // Updates URL to clean state
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
