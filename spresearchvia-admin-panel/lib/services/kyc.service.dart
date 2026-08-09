import 'package:flutter/foundation.dart';
import 'package:spresearch_web/services/api.service.dart';

class KycService extends ApiService {
  // onInit handled by ApiService

  Future<bool> updateKycStatus(String userId, String status) async {
    try {
      final response = await patch(
        '/user/kyc/document/kyc-status-change',
        {},
        query: {'userId': userId, 'status': status},
      );

      if (response.status.hasError) {
        debugPrint('Error updating KYC status: ${response.statusText}');
        return false;
      }

      return response.body['status'] == 200;
    } catch (e) {
      debugPrint('Error updating KYC status: $e');
      return false;
    }
  }
}
