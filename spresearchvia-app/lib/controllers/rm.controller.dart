import 'package:get/get.dart';
import '../core/models/relationship_manager.dart';
import '../services/api_client.service.dart';

class RMController extends GetxController {
  final Rx<RelationshipManager?> assignedRM = Rx<RelationshipManager?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final _apiClient = ApiClient();

  @override
  void onInit() {
    super.onInit();
    fetchAssignedRM();
  }

  Future<void> fetchAssignedRM() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiClient.get('/staff/my-rm');

      final data = response.data;
      if (data != null && data['data'] != null && data['data']['rm'] != null) {
        assignedRM.value = RelationshipManager.fromJson(
          Map<String, dynamic>.from(data['data']['rm']),
        );
      } else {
        assignedRM.value = null;
        errorMessage.value = data?['message'] ?? 'No RM assigned';
      }
    } catch (e) {
      Get.log('Error fetching assigned RM: $e');
      errorMessage.value = 'An error occurred';
    } finally {
      isLoading.value = false;
    }
  }

  void refresh() {
    fetchAssignedRM();
  }
}
