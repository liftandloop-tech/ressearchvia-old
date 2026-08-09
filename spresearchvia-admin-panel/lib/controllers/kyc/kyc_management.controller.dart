import 'package:get/get.dart';
import 'package:spresearch_web/services/kyc.service.dart';

class KycManagementController extends GetxController {
  final KycService _kycService = Get.find<KycService>();
  var isLoading = false.obs;

  Future<bool> updateKycStatus(String userId, String status) async {
    isLoading.value = true;
    try {
      final success = await _kycService.updateKycStatus(userId, status);
      if (success) {
        Get.snackbar(
          'Success',
          'KYC status updated to $status',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update KYC status',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return success;
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
