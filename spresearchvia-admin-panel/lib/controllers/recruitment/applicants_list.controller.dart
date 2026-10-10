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
  var selectedStage = 'ALL'.obs;
  var searchQuery = ''.obs;

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

  final stageFilters = const [
    {'key': 'ALL', 'label': 'All Applicants'},
    {'key': 'APPLIED', 'label': 'Applied'},
    {'key': 'SCREENING', 'label': 'Screening'},
    {'key': 'SHORTLISTED', 'label': 'Shortlisted'},
    {'key': 'INTERVIEW', 'label': 'Interview'},
    {'key': 'SELECTED', 'label': 'Selected'},
    {'key': 'OFFER_SENT', 'label': 'Offer Sent'},
    {'key': 'PROMOTED', 'label': 'Promoted'},
    {'key': 'REJECTED', 'label': 'Rejected'},
  ];

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

    debounce(
      searchQuery,
      (_) => fetchApplicants(),
      time: const Duration(milliseconds: 350),
    );
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

  void setStageFilter(String stage) {
    if (selectedStage.value == stage) return;
    selectedStage.value = stage;
    fetchApplicants();
  }

  Future<void> fetchApplicants() async {
    isLoading.value = true;
    try {
      final res = await _applicantService.getApplicantsList(
        stage: selectedStage.value,
        search: searchQuery.value,
      );
      if (res.error == null) {
        applicants.assignAll(res.applicants);
      } else {
        Get.snackbar('Error', res.error!, backgroundColor: Colors.red.withValues(alpha: 0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> promoteApplicant(String applicantId, {String? note}) async {
    isLoading.value = true;
    try {
      final success = await _applicantService.promoteApplicant(applicantId, note: note);
      if (success) {
        fetchApplicants();
        if (Get.isRegistered<StaffController>()) {
          Get.find<StaffController>().fetchStaffList();
        }
        if (Get.isRegistered<StaffManagementController>()) {
          Get.find<StaffManagementController>().fetchStaff();
        }
        Get.snackbar(
          'Candidate Promoted',
          'Applicant has been promoted to Staff. Configure Role, Supervisor, and MPIN from the Staff page.',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar('Promotion Failed', 'Failed to promote applicant to staff', backgroundColor: Colors.red.withValues(alpha: 0.15));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectApplicant(String applicantId, {String? reason}) async {
    isLoading.value = true;
    try {
      final success = await _applicantService.rejectApplicant(applicantId, reason: reason);
      if (success) {
        fetchApplicants();
        Get.snackbar('Candidate Rejected', 'Applicant marked as rejected', backgroundColor: Colors.red.withValues(alpha: 0.15));
      } else {
        Get.snackbar('Error', 'Failed to reject applicant', backgroundColor: Colors.red.withValues(alpha: 0.15));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateApplicantStage(String applicantId, String stage, {String? note}) async {
    isLoading.value = true;
    try {
      final success = await _applicantService.updateApplicantStage(applicantId, stage, note: note);
      if (success) {
        fetchApplicants();
        Get.snackbar('Stage Updated', 'Applicant moved to $stage', backgroundColor: Colors.blue.withValues(alpha: 0.15));
      } else {
        Get.snackbar('Error', 'Failed to update stage', backgroundColor: Colors.red.withValues(alpha: 0.15));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveApplicant(String applicantId) async {
    await promoteApplicant(applicantId);
  }
}
