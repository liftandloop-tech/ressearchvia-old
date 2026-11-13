import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api.service.dart';
import '../models/lead.model.dart';

class LeadService extends ApiService {
  Future<({List<LeadModel> leads, int total, String? error})> getLeads({
    int page = 1,
    int limit = 10,
    String search = '',
    String name = '',
    String mobile = '',
    String location = '',
    String stage = '',
    String assignedRM = '',
    String? leadPoolId,
    String? campaignId,
    String? leadVendorId,
    String? segmentId,
    String? leadSource,
    bool? isAppUser,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final query = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
        if (name.isNotEmpty) 'name': name,
        if (mobile.isNotEmpty) 'mobile': mobile,
        if (location.isNotEmpty) 'location': location,
        if (stage.isNotEmpty) 'stage': stage,
        if (assignedRM.isNotEmpty) 'assignedRM': assignedRM,
        if (leadPoolId != null && leadPoolId.isNotEmpty) 'leadPoolId': leadPoolId,
        if (campaignId != null && campaignId.isNotEmpty) 'campaignId': campaignId,
        if (leadVendorId != null && leadVendorId.isNotEmpty) 'leadVendorId': leadVendorId,
        if (segmentId != null && segmentId.isNotEmpty) 'segmentId': segmentId,
        if (leadSource != null && leadSource.isNotEmpty) 'leadSource': leadSource,
        if (isAppUser != null) 'isAppUser': isAppUser.toString(),
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      };

      final response = await get('/leads', query: query, forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'];
        final total = data['total'] as int? ?? 0;
        final list = data['leads'] as List<dynamic>? ?? [];
        final leads = list.map((x) => LeadModel.fromJson(x as Map<String, dynamic>)).toList();
        return (leads: leads, total: total, error: null);
      }
      return (leads: <LeadModel>[], total: 0, error: (response.body?['message'] ?? 'Failed to load leads').toString());
    } catch (e) {
      debugPrint('Error getting leads: $e');
      return (leads: <LeadModel>[], total: 0, error: e.toString());
    }
  }

  Future<bool> createLead(Map<String, dynamic> data) async {
    try {
      final response = await post('/leads/create', data);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error creating lead: $e');
      return false;
    }
  }

  Future<bool> updateLead(String id, Map<String, dynamic> data) async {
    try {
      final response = await put('/leads/update/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating lead: $e');
      return false;
    }
  }

  Future<bool> addFollowUp(
    String id,
    String notes,
    DateTime followUpDate, {
    required String followUpType,
    required String status,
    DateTime? nextFollowUpDate,
  }) async {
    try {
      final response = await post('/leads/follow-up/$id', {
        'notes': notes,
        'followUpDate': followUpDate.toIso8601String(),
        'followUpType': followUpType,
        'status': status,
        if (nextFollowUpDate != null)
          'nextFollowUpDate': nextFollowUpDate.toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error adding follow-up: $e');
      return false;
    }
  }

  Future<bool> updateFollowUpStatus(
    String leadId,
    String followUpId, {
    String? status,
    String? notes,
    DateTime? rescheduleDate,
    DateTime? nextFollowUpDate,
  }) async {
    try {
      final response = await patch('/leads/$leadId/follow-up/$followUpId', {
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
        if (rescheduleDate != null) 'rescheduleDate': rescheduleDate.toIso8601String(),
        if (nextFollowUpDate != null) 'nextFollowUpDate': nextFollowUpDate.toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating follow-up: $e');
      return false;
    }
  }

  Future<({List<PendingFollowUpModel> followUps, int total, String? error})> getPendingFollowups({
    int page = 1,
    int limit = 20,
    bool isOverdue = false,
  }) async {
    try {
      final query = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (isOverdue) 'isOverdue': 'true',
      };
      final response = await get('/leads/pending-followups', query: query, forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'];
        final total = data['total'] as int? ?? 0;
        final list = data['followUps'] as List<dynamic>? ?? [];
        final followUps = list.map((x) => PendingFollowUpModel.fromJson(x as Map<String, dynamic>)).toList();
        return (followUps: followUps, total: total, error: null);
      }
      return (followUps: <PendingFollowUpModel>[], total: 0, error: (response.body?['message'] ?? 'Failed to load followups').toString());
    } catch (e) {
      debugPrint('Error getting pending followups: $e');
      return (followUps: <PendingFollowUpModel>[], total: 0, error: e.toString());
    }
  }

  Future<List<LeadTimelineModel>> getLeadTimeline(String leadId) async {
    try {
      final response = await get('/leads/$leadId/timeline', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data'] as List<dynamic>? ?? [];
        return list.map((x) => LeadTimelineModel.fromJson(x as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting lead timeline: $e');
      return [];
    }
  }

  Future<bool> assignLeadSegments(String leadId, List<String> segmentIds) async {
    try {
      final response = await post('/leads/$leadId/segments', {'segmentIds': segmentIds});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error assigning segments: $e');
      return false;
    }
  }

  Future<bool> updateFreeTrial(String leadId, DateTime? startDate, DateTime? endDate) async {
    try {
      final response = await patch('/leads/$leadId/free-trial', {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating free trial: $e');
      return false;
    }
  }

  Future<List<LeadCampaignModel>> getCampaigns() async {
    try {
      final response = await get('/leads/campaigns', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data'] as List<dynamic>? ?? [];
        return list.map((x) => LeadCampaignModel.fromJson(x as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading campaigns: $e');
      return [];
    }
  }

  Future<bool> createCampaign(Map<String, dynamic> data) async {
    try {
      final response = await post('/leads/campaigns', data);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error creating campaign: $e');
      return false;
    }
  }

  Future<List<LeadVendorModel>> getVendors() async {
    try {
      final response = await get('/leads/vendors', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data'] as List<dynamic>? ?? [];
        return list.map((x) => LeadVendorModel.fromJson(x as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading vendors: $e');
      return [];
    }
  }

  Future<bool> createVendor(Map<String, dynamic> data) async {
    try {
      final response = await post('/leads/vendors', data);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error creating vendor: $e');
      return false;
    }
  }

  Future<List<LeadSegmentModel>> getSegments() async {
    try {
      final response = await get('/leads/segments', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data'] as List<dynamic>? ?? [];
        return list.map((x) => LeadSegmentModel.fromJson(x as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading segments: $e');
      return [];
    }
  }

  Future<Response> uploadBulkLeads(List<int> bytes, String filename) async {
    final formData = FormData({
      'file': MultipartFile(bytes, filename: filename),
    });
    return post('/leads/bulk-upload', formData);
  }

  Future<Response> bulkPasteLeads({
    required String rawText,
    String? leadPoolId,
    String? campaignId,
    String? leadVendorId,
    String? assignedRM,
    String stage = 'New',
    String duplicateStrategy = 'skip',
    String duplicatePolicy = 'skip',
    String defaultName = '',
  }) async {
    return post('/leads/bulk-paste', {
      'rawText': rawText,
      if (leadPoolId != null && leadPoolId.isNotEmpty) 'leadPoolId': leadPoolId,
      if (campaignId != null && campaignId.isNotEmpty) 'campaignId': campaignId,
      if (leadVendorId != null && leadVendorId.isNotEmpty) 'leadVendorId': leadVendorId,
      if (assignedRM != null && assignedRM.isNotEmpty) 'assignedRM': assignedRM,
      'stage': stage,
      'duplicateStrategy': duplicateStrategy,
      'duplicatePolicy': duplicatePolicy,
      'defaultName': defaultName,
    });
  }

  Future<Response> bulkAssignByNumbers({
    required String rawNumbers,
    required String assignedRM,
  }) async {
    return post('/leads/bulk-assign-by-numbers', {
      'rawNumbers': rawNumbers,
      'assignedRM': assignedRM,
    });
  }

  Future<Response> startImport(String importId, Map<String, dynamic> data) =>
      post('/leads/import/$importId/start', data);

  Future<Response> getImportPreview(String importId, Map<String, dynamic> mapping) =>
      post('/leads/import/$importId/preview', {'mapping': mapping});

  Future<Response> getImportStatus(String importId) =>
      get('/leads/import/$importId/status');

  Future<Response> getImportErrors(String importId) =>
      get('/leads/import/$importId/errors');

  Future<Response> getImportFields() =>
      get('/leads/import-fields');

  Future<Response> getTemplates() =>
      get('/leads/import/templates');

  Future<Response> saveTemplate(String name, Map<String, dynamic> mappings) =>
      post('/leads/import/templates', {'name': name, 'mappings': mappings});

  Future<Response> getLeadPools() =>
      get('/leads/pools');

  Future<Response> createLeadPool(
    String name,
    String? description, {
    int initialPullSize = 20,
    int subsequentPullSize = 30,
    int maxPerStaff = 50,
    int? pullSize,
    List<String>? assignedStaffIds,
  }) =>
      post('/leads/pools', {
        'name': name,
        if (description != null) 'description': description,
        'initialPullSize': initialPullSize,
        'subsequentPullSize': subsequentPullSize,
        'pullSize': pullSize ?? initialPullSize,
        'maxPerStaff': maxPerStaff,
        if (assignedStaffIds != null && assignedStaffIds.isNotEmpty) 'assignedStaffIds': assignedStaffIds,
      });

  Future<Response> updateLeadPool(String id, Map<String, dynamic> data) =>
      put('/leads/pools/$id', data);

  Future<Response> deleteLeadPool(String id) =>
      delete('/leads/pools/$id');

  Future<Response> assignLeadPool(String poolId, List<String> staffIds, {bool? canDelegate}) =>
      post('/leads/pools/$poolId/assign', {
        'staffIds': staffIds,
        if (canDelegate != null) 'canDelegate': canDelegate,
      });

  Future<Response> getAssignableStaffForPool(String poolId) =>
      get('/leads/pools/$poolId/assignable-staff');

  Future<Response> pullLeads(String type, {String? poolId}) =>
      post('/leads/pull', {
        'type': type,
        if (poolId != null) 'poolId': poolId,
      });

  Future<Response> getPullStats({String? poolId}) =>
      get(poolId != null ? '/leads/pull-stats?poolId=$poolId' : '/leads/pull-stats');

  Future<Response> markLeadRead(String id) =>
      patch('/leads/$id/read', {});

  Future<Response> getLeadDistributionSettings() =>
      get('/settings/lead_distribution');

  Future<Response> saveLeadDistributionSettings(Map<String, dynamic> value) =>
      post('/settings/lead_distribution', {'value': value});

  Future<Response> bulkAssignLeads(List<String> leadIds, String? staffId) =>
      post('/leads/bulk-assign', {
        'leadIds': leadIds,
        'assignedRM': staffId ?? 'unassigned',
      });
}
