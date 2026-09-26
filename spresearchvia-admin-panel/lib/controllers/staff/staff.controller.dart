import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/services/role_permission.service.dart';
import 'package:spresearch_web/models/role.model.dart';
import 'package:spresearch_web/models/department.model.dart';

class StaffController extends GetxController {
  late final StaffService _staffService;
  late final AuthController _authController;
  final _rolePermissionService = Get.put(RolePermissionService());
  var rolesList = <RoleModel>[].obs;
  var selectedRoleId = RxnString();
  var selectedRole = ''.obs;
  var departmentsList = <DepartmentModel>[].obs;
  var selectedDepartmentId = RxnString();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final mpinController = TextEditingController();
  final departmentController =
      TextEditingController(); // For now using text field, or dropdown if UI requires
  final joiningDateController = TextEditingController();

  final genderController = TextEditingController();
  final dobController = TextEditingController();
  final experienceController = TextEditingController();
  final previousCompanyController = TextEditingController();
  final lastCtcController = TextEditingController();
  final localAddressController = TextEditingController();
  final permanentAddressController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final emergencyRelationController = TextEditingController();

  // Walk-in form fields from Walk-in Interview Application Form
  final appliedPositionController = TextEditingController();
  final applicationDateController = TextEditingController();
  final nativePlaceController = TextEditingController();
  var maritalStatus = ''.obs;
  final currentLocationController = TextEditingController();
  final skypeController = TextEditingController();

  // Declarations
  var interviewedBefore = false.obs;
  final interviewedBeforeDetailsController = TextEditingController();
  var smoke = false.obs;
  var alcohol = false.obs;
  var differentlyAbled = false.obs;
  final differentlyAbledDetailsController = TextEditingController();
  var policeRecord = false.obs;
  final policeRecordDetailsController = TextEditingController();
  var majorIllness = false.obs;
  final majorIllnessDetailsController = TextEditingController();
  var source = ''.obs;
  final sourceDetailsController = TextEditingController();

  // Education Qualifications
  var educationEntries = <EducationEntryModel>[].obs;
  var academicGap = false.obs;
  final academicGapDetailsController = TextEditingController();
  final backlogsCountController = TextEditingController();

  // Work Experience & Compensation
  final currentOrganisationController = TextEditingController();
  final currentDesignationController = TextEditingController();
  final reportingManagerDesignationController = TextEditingController();
  final reportingManagerNameController = TextEditingController();
  final reporteesCountController = TextEditingController();
  final totalExperienceController = TextEditingController();
  final fixedSalaryController = TextEditingController();
  final bonusIncentiveController = TextEditingController();
  final totalSalaryController = TextEditingController();
  final expectedSalaryController = TextEditingController();
  final noticePeriodController = TextEditingController();

  // Employment History
  var employmentEntries = <EmploymentEntryModel>[].obs;
  final careerGapController = TextEditingController();

  void initDefaultEducationEntries() {
    if (educationEntries.isEmpty) {
      educationEntries.assignAll([
        EducationEntryModel(standard: '10th'),
        EducationEntryModel(standard: '12th'),
        EducationEntryModel(standard: 'Graduation'),
        EducationEntryModel(standard: 'Post graduation'),
      ]);
    }
  }

  void addEducationEntry() {
    educationEntries.add(EducationEntryModel(standard: ''));
  }

  void removeEducationEntry(int index) {
    if (index >= 0 && index < educationEntries.length) {
      educationEntries.removeAt(index);
    }
  }

  void addEmploymentEntry() {
    employmentEntries.add(EmploymentEntryModel());
  }

  void removeEmploymentEntry(int index) {
    if (index >= 0 && index < employmentEntries.length) {
      employmentEntries.removeAt(index);
    }
  }

  WalkInFormModel buildWalkInFormModel() {
    return WalkInFormModel(
      appliedPosition: appliedPositionController.text.trim(),
      applicationDate: applicationDateController.text.trim(),
      fullName: nameController.text.trim(),
      dob: dobController.text.trim(),
      nativePlace: nativePlaceController.text.trim(),
      gender: genderController.text.trim(),
      maritalStatus: maritalStatus.value,
      mobileNumber: mobileController.text.trim(),
      currentLocation: currentLocationController.text.trim(),
      emailAddress: emailController.text.trim(),
      skypeAddress: skypeController.text.trim(),
      interviewedBefore: interviewedBefore.value,
      interviewedBeforeDetails: interviewedBeforeDetailsController.text.trim(),
      smoke: smoke.value,
      alcohol: alcohol.value,
      differentlyAbled: differentlyAbled.value,
      differentlyAbledDetails: differentlyAbledDetailsController.text.trim(),
      policeRecord: policeRecord.value,
      policeRecordDetails: policeRecordDetailsController.text.trim(),
      majorIllness: majorIllness.value,
      majorIllnessDetails: majorIllnessDetailsController.text.trim(),
      source: source.value,
      sourceDetails: sourceDetailsController.text.trim(),
      educationList: educationEntries.toList(),
      academicGap: academicGap.value,
      academicGapDetails: academicGapDetailsController.text.trim(),
      backlogsCount: backlogsCountController.text.trim(),
      currentOrganisation: currentOrganisationController.text.trim().isNotEmpty
          ? currentOrganisationController.text.trim()
          : previousCompanyController.text.trim(),
      currentDesignation: currentDesignationController.text.trim(),
      reportingManagerDesignation: reportingManagerDesignationController.text.trim(),
      reportingManagerName: reportingManagerNameController.text.trim(),
      reporteesCount: reporteesCountController.text.trim(),
      totalExperience: totalExperienceController.text.trim().isNotEmpty
          ? totalExperienceController.text.trim()
          : experienceController.text.trim(),
      fixedSalary: fixedSalaryController.text.trim(),
      bonusIncentive: bonusIncentiveController.text.trim(),
      totalSalary: totalSalaryController.text.trim().isNotEmpty
          ? totalSalaryController.text.trim()
          : lastCtcController.text.trim(),
      expectedSalary: expectedSalaryController.text.trim(),
      noticePeriod: noticePeriodController.text.trim(),
      employmentList: employmentEntries.toList(),
      careerGap: careerGapController.text.trim(),
    );
  }

  var isLoading = false.obs;
  var staffList = <StaffModel>[].obs;

  var filterName = ''.obs;
  var filterMobile = ''.obs;
  var filterEmail = ''.obs;
  var filterSelectedRoles = <String>[].obs;
  var filterSelectedStatuses = <String>[].obs;
  var currentPage = 1.obs;

  var researchersExpanded = true.obs;
  var directorsExpanded = false.obs;
  var managersExpanded = false.obs;
  var researchersPage = 1.obs;
  var directorsPage = 1.obs;
  var managersPage = 1.obs;
  final itemsPerPage = 10;

  var selectedDepartment = ''.obs;

  var isActive = true.obs;
  var autoGeneratedStaffId = ''.obs;

  var isEditing = false.obs;
  var editingStaffId = ''.obs;
  var isViewOnly = false.obs;

  var assignedDirector = Rxn<StaffModel>();

  @override
  void onInit() {
    super.onInit();
    _staffService = Get.find<StaffService>();
    if (Get.isRegistered<AuthController>()) {
      _authController = Get.find<AuthController>();
    }
    _loadFiltersFromUrl();
    initDefaultEducationEntries();
    fetchStaffList();
    fetchRolesList();
    fetchDepartmentsList();

    // Listen to changes on filtering variables to dynamically keep the URL in sync
    ever(filterName, (_) => updateUrlQueryParameters());
    ever(filterMobile, (_) => updateUrlQueryParameters());
    ever(filterEmail, (_) => updateUrlQueryParameters());
    filterSelectedRoles.listen((_) => updateUrlQueryParameters());
    filterSelectedStatuses.listen((_) => updateUrlQueryParameters());
  }

  void _loadFiltersFromUrl() {
    if (!kIsWeb) return;
    try {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('name')) {
        filterName.value = uri.queryParameters['name'] ?? '';
      }
      if (uri.queryParameters.containsKey('mobile')) {
        filterMobile.value = uri.queryParameters['mobile'] ?? '';
      }
      if (uri.queryParameters.containsKey('email')) {
        filterEmail.value = uri.queryParameters['email'] ?? '';
      }
      if (uri.queryParameters.containsKey('roles')) {
        final rolesStr = uri.queryParameters['roles'] ?? '';
        if (rolesStr.isNotEmpty) {
          filterSelectedRoles.assignAll(rolesStr.split(','));
        }
      }
      if (uri.queryParameters.containsKey('statuses')) {
        final statusesStr = uri.queryParameters['statuses'] ?? '';
        if (statusesStr.isNotEmpty) {
          filterSelectedStatuses.assignAll(statusesStr.split(','));
        }
      }
    } catch (e) {
      debugPrint('Error loading filters from URL: $e');
    }
  }

  void updateUrlQueryParameters() {
    if (!kIsWeb) return;
    try {
      final params = <String, String>{};
      if (filterName.value.isNotEmpty) params['name'] = filterName.value;
      if (filterMobile.value.isNotEmpty) params['mobile'] = filterMobile.value;
      if (filterEmail.value.isNotEmpty) params['email'] = filterEmail.value;
      if (filterSelectedRoles.isNotEmpty) params['roles'] = filterSelectedRoles.join(',');
      if (filterSelectedStatuses.isNotEmpty) params['statuses'] = filterSelectedStatuses.join(',');

      final uri = Uri.base;
      final newUri = uri.replace(queryParameters: params);
      
      // Update browser URL query parameters without reloading
      html.window.history.replaceState(null, '', newUri.toString());
    } catch (e) {
      debugPrint('Failed to update URL parameters: $e');
    }
  }

  Future<void> fetchRolesList() async {
    try {
      final response = await _rolePermissionService.getRoles();
      if (!response.status.hasError && response.body != null) {
        final list = (response.body['data'] as List? ?? [])
            .map((item) => RoleModel.fromJson(item))
            .toList();
        rolesList.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error fetching roles: $e');
    }
  }

  Future<void> fetchDepartmentsList() async {
    try {
      final response = await _rolePermissionService.getDepartments();
      if (!response.status.hasError && response.body != null) {
        final list = (response.body['data'] as List? ?? [])
            .map((item) => DepartmentModel.fromJson(item))
            .toList();
        departmentsList.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  @override
  void onClose() {
    // Dispose all TextEditingControllers to prevent memory leaks
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    mpinController.dispose();
    departmentController.dispose();
    joiningDateController.dispose();
    genderController.dispose();
    dobController.dispose();
    experienceController.dispose();
    previousCompanyController.dispose();
    lastCtcController.dispose();
    localAddressController.dispose();
    permanentAddressController.dispose();
    emergencyNameController.dispose();
    emergencyPhoneController.dispose();
    emergencyRelationController.dispose();

    super.onClose();
  }

  Future<void> fetchStaffList() async {
    isLoading.value = true;
    try {
      final list = await _staffService.getStaffList();

      debugPrint('=== Received ${list.length} staff from backend ===');
      for (var s in list) {
        debugPrint('Staff: ${s.name}, Department: "${s.department}"');
      }

      // Use backend-scoped staff list directly (backend strictly enforces hierarchy: Admin -> all, Director/Manager -> self + supervised team, Staff -> self)
      staffList.value = list;

      if (list.isEmpty) {
        debugPrint('No staff members found');
      } else {
        debugPrint('Loaded ${list.length} staff members');
      }
    } catch (e) {
      debugPrint('Error fetching staff list: $e');

      // Extract user-friendly error message
      final errorMsg = e.toString().replaceAll('Exception: ', '');

      Get.snackbar(
        'Error',
        errorMsg.isEmpty || errorMsg == 'null'
            ? 'Failed to load staff list. Please check your connection and try again.'
            : errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 4),
      );
      staffList.value = []; // Ensure list is empty on error
    } finally {
      isLoading.value = false;
    }
  }

  String _normalizeDepartment(String department) {
    // Normalize department to match our standard format
    final normalized = department.toLowerCase().trim();
    if (normalized == 'researcher') return 'Researcher';
    if (normalized == 'director') return 'Director';
    if (normalized == 'manager') return 'Manager';
    if (normalized == 'executive') return 'Executive';
    // Map old 'other staff' / 'other' to 'Manager' for backward compatibility
    if (normalized == 'other staff' || normalized == 'other') {
      return 'Manager';
    }
    // Fallback: default to 'Researcher' to keep the dropdown value valid.
    // Any unknown DB value would otherwise crash the DropdownButton assertion.
    return 'Researcher';
  }

  void populateForEdit(StaffModel staff) {
    isEditing.value = true;
    editingStaffId.value =
        staff.id; // Assuming StaffModel has an 'id' field for the DB ID
    autoGeneratedStaffId.value = staff.staffId;
    nameController.text = staff.name;
    // Remove +91 prefix if present for display in form
    String mobile = staff.mobile;
    if (mobile.startsWith('91')) {
      mobile = mobile.substring(2);
    }
    mobileController.text = mobile;
    emailController.text = staff.email;
    mpinController.text = staff.mpin ?? '';

    // Handle role and auto-assigned department
    selectedRoleId.value = staff.roleId;
    selectedRole.value = staff.role;
    final matchingRole = rolesList.firstWhereOrNull((r) =>
        (staff.roleId != null && r.id == staff.roleId) ||
        r.name.toLowerCase().trim() == staff.role.toLowerCase().trim());
    if (matchingRole != null) {
      selectedRoleId.value = matchingRole.id;
      selectedRole.value = matchingRole.name;
      selectedDepartment.value = matchingRole.departmentName ?? _normalizeDepartment(staff.department);
      selectedDepartmentId.value = matchingRole.departmentId ?? staff.departmentId;
    } else {
      selectedDepartment.value = _normalizeDepartment(staff.department);
      selectedDepartmentId.value = staff.departmentId;
    }

    if (staff.joiningDate != null) {
      final date = staff.joiningDate!;
      joiningDateController.text =
          "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
    } else {
      joiningDateController.clear();
    }

    isActive.value = staff.status == 'Active';
    isViewOnly.value = staff.isViewOnly;

    genderController.text = staff.gender ?? '';
    dobController.text = staff.dob ?? '';
    experienceController.text = staff.experienceYears?.toString() ?? '';
    previousCompanyController.text = staff.previousCompany ?? '';
    lastCtcController.text = staff.lastCtc ?? '';
    localAddressController.text = staff.localAddress ?? '';
    permanentAddressController.text = staff.permanentAddress ?? '';
    emergencyNameController.text = staff.emergencyContact?.name ?? '';
    emergencyPhoneController.text = staff.emergencyContact?.phone ?? '';
    emergencyRelationController.text = staff.emergencyContact?.relation ?? '';

    // Handle assigned director for update
    assignedDirector.value = null;
    if (staff.assignedDirector != null && staff.assignedDirector!.isNotEmpty) {
      // Find staff in list
      final director = staffList.firstWhereOrNull(
        (s) => s.id == staff.assignedDirector,
      );
      if (director != null) {
        assignedDirector.value = director;
      } else if (staff.assignedDirectorName != null && staff.assignedDirectorName!.isNotEmpty) {
        final dirByName = staffList.firstWhereOrNull(
          (s) => s.name.toLowerCase().trim() == staff.assignedDirectorName!.toLowerCase().trim(),
        );
        if (dirByName != null) {
          assignedDirector.value = dirByName;
        }
      }
    }

    final w = staff.walkInForm;
    if (w != null) {
      appliedPositionController.text = w.appliedPosition;
      applicationDateController.text = w.applicationDate;
      nativePlaceController.text = w.nativePlace;
      maritalStatus.value = w.maritalStatus;
      currentLocationController.text = w.currentLocation;
      skypeController.text = w.skypeAddress;
      interviewedBefore.value = w.interviewedBefore;
      interviewedBeforeDetailsController.text = w.interviewedBeforeDetails;
      smoke.value = w.smoke;
      alcohol.value = w.alcohol;
      differentlyAbled.value = w.differentlyAbled;
      differentlyAbledDetailsController.text = w.differentlyAbledDetails;
      policeRecord.value = w.policeRecord;
      policeRecordDetailsController.text = w.policeRecordDetails;
      majorIllness.value = w.majorIllness;
      majorIllnessDetailsController.text = w.majorIllnessDetails;
      source.value = w.source;
      sourceDetailsController.text = w.sourceDetails;
      educationEntries.assignAll(w.educationList);
      academicGap.value = w.academicGap;
      academicGapDetailsController.text = w.academicGapDetails;
      backlogsCountController.text = w.backlogsCount;
      currentOrganisationController.text = w.currentOrganisation.isNotEmpty
          ? w.currentOrganisation
          : (staff.previousCompany ?? '');
      currentDesignationController.text = w.currentDesignation;
      reportingManagerDesignationController.text = w.reportingManagerDesignation;
      reportingManagerNameController.text = w.reportingManagerName;
      reporteesCountController.text = w.reporteesCount;
      totalExperienceController.text = w.totalExperience.isNotEmpty
          ? w.totalExperience
          : (staff.experienceYears?.toString() ?? '');
      fixedSalaryController.text = w.fixedSalary;
      bonusIncentiveController.text = w.bonusIncentive;
      totalSalaryController.text = w.totalSalary.isNotEmpty
          ? w.totalSalary
          : (staff.lastCtc ?? '');
      expectedSalaryController.text = w.expectedSalary;
      noticePeriodController.text = w.noticePeriod;
      employmentEntries.assignAll(w.employmentList);
      careerGapController.text = w.careerGap;
    } else {
      initDefaultEducationEntries();
      currentOrganisationController.text = staff.previousCompany ?? '';
      totalExperienceController.text = staff.experienceYears?.toString() ?? '';
      totalSalaryController.text = staff.lastCtc ?? '';
    }
  }

  Future<void> saveStaff() async {
    // Validate required fields
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter full name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    // Validate name length (at least 2 characters, max 100)
    if (nameController.text.trim().length < 2) {
      Get.snackbar(
        'Validation Error',
        'Name must be at least 2 characters long',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    if (nameController.text.trim().length > 100) {
      Get.snackbar(
        'Validation Error',
        'Name cannot exceed 100 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    if (mobileController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter mobile number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    // Validate mobile number format
    final mobileStr = mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (mobileStr.length != 10) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid 10-digit mobile number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    // Validate mobile number starts with 6-9 (Indian mobile numbers)
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobileStr)) {
      Get.snackbar(
        'Validation Error',
        'Mobile number must start with 6, 7, 8, or 9',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    final mobileNumber = int.tryParse(mobileStr);

    if (mobileNumber == null) {
      Get.snackbar(
        'Validation Error',
        'Invalid mobile number format',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    // Validate email if provided (optional field)
    if (emailController.text.trim().isNotEmpty) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      if (!emailRegex.hasMatch(emailController.text.trim())) {
        Get.snackbar(
          'Validation Error',
          'Please enter a valid email address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return;
      }
    }

    // Validate MPIN (Only for non-Managers)
    if (selectedDepartment.value.toLowerCase() != 'manager') {
      if (mpinController.text.isNotEmpty) {
        if (mpinController.text.length < 4) {
          Get.snackbar(
            'Validation Error',
            'MPIN must be at least 4 digits',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[900],
          );
          return;
        }
      } else if (!isEditing.value) {
        Get.snackbar(
          'Validation Error',
          'Please set an MPIN for the new staff member',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return;
      }
    }

    // Assigned director validation for managers when directors are available
    if (selectedDepartment.value.toLowerCase() == 'manager' && !isDirectorLoggedIn) {
      if (assignedDirector.value == null && availableDirectors.isNotEmpty) {
        // Optional warning or fallback, allow proceeding if admin prefers unassigned
      }
    }

    // Validate joining date if provided
    if (joiningDateController.text.trim().isNotEmpty) {
      final parsedDate = _validateJoiningDate(joiningDateController.text);
      if (parsedDate == null) {
        Get.snackbar(
          'Validation Error',
          'Invalid date format. Please use MM/DD/YYYY format.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return;
      }

      // Check if date is in the future
      if (parsedDate.isAfter(DateTime.now())) {
        Get.snackbar(
          'Validation Error',
          'Joining date cannot be in the future',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return;
      }

      // Check if date is too far in the past (e.g., before 1950)
      if (parsedDate.year < 1950) {
        Get.snackbar(
          'Validation Error',
          'Please enter a valid joining date',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return;
      }
    }

    final hasRole = (selectedRoleId.value != null && selectedRoleId.value!.isNotEmpty) ||
        selectedRole.value.isNotEmpty;
    if (!hasRole) {
      Get.snackbar(
        'Validation Error',
        'Please select a role for this staff member',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    Map<String, String>? permanentAddressObj;
    if (permanentAddressController.text.trim().isNotEmpty) {
      final text = permanentAddressController.text.trim();
      if (text.startsWith('{') && text.endsWith('}')) {
        final map = <String, String>{};
        final content = text.substring(1, text.length - 1);
        final parts = content.split(',');
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length >= 2) {
            final key = kv[0].trim();
            final val = kv.sublist(1).join(':').trim();
            map[key] = val;
          }
        }
        permanentAddressObj = {
          "street": map["street"] ?? "",
          "city": map["city"] ?? "",
          "state": map["state"] ?? "",
          "zip": map["zip"] ?? "",
        };
      } else {
        final parts = text.split(',');
        final street = parts.isNotEmpty ? parts[0].trim() : "";
        final city = parts.length > 1 ? parts[1].trim() : "";
        final state = parts.length > 2 ? parts[2].trim() : "";
        permanentAddressObj = {
          "street": street,
          "city": city,
          "state": state,
          "zip": "",
        };
      }
    }

    isLoading.value = true;
    try {
      final Map<String, dynamic> data = {
        "fullName": nameController.text.trim(),
        "mobileNumber": "+91$mobileStr",
        "emailAddress": emailController.text.trim(),
        if (selectedRoleId.value != null && selectedRoleId.value!.isNotEmpty)
          "roleId": selectedRoleId.value,
        "role": selectedRole.value,
        if (selectedDepartment.value.isNotEmpty)
          "deparment": selectedDepartment.value, // Auto-derived department
        if (selectedDepartmentId.value != null && selectedDepartmentId.value!.isNotEmpty)
          "departmentId": selectedDepartmentId.value,
        "joiningDate": joiningDateController.text.isEmpty
            ? DateTime.now().toIso8601String()
            : _parseJoiningDate(joiningDateController.text),
        "status": isActive.value ? 'Active' : 'Inactive',
        "isViewOnly": isViewOnly.value,
        if (genderController.text.trim().isNotEmpty) "gender": genderController.text.trim(),
        if (dobController.text.trim().isNotEmpty) "dob": dobController.text.trim(),
        if (experienceController.text.trim().isNotEmpty) "experienceYears": int.tryParse(experienceController.text.trim()) ?? 0,
        if (previousCompanyController.text.trim().isNotEmpty) "previousCompany": previousCompanyController.text.trim(),
        if (lastCtcController.text.trim().isNotEmpty) "lastCtc": lastCtcController.text.trim(),
        if (localAddressController.text.trim().isNotEmpty) "localAddress": localAddressController.text.trim(),
        if (permanentAddressObj != null) "permanentAddress": permanentAddressObj,
        "emergencyContact": (emergencyNameController.text.trim().isNotEmpty ||
                emergencyPhoneController.text.trim().isNotEmpty ||
                emergencyRelationController.text.trim().isNotEmpty)
            ? {
                "name": emergencyNameController.text.trim(),
                "phone": emergencyPhoneController.text.trim(),
                "relation": emergencyRelationController.text.trim(),
              }
            : null,
        "walkInForm": buildWalkInFormModel().toJson(),
      };

      final roleLower = selectedRole.value.toLowerCase().trim();
      final deptLower = selectedDepartment.value.toLowerCase().trim();
      final isManager = roleLower == 'manager' || deptLower == 'manager';
      if (!isManager && mpinController.text.isNotEmpty) {
        data["mpin"] = mpinController.text.trim();
      }

      // Handle assigned director (Supervisor for all non-director staff roles)
      final isDirector = roleLower == 'director' || deptLower == 'director';
      if (!isDirector) {
        if (isDirectorLoggedIn) {
          data["assignedDirector"] = _authController.user.value!.id;
          data["assignedDirectorName"] = _authController.user.value!.fullName;
        } else if (assignedDirector.value != null) {
          data["assignedDirector"] = assignedDirector.value!.id;
          data["assignedDirectorName"] = assignedDirector.value!.name;
        } else {
          data["assignedDirector"] = null;
          data["assignedDirectorName"] = null;
        }
      } else {
        data["assignedDirector"] = null;
        data["assignedDirectorName"] = null;
      }

      // Only include staffId for update operations
      if (isEditing.value) {
        data["staffId"] = autoGeneratedStaffId.value;
      }

      debugPrint('Submitting staff data: $data');
      print('DEBUG: isViewOnly value being sent: ${data["isViewOnly"]}');

      bool success = false;
      String? errorMessage;

      try {
        if (isEditing.value) {
          success = await _staffService.updateStaff(editingStaffId.value, data);
        } else {
          success = await _staffService.createStaff(data);
        }
      } catch (serviceError) {
        errorMessage = serviceError.toString().replaceAll('Exception: ', '');
        debugPrint('Service error: $errorMessage');
      }

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          isEditing.value
              ? 'Staff member updated successfully'
              : 'Staff member added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          duration: const Duration(seconds: 3),
        );
        resetForm();
        await fetchStaffList(); // Refresh list
      } else {
        Get.snackbar(
          'Error',
          errorMessage ??
              (isEditing.value
                  ? 'Failed to update staff member. Please try again.'
                  : 'Failed to add staff member. Please try again.'),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint('Exception in saveStaff: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _parseJoiningDate(String dateStr) {
    try {
      // Input format: mm/dd/yyyy
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        // Validate month and day ranges
        if (month < 1 || month > 12 || day < 1 || day > 31) {
          throw FormatException('Invalid date values');
        }

        final date = DateTime(year, month, day);
        return date.toIso8601String();
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return DateTime.now().toIso8601String();
  }

  DateTime? _validateJoiningDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;

      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (month == null || day == null || year == null) return null;

      // Validate ranges
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      if (year < 1900 || year > 2100) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  void resetForm() {
    isEditing.value = false;
    editingStaffId.value = '';
    autoGeneratedStaffId.value = '';
    nameController.clear();
    mobileController.clear();
    emailController.clear();
    mpinController.clear();
    departmentController.clear();
    joiningDateController.clear();
    genderController.clear();
    dobController.clear();
    experienceController.clear();
    previousCompanyController.clear();
    lastCtcController.clear();
    localAddressController.clear();
    permanentAddressController.clear();
    emergencyNameController.clear();
    emergencyPhoneController.clear();
    emergencyRelationController.clear();

    appliedPositionController.clear();
    applicationDateController.clear();
    nativePlaceController.clear();
    maritalStatus.value = '';
    currentLocationController.clear();
    skypeController.clear();
    interviewedBefore.value = false;
    interviewedBeforeDetailsController.clear();
    smoke.value = false;
    alcohol.value = false;
    differentlyAbled.value = false;
    differentlyAbledDetailsController.clear();
    policeRecord.value = false;
    policeRecordDetailsController.clear();
    majorIllness.value = false;
    majorIllnessDetailsController.clear();
    source.value = '';
    sourceDetailsController.clear();
    educationEntries.clear();
    initDefaultEducationEntries();
    academicGap.value = false;
    academicGapDetailsController.clear();
    backlogsCountController.clear();
    currentOrganisationController.clear();
    currentDesignationController.clear();
    reportingManagerDesignationController.clear();
    reportingManagerNameController.clear();
    reporteesCountController.clear();
    totalExperienceController.clear();
    fixedSalaryController.clear();
    bonusIncentiveController.clear();
    totalSalaryController.clear();
    expectedSalaryController.clear();
    noticePeriodController.clear();
    employmentEntries.clear();
    careerGapController.clear();

    selectedRoleId.value = null;
    selectedRole.value = '';
    selectedDepartment.value = '';
    selectedDepartmentId.value = null;

    isActive.value = true;
    isViewOnly.value = false;
    assignedDirector.value = null;
  }

  bool get isDirectorLoggedIn {
    if (!Get.isRegistered<AuthController>()) return false;
    return _authController.user.value?.isDirector == true;
  }

  bool get isAdminLoggedIn {
    if (!Get.isRegistered<AuthController>()) return false;
    return _authController.user.value?.isAdmin == true;
  }

  String get currentDirectorName {
    if (!Get.isRegistered<AuthController>()) return '';
    return _authController.user.value?.fullName ?? '';
  }

  List<StaffModel> get filteredStaffList {
    return staffList.where((s) {
      if (filterName.value.isNotEmpty) {
        if (!s.name.toLowerCase().contains(filterName.value.toLowerCase())) {
          return false;
        }
      }
      
      if (filterMobile.value.isNotEmpty) {
        if (!s.mobile.toLowerCase().contains(filterMobile.value.toLowerCase())) {
          return false;
        }
      }

      if (filterEmail.value.isNotEmpty) {
        if (!s.email.toLowerCase().contains(filterEmail.value.toLowerCase())) {
          return false;
        }
      }

      if (filterSelectedRoles.isNotEmpty) {
        if (!filterSelectedRoles.contains(s.role.trim())) {
          return false;
        }
      }

      if (filterSelectedStatuses.isNotEmpty) {
        if (!filterSelectedStatuses.contains(s.status.trim())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void clearAllFilters() {
    filterName.value = '';
    filterMobile.value = '';
    filterEmail.value = '';
    filterSelectedRoles.clear();
    filterSelectedStatuses.clear();
    currentPage.value = 1;
  }

  int get totalPages => filteredStaffList.isEmpty 
      ? 1 
      : (filteredStaffList.length / itemsPerPage).ceil();

  List<StaffModel> get paginatedStaffList {
    if (filteredStaffList.isEmpty) return [];

    if (currentPage.value < 1) {
      currentPage.value = 1;
    }

    final start = (currentPage.value - 1) * itemsPerPage;
    if (start >= filteredStaffList.length && filteredStaffList.isNotEmpty) {
      currentPage.value = totalPages;
      final newStart = (currentPage.value - 1) * itemsPerPage;
      final newEnd = newStart + itemsPerPage;
      return filteredStaffList.sublist(
        newStart,
        newEnd > filteredStaffList.length ? filteredStaffList.length : newEnd,
      );
    }

    final end = start + itemsPerPage;
    return filteredStaffList.sublist(
      start,
      end > filteredStaffList.length ? filteredStaffList.length : end,
    );
  }

  List<String> get availableRolesFilterOptions {
    final roles = <String>{'All'};
    for (var s in staffList) {
      if (s.role.isNotEmpty) {
        roles.add(s.role.trim());
      }
    }
    for (var r in rolesList) {
      roles.add(r.name.trim());
    }
    return roles.toList()..sort((a, b) => a == 'All' ? -1 : b == 'All' ? 1 : a.compareTo(b));
  }

  List<StaffModel> get availableDirectors {
    final directors = staffList
        .where((s) {
          if (editingStaffId.value.isNotEmpty && s.id == editingStaffId.value) {
            return false;
          }
          final dept = s.department.toLowerCase().trim();
          final role = s.role.toLowerCase().trim();
          return dept.contains('director') ||
              role.contains('director') ||
              dept.contains('admin') ||
              role.contains('admin');
        })
        .toList();
    return directors;
  }

  List<StaffModel> get allResearchers {
    final list = staffList
        .where((s) {
          final dept = s.department.toLowerCase().trim();
          return dept.contains('research') || dept.contains('analyst');
        })
        .toList();
    return list;
  }

  List<StaffModel> get allManagers {
    final list = staffList.where((s) {
      final dept = s.department.toLowerCase().trim();
      return dept.contains('manager');
    }).toList();
    return list;
  }

  List<StaffModel> get otherStaff {
    final list = staffList.where((s) {
      final dept = s.department.toLowerCase().trim();
      final isDirector = dept.contains('director');
      final isResearcher = dept.contains('research') || dept.contains('analyst');
      final isManager = dept.contains('manager');
      return !isDirector && !isResearcher && !isManager;
    }).toList();
    return list;
  }

  List<StaffModel> get paginatedDirectors {
    if (availableDirectors.isEmpty) return [];

    // Ensure page is within valid bounds
    if (directorsPage.value < 1) {
      directorsPage.value = 1;
    }

    final start = (directorsPage.value - 1) * itemsPerPage;
    if (start >= availableDirectors.length && availableDirectors.isNotEmpty) {
      // Reset to last valid page
      directorsPage.value = directorsTotalPages;
      final newStart = (directorsPage.value - 1) * itemsPerPage;
      final newEnd = newStart + itemsPerPage;
      return availableDirectors.sublist(
        newStart,
        newEnd > availableDirectors.length ? availableDirectors.length : newEnd,
      );
    }

    final end = start + itemsPerPage;
    return availableDirectors.sublist(
      start,
      end > availableDirectors.length ? availableDirectors.length : end,
    );
  }

  List<StaffModel> get paginatedResearchers {
    if (allResearchers.isEmpty) return [];

    // Ensure page is within valid bounds
    if (researchersPage.value < 1) {
      researchersPage.value = 1;
    }

    final start = (researchersPage.value - 1) * itemsPerPage;
    if (start >= allResearchers.length && allResearchers.isNotEmpty) {
      // Reset to last valid page
      researchersPage.value = researchersTotalPages;
      final newStart = (researchersPage.value - 1) * itemsPerPage;
      final newEnd = newStart + itemsPerPage;
      return allResearchers.sublist(
        newStart,
        newEnd > allResearchers.length ? allResearchers.length : newEnd,
      );
    }

    final end = start + itemsPerPage;
    return allResearchers.sublist(
      start,
      end > allResearchers.length ? allResearchers.length : end,
    );
  }

  List<StaffModel> get paginatedManagers {
    if (allManagers.isEmpty) return [];

    // Ensure page is within valid bounds
    if (managersPage.value < 1) {
      managersPage.value = 1;
    }

    final start = (managersPage.value - 1) * itemsPerPage;
    if (start >= allManagers.length && allManagers.isNotEmpty) {
      // Reset to last valid page
      managersPage.value = managersTotalPages;
      final newStart = (managersPage.value - 1) * itemsPerPage;
      final newEnd = newStart + itemsPerPage;
      return allManagers.sublist(
        newStart,
        newEnd > allManagers.length ? allManagers.length : newEnd,
      );
    }

    final end = start + itemsPerPage;
    return allManagers.sublist(
      start,
      end > allManagers.length ? allManagers.length : end,
    );
  }

  var otherStaffPage = 1.obs;
  var otherStaffExpanded = false.obs;

  List<StaffModel> get paginatedOtherStaff {
    if (otherStaff.isEmpty) return [];

    if (otherStaffPage.value < 1) {
      otherStaffPage.value = 1;
    }

    final start = (otherStaffPage.value - 1) * itemsPerPage;
    if (start >= otherStaff.length && otherStaff.isNotEmpty) {
      otherStaffPage.value = otherStaffTotalPages;
      final newStart = (otherStaffPage.value - 1) * itemsPerPage;
      final newEnd = newStart + itemsPerPage;
      return otherStaff.sublist(
        newStart,
        newEnd > otherStaff.length ? otherStaff.length : newEnd,
      );
    }

    final end = start + itemsPerPage;
    return otherStaff.sublist(
      start,
      end > otherStaff.length ? otherStaff.length : end,
    );
  }

  int get directorsTotalPages => availableDirectors.isEmpty
      ? 1
      : (availableDirectors.length / itemsPerPage).ceil();

  int get researchersTotalPages => allResearchers.isEmpty
      ? 1
      : (allResearchers.length / itemsPerPage).ceil();
  int get managersTotalPages =>
      allManagers.isEmpty ? 1 : (allManagers.length / itemsPerPage).ceil();
  int get otherStaffTotalPages =>
      otherStaff.isEmpty ? 1 : (otherStaff.length / itemsPerPage).ceil();

  // Available roles for staff assignment
  List<RoleModel> get availableRoles {
    if (isDirectorLoggedIn) {
      final managers = rolesList.where((r) => r.name.toLowerCase().contains('manager')).toList();
      if (managers.isNotEmpty) return managers;
    }
    return rolesList.toList();
  }

  List<String> get availableRoleNames => rolesList.map((r) => r.name).toList();

  void updateRole(String roleId) {
    selectedRoleId.value = roleId;
    final match = rolesList.firstWhereOrNull((r) => r.id == roleId);
    if (match != null) {
      selectedRole.value = match.name;
      selectedDepartment.value = match.departmentName ?? '';
      selectedDepartmentId.value = match.departmentId;
    }
  }

  void updateRoleByName(String roleName) {
    selectedRole.value = roleName;
    final match = rolesList.firstWhereOrNull((r) => r.name.toLowerCase().trim() == roleName.toLowerCase().trim());
    if (match != null) {
      selectedRoleId.value = match.id;
      selectedDepartment.value = match.departmentName ?? '';
      selectedDepartmentId.value = match.departmentId;
    }
  }

  // Department dropdown options (legacy fallback, auto-assigned from role)
  List<String> get availableDepartments {
    if (isDirectorLoggedIn) {
      return ['Manager'];
    }
    if (departmentsList.isNotEmpty) {
      return departmentsList.map((d) => d.name).toList();
    }
    if (rolesList.isNotEmpty) {
      return rolesList.map((r) => r.name).toList();
    }
    return ['Administration & Management', 'Research & Advisory', 'Sales & Relationship Management', 'Operations & Compliance'];
  }

  void updateDepartment(String dept) {
    selectedDepartment.value = dept;
    final match = departmentsList.firstWhereOrNull((d) => d.name == dept);
    selectedDepartmentId.value = match?.id;
  }

  Future<bool> assignSupervisor(String staffId, String? supervisorId, String? supervisorName) async {
    try {
      final isDirectAdmin = supervisorId == null || supervisorId == 'admin' || supervisorId == 'unassigned';
      final Map<String, dynamic> data = {
        "assignedDirector": isDirectAdmin ? null : supervisorId,
        "assignedDirectorName": isDirectAdmin ? 'Admin' : supervisorName,
      };

      final success = await _staffService.updateStaff(staffId, data);
      if (success) {
        final index = staffList.indexWhere((s) => s.id == staffId);
        if (index != -1) {
          final old = staffList[index];
          staffList[index] = StaffModel(
            id: old.id,
            staffId: old.staffId,
            name: old.name,
            mobile: old.mobile,
            email: old.email,
            role: old.role,
            status: old.status,
            department: old.department,
            joiningDate: old.joiningDate,
            remark: old.remark,
            assignedDirector: data["assignedDirector"],
            assignedDirectorName: data["assignedDirectorName"],
            mpin: old.mpin,
            isViewOnly: old.isViewOnly,
            panUrl: old.panUrl,
            aadhaarUrl: old.aadhaarUrl,
            nismUrl: old.nismUrl,
            highestEducationUrl: old.highestEducationUrl,
            kycVideoUrl: old.kycVideoUrl,
            onboardingStatus: old.onboardingStatus,
            isEmailVerified: old.isEmailVerified,
            isMobileVerified: old.isMobileVerified,
            photoUrl: old.photoUrl,
            resumeUrl: old.resumeUrl,
            stage: old.stage,
            dob: old.dob,
            gender: old.gender,
            experienceYears: old.experienceYears,
            previousCompany: old.previousCompany,
            lastCtc: old.lastCtc,
            localAddress: old.localAddress,
            permanentAddress: old.permanentAddress,
            emergencyContact: old.emergencyContact,
          );
          staffList.refresh();
        }
        Get.snackbar(
          'Updated',
          'Reporting authority updated to ${data["assignedDirectorName"]}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          duration: const Duration(seconds: 2),
        );
      }
      return success;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update reporting authority: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }
  }

  Future<void> deleteStaff(String staffId, String staffName) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Confirm Deletion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete $staffName?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. All data associated with this staff member will be permanently removed.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      isLoading.value = true;
      try {
        final success = await _staffService.deleteStaff(staffId);
        if (success) {
          Get.snackbar(
            'Success',
            'Staff member deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
          );
          await fetchStaffList();
        } else {
          Get.snackbar(
            'Error',
            'Failed to delete staff member',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[900],
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'An error occurred while deleting staff member',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> toggleStaffStatus(String staffId, bool isActive) async {
    final newStatus = isActive ? 'Active' : 'Deactivated';

    // Optimistic update logic could go here

    try {
      // Assuming updateStaff method handles partial updates
      // If not, we need to pass strict structure or fetch-modify-save
      // Since `staffReset` in backend seems to update fields, checking if it handles partial
      // Backend `staffReset` updates: fullName, mobileNumber, emailAddress, deparment, etc.
      // It DOES expect these fields.
      // If I send ONLY status, other fields might be overwritten with undefined if not handled carefully in backend.
      // Let's check backend `staffReset`...
      // Backend: `let { fullName, ... } = body`.
      // `staff.fullName = fullName`. If fullName is undefined, it sets undefined?
      // Mongoose might ignore undefined for updates if not explicitly set to null, but let's be safe.

      // Wait, `staffReset` implementation:
      // staff.fullName = fullName
      // It assigns directly. So if I send minimal body, it might break data.

      // BUT, I can find the staff model in `staffList` and send all data + new status.

      final staff = staffList.firstWhereOrNull((s) => s.id == staffId);
      if (staff == null) {
        Get.snackbar('Error', 'Staff not found locally');
        return;
      }

      final data = {
        "fullName": staff.name,
        "mobileNumber": staff.mobile, // Ensure format is correct
        "emailAddress": staff.email,
        "deparment": staff.department,
        "joiningDate": staff.joiningDate?.toIso8601String(),
        "status": newStatus,
        "staffId": staff.staffId,
        // Include MPIN only if it's not null/empty?
        "mpin": staff.mpin,
        // Assigned Director
        "assignedDirector": staff.assignedDirector,
        "assignedDirectorName": staff.assignedDirectorName,
      };

      // Fix mobile number if it has +91 or not
      // Backend expects usually numbers, stored as Number or String?
      // Model says Number.
      // `staffReset` takes body.mobileNumber.

      final success = await _staffService.updateStaff(staffId, data);

      if (success) {
        Get.snackbar(
          'Success',
          'Staff status updated to $newStatus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          duration: const Duration(seconds: 2),
        );
        await fetchStaffList(); // Refresh to ensure sync
      } else {
        Get.snackbar(
          'Error',
          'Failed to assign status',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }
    } catch (e) {
      debugPrint('Error toggling status: $e');
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  Future<void> pickAndUploadDoc(String id, String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: type == 'video' ? ['mp4', 'mov', 'avi'] : ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        isLoading.value = true;
        final res = type == 'video'
            ? await _staffService.uploadStaffVideo(id, result.files.single.bytes!, result.files.single.name)
            : await _staffService.uploadStaffDocument(id, type, result.files.single.bytes!, result.files.single.name);

        isLoading.value = false;
        if (res.success) {
          await fetchStaffList(); // reload staff list to update file URLs
          Get.snackbar('Upload Complete', '${type.toUpperCase()} uploaded successfully', backgroundColor: Colors.green.withOpacity(0.1));
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'An error occurred', backgroundColor: Colors.red.withOpacity(0.1));
        }
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to upload: $e', backgroundColor: Colors.red.withOpacity(0.1));
    }
  }
}
