import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/applicant.service.dart';
import '../../services/role_permission.service.dart';
import '../../services/staff.service.dart';
import '../../services/branch.service.dart';
import '../../models/staff.model.dart';
import '../../models/role.model.dart';
import '../../models/branch.model.dart';
import '../staff/staff.controller.dart';
import '../staff/staff_management.controller.dart';
import '../auth/auth.controller.dart';

class ApplicantsListController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());
  final RolePermissionService _roleService = Get.put(RolePermissionService());
  final StaffService _staffService = Get.put(StaffService());
  final BranchService _branchService = Get.put(BranchService());

  var isLoading = false.obs;
  var applicants = <StaffModel>[].obs;
  var selectedStage = 'ALL'.obs;
  var searchQuery = ''.obs;
  var selectedStaffFilter = RxnString();
  var selectedBranchFilter = RxnString();
  var selectedHRFilter = RxnString();

  var branchList = <BranchModel>[].obs;
  var hrStaffList = <StaffModel>[].obs;

  // Column-level filters
  var filterCandidate = ''.obs;
  var filterRole = <String>[].obs;
  var filterContact = ''.obs;
  var filterStatus = <String>[].obs;
  var filterStage = <String>[].obs;
  var filterStaff = <String>[].obs;
  var filterBranch = <String>[].obs;
  var filterHR = <String>[].obs;

  bool get hasActiveColumnFilters {
    return filterCandidate.value.trim().isNotEmpty ||
        filterRole.isNotEmpty ||
        filterContact.value.trim().isNotEmpty ||
        filterStatus.isNotEmpty ||
        filterStage.isNotEmpty ||
        filterStaff.isNotEmpty ||
        filterBranch.isNotEmpty ||
        filterHR.isNotEmpty ||
        (selectedBranchFilter.value != null && selectedBranchFilter.value != 'ALL') ||
        (selectedHRFilter.value != null && selectedHRFilter.value != 'ALL');
  }

  void resetColumnFilters() {
    filterCandidate.value = '';
    filterRole.clear();
    filterContact.value = '';
    filterStatus.clear();
    filterStage.clear();
    filterStaff.clear();
    filterBranch.clear();
    filterHR.clear();
    selectedBranchFilter.value = null;
    selectedHRFilter.value = null;
  }

  String resolveApplicantRole(StaffModel applicant) {
    if (applicant.role.isNotEmpty &&
        applicant.role.toLowerCase() != 'staff' &&
        applicant.role.toLowerCase() != 'applicant') {
      return applicant.role.trim();
    }
    final raw = applicant.rawJson ?? {};
    final rawTarget = raw['targetRole']?.toString() ??
        raw['walkInForm']?['appliedPosition']?.toString() ??
        raw['walkInForm']?['positionApplied']?.toString() ??
        raw['appliedPosition']?.toString();
    if (rawTarget != null &&
        rawTarget.trim().isNotEmpty &&
        rawTarget.toLowerCase() != 'staff' &&
        rawTarget.toLowerCase() != 'applicant') {
      return rawTarget.trim();
    }
    if (applicant.currentDesignation?.isNotEmpty == true &&
        applicant.currentDesignation!.toLowerCase() != 'staff') {
      return applicant.currentDesignation!.trim();
    }
    return 'Business Development executive';
  }

  List<String> get availableRoleFilterOptions {
    final set = <String>{};
    for (var r in availableRoles) {
      if (r.name.trim().isNotEmpty) set.add(r.name.trim());
    }
    for (var a in applicants) {
      final role = resolveApplicantRole(a);
      if (role.isNotEmpty) set.add(role);
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

  List<String> get availableBranchFilterOptions {
    final set = <String>{};
    for (var b in branchList) {
      if (b.name.trim().isNotEmpty) set.add(b.name.trim());
    }
    for (var a in applicants) {
      if (a.branchName != null && a.branchName!.trim().isNotEmpty) {
        set.add(a.branchName!.trim());
      }
    }
    final sorted = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    sorted.add('Unassigned');
    return sorted;
  }

  List<String> get availableHRFilterOptions {
    final set = <String>{};
    for (var h in hrStaffList) {
      if (h.name.trim().isNotEmpty) set.add(h.name.trim());
    }
    for (var a in applicants) {
      if (a.assignedHRName != null && a.assignedHRName!.trim().isNotEmpty) {
        set.add(a.assignedHRName!.trim());
      }
    }
    final sorted = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    sorted.add('Unassigned');
    return sorted;
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
      final selectedRolesLower = filterRole.map((r) => r.toLowerCase().trim()).toSet();
      list = list.where((a) {
        final resolvedRole = resolveApplicantRole(a).toLowerCase().trim();
        final r1 = a.role.toLowerCase().trim();
        final r2 = (a.targetRole ?? '').toLowerCase().trim();
        final r3 = (a.rawJson?['targetRole']?.toString() ?? '').toLowerCase().trim();
        final r4 = (a.rawJson?['walkInForm']?['appliedPosition']?.toString() ?? '').toLowerCase().trim();
        final r5 = (a.rawJson?['appliedPosition']?.toString() ?? '').toLowerCase().trim();
        return selectedRolesLower.contains(resolvedRole) ||
            selectedRolesLower.contains(r1) ||
            (r2.isNotEmpty && selectedRolesLower.contains(r2)) ||
            (r3.isNotEmpty && selectedRolesLower.contains(r3)) ||
            (r4.isNotEmpty && selectedRolesLower.contains(r4)) ||
            (r5.isNotEmpty && selectedRolesLower.contains(r5));
      }).toList();
    }

    // 6. Contact Details Column Filter (email or mobile)
    if (filterContact.value.trim().isNotEmpty) {
      final contactQuery = filterContact.value.trim().toLowerCase();
      list = list.where((a) {
        final raw = a.rawJson ?? {};
        final email = a.email.toLowerCase();
        final mobile = a.mobile.toLowerCase();
        final rawEmail = (raw['email']?.toString() ?? '').toLowerCase();
        final rawMobile = (raw['mobile']?.toString() ?? '').toLowerCase();
        return email.contains(contactQuery) ||
            mobile.contains(contactQuery) ||
            rawEmail.contains(contactQuery) ||
            rawMobile.contains(contactQuery);
      }).toList();
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
        final isPromoted = aStage == 'PROMOTED' ||
            aStage == 'OFFER_ACCEPTED' ||
            aStage == 'EMPLOYEE' ||
            a.rawJson?['convertedToStaffId'] != null ||
            a.rawJson?['convertedStaffId'] != null;
        if (isPromoted && selectedStagesUpper.contains('PROMOTED')) {
          return true;
        }
        return selectedStagesUpper.contains(aStage);
      }).toList();
    }

    // 9. Assigned Staff Column Filter
    if (filterStaff.isNotEmpty) {
      final selectedStaffNamesLower = filterStaff.map((s) => s.toLowerCase().trim()).toSet();
      final includesUnassigned = selectedStaffNamesLower.contains('unassigned');
      list = list.where((a) {
        final staffName = a.assignedStaffName?.trim().toLowerCase();
        if (staffName == null || staffName.isEmpty || staffName == 'assign staff') {
          return includesUnassigned;
        }
        return selectedStaffNamesLower.contains(staffName);
      }).toList();
    }

    // 10. Branch Column Filter
    if (filterBranch.isNotEmpty) {
      final selectedBranchesLower = filterBranch.map((b) => b.toLowerCase().trim()).toSet();
      final includesUnassigned = selectedBranchesLower.contains('unassigned');
      list = list.where((a) {
        final branchName = a.branchName?.trim().toLowerCase();
        if (branchName == null || branchName.isEmpty) {
          return includesUnassigned;
        }
        return selectedBranchesLower.contains(branchName);
      }).toList();
    }

    // 11. Assigned HR Column Filter
    if (filterHR.isNotEmpty) {
      final selectedHRNamesLower = filterHR.map((h) => h.toLowerCase().trim()).toSet();
      final includesUnassigned = selectedHRNamesLower.contains('unassigned');
      list = list.where((a) {
        final hrName = a.assignedHRName?.trim().toLowerCase();
        if (hrName == null || hrName.isEmpty) {
          return includesUnassigned;
        }
        return selectedHRNamesLower.contains(hrName);
      }).toList();
    }

    // 12. Top-level Branch Filter
    final bFilter = selectedBranchFilter.value;
    if (bFilter != null && bFilter.isNotEmpty && bFilter != 'ALL') {
      if (bFilter == 'UNASSIGNED') {
        list = list.where((a) => a.branchId == null || a.branchId!.isEmpty).toList();
      } else {
        list = list.where((a) => a.branchId == bFilter || (a.branchName?.toLowerCase() == bFilter.toLowerCase())).toList();
      }
    }

    // 13. Top-level Assigned HR Filter
    final hrFilter = selectedHRFilter.value;
    if (hrFilter != null && hrFilter.isNotEmpty && hrFilter != 'ALL') {
      if (hrFilter == 'UNASSIGNED') {
        list = list.where((a) => a.assignedHR == null || a.assignedHR!.isEmpty).toList();
      } else {
        list = list.where((a) => a.assignedHR == hrFilter || (a.assignedHRName?.toLowerCase() == hrFilter.toLowerCase())).toList();
      }
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
    final filtered = rawList.where((r) => r.id.isNotEmpty && seen.add(r.id)).toList();
    if (filtered.isNotEmpty) return filtered;

    // Fallback default roles with official IDs if async fetch hasn't completed
    return [
      RoleModel(id: '6abb56bee8d43dce5ed8e90a', name: 'Business Development Executive', permissionGroups: []),
      RoleModel(id: '6abb57b7e8d43dce5ed920a3', name: 'Team Leader', permissionGroups: []),
      RoleModel(id: '6abb7578e8d43dce5edd95ac', name: 'Director', permissionGroups: []),
      RoleModel(id: '6ad33bf8e5bf19d93bc0eb1b', name: 'Manager', permissionGroups: []),
      RoleModel(id: '6abb587fe8d43dce5ed954f2', name: 'Research Analyst', permissionGroups: []),
      RoleModel(id: '6ad339aee5bf19d93bc0d237', name: 'Senior Business development', permissionGroups: []),
      RoleModel(id: '6abb702ee8d43dce5edd0a0c', name: 'Operation Executive', permissionGroups: []),
      RoleModel(id: '6abb7224e8d43dce5edd4511', name: 'Human Resource', permissionGroups: []),
      RoleModel(id: '6aabedd9042e5407fb1b7b99', name: 'Admin', permissionGroups: []),
    ];
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
    loadBranchesAndHR();

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
          loadBranchesAndHR();
        }
      });
    }
  }

  Future<void> loadBranchesAndHR() async {
    try {
      final bRes = await _branchService.getBranches(isActive: true);
      if (bRes.statusCode == 200 && bRes.body != null) {
        final list = (bRes.body['data'] as List? ?? [])
            .map((e) => BranchModel.fromJson(e as Map<String, dynamic>))
            .toList();
        branchList.assignAll(list);
      }

      final hrRes = await _staffService.getHRStaff();
      if (hrRes.statusCode == 200 && hrRes.body != null) {
        final raw = hrRes.body['data'];
        final all = (raw['all'] as List? ?? [])
            .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
            .toList();
        hrStaffList.assignAll(all);
      }
    } catch (e) {
      debugPrint('Failed to load branches and HR in applicants list: $e');
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
        branchId: (selectedBranchFilter.value != null && selectedBranchFilter.value != 'ALL' && selectedBranchFilter.value != 'UNASSIGNED')
            ? selectedBranchFilter.value
            : null,
        assignedHR: (selectedHRFilter.value != null && selectedHRFilter.value != 'ALL' && selectedHRFilter.value != 'UNASSIGNED')
            ? selectedHRFilter.value
            : null,
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
    bool autoSendOfferLetter = true,
    String? roleId,
    String? role,
    String? department,
    String? joiningDate,
    String? offerDesignation,
    String? offerJoiningDate,
    String? offerIssueDate,
    String? branchId,
    String? branchName,
    String? assignedHR,
    String? assignedHRName,
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
        roleId: roleId,
        role: role,
        department: department,
        joiningDate: joiningDate,
        offerDesignation: offerDesignation,
        offerJoiningDate: offerJoiningDate,
        offerIssueDate: offerIssueDate,
        branchId: branchId ?? applicant?.branchId,
        branchName: branchName ?? applicant?.branchName,
        assignedHR: assignedHR ?? applicant?.assignedHR,
        assignedHRName: assignedHRName ?? applicant?.assignedHRName,
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

  Future<void> assignBranchToApplicant(String applicantId, String? branchId, {String? branchName}) async {
    isLoading.value = true;
    try {
      final res = await _applicantService.assignApplicantBranch(applicantId, branchId, branchName: branchName);
      if (!res.status.hasError) {
        await fetchApplicants();
        Get.snackbar(
          'Branch Assigned',
          'Candidate branch updated to ${branchName ?? "Unassigned"} successfully.',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
        );
      } else {
        Get.snackbar(
          'Error',
          res.body?['message']?.toString() ?? 'Failed to update branch',
          backgroundColor: Colors.red.withValues(alpha: 0.15),
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red.withValues(alpha: 0.15));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> assignHRToApplicant(String applicantId, String? hrId, {String? hrName}) async {
    isLoading.value = true;
    try {
      final res = await _applicantService.assignApplicantHR(applicantId, hrId, hrName: hrName);
      if (!res.status.hasError) {
        await fetchApplicants();
        Get.snackbar(
          'HR Assigned',
          'Candidate HR updated to ${hrName ?? "Unassigned"} successfully.',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
        );
      } else {
        Get.snackbar(
          'Error',
          res.body?['message']?.toString() ?? 'Failed to assign HR',
          backgroundColor: Colors.red.withValues(alpha: 0.15),
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red.withValues(alpha: 0.15));
    } finally {
      isLoading.value = false;
    }
  }
}
