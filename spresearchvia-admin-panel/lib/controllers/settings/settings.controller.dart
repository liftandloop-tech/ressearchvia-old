import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/settings.service.dart';
import '../../services/staff.service.dart';
import '../../models/staff.model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/config/theme.config.dart';

class SettingsController extends GetxController {
  final SettingsService _settingsService = Get.find<SettingsService>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploadingQR = false.obs;
  final isEditing = false.obs; // view-only by default

  // Bank Details Controllers
  final bankNameController = TextEditingController();
  final accountNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ifscCodeController = TextEditingController();
  final upiIdController = TextEditingController();

  final qrCodePath = ''.obs;

  // Default Relationship Manager (RM) State
  final isEditingRM = false.obs;
  final isSavingRM = false.obs;
  final isLoadingRM = false.obs;

  final rmStaffId = ''.obs;
  final rmNameController = TextEditingController();
  final rmPhoneController = TextEditingController();
  final rmEmailController = TextEditingController();
  final rmDepartmentController = TextEditingController();

  final staffList = <StaffModel>[].obs;
  final selectedStaff = Rxn<StaffModel>();

  @override
  void onInit() {
    super.onInit();
    fetchBankDetails();
    fetchDefaultRM();
    loadStaffList();
  }

  void startEditing() => isEditing.value = true;

  void cancelEdit() {
    isEditing.value = false;
    fetchBankDetails(); // restore original values
  }

  void startEditingRM() => isEditingRM.value = true;

  void cancelEditRM() {
    isEditingRM.value = false;
    fetchDefaultRM();
  }

  Future<void> fetchBankDetails() async {
    isLoading.value = true;
    try {
      final response = await _settingsService.getSettings('bank_details');
      if (response.status.isOk) {
        final data = response.body['data'];
        if (data != null) {
          bankNameController.text = data['bankName'] ?? '';
          accountNameController.text = data['accountName'] ?? '';
          accountNumberController.text = data['accountNumber'] ?? '';
          ifscCodeController.text = data['ifscCode'] ?? '';
          upiIdController.text = data['upiId'] ?? '';
          qrCodePath.value = data['qrCode'] ?? '';
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch bank details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDefaultRM() async {
    isLoadingRM.value = true;
    try {
      final response = await _settingsService.getSettings('default_rm');
      if (response.status.isOk) {
        final data = response.body['data'];
        if (data != null && data is Map) {
          rmStaffId.value = (data['staffId'] ?? '').toString();
          rmNameController.text = (data['fullName'] ?? '').toString();
          rmPhoneController.text = (data['mobileNumber'] ?? '').toString();
          rmEmailController.text = (data['emailAddress'] ?? '').toString();
          rmDepartmentController.text =
              (data['department'] ?? 'Relationship Manager').toString();
          _syncSelectedStaff();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch default RM: $e');
    } finally {
      isLoadingRM.value = false;
    }
  }

  Future<void> loadStaffList() async {
    try {
      final staffService = Get.isRegistered<StaffService>()
          ? Get.find<StaffService>()
          : Get.put(StaffService());
      final list = await staffService.getStaffList();
      staffList.assignAll(list);
      _syncSelectedStaff();
    } catch (e) {
      debugPrint('Error loading staff list: $e');
    }
  }

  void _syncSelectedStaff() {
    if (staffList.isEmpty) return;
    if (rmStaffId.value.isNotEmpty) {
      final found = staffList.firstWhereOrNull(
        (s) => s.staffId == rmStaffId.value || s.id == rmStaffId.value,
      );
      if (found != null) {
        selectedStaff.value = found;
        return;
      }
    }
    if (rmNameController.text.isNotEmpty) {
      final foundByName = staffList.firstWhereOrNull(
        (s) =>
            s.name.toLowerCase().trim() ==
            rmNameController.text.toLowerCase().trim(),
      );
      if (foundByName != null) {
        selectedStaff.value = foundByName;
        return;
      }
    }
    selectedStaff.value = null;
  }

  void onSelectStaff(StaffModel? staff) {
    selectedStaff.value = staff;
    if (staff != null) {
      rmStaffId.value = staff.staffId.isNotEmpty ? staff.staffId : staff.id;
      rmNameController.text = staff.name;
      rmPhoneController.text = staff.mobile;
      rmEmailController.text = staff.email;
      rmDepartmentController.text =
          staff.department.isNotEmpty ? staff.department : staff.role;
    } else {
      rmStaffId.value = '';
    }
  }

  Future<void> updateDefaultRM() async {
    if (rmNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation',
        'RM Full Name is required',
        backgroundColor: AppTheme.warningOrange,
        colorText: Colors.white,
      );
      return;
    }
    if (rmPhoneController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation',
        'RM Contact Number is required',
        backgroundColor: AppTheme.warningOrange,
        colorText: Colors.white,
      );
      return;
    }

    isSavingRM.value = true;
    try {
      final rmData = {
        'staffId': rmStaffId.value.trim(),
        'fullName': rmNameController.text.trim(),
        'mobileNumber': rmPhoneController.text.trim(),
        'emailAddress': rmEmailController.text.trim(),
        'department': rmDepartmentController.text.trim().isNotEmpty
            ? rmDepartmentController.text.trim()
            : 'Relationship Manager',
      };

      final response =
          await _settingsService.updateSettings('default_rm', rmData);
      if (response.status.isOk) {
        isEditingRM.value = false;
        Get.snackbar(
          'Success',
          'Default Relationship Manager updated successfully',
          backgroundColor: AppTheme.successGreen,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          response.body?['message'] ?? 'Failed to update Default RM',
          backgroundColor: AppTheme.errorRed,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update Default RM: $e');
    } finally {
      isSavingRM.value = false;
    }
  }

  Future<void> pickAndUploadQR() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        isUploadingQR.value = true;
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        final response = await _settingsService.uploadQR(fileBytes, fileName);

        if (response.status.isOk) {
          final path = response.body['data'];
          print('[QR Upload] Backend returned path: $path');
          qrCodePath.value = path;
          print('[QR Upload] fullQrUrl will be: $fullQrUrl');
          Get.snackbar('Success', 'QR Code uploaded');
        } else {
          print('[QR Upload] Failed: ${response.statusCode} ${response.body}');
          Get.snackbar('Error', 'Failed to upload QR Code');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Error picking file: $e');
    } finally {
      isUploadingQR.value = false;
    }
  }

  void removeQR() {
    qrCodePath.value = '';
  }

  Future<void> updateBankDetails() async {
    if (bankNameController.text.isEmpty ||
        accountNameController.text.isEmpty ||
        accountNumberController.text.isEmpty ||
        ifscCodeController.text.isEmpty) {
      Get.snackbar('Validation', 'Bank details are required');
      return;
    }

    isSaving.value = true;
    try {
      final bankDetails = {
        'bankName': bankNameController.text,
        'accountName': accountNameController.text,
        'accountNumber': accountNumberController.text,
        'ifscCode': ifscCodeController.text,
        'upiId': upiIdController.text,
        'qrCode': qrCodePath.value,
      };

      final response = await _settingsService.updateSettings(
        'bank_details',
        bankDetails,
      );
      if (response.status.isOk) {
        isEditing.value = false; // return to view-only mode
        Get.snackbar('Success', 'Bank details updated successfully');
      } else {
        Get.snackbar(
          'Error',
          response.body['message'] ?? 'Failed to update bank details',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update bank details: $e');
    } finally {
      isSaving.value = false;
    }
  }

  String get fullQrUrl {
    if (qrCodePath.value.isEmpty) return '';
    if (qrCodePath.value.startsWith('http')) return qrCodePath.value;
    // Remove /api suffix if present to get the server base
    final base = AppConfig.apiBaseUrl.endsWith('/api')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 4)
        : AppConfig.apiBaseUrl;
    final url = '$base/${qrCodePath.value}';
    print('[QR Display] Loading QR from: $url');
    return url;
  }

  @override
  void onClose() {
    bankNameController.dispose();
    accountNameController.dispose();
    accountNumberController.dispose();
    ifscCodeController.dispose();
    upiIdController.dispose();
    rmNameController.dispose();
    rmPhoneController.dispose();
    rmEmailController.dispose();
    rmDepartmentController.dispose();
    super.onClose();
  }
}
