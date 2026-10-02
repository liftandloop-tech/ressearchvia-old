import 'package:flutter/foundation.dart';
import 'api.service.dart';
import '../models/call_log.model.dart';

class TelephonyService extends ApiService {
  /// Initiate a Click-to-Call session via Airtel/Vonage Virtual SIM
  Future<({bool success, String? callId, String? callLogId, String? message})> initiateClickToCall({
    required String leadId,
    String? extension,
  }) async {
    try {
      final payload = {
        'leadId': leadId,
        if (extension != null && extension.trim().isNotEmpty) 'extension': extension.trim(),
      };

      final response = await post('/telephony/click-to-call', payload);
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'];
        return (
          success: true,
          callId: data?['callId']?.toString(),
          callLogId: data?['callLogId']?.toString(),
          message: response.body['message']?.toString(),
        );
      }

      final errorMsg = response.body?['message']?.toString() ?? 'Failed to initiate call';
      return (success: false, callId: null, callLogId: null, message: errorMsg);
    } catch (e) {
      debugPrint('[TelephonyService] Error initiating call: $e');
      return (success: false, callId: null, callLogId: null, message: e.toString());
    }
  }

  /// Get live status of an active call
  Future<({bool success, String status, int durationSeconds, CallLogModel? callLog})> getCallStatus(String callId) async {
    try {
      final response = await get('/telephony/calls/$callId/status', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'];
        if (data != null && data is Map<String, dynamic>) {
          final log = CallLogModel.fromJson(data);
          return (
            success: true,
            status: log.status,
            durationSeconds: log.durationSeconds,
            callLog: log,
          );
        }
      }
      return (success: false, status: 'unknown', durationSeconds: 0, callLog: null);
    } catch (e) {
      debugPrint('[TelephonyService] Error getting call status: $e');
      return (success: false, status: 'error', durationSeconds: 0, callLog: null);
    }
  }

  /// Hangup / Terminate an ongoing call
  Future<bool> hangupCall(String callId) async {
    try {
      final response = await post('/telephony/calls/$callId/hangup', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[TelephonyService] Error hanging up call: $e');
      return false;
    }
  }

  /// Fetch call logs for a lead
  Future<List<CallLogModel>> getLeadCalls(String leadId) async {
    try {
      final response = await get('/telephony/lead/$leadId/calls', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data'] as List<dynamic>? ?? [];
        return list.map((item) => CallLogModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[TelephonyService] Error fetching lead calls: $e');
      return [];
    }
  }

  /// Log follow-up details from a call session
  Future<bool> logCallFollowUp({
    required String callLogId,
    required String notes,
    String status = 'Completed',
    DateTime? nextFollowUpDate,
    String? stage,
  }) async {
    try {
      final payload = {
        'notes': notes,
        'status': status,
        if (nextFollowUpDate != null) 'nextFollowUpDate': nextFollowUpDate.toIso8601String(),
        if (stage != null && stage.isNotEmpty) 'stage': stage,
      };

      final response = await post('/telephony/calls/$callLogId/log-followup', payload);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[TelephonyService] Error logging call follow-up: $e');
      return false;
    }
  }

  /// Get available extensions
  Future<List<Map<String, dynamic>>> getExtensions() async {
    try {
      final response = await get('/telephony/extensions', cacheTtlSeconds: 120);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data'] as List<dynamic>? ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[TelephonyService] Error getting extensions: $e');
      return [];
    }
  }
}
