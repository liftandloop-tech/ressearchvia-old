import 'package:get/get.dart';
import 'plan_purchase.controller.dart';

class BillingHistoryController extends GetxController {
  final PlanPurchaseController _planPurchaseController = Get.isRegistered<PlanPurchaseController>() 
      ? Get.find<PlanPurchaseController>() 
      : Get.put(PlanPurchaseController());
  
  final billingHistory = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBillingHistory();
  }

  Future<void> fetchBillingHistory() async {
    try {
      isLoading.value = true;
      final history = await _planPurchaseController.fetchBillingHistoryApi();
      billingHistory.assignAll(history);
    } catch (e) {
      print('Error fetching billing history: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
