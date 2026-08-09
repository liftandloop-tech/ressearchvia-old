import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/applicant.service.dart';
import '../../models/staff.model.dart';
import '../staff/staff.controller.dart';
import '../staff/staff_management.controller.dart';

class ApplicantProfileController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  var isLoading = false.obs;
  var applicantId = ''.obs;
  var applicant = Rxn<StaffModel>();

  // OTP field controllers
  final mobileOtpController = TextEditingController();
  final emailOtpController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    applicantId.value = Get.parameters['id'] ?? '';
    if (applicantId.value.isNotEmpty) {
      fetchDetails();
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
  final selectedDepartment = ''.obs;
  final mpinController = TextEditingController();
  final joiningDateController = TextEditingController();
  var isViewOnly = false.obs;

  Future<bool> approveApplicant() async {
    if (selectedDepartment.value.isEmpty || mpinController.text.trim().isEmpty) {
      Get.snackbar('Alert', 'Please select a department and enter an MPIN', backgroundColor: Colors.orange.withOpacity(0.1));
      return false;
    }

    isLoading.value = true;
    try {
      final data = {
        'deparment': selectedDepartment.value,
        'mpin': mpinController.text.trim(),
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
