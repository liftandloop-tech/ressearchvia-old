import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/applicant.service.dart';
import '../../services/role_permission.service.dart';
import '../../services/staff.service.dart';
import '../../models/staff.model.dart';
import '../../models/role.model.dart';
import '../staff/staff.controller.dart';
import '../staff/staff_management.controller.dart';

class ApplicantsListController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());
  final RolePermissionService _roleService = Get.put(RolePermissionService());
  final StaffService _staffService = Get.put(StaffService());

  var isLoading = false.obs;
  var applicants = <StaffModel>[].obs;

  var rolesList = <RoleModel>[].obs;
  var supervisorsList = <StaffModel>[].obs;

  // Dialog fields
  final mpinController = TextEditingController();
  final joiningDateController = TextEditingController();
  var selectedRoleId = RxnString();
  var selectedRole = ''.obs;
  var selectedDepartment = ''.obs;
  var selectedSupervisorId = RxnString();
  var selectedSupervisorName = RxnString();
  var isViewOnly = false.obs;

  List<RoleModel> get availableRoles {
    final rawList = rolesList.isNotEmpty
        ? rolesList
        : (Get.isRegistered<StaffController>()
            ? Get.find<StaffController>().availableRoles
            : <RoleModel>[]);
    final seen = <String>{};
    return rawList.where((r) => r.id.isNotEmpty && seen.add(r.id)).toList();
  }

  List<StaffModel> get availableSupervisors {
    final rawList = supervisorsList.isNotEmpty
        ? supervisorsList
        : (Get.isRegistered<StaffController>()
            ? Get.find<StaffController>().staffList
            : <StaffModel>[]);
    final seen = <String>{};
    return rawList
        .where((s) =>
            s.status.toLowerCase() == 'active' &&
            s.id.isNotEmpty &&
            seen.add(s.id))
        .toList();
  }

  void updateRole(String roleId) {
    selectedRoleId.value = roleId;
    final match = availableRoles.firstWhereOrNull((r) => r.id == roleId);
    if (match != null) {
      selectedRole.value = match.name;
      selectedDepartment.value = match.departmentName ?? '';
    }
  }

  void updateSupervisor(String? supervisorId) {
    if (supervisorId == null) {
      selectedSupervisorId.value = null;
      selectedSupervisorName.value = null;
      return;
    }
    selectedSupervisorId.value = supervisorId;
    if (supervisorId == 'admin') {
      selectedSupervisorName.value = 'Admin';
    } else {
      final match = availableSupervisors.firstWhereOrNull((s) => s.id == supervisorId);
      selectedSupervisorName.value = match?.name;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchApplicants();
    fetchRolesAndSupervisors();
  }

  Future<void> fetchRolesAndSupervisors() async {
    try {
      final roleRes = await _roleService.getRoles();
      if (!roleRes.status.hasError && roleRes.body != null) {
        final list = (roleRes.body['data'] as List? ?? [])
            .map((item) => RoleModel.fromJson(item))
            .toList();
        rolesList.assignAll(list);
      }

      final staffList = await _staffService.getStaffList();
      if (staffList.isNotEmpty) {
        final list = staffList
            .where((s) => s.status.toLowerCase() == 'active')
            .toList();
        supervisorsList.assignAll(list);
      }
    } catch (e) {
      debugPrint('Failed to load roles and supervisors in applicants list: $e');
    }
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
    if (!hasRole) {
      Get.snackbar('Alert', 'Please select a role for the new staff member', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    final hasSupervisor = (selectedSupervisorId.value != null && selectedSupervisorId.value!.isNotEmpty) ||
        (selectedSupervisorName.value != null && selectedSupervisorName.value!.isNotEmpty);
    if (!hasSupervisor) {
      Get.snackbar('Alert', 'Please select a Reporting Supervisor for the new staff member', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    final mpin = mpinController.text.trim();
    if (mpin.isEmpty || mpin.length != 4 || int.tryParse(mpin) == null) {
      Get.snackbar('Alert', 'Please enter a valid 4-digit MPIN', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final isDirectAdmin = selectedSupervisorId.value == 'admin';
      final data = {
        if (selectedRoleId.value != null && selectedRoleId.value!.isNotEmpty)
          'roleId': selectedRoleId.value,
        'role': selectedRole.value,
        if (selectedDepartment.value.isNotEmpty)
          'deparment': selectedDepartment.value,
        'mpin': mpin,
        'isViewOnly': isViewOnly.value,
        'joiningDate': joiningDateController.text.trim().isEmpty ? null : joiningDateController.text.trim(),
        'assignedDirector': isDirectAdmin ? 'admin' : selectedSupervisorId.value,
        'assignedDirectorName': isDirectAdmin ? 'Admin' : selectedSupervisorName.value,
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
