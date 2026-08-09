import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/notification.service.dart';

class BulkMessagingController extends GetxController {
  final notificationService = Get.put(NotificationService());

  final messageController = TextEditingController();
  final subjectController = TextEditingController();
  final manualEmailsController = TextEditingController();

  final messageType = 'Email'.obs;
  final selectedAudience = 'All Users'.obs;

  final isPreviewMode = false.obs;
  final previewHtml = ''.obs;

  final selectedFileName = ''.obs;
  Uint8List? fileBytes;
  final isLoading = false.obs;

  void updateMessageType(String? value) {
    if (value != null) messageType.value = value;
  }

  void updateAudience(String? value) {
    if (value != null) selectedAudience.value = value;
    // Reset file if changed
    if (value != 'Import CSV/Excel') {
      fileBytes = null;
      selectedFileName.value = '';
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result != null) {
        fileBytes = result.files.first.bytes;
        selectedFileName.value = result.files.first.name;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick file: $e');
    }
  }

  void togglePreview() async {
    if (!isPreviewMode.value) {
      if (messageController.text.isEmpty) {
        Get.snackbar('Error', 'Please enter a message first');
        return;
      }

      isLoading.value = true;
      try {
        final res = await notificationService.getHtmlPreview(
          messageController.text,
        );
        if (res.isOk) {
          previewHtml.value = res.bodyString ?? '';
          isPreviewMode.value = true;
        } else {
          Get.snackbar('Error', 'Failed to load preview');
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to load preview');
      } finally {
        isLoading.value = false;
      }
    } else {
      isPreviewMode.value = false;
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.isEmpty) {
      Get.snackbar('Error', 'Message is required');
      return;
    }

    if (selectedAudience.value == 'Import CSV/Excel' && fileBytes == null) {
      Get.snackbar('Error', 'Please select a file');
      return;
    }

    isLoading.value = true;

    try {
      final formData = FormData({
        'subject': subjectController.text,
        'message': messageController.text,
        'audience': selectedAudience.value,
        'manualEmails': manualEmailsController.text,
      });

      if (selectedAudience.value == 'Import CSV/Excel' && fileBytes != null) {
        formData.files.add(
          MapEntry(
            'file',
            MultipartFile(fileBytes!, filename: selectedFileName.value),
          ),
        );
      }

      final res = await notificationService.sendBulkEmail(formData);

      if (res.isOk) {
        Get.snackbar('Success', 'Emails sent successfully');
        messageController.clear();
        subjectController.clear();
        manualEmailsController.clear();
        fileBytes = null;
        selectedFileName.value = '';
        isPreviewMode.value = false;
      } else {
        Get.snackbar('Error', res.body['message'] ?? 'Failed to send emails');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    subjectController.dispose();
    manualEmailsController.dispose();
    super.onClose();
  }
}
