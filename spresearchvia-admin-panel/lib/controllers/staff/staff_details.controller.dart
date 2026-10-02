import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/staff.model.dart';
import '../../services/staff.service.dart';

class StaffDetailsController extends GetxController {
  final StaffService _staffService = Get.isRegistered<StaffService>() ? Get.find<StaffService>() : Get.put(StaffService());

  var isLoading = false.obs;
  var isVerifying = false.obs;
  var isRejecting = false.obs;
  var isInitiatingAgreement = false.obs;
  var staffId = ''.obs;
  var staff = Rxn<StaffModel>();
  var selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    staffId.value = Get.parameters['id'] ?? '';
    if (staffId.value.isNotEmpty) {
      fetchStaffDetails();
    }
  }

  Future<void> fetchStaffDetails() async {
    isLoading.value = true;
    try {
      final list = await _staffService.getStaffList();
      final found = list.firstWhereOrNull((s) => s.id == staffId.value || s.staffId == staffId.value);
      if (found != null) {
        staff.value = found;
      }
    } catch (e) {
      debugPrint('Error fetching staff details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyAgreement() async {
    final currentStaff = staff.value;
    if (currentStaff == null) return false;

    isVerifying.value = true;
    try {
      final success = await _staffService.verifyStaffAgreement(currentStaff.id);
      if (success) {
        Get.snackbar(
          'Agreement Verified',
          '${currentStaff.name}\'s employment agreement has been formally verified and approved.',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green.shade900,
        );
        await fetchStaffDetails();
        return true;
      } else {
        Get.snackbar('Verification Failed', 'Could not verify agreement. Please try again.',
            backgroundColor: Colors.red.withValues(alpha: 0.1));
        return false;
      }
    } finally {
      isVerifying.value = false;
    }
  }

  Future<bool> rejectAgreement(String reason) async {
    final currentStaff = staff.value;
    if (currentStaff == null) return false;
    if (reason.trim().isEmpty) {
      Get.snackbar('Rejection Reason Required', 'Please provide a clear reason for rejecting the agreement.',
          backgroundColor: Colors.orange.withValues(alpha: 0.1));
      return false;
    }

    isRejecting.value = true;
    try {
      final success = await _staffService.rejectStaffAgreement(currentStaff.id, reason.trim());
      if (success) {
        Get.snackbar(
          'Agreement Rejected',
          'The agreement was marked as rejected. The staff member has been notified to correct their details and re-sign.',
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange.shade900,
        );
        await fetchStaffDetails();
        return true;
      } else {
        Get.snackbar('Action Failed', 'Could not reject agreement. Please try again.',
            backgroundColor: Colors.red.withValues(alpha: 0.1));
        return false;
      }
    } finally {
      isRejecting.value = false;
    }
  }

  Future<bool> initiateAgreement() async {
    final currentStaff = staff.value;
    if (currentStaff == null) return false;

    isInitiatingAgreement.value = true;
    try {
      final success = await _staffService.initiateStaffAgreement(currentStaff.id);
      if (success) {
        Get.snackbar(
          'Agreement Dispatched',
          'Agreement initiated and sent to ${currentStaff.name} via Digio SMS and email.',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
        );
        await fetchStaffDetails();
        return true;
      } else {
        Get.snackbar('Error', 'Failed to dispatch agreement.', backgroundColor: Colors.red.withValues(alpha: 0.1));
        return false;
      }
    } finally {
      isInitiatingAgreement.value = false;
    }
  }
}
