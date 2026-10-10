import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../services/applicant.service.dart';
import '../../services/staff.service.dart';
import '../../services/role_permission.service.dart';
import '../../models/staff.model.dart';
import '../../models/role.model.dart';
import '../../config/routes.config.dart';
import '../staff/staff.controller.dart';
import '../staff/staff_management.controller.dart';
import 'applicants_list.controller.dart';
import '../../ui/widgets/video_kyc_recorder_dialog.widget.dart';

class ApplicantProfileController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());
  final StaffService _staffService = Get.put(StaffService());
  final RolePermissionService _rolePermissionService = Get.put(RolePermissionService());

  var isLoading = false.obs;
  var uploadingDocType = ''.obs;
  var applicantId = ''.obs;
  var applicant = Rxn<StaffModel>();
  final selectedTabIndex = 0.obs;
  void setTab(int index) => selectedTabIndex.value = index;

  Future<void> handleVideoKyc(BuildContext context) async {
    final name = applicant.value?.fullName ?? '';
    await VideoKycRecorderDialog.showChoice(
      context: context,
      applicantName: name,
      onVideoRecorded: (bytes, filename) async {
        uploadingDocType.value = 'video';
        final res = await _applicantService.uploadApplicantVideo(applicantId.value, bytes, filename);
        uploadingDocType.value = '';
        if (res.success) {
          if (res.applicant != null) {
            applicant.value = res.applicant;
          }
          applicant.refresh();
          fetchDetails(showLoading: false);
          Get.snackbar('Upload Success', 'KYC Video uploaded successfully', backgroundColor: Colors.green.withValues(alpha: 0.1));
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'An error occurred during upload', backgroundColor: Colors.red.withValues(alpha: 0.1));
        }
      },
      onFallbackUpload: () => uploadDoc('video'),
    );
  }

  // Approval validation errors & state
  final roleError = ''.obs;
  final supervisorError = ''.obs;
  final mpinError = ''.obs;
  final isApproving = false.obs;

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
      fetchDetails(showLoading: true);
    }
    // Only fetch staff/admin roles & supervisors if not on a public applicant onboarding page
    if (!AppRoutes.isPublicRoute(Get.currentRoute)) {
      fetchRolesAndSupervisors();
    }
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

  Future<void> fetchDetails({bool showLoading = false}) async {
    if (showLoading) isLoading.value = true;
    try {
      final res = await _applicantService.getApplicantDetails(applicantId.value);
      if (res.error == null) {
        applicant.value = res.applicant;
        applicant.refresh();
      } else {
        Get.snackbar('Error', res.error!, backgroundColor: Colors.red.withValues(alpha: 0.1));
      }
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  Future<void> verifyOtps() async {
    if (mobileOtpController.text.trim().isEmpty || emailOtpController.text.trim().isEmpty) {
      Get.snackbar('Alert', 'Please enter both OTPs', backgroundColor: Colors.orange.withValues(alpha: 0.1));
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
        await fetchDetails(showLoading: false);
        applicant.refresh();
        Get.snackbar('Success', 'Verification complete', backgroundColor: Colors.green.withValues(alpha: 0.1));
      } else {
        Get.snackbar('Verification Failed', res.message ?? 'Invalid OTPs', backgroundColor: Colors.red.withValues(alpha: 0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadDoc(String type) async {
    try {
      FilePickerResult? result;
      if (type == 'video') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          withData: true,
        );
      } else if (type == 'photo') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
      } else if (type == 'resume') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
          withData: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;
        final bytes = pickedFile.bytes;

        if (bytes == null || bytes.isEmpty) {
          Get.snackbar('Upload Failed', 'Could not read file data. Please try again.', backgroundColor: Colors.red.withValues(alpha: 0.1));
          return;
        }

        // Sanitize filename to avoid 'blob' or missing extension camera issues
        String fileName = pickedFile.name.trim();
        final isVideo = type == 'video';
        final hasExt = fileName.contains('.') && fileName.split('.').last.trim().isNotEmpty;
        if (!hasExt || fileName.toLowerCase() == 'blob' || fileName.toLowerCase() == 'image') {
          final defaultExt = isVideo ? 'mp4' : 'jpg';
          fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.$defaultExt';
        }

        uploadingDocType.value = type;
        final res = isVideo
            ? await _applicantService.uploadApplicantVideo(applicantId.value, bytes, fileName)
            : await _applicantService.uploadApplicantFile(applicantId.value, type, bytes, fileName);

        uploadingDocType.value = '';
        if (res.success) {
          if (res.applicant != null) {
            applicant.value = res.applicant;
          }
          applicant.refresh();
          // Update details in background to sync completeness status
          fetchDetails(showLoading: false);
          Get.snackbar('Upload Success', '${type.toUpperCase()} file uploaded', backgroundColor: Colors.green.withValues(alpha: 0.1));
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'An error occurred during upload', backgroundColor: Colors.red.withValues(alpha: 0.1));
        }
      }
    } catch (e) {
      uploadingDocType.value = '';
      Get.snackbar('Error', 'Failed to upload document: $e', backgroundColor: Colors.red.withValues(alpha: 0.1));
    }
  }

  void promptUploadChoice(BuildContext context, String type) {
    if (type == 'video') {
      handleVideoKyc(context);
    } else {
      uploadDoc(type);
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

  void resetApproveForm() {
    roleError.value = '';
    supervisorError.value = '';
    mpinError.value = '';
    isApproving.value = false;
    mpinController.clear();
    selectedRoleId.value = null;
    selectedRole.value = '';
    selectedDepartment.value = '';
    selectedSupervisorId.value = null;
    selectedSupervisorName.value = null;
    isViewOnly.value = false;
    joiningDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void updateRole(String roleId) {
    roleError.value = '';
    selectedRoleId.value = roleId;
    final match = availableRoles.firstWhereOrNull((r) => r.id == roleId);
    if (match != null) {
      selectedRole.value = match.name;
      selectedDepartment.value = match.departmentName ?? '';
    }
  }

  void updateSupervisor(String? supervisorId) {
    supervisorError.value = '';
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

  final isPromoting = false.obs;
  final isRejecting = false.obs;
  final isUpdatingStage = false.obs;

  Future<bool> promoteToStaff({String? note}) async {
    isPromoting.value = true;
    try {
      final success = await _applicantService.promoteApplicant(
        applicantId.value,
        note: note,
      );
      if (success) {
        await fetchDetails(showLoading: false);
        applicant.refresh();
        if (Get.isRegistered<ApplicantsListController>()) {
          Get.find<ApplicantsListController>().fetchApplicants();
        }
        if (Get.isRegistered<StaffController>()) {
          Get.find<StaffController>().fetchStaffList();
        }
        if (Get.isRegistered<StaffManagementController>()) {
          Get.find<StaffManagementController>().fetchStaff();
        }
        Get.snackbar(
          'Candidate Promoted',
          '${applicant.value?.name ?? "Applicant"} has been promoted to Staff. You can configure their Role, Reporting Authority, and MPIN from the Staff page.',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          duration: const Duration(seconds: 4),
        );
        return true;
      } else {
        Get.snackbar('Promotion Failed', 'Failed to promote applicant to staff', backgroundColor: Colors.red.withValues(alpha: 0.15));
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during promotion: $e', backgroundColor: Colors.red.withValues(alpha: 0.15));
      return false;
    } finally {
      isPromoting.value = false;
    }
  }

  // Alias for backward compatibility
  Future<bool> approveApplicant() async {
    return promoteToStaff();
  }

  Future<bool> rejectApplicant({String? reason}) async {
    isRejecting.value = true;
    try {
      final success = await _applicantService.rejectApplicant(
        applicantId.value,
        reason: reason,
      );
      if (success) {
        await fetchDetails(showLoading: false);
        applicant.refresh();
        if (Get.isRegistered<ApplicantsListController>()) {
          Get.find<ApplicantsListController>().fetchApplicants();
        }
        Get.snackbar(
          'Candidate Rejected',
          '${applicant.value?.name ?? "Applicant"} application has been rejected.',
          backgroundColor: Colors.red.withValues(alpha: 0.15),
        );
        return true;
      } else {
        Get.snackbar('Rejection Failed', 'Failed to reject applicant', backgroundColor: Colors.red.withValues(alpha: 0.15));
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during rejection: $e', backgroundColor: Colors.red.withValues(alpha: 0.15));
      return false;
    } finally {
      isRejecting.value = false;
    }
  }

  Future<bool> updateStage(String newStage, {String? note}) async {
    isUpdatingStage.value = true;
    try {
      final success = await _applicantService.updateApplicantStage(
        applicantId.value,
        newStage,
        note: note,
      );
      if (success) {
        await fetchDetails(showLoading: false);
        applicant.refresh();
        if (Get.isRegistered<ApplicantsListController>()) {
          Get.find<ApplicantsListController>().fetchApplicants();
        }
        Get.snackbar(
          'Stage Updated',
          'Applicant stage updated to $newStage',
          backgroundColor: Colors.blue.withValues(alpha: 0.15),
        );
        return true;
      } else {
        Get.snackbar('Update Failed', 'Failed to update applicant stage', backgroundColor: Colors.red.withValues(alpha: 0.15));
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred updating stage: $e', backgroundColor: Colors.red.withValues(alpha: 0.15));
      return false;
    } finally {
      isUpdatingStage.value = false;
    }
  }
}
