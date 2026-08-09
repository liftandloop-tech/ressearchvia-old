import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/settings.service.dart';

import 'package:file_picker/file_picker.dart';
import 'package:spresearch_web/config/app.config.dart';

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

  @override
  void onInit() {
    super.onInit();
    fetchBankDetails();
  }

  void startEditing() => isEditing.value = true;

  void cancelEdit() {
    isEditing.value = false;
    fetchBankDetails(); // restore original values
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
    super.onClose();
  }
}
