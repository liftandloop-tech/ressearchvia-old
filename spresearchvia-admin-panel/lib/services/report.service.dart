import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get_connect/http/src/multipart/form_data.dart';
import 'package:get/get_connect/http/src/multipart/multipart_file.dart';
import 'package:spresearch_web/services/api.service.dart';
import 'package:spresearch_web/config/app.config.dart';
import '../models/report.model.dart';

class ReportService extends ApiService {
  // onInit handled by ApiService

  Future<({List<ReportModel> reports, int totalCount})> getReports({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? segmentId,
    String? planId,
    String? status,
    String? reportType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (search != null && search.isNotEmpty) {
        query['search'] = search;
      }
      if (segmentId != null && segmentId.isNotEmpty) {
        query['segmentId'] = segmentId;
      }
      if (planId != null && planId.isNotEmpty) {
        query['planId'] = planId;
      }
      if (status != null && status.isNotEmpty) {
        query['status'] = status;
      }
      if (reportType != null && reportType.isNotEmpty) {
        query['reportType'] = reportType;
      }
      if (startDate != null && startDate.isNotEmpty) {
        query['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        query['endDate'] = endDate;
      }

      final response = await get('/reports/report-list', query: query);

      if (response.status.hasError) {
        debugPrint('Error fetching reports: ${response.statusText}');
        return (reports: <ReportModel>[], totalCount: 0);
      }

      final responseData = response.body['data'];
      final List<dynamic> data = responseData['data'] ?? [];
      final totalCount = responseData['totalCount'] is int
          ? responseData['totalCount'] as int
          : int.tryParse(responseData['totalCount']?.toString() ?? '0') ?? 0;

      return (
        reports: data.map((e) => ReportModel.fromJson(e)).toList(),
        totalCount: totalCount,
      );
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return (reports: <ReportModel>[], totalCount: 0);
    }
  }

  Future<bool> createReport({
    required String title,
    required String categoryId,
    required List<String> planIds,
    required String reportType,
    required String description,
    String? youtubeUrl,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final formData = FormData({});
      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('segment', categoryId));
      formData.fields.add(MapEntry('reportType', reportType));
      formData.fields.add(MapEntry('description', description));
      formData.fields.add(MapEntry('youtubeUrl', youtubeUrl ?? ""));

      debugPrint('=== CREATE REPORT SENDING ===');
      debugPrint('youtubeUrl field in FormData: ${youtubeUrl ?? ""}');

      if (fileBytes != null && fileName != null) {
        formData.files.add(
          MapEntry('file', MultipartFile(fileBytes, filename: fileName)),
        );
      }

      for (var planId in planIds) {
        formData.fields.add(MapEntry('planArray', planId));
      }

      final response = await post(
        '/reports/create-report?type=report',
        formData,
      );

      if (response.status.hasError) {
        debugPrint('Error creating report: ${response.statusText}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error creating report: $e');
      return false;
    }
  }

  Future<bool> updateReport({
    required String id,
    required String title,
    required String categoryId,
    required List<String> planIds,
    required String reportType,
    required String description,
    String? newUpdate,
    String? youtubeUrl,
    Uint8List? fileBytes,
    String? fileName,
    bool removeFile = false,
  }) async {
    try {
      final formData = FormData({});
      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('segment', categoryId));
      formData.fields.add(MapEntry('reportType', reportType));
      formData.fields.add(MapEntry('description', description));
      if (newUpdate != null && newUpdate.isNotEmpty) {
        formData.fields.add(MapEntry('newUpdate', newUpdate));
      }
      formData.fields.add(MapEntry('youtubeUrl', youtubeUrl ?? ""));
      formData.fields.add(MapEntry('removeFile', removeFile.toString()));

      debugPrint('=== UPDATE REPORT SENDING ===');
      debugPrint('newUpdate field in FormData: ${newUpdate ?? ""}');
      debugPrint('youtubeUrl field in FormData: ${youtubeUrl ?? ""}');

      if (fileBytes != null && fileName != null) {
        formData.files.add(
          MapEntry('file', MultipartFile(fileBytes, filename: fileName)),
        );
      }

      for (var planId in planIds) {
        formData.fields.add(MapEntry('planArray', planId));
      }

      final response = await post(
        '/reports/report-update?id=$id&type=report',
        formData,
      );

      if (response.status.hasError) {
        debugPrint('Error updating report: ${response.statusText}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error updating report: $e');
      return false;
    }
  }

  Future<bool> deleteReport(String id) async {
    try {
      final response = await delete('/reports/report-delete/$id');

      if (response.status.hasError) {
        debugPrint('Error deleting report: ${response.statusText}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting report: $e');
      return false;
    }
  }

  Future<bool> publishReportStatus({
    required String id,
    required String currentStatus,
  }) async {
    try {
      final response = await put(
        '/reports/report-public-status-change?id=$id',
        {'publishedStatus': currentStatus},
      );

      if (response.status.hasError) {
        debugPrint('Error toggling report status: ${response.statusText}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error toggling report status: $e');
      return false;
    }
  }

  Future<Uint8List?> downloadReport(
    String? reportId, {
    String? reportName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final deviceId = prefs.getString('device_id');

      Uri url;
      if (reportName != null && reportName.isNotEmpty) {
        // Build the direct static URL ("original URL") to bypass middleware
        // reports are stored in uploads/reports/FILENAME
        final directPath = 'reports/$reportName';
        final directUrlStr = AppConfig.buildImageUrl(directPath);
        url = Uri.parse(directUrlStr);
        debugPrint('Downloading report via direct static URL: $url');
      } else {
        // Fallback to API route if reportId is provided instead
        url = Uri.parse(
          '${AppConfig.apiBaseUrl}/reports/download-report/$reportId',
        );
        debugPrint(
          'Downloading report via API route: $url (token: ${token != null}, deviceId: $deviceId)',
        );
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': token ?? '',
          if (deviceId != null) 'device-id': deviceId,
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Error downloading report (HTTP ${response.statusCode}): ${response.body}',
        );
        return null;
      }

      return response.bodyBytes;
    } catch (e) {
      debugPrint('Error in downloadReport service: $e');
      return null;
    }
  }
}
