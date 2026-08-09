import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api.service.dart';
import '../../services/notification.service.dart';

class PushNotificationsController extends GetxController {
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final selectedAudienceType = 'All Users'.obs;
  final selectedAudienceId = ''.obs; // For Segment or Plan ID

  final isLoading = false.obs;
  final sendNow = true.obs;

  final notificationTitle = ''.obs;
  final notificationMessage = ''.obs;

  // Image selection
  final selectedImageBytes = Rxn<Uint8List>();
  final selectedImageName = RxnString();

  final segments = <Map<String, String>>[].obs;
  final plans = <Map<String, String>>[].obs;

  final isLoadingData = false.obs;

  final ApiService _apiService = Get.find<ApiService>();

  @override
  void onInit() {
    super.onInit();
    fetchScheduledNotifications();
    fetchNotificationHistory();
    // Pre-fetch data or fetch on demand
  }

  void updateAudienceType(String? value) async {
    if (value != null) {
      selectedAudienceType.value = value;
      selectedAudienceId.value = ''; // Reset specific selection

      if (value == 'Segment Specific' && segments.isEmpty) {
        await fetchSegments();
      } else if (value == 'Plan Specific' && plans.isEmpty) {
        await fetchPlans();
      }
    }
  }

  void updateAudienceId(String? value) {
    if (value != null) selectedAudienceId.value = value;
  }

  Future<void> fetchSegments() async {
    try {
      isLoadingData.value = true;
      final response = await _apiService.get('/notifications/segments');
      if (response.statusCode == 200 && response.body['status'] == 200) {
        final data = List<Map<String, dynamic>>.from(response.body['data']);
        segments.assignAll(
          data
              .map(
                (e) => {
                  'id': e['_id'].toString(),
                  'name': e['segmentName'].toString(),
                },
              )
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching segments: $e');
    } finally {
      isLoadingData.value = false;
    }
  }

  Future<void> fetchPlans() async {
    try {
      isLoadingData.value = true;
      final response = await _apiService.get('/notifications/plans');
      if (response.statusCode == 200 && response.body['status'] == 200) {
        final data = List<Map<String, dynamic>>.from(response.body['data']);
        plans.assignAll(
          data
              .map(
                (e) => {
                  'id': e['_id'].toString(),
                  'name': e['planName'].toString(),
                },
              )
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching plans: $e');
    } finally {
      isLoadingData.value = false;
    }
  }

  void updateTitle(String value) {
    notificationTitle.value = value;
  }

  void updateMessage(String value) {
    notificationMessage.value = value;
  }

  void toggleSendNow(bool value) {
    sendNow.value = value;
  }

  Future<void> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Needed for web and raw bytes
      );

      if (result != null && result.files.isNotEmpty) {
        selectedImageBytes.value = result.files.first.bytes;
        selectedImageName.value = result.files.first.name;

        // Ensure image is not too large if needed, but for now assuming valid
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void clearImage() {
    selectedImageBytes.value = null;
    selectedImageName.value = null;
  }

  final scheduledDate = Rxn<DateTime>();

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        scheduledDate.value = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
      }
    }
  }

  Future<void> sendNotification() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Title is required',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }
    if (messageController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Message is required',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    if (!sendNow.value && scheduledDate.value == null) {
      Get.snackbar(
        'Error',
        'Please select a date and time for scheduling',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      isLoading.value = true;

      final body = FormData({
        'title': titleController.text.trim(),
        'message': messageController.text.trim(),
        'audience': selectedAudienceType.value,
        'audienceId': selectedAudienceId.value,
        'schedule': sendNow.value
            ? 'Send Now'
            : scheduledDate.value!.toUtc().toIso8601String(),
        if (selectedImageBytes.value != null)
          'image': MultipartFile(
            selectedImageBytes.value!,
            filename: selectedImageName.value ?? 'image.png',
          ),
      });

      final response = await _apiService.post(
        '/notifications/send?type=image',
        body,
      );

      if (response.status.hasError) {
        Get.snackbar(
          'Error',
          response.body['message'] ?? 'Failed to send notification',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      } else {
        final details = response.body['details'];
        String successMessage = 'Notification sent successfully';

        if (details != null) {
          debugPrint('Notification Details: $details');
          if (details['successCount'] != null &&
              details['failureCount'] != null) {
            successMessage +=
                '\nSuccess: ${details['successCount']}, Failed: ${details['failureCount']}';
          }
        }

        Get.snackbar(
          'Success',
          successMessage,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 5),
        );

        // Clear fields
        titleController.clear();
        messageController.clear();
        clearImage();
        notificationTitle.value = '';
        notificationMessage.value = '';

        fetchScheduledNotifications();
        fetchNotificationHistory();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  final scheduledNotifications = <Map<String, dynamic>>[].obs;
  final notificationHistory = <Map<String, dynamic>>[].obs;
  final isLoadingHistory = false.obs;

  final NotificationService _notificationService =
      Get.find<NotificationService>();

  // ... existing methods ...

  Future<void> fetchScheduledNotifications() async {
    try {
      final response = await _notificationService.getScheduledNotifications();
      if (response.statusCode == 200 && response.body['status'] == 200) {
        final data = List<Map<String, dynamic>>.from(response.body['data']);
        scheduledNotifications.assignAll(data);
      }
    } catch (e) {
      debugPrint("Error fetching scheduled notifications: $e");
    }
  }

  Future<void> deleteScheduled(String id) async {
    try {
      final response = await _notificationService.deleteScheduledNotification(
        id,
      );
      if (response.statusCode == 200 && response.body['status'] == 200) {
        Get.snackbar(
          'Success',
          'Scheduled notification deleted',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
        fetchScheduledNotifications();
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete notification',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error deleting notification: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> fetchNotificationHistory() async {
    try {
      isLoadingHistory.value = true;
      final response = await _notificationService.getNotificationHistory();
      if (response.statusCode == 200 && response.body['status'] == 200) {
        final data = List<Map<String, dynamic>>.from(response.body['data']);
        notificationHistory.assignAll(data);
      }
    } catch (e) {
      debugPrint("Error fetching notification history: $e");
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // ... inside sendNotification success block, call fetchScheduledNotifications() and fetchNotificationHistory() ...

  @override
  void onClose() {
    titleController.dispose();
    messageController.dispose();
    super.onClose();
  }
}
