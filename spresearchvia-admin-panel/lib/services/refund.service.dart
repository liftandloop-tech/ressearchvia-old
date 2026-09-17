import 'package:flutter/foundation.dart';
import 'package:spresearch_web/services/api.service.dart';

class RefundService extends ApiService {
  /// Preview refund calculation (prorated vs full)
  Future<Map<String, dynamic>?> previewRefundCalculation({
    required String userId,
    String? planId,
    String? paymentIntentId,
    required double originalAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = {
        'userId': userId,
        'planId': planId,
        'paymentIntentId': paymentIntentId,
        'originalAmount': originalAmount,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

      final response = await post('/refund/preview', body);
      if (response.statusCode == 200 && response.body != null) {
        if (response.body is Map && response.body['data'] != null) {
          return Map<String, dynamic>.from(response.body['data']);
        }
        return Map<String, dynamic>.from(response.body);
      } else {
        if (kDebugMode) {
          debugPrint('Preview refund error: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in previewRefundCalculation: $e');
      }
      return null;
    }
  }

  /// Process and execute refund (Admin Only)
  Future<Map<String, dynamic>> processRefund(Map<String, dynamic> payload) async {
    try {
      final response = await post('/refund/process', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.body?['message'] ?? 'Refund processed successfully',
          'data': response.body?['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.body?['message'] ?? 'Failed to process refund (Status ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error processing refund: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Fetch user refund history
  Future<List<Map<String, dynamic>>> getUserRefunds(String userId) async {
    try {
      final response = await get('/refund/user/$userId');
      if (response.statusCode == 200 && response.body != null) {
        final List? refunds = response.body['data']?['refunds'];
        if (refunds != null) {
          return List<Map<String, dynamic>>.from(refunds);
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user refunds: $e');
      }
      return [];
    }
  }
}
