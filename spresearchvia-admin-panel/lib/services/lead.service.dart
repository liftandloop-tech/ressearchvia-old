import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api.service.dart';
import '../models/lead.model.dart';

class LeadService extends ApiService {
  Future<({List<LeadModel> leads, int total, String? error})> getLeads({
    int page = 1,
    int limit = 10,
    String search = '',
    String stage = '',
    String assignedRM = '',
  }) async {
    try {
      final query = {
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search,
        'stage': stage,
        'assignedRM': assignedRM,
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

  Future<Response> uploadBulkLeads(List<int> bytes, String filename) async {
    final formData = FormData({
      'file': MultipartFile(bytes, filename: filename),
    });
    return post('/leads/bulk-upload', formData);
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

  Future<Response> createLeadPool(String name, String? description) =>
      post('/leads/pools', {'name': name, 'description': description});

  Future<Response> pullLeads(String type) =>
      post('/leads/pull', {'type': type});

  Future<Response> getPullStats() =>
      get('/leads/pull-stats');

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
