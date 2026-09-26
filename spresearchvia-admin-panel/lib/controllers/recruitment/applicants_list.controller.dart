import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/applicant.service.dart';
import '../../models/staff.model.dart';
import '../../models/role.model.dart';
import '../staff/staff.controller.dart';
import '../staff/staff_management.controller.dart';

class ApplicantsListController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  var isLoading = false.obs;
  var applicants = <StaffModel>[].obs;

  // Dialog fields
  final mpinController = TextEditingController();
  final joiningDateController = TextEditingController();
  var selectedRoleId = RxnString();
  var selectedRole = ''.obs;
  var selectedDepartment = ''.obs;
  var isViewOnly = false.obs;

  List<RoleModel> get availableRoles {
    if (Get.isRegistered<StaffController>()) {
      return Get.find<StaffController>().availableRoles;
    }
    return [];
  }

  void updateRole(String roleId) {
    selectedRoleId.value = roleId;
    final match = availableRoles.firstWhereOrNull((r) => r.id == roleId);
    if (match != null) {
      selectedRole.value = match.name;
      selectedDepartment.value = match.departmentName ?? '';
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    isLoading.value = true;
    try {
      final res = await _applicantService.getApplicantsList();
      if (res.error == null) {
        applicants.assignAll(res.applicants);
      } else {
        Get.snackbar('Error', res.error!, backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveApplicant(String applicantId) async {
    final hasRole = (selectedRoleId.value != null && selectedRoleId.value!.isNotEmpty) ||
        selectedRole.value.isNotEmpty;
    if (!hasRole || mpinController.text.trim().isEmpty) {
      Get.snackbar('Alert', 'Please select a role and enter an MPIN', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final data = {
        if (selectedRoleId.value != null && selectedRoleId.value!.isNotEmpty)
          'roleId': selectedRoleId.value,
        'role': selectedRole.value,
        if (selectedDepartment.value.isNotEmpty)
          'deparment': selectedDepartment.value,
        'mpin': mpinController.text.trim(),
        'isViewOnly': isViewOnly.value,
        'joiningDate': joiningDateController.text.trim().isEmpty ? null : joiningDateController.text.trim(),
      };

      final success = await _applicantService.approveApplicant(applicantId, data);
      if (success) {
        Get.back(); // close approve dialog
        fetchApplicants();
        // If staff controller is registered, refresh staff list as well
        if (Get.isRegistered<StaffController>()) {
          Get.find<StaffController>().fetchStaffList();
        }
        if (Get.isRegistered<StaffManagementController>()) {
          Get.find<StaffManagementController>().fetchStaff();
        }
        Get.snackbar('Success', 'Applicant approved and promoted to staff member', backgroundColor: Colors.green.withOpacity(0.1));
      } else {
        Get.snackbar('Error', 'Failed to approve applicant', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }
}
