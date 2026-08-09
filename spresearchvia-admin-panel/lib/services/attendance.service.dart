import 'package:flutter/foundation.dart';
import 'api.service.dart';
import '../models/attendance.model.dart';

class AttendanceService extends ApiService {
  Future<({List<AttendanceModel> records, String? error})> getAttendanceReport({
    String? startDate,
    String? endDate,
    String? staffId,
  }) async {
    try {
      final query = <String, String>{};
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;
      if (staffId != null) query['staffId'] = staffId;

      final response = await get('/staff-reports/attendance', query: query, forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data']['records'] as List<dynamic>? ?? [];
        final records = list.map((x) => AttendanceModel.fromJson(x as Map<String, dynamic>)).toList();
        return (records: records, error: null);
      }
      return (records: <AttendanceModel>[], error: (response.body?['message'] ?? 'Failed to load attendance report').toString());
    } catch (e) {
      debugPrint('Error getting attendance: $e');
      return (records: <AttendanceModel>[], error: e.toString());
    }
  }

  Future<({List<Map<String, dynamic>> performance, String? error})> getPerformanceOverview() async {
    try {
      final response = await get('/staff-reports/performance', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data']['overview'] as List<dynamic>? ?? [];
        final performance = list.map((x) => Map<String, dynamic>.from(x as Map)).toList();
        return (performance: performance, error: null);
      }
      return (performance: <Map<String, dynamic>>[], error: (response.body?['message'] ?? 'Failed to load performance').toString());
    } catch (e) {
      debugPrint('Error getting performance overview: $e');
      return (performance: <Map<String, dynamic>>[], error: e.toString());
    }
  }
}
