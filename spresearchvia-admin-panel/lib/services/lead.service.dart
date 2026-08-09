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

  Future<bool> addFollowUp(String id, String notes, DateTime followUpDate) async {
    try {
      final response = await post('/leads/follow-up/$id', {
        'notes': notes,
        'followUpDate': followUpDate.toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error adding follow-up: $e');
      return false;
    }
  }

  Future<({bool success, String? message})> uploadBulkLeads(List<int> bytes, String filename) async {
    try {
      final formData = FormData({
        'file': MultipartFile(bytes, filename: filename),
      });

      final response = await post('/leads/bulk-upload', formData);
      if (response.statusCode == 200) {
        return (success: true, message: response.body?['message']?.toString());
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Bulk upload failed');
    } catch (e) {
      debugPrint('Error bulk uploading leads: $e');
      return (success: false, message: e.toString());
    }
  }
}
