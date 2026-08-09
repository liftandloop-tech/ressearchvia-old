import 'package:flutter/foundation.dart';
import 'package:spresearch_web/services/api.service.dart';

class SegmentService extends ApiService {
  // onInit handled by ApiService

  Future<bool> createSegment(Map<String, dynamic> data) async {
    try {
      final response = await post('/segments/create-segments', data);

      if (response.status.hasError) {
        debugPrint('Error creating segment: ${response.statusText}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error creating segment: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSegmentDropdownList() async {
    try {
      final response = await get('/segments/segment-drop-down-list');

      if (response.status.hasError) {
        debugPrint('Error fetching segment dropdown: ${response.statusText}');
        return [];
      }

      if (response.body['status'] == 200 && response.body['data'] != null) {
        final List<dynamic> segments = response.body['data']['segmentsData'];
        return segments.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching segment dropdown: $e');
      return [];
    }
  }

  // Get all segments list
  Future<List<Map<String, dynamic>>> getSegmentsList() async {
    try {
      final response = await get('/segments/list-segments');

      if (response.status.hasError) {
        debugPrint('Error fetching segments list: ${response.statusText}');
        debugPrint('Response body: ${response.body}');
        return [];
      }

      if (response.body['status'] == 200 && response.body['data'] != null) {
        final List<dynamic> segments = response.body['data']['data'] ?? [];
        debugPrint('Fetched ${segments.length} segments');
        return segments.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching segments list: $e');
      return [];
    }
  }

  // Get plans by segment ID
  Future<List<Map<String, dynamic>>> getPlansBySegment(String segmentId) async {
    try {
      // Use segment-plan-list with id parameter
      final response = await get('/segments/segment-plan-list?id=$segmentId');

      if (response.status.hasError) {
        debugPrint('Error fetching plans: ${response.statusText}');
        debugPrint('Response body: ${response.body}');
        return [];
      }

      if (response.body['status'] == 200 && response.body['data'] != null) {
        final List<dynamic> plans = response.body['data']['planlist'] ?? [];
        debugPrint('Fetched ${plans.length} plans for segment $segmentId');
        return plans.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching plans by segment: $e');
      return [];
    }
  }

  Future<bool> createPlan(Map<String, dynamic> data) async {
    try {
      final response = await post('/segments/segment-plan-create', data);

      if (response.status.hasError) {
        debugPrint('Error creating plan: ${response.statusText}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error creating plan: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPendingBankTransfers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    try {
      // Add timestamp to prevent browser caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String url =
          '/segments/pending-bank-transfers?page=$page&pageSize=$pageSize&_t=$timestamp';

      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      if (status != null && status != 'All') {
        url += '&status=${Uri.encodeComponent(status)}';
      }

      final response = await get(url);

      if (response.status.hasError) {
        debugPrint('Error fetching pending transfers: ${response.statusText}');
        return {'totalCount': 0, 'pendingPayments': []};
      }

      if (response.body['status'] == 200 && response.body['data'] != null) {
        debugPrint(
          '[API] Received ${response.body['data']['pendingPayments']?.length ?? 0} pending payments',
        );
        return response.body['data'];
      }
      return {'totalCount': 0, 'pendingPayments': []};
    } catch (e) {
      debugPrint('Error fetching pending transfers: $e');
      return {'totalCount': 0, 'pendingPayments': []};
    }
  }

  Future<bool> adminGrantSegment({
    required String userId,
    required String segmentPlanId,
    required String paymentRefId,
    required double amount,
    String paymentMode = 'BANK_TRANSFER',
    String? remark,
    double? discount,
  }) async {
    try {
      final data = {
        'userId': userId,
        'segmentPlanId': segmentPlanId,
        'paymentRefId': paymentRefId,
        'amount': amount,
        'paymentMode': paymentMode,
        if (remark != null && remark.isNotEmpty) 'comment': remark,
        if (discount != null && discount > 0) 'discount': discount,
      };

      final response = await post('/segments/admin-grant-segment', data);

      if (response.status.hasError) {
        debugPrint('Error granting segment: ${response.statusText}');
        return false;
      }

      if (response.body['status'] == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error granting segment: $e');
      return false;
    }
  }

  Future<bool> rejectBankTransfer(String paymentId) async {
    try {
      final response = await post('/segments/reject-bank-transfer', {
        'paymentId': paymentId,
      });
      return response.status.hasError == false &&
          response.body['status'] == 200;
    } catch (e) {
      debugPrint('Error rejecting transfer: $e');
      return false;
    }
  }

  Future<bool> revertToRejected(
    String paymentIntentId, {
    String? reason,
    String? historyId,
  }) async {
    try {
      final response = await post('/segments/revert-to-rejected', {
        'paymentIntentId': paymentIntentId,
        if (historyId != null && historyId.isNotEmpty) 'historyId': historyId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return response.status.hasError == false &&
          response.body['status'] == 200;
    } catch (e) {
      debugPrint('Error reverting approval: $e');
      return false;
    }
  }

  Future<bool> revertToApproved(
    String paymentIntentId, {
    String? historyId,
    String? reason,
  }) async {
    try {
      final response = await post('/segments/revert-to-approved', {
        'paymentIntentId': paymentIntentId,
        if (historyId != null && historyId.isNotEmpty) 'historyId': historyId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return response.status.hasError == false &&
          response.body['status'] == 200;
    } catch (e) {
      debugPrint('Error reverting rejection: $e');
      return false;
    }
  }
}
