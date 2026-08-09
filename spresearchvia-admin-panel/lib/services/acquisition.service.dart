import 'package:flutter/foundation.dart';
import 'package:spresearch_web/services/api.service.dart';

class AcquisitionService extends ApiService {
  Future<bool> approvePartialPayment({
    required String paymentIntentId,
    required String historyId,
    String? remark,
    double? discount,
  }) async {
    try {
      final response = await post('/acquisition/approve-partial-payment', {
        'paymentIntentId': paymentIntentId,
        'historyId': historyId,
        if (remark != null && remark.isNotEmpty) 'comment': remark,
        if (discount != null && discount > 0) 'discount': discount,
      });

      if (response.status.hasError) {
        debugPrint(
          'Error approving partial payment: ${response.statusText} - Body: ${response.body}',
        );
        return false;
      }
      return response.body['status'] == 200;
    } catch (e) {
      debugPrint('Error approving partial payment: $e');
      return false;
    }
  }

  Future<bool> rejectPartialPayment({
    required String paymentIntentId,
    required String historyId,
  }) async {
    try {
      final response = await post('/acquisition/reject-partial-payment', {
        'paymentIntentId': paymentIntentId,
        'historyId': historyId,
      });

      if (response.status.hasError) {
        debugPrint('Error rejecting partial payment: ${response.statusText}');
        return false;
      }
      return response.body['status'] == 200;
    } catch (e) {
      debugPrint('Error rejecting partial payment: $e');
      return false;
    }
  }

  Future<bool> updatePaymentDiscount({
    required String paymentIntentId,
    required double discount,
  }) async {
    try {
      final response = await post('/acquisition/update-payment-discount', {
        'paymentIntentId': paymentIntentId,
        'discount': discount,
      });

      if (response.status.hasError) {
        debugPrint('Error updating discount: ${response.statusText}');
        return false;
      }
      return response.body['status'] == 200;
    } catch (e) {
      debugPrint('Error updating discount: $e');
      return false;
    }
  }

  Future<bool> updateSubscriptionMetadata({
    required String paymentIntentId,
    required String newSegmentId,
    required String newPlanId,
    String? newStartDate,
    String? newExpiryDate,
    int? clientVersion,
  }) async {
    try {
      final response = await post('/acquisition/update-subscription-metadata', {
        'paymentIntentId': paymentIntentId,
        'newSegmentId': newSegmentId,
        'newPlanId': newPlanId,
        if (newStartDate != null) 'newStartDate': newStartDate,
        if (newExpiryDate != null) 'newExpiryDate': newExpiryDate,
        if (clientVersion != null) 'clientVersion': clientVersion,
      });

      if (response.status.hasError) {
        debugPrint(
          'Error updating metadata: ${response.statusText} - Body: ${response.body}',
        );
        return false;
      }
      return response.body['status'] == 200;
    } catch (e) {
      debugPrint('Error updating metadata: $e');
      return false;
    }
  }
}
