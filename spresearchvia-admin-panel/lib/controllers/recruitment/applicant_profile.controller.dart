import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/applicant.service.dart';
import '../../services/staff.service.dart';
import '../../services/role_permission.service.dart';
import '../../models/staff.model.dart';
import '../../models/role.model.dart';
import '../staff/staff.controller.dart';
import '../staff/staff_management.controller.dart';

class ApplicantProfileController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());
  final StaffService _staffService = Get.put(StaffService());
  final RolePermissionService _rolePermissionService = Get.put(RolePermissionService());

  var isLoading = false.obs;
  var applicantId = ''.obs;
  var applicant = Rxn<StaffModel>();

  // OTP field controllers
  final mobileOtpController = TextEditingController();
  final emailOtpController = TextEditingController();

  // Roles & Supervisors lists
  var rolesList = <RoleModel>[].obs;
  var supervisorsList = <StaffModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    applicantId.value = Get.parameters['id'] ?? '';
    if (applicantId.value.isNotEmpty) {
      fetchDetails();
    }
    fetchRolesAndSupervisors();
  }

  Future<void> fetchRolesAndSupervisors() async {
    try {
      final roleRes = await _rolePermissionService.getRoles();
      if (!roleRes.status.hasError && roleRes.body != null) {
        final list = (roleRes.body['data'] as List? ?? [])
            .map((item) => RoleModel.fromJson(item))
            .toList();
        rolesList.assignAll(list);
      }

      final staffList = await _staffService.getStaffList();
      if (staffList.isNotEmpty) {
        final list = staffList
            .where((s) => s.status.toLowerCase() == 'active' && s.id != applicantId.value)
            .toList();
        supervisorsList.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error fetching roles and supervisors in applicant profile: $e');
    }
  }

  Future<void> fetchDetails() async {
    isLoading.value = true;
    try {
      final res = await _applicantService.getApplicantDetails(applicantId.value);
      if (res.error == null) {
        applicant.value = res.applicant;
      } else {
        Get.snackbar('Error', res.error!, backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtps() async {
    if (mobileOtpController.text.trim().isEmpty || emailOtpController.text.trim().isEmpty) {
      Get.snackbar('Alert', 'Please enter both OTPs', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.verifyOtp(
        applicantId.value,
        mobileOtpController.text.trim(),
        emailOtpController.text.trim(),
      );

      if (res.success) {
        fetchDetails();
        Get.snackbar('Success', 'Verification complete', backgroundColor: Colors.green.withOpacity(0.1));
      } else {
        Get.snackbar('Verification Failed', res.message ?? 'Invalid OTPs', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadDoc(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: type == 'video' ? ['mp4', 'mov', 'avi'] : ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        isLoading.value = true;
        final res = type == 'video'
            ? await _applicantService.uploadApplicantVideo(applicantId.value, result.files.single.bytes!, result.files.single.name)
            : await _applicantService.uploadApplicantFile(applicantId.value, type, result.files.single.bytes!, result.files.single.name);

        isLoading.value = false;
        if (res.success) {
          fetchDetails();
          Get.snackbar('Upload Success', '${type.toUpperCase()} file uploaded', backgroundColor: Colors.green.withOpacity(0.1));
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'An error occurred', backgroundColor: Colors.red.withOpacity(0.1));
        }
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to upload document: $e', backgroundColor: Colors.red.withOpacity(0.1));
    }
  }

  // Approval Controllers and Methods
  final selectedRoleId = RxnString();
  final selectedRole = ''.obs;
  final selectedDepartment = ''.obs;
  final selectedSupervisorId = RxnString();
  final selectedSupervisorName = RxnString();
  final mpinController = TextEditingController();
  final joiningDateController = TextEditingController();
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
            s.id != applicantId.value &&
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

  Future<bool> approveApplicant() async {
    final hasRole = (selectedRoleId.value != null && selectedRoleId.value!.isNotEmpty) ||
        selectedRole.value.isNotEmpty;
    if (!hasRole) {
      Get.snackbar('Validation Alert', 'Please select a Role for the new staff member', backgroundColor: Colors.orange.withOpacity(0.1));
      return false;
    }

    final hasSupervisor = selectedSupervisorId.value != null && selectedSupervisorId.value!.isNotEmpty;
    if (!hasSupervisor) {
      Get.snackbar('Validation Alert', 'Please select who this staff member will report to', backgroundColor: Colors.orange.withOpacity(0.1));
      return false;
    }

    final mpin = mpinController.text.trim();
    if (mpin.isEmpty || mpin.length != 4) {
      Get.snackbar('Validation Alert', 'Please enter a valid 4-digit MPIN', backgroundColor: Colors.orange.withOpacity(0.1));
      return false;
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
        'assignedDirector': isDirectAdmin ? 'admin' : selectedSupervisorId.value,
        'assignedDirectorName': isDirectAdmin ? 'Admin' : selectedSupervisorName.value,
        'isViewOnly': isViewOnly.value,
        'joiningDate': joiningDateController.text.trim().isEmpty ? null : joiningDateController.text.trim(),
      };

      final success = await _applicantService.approveApplicant(applicantId.value, data);
      if (success) {
        await fetchDetails();
        if (Get.isRegistered<StaffController>()) {
          Get.find<StaffController>().fetchStaffList();
        }
        if (Get.isRegistered<StaffManagementController>()) {
          Get.find<StaffManagementController>().fetchStaff();
        }
        Get.snackbar('Success', 'Applicant approved and promoted to staff member', backgroundColor: Colors.green.withOpacity(0.1));
        return true;
      } else {
        Get.snackbar('Error', 'Failed to approve applicant', backgroundColor: Colors.red.withOpacity(0.1));
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }
}

