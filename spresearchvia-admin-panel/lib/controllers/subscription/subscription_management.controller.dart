import 'package:get/get.dart';
import 'package:spresearch_web/services/subscription.service.dart';

class SubscriptionManagementController extends GetxController {
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();
  var isLoading = false.obs;

  Future<bool> extendSubscription(String userId, int days) async {
    isLoading.value = true;
    try {
      return await _subscriptionService.extendSubscription(userId, days);
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePlan(String userId, String newPlanId) async {
    isLoading.value = true;
    try {
      return await _subscriptionService.changePlan(userId, newPlanId);
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> revokeSubscription(String userId) async {
    isLoading.value = true;
    try {
      return await _subscriptionService.revokeSubscription(userId);
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
