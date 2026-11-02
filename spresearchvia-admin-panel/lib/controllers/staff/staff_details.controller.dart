import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/staff.model.dart';
import '../../services/staff.service.dart';
import '../../ui/widgets/video_kyc_recorder_dialog.widget.dart';

class StaffDetailsController extends GetxController {
  final StaffService _staffService = Get.isRegistered<StaffService>() ? Get.find<StaffService>() : Get.put(StaffService());

  var isLoading = false.obs;
  var isVerifying = false.obs;
  var isRejecting = false.obs;
  var isInitiatingAgreement = false.obs;
  var uploadingDocType = ''.obs;
  var staffId = ''.obs;
  var staff = Rxn<StaffModel>();
  var selectedTabIndex = 0.obs;

  void setTab(int index) => selectedTabIndex.value = index;

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
      final list = await _staffService.getStaffList(status: 'all');
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

  Future<void> uploadDoc(String type) async {
    final currentStaff = staff.value;
    if (currentStaff == null) return;

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
          Get.snackbar('Upload Failed', 'Could not read file data. Please try again.',
              backgroundColor: Colors.red.withValues(alpha: 0.1));
          return;
        }

        String fileName = pickedFile.name.trim();
        final isVideo = type == 'video';
        final hasExt = fileName.contains('.') && fileName.split('.').last.trim().isNotEmpty;
        if (!hasExt || fileName.toLowerCase() == 'blob' || fileName.toLowerCase() == 'image') {
          final defaultExt = isVideo ? 'mp4' : 'jpg';
          fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.$defaultExt';
        }

        uploadingDocType.value = type;
        final res = isVideo
            ? await _staffService.uploadStaffVideo(currentStaff.id, bytes, fileName)
            : await _staffService.uploadStaffDocument(currentStaff.id, type, bytes, fileName);

        uploadingDocType.value = '';
        if (res.success) {
          if (res.staff != null) {
            staff.value = res.staff;
          }
          staff.refresh();
          await fetchStaffDetails();
          Get.snackbar('Upload Success', '${type.toUpperCase()} file uploaded',
              backgroundColor: Colors.green.withValues(alpha: 0.1));
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'An error occurred during upload',
              backgroundColor: Colors.red.withValues(alpha: 0.1));
        }
      }
    } catch (e) {
      uploadingDocType.value = '';
      Get.snackbar('Error', 'Failed to upload document: $e', backgroundColor: Colors.red.withValues(alpha: 0.1));
    }
  }

  Future<void> handleVideoKyc(BuildContext context) async {
    final currentStaff = staff.value;
    if (currentStaff == null) return;
    await VideoKycRecorderDialog.showChoice(
      context: context,
      applicantName: currentStaff.name,
      onVideoRecorded: (bytes, filename) async {
        uploadingDocType.value = 'video';
        final res = await _staffService.uploadStaffVideo(currentStaff.id, bytes, filename);
        uploadingDocType.value = '';
        if (res.success) {
          if (res.staff != null) {
            staff.value = res.staff;
          }
          staff.refresh();
          await fetchStaffDetails();
          Get.snackbar('Upload Success', 'KYC Video uploaded successfully',
              backgroundColor: Colors.green.withValues(alpha: 0.1));
          return true;
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'An error occurred during upload',
              backgroundColor: Colors.red.withValues(alpha: 0.1));
          return false;
        }
      },
      onFallbackUpload: () => uploadDoc('video'),
    );
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
