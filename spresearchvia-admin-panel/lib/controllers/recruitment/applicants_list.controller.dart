import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/applicant.service.dart';
import '../../services/role_permission.service.dart';
import '../../services/staff.service.dart';
import '../../models/staff.model.dart';
import '../../models/role.model.dart';
import '../staff/staff.controller.dart';
import '../staff/staff_management.controller.dart';
import '../auth/auth.controller.dart';

class ApplicantsListController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());
  final RolePermissionService _roleService = Get.put(RolePermissionService());
  final StaffService _staffService = Get.put(StaffService());

  var isLoading = false.obs;
  var applicants = <StaffModel>[].obs;
  var selectedStage = 'ALL'.obs;
  var searchQuery = ''.obs;
  var selectedStaffFilter = RxnString();

  // Column-level filters
  var filterCandidate = ''.obs;
  var filterRole = <String>[].obs;
  var filterContact = ''.obs;
  var filterStatus = <String>[].obs;
  var filterStage = <String>[].obs;
  var filterStaff = <String>[].obs;

  List<String> get availableRoleFilterOptions {
    final set = <String>{};
    for (var r in availableRoles) {
      if (r.name.trim().isNotEmpty) set.add(r.name.trim());
    }
    for (var a in applicants) {
      if (a.role.isNotEmpty && a.role.toLowerCase() != 'applicant' && a.role.toLowerCase() != 'staff') {
        set.add(a.role.trim());
      }
      final rawTarget = a.rawJson?['targetRole']?.toString() ??
          a.rawJson?['walkInForm']?['appliedPosition']?.toString() ??
          a.rawJson?['appliedPosition']?.toString();
      if (rawTarget != null && rawTarget.trim().isNotEmpty && rawTarget.toLowerCase() != 'staff' && rawTarget.toLowerCase() != 'applicant') {
        set.add(rawTarget.trim());
      }
    }
    if (set.isEmpty) {
      set.addAll([
        'Business Development executive',
        'Floor Manager',
        'Team Leader',
        'Director',
      ]);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get availableStaffFilterOptions {
    final list = <String>['Unassigned'];
    final seen = <String>{};
    for (var s in availableSupervisors) {
      final name = s.name.trim().isNotEmpty ? s.name.trim() : s.email.trim();
      if (name.isNotEmpty && seen.add(name)) {
        list.add(name);
      }
    }
    for (var a in applicants) {
      final staffName = a.assignedStaffName?.trim();
      if (staffName != null && staffName.isNotEmpty && seen.add(staffName)) {
        list.add(staffName);
      }
    }
    return list;
  }

  List<String> get availableStatusFilterOptions {
    return const ['Submitted', 'Pending', 'Not Started'];
  }

  List<String> get availableStageFilterOptions {
    return const [
      'Applied',
      'Screening',
      'Shortlisted',
      'Interview',
      'Selected',
      'Offer Sent',
      'Promoted',
      'Rejected',
    ];
  }

  List<StaffModel> get filteredApplicants {
    var list = applicants.toList();

    // 1. Stage filter pills at the top
    final stage = selectedStage.value.toUpperCase();
    if (stage.isNotEmpty && stage != 'ALL') {
      list = list.where((a) => a.stage.toUpperCase() == stage).toList();
    }

    // 2. Staff filter dropdown at the top
    final staff = selectedStaffFilter.value;
    if (staff != null && staff != 'ALL') {
      if (staff == 'UNASSIGNED') {
        list = list.where((a) => a.assignedStaffName == null || a.assignedStaffName!.trim().isEmpty).toList();
      } else {
        list = list.where((a) => a.assignedStaffId == staff || a.assignedRecruiterId == staff).toList();
      }
    }

    // 3. Search query at the top
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((a) {
        return a.name.toLowerCase().contains(q) ||
            a.email.toLowerCase().contains(q) ||
            a.mobile.toLowerCase().contains(q) ||
            a.role.toLowerCase().contains(q) ||
            (a.targetRole?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 4. Candidate Column Filter (name search)
    if (filterCandidate.value.trim().isNotEmpty) {
      final cQuery = filterCandidate.value.trim().toLowerCase();
      list = list.where((a) => a.name.toLowerCase().contains(cQuery)).toList();
    }

    // 5. Applied Role Column Filter (multi-select)
    if (filterRole.isNotEmpty) {
      final selectedRolesLower = filterRole.map((r) => r.toLowerCase()).toSet();
      list = list.where((a) {
        final r1 = a.role.toLowerCase();
        final r2 = a.targetRole?.toLowerCase() ?? '';
        final r3 = a.rawJson?['targetRole']?.toString().toLowerCase() ?? '';
        final r4 = a.rawJson?['walkInForm']?['appliedPosition']?.toString().toLowerCase() ?? '';
        final r5 = a.rawJson?['appliedPosition']?.toString().toLowerCase() ?? '';
        return selectedRolesLower.contains(r1) ||
            selectedRolesLower.contains(r2) ||
            selectedRolesLower.contains(r3) ||
            selectedRolesLower.contains(r4) ||
            selectedRolesLower.contains(r5);
      }).toList();
    }

    // 6. Contact Details Column Filter (email or mobile)
    if (filterContact.value.trim().isNotEmpty) {
      final contactQuery = filterContact.value.trim().toLowerCase();
      list = list.where((a) =>
        a.email.toLowerCase().contains(contactQuery) ||
        a.mobile.toLowerCase().contains(contactQuery)
      ).toList();
    }

    // 7. Status Column Filter (Submitted, Pending, Not Started)
    if (filterStatus.isNotEmpty) {
      final selectedStatusesUpper = filterStatus.map((s) => s.toUpperCase()).toSet();
      list = list.where((applicant) {
        final raw = applicant.rawJson ?? {};
        final aStage = applicant.stage.toUpperCase();
        final isPromoted = aStage == 'PROMOTED' ||
            aStage == 'OFFER_ACCEPTED' ||
            aStage == 'EMPLOYEE' ||
            applicant.rawJson?['convertedToStaffId'] != null ||
            applicant.rawJson?['convertedStaffId'] != null;
        final isDraft = raw['isDraft'] == true;
        final currentStep = raw['currentStep'] is int
            ? raw['currentStep'] as int
            : (int.tryParse(raw['currentStep']?.toString() ?? '1') ?? 1);
        final hasFilledStep1 = currentStep >= 2 ||
            (raw['firstName'] != null && raw['firstName'].toString().trim().isNotEmpty) ||
            (raw['fatherName'] != null && raw['fatherName'].toString().trim().isNotEmpty) ||
            (raw['currentLocation'] != null && raw['currentLocation'].toString().trim().isNotEmpty) ||
            (applicant.name.trim().isNotEmpty &&
                applicant.name.trim().toLowerCase() != 'candidate' &&
                applicant.name.trim() != '—');
        final isFormSubmitted = !isDraft ||
            raw['isVerified'] == true ||
            applicant.onboardingStatus == 'COMPLETED' ||
            applicant.onboardingStatus == 'VERIFIED' ||
            applicant.onboardingStatus == 'DOCUMENTS_UPLOADED' ||
            applicant.onboardingStatus == 'SUBMITTED' ||
            isPromoted ||
            (aStage != 'APPLIED' && aStage != 'SCREENING');

        String st = 'NOT STARTED';
        if (isFormSubmitted && hasFilledStep1) {
          st = 'SUBMITTED';
        } else if (hasFilledStep1) {
          st = 'PENDING';
        }
        return selectedStatusesUpper.contains(st);
      }).toList();
    }

    // 8. Pipeline Stage Column Filter
    if (filterStage.isNotEmpty) {
      final selectedStagesUpper = filterStage.map((s) => s.toUpperCase().replaceAll(' ', '_')).toSet();
      list = list.where((a) {
        final aStage = a.stage.toUpperCase();
        return selectedStagesUpper.contains(aStage);
      }).toList();
    }

    // 9. Assigned Staff Column Filter
    if (filterStaff.isNotEmpty) {
      final selectedStaffNamesLower = filterStaff.map((s) => s.toLowerCase()).toSet();
      final includesUnassigned = selectedStaffNamesLower.contains('unassigned');
      list = list.where((a) {
        final staffName = a.assignedStaffName?.trim().toLowerCase();
        if (staffName == null || staffName.isEmpty) {
          return includesUnassigned;
        }
        return selectedStaffNamesLower.contains(staffName);
      }).toList();
    }

    return list;
  }

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

    if (Get.isRegistered<AuthController>()) {
      ever(Get.find<AuthController>().user, (user) {
        if (user != null && applicants.isEmpty && !isLoading.value) {
          fetchApplicants();
          fetchRolesAndSupervisors();
        }
      });
    }
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

  Future<void> promoteApplicant(
    String applicantId, {
    String? note,
    bool autoSendOfferLetter = false,
    String? offerDesignation,
    String? offerJoiningDate,
  }) async {
    isLoading.value = true;
    try {
      final applicant = applicants.firstWhereOrNull((a) => a.id == applicantId);
      final result = await _applicantService.promoteApplicant(
        applicantId,
        note: note,
        assignedDirector: applicant?.assignedStaffId,
        assignedDirectorName: applicant?.assignedStaffName,
        autoSendOfferLetter: autoSendOfferLetter,
        offerDesignation: offerDesignation,
        offerJoiningDate: offerJoiningDate,
      );
      if (result.success) {
        fetchApplicants();
        if (Get.isRegistered<StaffController>()) {
          Get.find<StaffController>().fetchStaffList();
        }
        if (Get.isRegistered<StaffManagementController>()) {
          Get.find<StaffManagementController>().fetchStaff();
        }
        Get.snackbar(
          'Candidate Promoted',
          autoSendOfferLetter
              ? 'Applicant has been promoted to Staff & official Offer Letter emailed to candidate.'
              : 'Applicant has been promoted to Staff. You can send the offer letter manually anytime.',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'Promotion Failed',
          result.message ?? 'Failed to promote applicant to staff',
          backgroundColor: Colors.red.withValues(alpha: 0.15),
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectApplicant(String applicantId, {String? reason}) async {
    isLoading.value = true;
    try {
      final result = await _applicantService.rejectApplicant(applicantId, reason: reason);
      if (result.success) {
        fetchApplicants();
        Get.snackbar('Candidate Rejected', 'Applicant marked as rejected', backgroundColor: Colors.red.withValues(alpha: 0.15));
      } else {
        Get.snackbar(
          'Rejection Failed',
          result.message ?? 'Failed to reject applicant',
          backgroundColor: Colors.red.withValues(alpha: 0.15),
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateApplicantStage(String applicantId, String stage, {String? note}) async {
    isLoading.value = true;
    try {
      final result = await _applicantService.updateApplicantStage(applicantId, stage, note: note);
      if (result.success) {
        fetchApplicants();
        Get.snackbar('Stage Updated', 'Applicant moved to $stage', backgroundColor: Colors.blue.withValues(alpha: 0.15));
      } else {
        Get.snackbar(
          'Error',
          result.message ?? 'Failed to update stage',
          backgroundColor: Colors.red.withValues(alpha: 0.15),
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveApplicant(String applicantId) async {
    await promoteApplicant(applicantId);
  }

  Future<void> assignApplicant(String applicantId, {String? staffId, String? staffName}) async {
    isLoading.value = true;
    try {
      final result = await _applicantService.assignApplicant(applicantId, staffId: staffId, staffName: staffName);
      if (result.success) {
        fetchApplicants();
        Get.snackbar(
          'Staff Assigned',
          result.message ?? 'Applicant assigned successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
        );
      } else {
        Get.snackbar(
          'Assignment Failed',
          result.message ?? 'Failed to assign staff',
          backgroundColor: Colors.red.withValues(alpha: 0.15),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteApplicant(String applicantId) async {
    isLoading.value = true;
    try {
      final result = await _applicantService.deleteApplicant(applicantId);
      if (result.success) {
        fetchApplicants();
        Get.snackbar(
          'Applicant Deleted',
          result.message ?? 'Applicant deleted successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
        );
      } else {
        Get.snackbar(
          'Delete Failed',
          result.message ?? 'Failed to delete applicant',
          backgroundColor: Colors.red.withValues(alpha: 0.15),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
