import 'package:get/get.dart';
import 'segment_plan.controller.dart';
import '../services/api_client.service.dart';
import '../core/config/api.config.dart';
import '../services/snackbar.service.dart';

class SegmentDropdownController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  
  // Use RxString with empty string to handle initial state (safest for hot reload vs Rxn)
  final selectedSegment = ''.obs;
  final isOpen = false.obs;
  final isLoading = false.obs;
  
  // Observable list for segments fetched from API (storing full maps now)
  final segments = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSegments();
  }

  Future<void> fetchSegments() async {
    try {
      isLoading.value = true;
      final response = await _apiClient.get(ApiConfig.segmentDropDownList);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null && data['data']['segmentsData'] != null) {
          final List<dynamic> segmentsData = data['data']['segmentsData'];
          
          segments.value = segmentsData
              .cast<Map<String, dynamic>>()
              .where((s) => s['segmentStatus']?.toString().toLowerCase() == 'active')
              .toList();
          
          // Set default selected segment if available and none selected
          if (segments.isNotEmpty && selectedSegment.value.isEmpty) {
            final spark = segments.firstWhereOrNull((s) => s['segmentName'] == 'SPARK');
            if (spark != null) {
              selectSegment(spark['segmentName'], segmentId: spark['_id']);
            } else {
              selectSegment(segments.first['segmentName'], segmentId: segments.first['_id']);
            }
          }
        }
      }
    } catch (e) {
      Get.log('Error fetching segments: $e');
      SnackbarService.showError('Failed to load segments');
    } finally {
      isLoading.value = false;
    }
  }

  void selectSegment(String segment, {String? segmentId}) {
    selectedSegment.value = segment;
    isOpen.value = false;

    try {
      final segmentPlanController = Get.find<SegmentPlanController>();
      segmentPlanController.filterBySegment(segment, segmentId: segmentId);
    } catch (e) {
      Get.log('Error finding SegmentPlanController: $e');
    }
  }

  void toggleDropdown() {
    isOpen.value = !isOpen.value;
  }
}
