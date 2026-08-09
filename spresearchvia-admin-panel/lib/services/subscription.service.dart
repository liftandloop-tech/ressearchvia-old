import 'package:flutter/foundation.dart';
import 'package:spresearch_web/services/api.service.dart';
import 'package:get/get.dart';
import '../models/subscription_plan.model.dart';
import '../models/segment.model.dart';

class SubscriptionService extends ApiService {
  // onInit handled by ApiService

  Future<({List<SubscriptionPlanModel> plans, int totalCount})>
  getSubscriptionPlans({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    String? date,
  }) async {
    try {
      final query = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (search != null && search.isNotEmpty) {
        query['search'] = search;
      }
      if (status != null && status != 'All Status') {
        query['status'] = status.toLowerCase();
      }

      final response = await get(
        '/segments/subscriptions-plan-list',
        query: query,
      );

      if (response.statusCode == 200 && response.body != null) {
        final data = SubscriptionPlanResponse.fromJson(response.body);
        return (plans: data.data.plans, totalCount: data.data.totalCount);
      } else {
        if (kDebugMode) {
          debugPrint(
            'Failed to fetch subscription plans: ${response.statusCode}',
          );
        }
        return (plans: <SubscriptionPlanModel>[], totalCount: 0);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching subscription plans: $e');
      }
      return (plans: <SubscriptionPlanModel>[], totalCount: 0);
    }
  }

  Future<List<SegmentModel>> getSegments() async {
    try {
      final response = await get('/segments/subscriptions-segment-list');

      if (response.statusCode == 200 && response.body != null) {
        final data = SegmentResponse.fromJson(response.body);
        return data.data.segmentsData;
      } else {
        if (kDebugMode) {
          debugPrint('Failed to fetch segments: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching segments: $e');
      }
      return [];
    }
  }

  Future<bool> updateSegment({
    required String segmentId,
    required String name,
    required String description,
    required String status,
  }) async {
    try {
      final body = {
        "segmentName": name,
        "segmentDiscription": description,
        "segmentStatus": status,
      };
      final response = await put(
        '/segments/update-segments?segmentId=$segmentId',
        body,
      );
      debugPrint(
        'Update segment response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating segment: $e');
      }
      return false;
    }
  }

  Future<bool> createSegment({
    required String name,
    required String description,
    required String status,
  }) async {
    try {
      final body = {
        "segmentName": name,
        "segmentDiscription": description,
        "segmentStatus": status,
      };
      final response = await post('/segments/create-segments', body);
      debugPrint(
        'Create segment response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating segment: $e');
      }
      return false;
    }
  }

  Future<bool> deleteSegment(String segmentId) async {
    try {
      final response = await delete(
        '/segments/delete-segments?segmentId=$segmentId',
      );
      debugPrint(
        'Delete segment response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting segment: $e');
      }
      return false;
    }
  }

  Future<bool> updatePlan({
    required String planId,
    required String name,
    required int duration,
    required String day,
    required double price,
    required String description,
    required String planFeatures,
    required String planStatus,
    bool isHni = false,
  }) async {
    try {
      final body = {
        "planName": name,
        "duration": duration,
        "day": day,
        "price": price,
        "discription": description,
        "planFeatures": planFeatures,
        "planStatus": planStatus,
        "isHni": isHni,
      };
      final response = await put(
        '/segments/segment-plan-update?id=$planId',
        body,
      );
      debugPrint(
        'Update plan response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating plan: $e');
      }
      return false;
    }
  }

  Future<bool> deletePlan(String planId) async {
    try {
      final response = await delete('/segments/segment-plan-delete?id=$planId');
      debugPrint(
        'Delete plan response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting plan: $e');
      }
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

  Future<bool> createPlan(Map<String, dynamic> data) async {
    try {
      // Remove any previously existing multiplication by 100 if present in passed data,
      // but here we just ensure we don't multiply it again if we were doing it.
      // Actually the logic was inside this block.

      final response = await post('/segments/segment-plan-create', data);
      debugPrint(
        'Create plan response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating plan: $e');
      return false;
    }
  }

  Future<bool> extendSubscription(String userId, int days) async {
    try {
      final body = {"userId": userId, "days": days};
      final response = await put('/user/purchase/extend-subscription', body);
      debugPrint(
        'Extend subscription response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error extending subscription: $e');
      return false;
    }
  }

  Future<bool> changePlan(String userId, String newPlanId) async {
    try {
      final body = {"userId": userId, "newPlanId": newPlanId};
      final response = await put('/user/purchase/change-plan', body);
      debugPrint(
        'Change plan response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error changing plan: $e');
      return false;
    }
  }

  Future<bool> revokeSubscription(String userId, {String? planId}) async {
    try {
      final body = {"userId": userId, if (planId != null) "planId": planId};
      final response = await put('/user/purchase/revoke-subscription', body);
      debugPrint(
        'Revoke subscription response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error revoking subscription: $e');
      return false;
    }
  }

  Future<bool> suspendSubscription(
    String userId, {
    String? planId,
    String? reason,
  }) async {
    try {
      final body = {
        "userId": userId,
        if (planId != null) "planId": planId,
        if (reason != null) "reason": reason,
      };
      final response = await put('/user/purchase/suspend-subscription', body);
      debugPrint(
        'Suspend subscription response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error suspending subscription: $e');
      return false;
    }
  }

  Future<bool> activateSubscription(String userId, {String? planId}) async {
    try {
      final body = {"userId": userId, if (planId != null) "planId": planId};
      final response = await put('/user/purchase/activate-subscription', body);
      debugPrint(
        'Activate subscription response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error activating subscription: $e');
      return false;
    }
  }

  Future<bool> adminTopUpPartialPlan({
    required String userId,
    required String entitlementId,
    required double amount,
    String? comment,
  }) async {
    try {
      final body = {
        "userId": userId,
        "entitlementId": entitlementId,
        "amount": amount,
        if (comment != null) "comment": comment,
      };
      final response = await post(
        '/user/purchase/admin/topup-partial-plan',
        body,
      );
      debugPrint(
        'TopUp partial plan response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error topping up partial plan: $e');
      return false;
    }
  }

  Future<bool> updateSubscriptionDates({
    required String planId,
    String? startDate,
    String? endDate,
    String? editReason,
  }) async {
    try {
      final body = {
        "planId": planId,
        if (startDate != null) "startDate": startDate,
        if (endDate != null) "endDate": endDate,
        if (editReason != null) "editReason": editReason,
      };
      final response = await put(
        '/user/purchase/update-subscription-dates',
        body,
      );
      debugPrint(
        'Update dates response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating dates: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserSubscriptions(String userId) async {
    try {
      final response = await get(
        '/user/purchase/user-subscription-history/$userId?pageSize=100&includeTrials=true',
      );
      if (response.statusCode == 200 && response.body['status'] == 200) {
        final data = response.body['data'];
        if (data is Map && data.containsKey('userSubcriptionHistory')) {
          return List<Map<String, dynamic>>.from(
            data['userSubcriptionHistory'],
          );
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user subscriptions: $e');
      return [];
    }
  }

  Future<bool> adminCreatePlan({
    required String userId,
    required String packageName,
    required double amount,
    required int validity,
    DateTime? startDate,
    required String segmentId,
    List<String>? segmentIds,
    String? planId,
    bool isPartial = false,
    double? partialAmountPaid,
    String? comment,
    double? totalAgreementPrice,
    String? raId,
    bool isHniGrant = false,
  }) async {
    try {
      final body = {
        "userId": userId,
        "segmentId": segmentId,
        "segmentIds": segmentIds,
        "packageName": packageName,
        "amount": isPartial ? partialAmountPaid : amount,
        "validity": validity,
        if (startDate != null) "startDate": startDate.toIso8601String(),
        if (planId != null) "planId": planId,
        "isPartial": isPartial,
        if (comment != null) "comment": comment,
        if (totalAgreementPrice != null)
          "totalAgreementPrice": totalAgreementPrice,
        if (raId != null) "raId": raId,
        "isHniGrant": isHniGrant,
      };
      final response = await post('/user/purchase/admin/create-plan', body);
      debugPrint(
        'Admin create plan response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating plan (admin): $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> adminPreviewCorrection({
    required String paymentIntentId,
    required double newAmount,
    required bool targetIsPartial,
  }) async {
    try {
      final body = {
        "paymentIntentId": paymentIntentId,
        "newAmount": newAmount,
        "targetIsPartial": targetIsPartial,
      };
      final response = await post(
        '/user/purchase/admin/preview-correction',
        body,
      );
      if (response.statusCode == 200 && response.body != null) {
        return Map<String, dynamic>.from(response.body['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error previewing correction: $e');
      return null;
    }
  }

  Future<bool> adminUpdatePayment({
    required String paymentIntentId,
    required double newAmount,
    required bool targetIsPartial,
    required String reason,
    required String previewTimestamp,
    String? utrNumber,
    List<dynamic>? files, // Pass PlatformFile list
  }) async {
    try {
      if (files != null && files.isNotEmpty) {
        List<MultipartFile> multipartList = [];
        for (var f in files) {
          if (f.bytes != null) {
            multipartList.add(MultipartFile(f.bytes!, filename: f.name));
          }
        }
        final formData = FormData({
          "paymentIntentId": paymentIntentId,
          "newAmount": newAmount.toString(),
          "targetIsPartial": targetIsPartial.toString(),
          "reason": reason,
          "previewTimestamp": previewTimestamp,
          if (utrNumber != null) "utrNumber": utrNumber,
          "file": multipartList,
        });
        final response = await post(
          '/user/purchase/admin/update-payment',
          formData,
        );
        return response.statusCode == 200 || response.statusCode == 201;
      } else {
        final body = {
          "paymentIntentId": paymentIntentId,
          "newAmount": newAmount,
          "targetIsPartial": targetIsPartial,
          "reason": reason,
          "previewTimestamp": previewTimestamp,
          if (utrNumber != null) "utrNumber": utrNumber,
        };
        final response = await post(
          '/user/purchase/admin/update-payment',
          body,
        );
        return response.statusCode == 200 || response.statusCode == 201;
      }
    } catch (e) {
      debugPrint('Error updating payment: $e');
      return false;
    }
  }
}
