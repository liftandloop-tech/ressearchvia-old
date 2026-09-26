import 'package:get/get.dart';
import '../services/api_client.service.dart';
import '../services/api_exception.service.dart';
import '../services/snackbar.service.dart';
import '../core/config/api.config.dart';
import 'segment_plan.controller.dart';

class SegmentItem {
  final String id;
  final String name;
  final String description;
  final RxBool isActive;
  final RxBool isToggling;

  SegmentItem({
    required this.id,
    required this.name,
    required this.description,
    required bool isActive,
  })  : isActive = isActive.obs,
        isToggling = false.obs;
}

class ManageSegmentsController extends GetxController {
  final ApiClient _apiClient = ApiClient();

  final RxBool isLoading = false.obs;
  final RxBool hasActivePlan = false.obs;
  final RxMap<String, dynamic> activePlan = <String, dynamic>{}.obs;
  final RxList<SegmentItem> segments = <SegmentItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserPlanSegments();
  }

  Future<void> fetchUserPlanSegments() async {
    try {
      isLoading.value = true;
      final response = await _apiClient.get(ApiConfig.userPlanSegments);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          hasActivePlan.value = data['hasActivePlan'] ?? false;
          if (data['activePlan'] != null) {
            activePlan.value = Map<String, dynamic>.from(data['activePlan']);
          } else {
            activePlan.clear();
          }

          final List<dynamic> rawSegs = data['segments'] ?? [];
          segments.value = rawSegs.map((s) => SegmentItem(
            id: s['_id'],
            name: s['segmentName'] ?? '',
            description: s['segmentDiscription'] ?? '',
            isActive: s['isActive'] ?? false,
          )).toList();
        }
      }
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleSegment(SegmentItem item) async {
    final currentlyActive = item.isActive.value;
    final activeCount = segments.where((s) => s.isActive.value).length;

    // Client-side rule: At least 1 segment must stay active
    if (currentlyActive && activeCount <= 1) {
      SnackbarService.showWarning('At least one segment must remain active.');
      return;
    }

    try {
      item.isToggling.value = true;
      final nextStatus = !currentlyActive;

      final response = await _apiClient.post(
        ApiConfig.toggleUserSegment,
        data: {
          'segmentId': item.id,
          'activate': nextStatus,
        },
      );

      if (response.statusCode == 200) {
        item.isActive.value = nextStatus;
        SnackbarService.showSuccess(
          nextStatus
              ? '${item.name} activated successfully!'
              : '${item.name} deactivated successfully!',
        );

        // Synchronize SegmentPlanController so dashboard and other screens reflect the change
        if (Get.isRegistered<SegmentPlanController>()) {
          Get.find<SegmentPlanController>().fetchActiveSegment(force: true);
        }
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to update segment');
      }
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
    } finally {
      item.isToggling.value = false;
    }
  }
}
