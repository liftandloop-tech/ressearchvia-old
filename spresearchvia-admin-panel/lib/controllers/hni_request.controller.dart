import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/api.service.dart';

class HniRequestController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isLoading = false.obs;
  final requests = <Map<String, dynamic>>[].obs;
  final staffList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchStaffList();
  }

  Future<void> fetchHniRequests() async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/segments/hni-requests');

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body as Map<String, dynamic>;
        if (data['data'] != null && data['data']['requests'] != null) {
          requests.value = List<Map<String, dynamic>>.from(
            data['data']['requests'],
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch HNI requests: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStaffList() async {
    try {
      final response = await _apiService.get('/staff/list');

      if (response.statusCode == 200 && response.body != null) {
        if (response.body is Map) {
          final data = response.body as Map<String, dynamic>;
          if (data['data'] != null && data['data']['staffList'] != null) {
            staffList.value = List<Map<String, dynamic>>.from(
              data['data']['staffList'],
            );
          }
        }
      } else {
        debugPrint(
          'Failed to fetch staff list: ${response.statusCode} ${response.statusText}',
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch staff list: $e');
    }
  }

  Future<void> grantHniPlan({
    required String requestId,
    required String userId,
    required String segmentId,
    required String planId,
    required double customPrice,
    required int customValidity,
    required String assignedRaId,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService
          .post('/segments/admin-grant-hni-plan', {
            'requestId': requestId,
            'userId': userId,
            'segmentId': segmentId,
            'planId': planId,
            'customPrice': customPrice,
            'customValidity': customValidity,
            'assignedRaId': assignedRaId,
          });

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'HNI Plan granted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        await fetchHniRequests(); // Refresh list
      } else {
        throw Exception('Failed to grant plan: ${response.statusText}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to grant plan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      isLoading.value = true;

      // You can implement a reject endpoint or just delete the request
      Get.snackbar(
        'Info',
        'Reject functionality to be implemented',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
