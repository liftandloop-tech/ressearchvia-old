import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/api.service.dart';
import '../models/staff.model.dart';

class StaffService extends ApiService {
  // onInit handled by ApiService

  Future<bool> createStaff(Map<String, dynamic> data) async {
    try {
      debugPrint('Creating staff with data: $data');
      final response = await post('/staff/create', data);

      debugPrint('Create staff response status: ${response.statusCode}');
      debugPrint('Create staff response body: ${response.body}');

      if (response.status.hasError) {
        // Handle both JSON and plain text responses
        String errorMsg = 'Unknown error';
        if (response.body is String) {
          errorMsg = response.body.toString();
        } else if (response.body is Map) {
          errorMsg =
              (response.body['message'] ??
                      response.statusText ??
                      'Unknown error')
                  .toString();
        } else {
          errorMsg = response.statusText ?? 'Unknown error';
        }
        debugPrint('Error creating staff: $errorMsg');
        throw Exception(errorMsg);
      }

      // Check if response indicates success - handle both int and String status
      if (response.body != null && response.body is Map) {
        final status = response.body['status'];
        if (status == 200 || status == '200') {
          return true;
        }
      }

      throw Exception('Failed to create staff');
    } catch (e) {
      debugPrint('Error creating staff: $e');
      rethrow;
    }
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> data) async {
    try {
      if (id.isEmpty) {
        throw Exception('Staff ID is required for update');
      }

      debugPrint('Updating staff $id with data: $data');
      // Backend endpoint is /staff/reset and expects id in query
      final response = await put('/staff/reset?id=$id', data);

      debugPrint('Update staff response status: ${response.statusCode}');
      debugPrint('Update staff response body: ${response.body}');

      if (response.status.hasError) {
        final errorMsg =
            (response.body?['message'] ??
                    response.statusText ??
                    'Unknown error')
                .toString();
        debugPrint('Error updating staff: $errorMsg');
        throw Exception(errorMsg);
      }

      if (response.body != null && response.body['status'] == 200) {
        return true;
      }

      throw Exception(
        (response.body?['message'] ?? 'Failed to update staff').toString(),
      );
    } catch (e) {
      debugPrint('Error updating staff: $e');
      rethrow;
    }
  }

  Future<List<StaffModel>> getStaffList() async {
    try {
      final response = await get('/staff/list');

      if (response.status.hasError) {
        String errorMsg = 'Unknown error';
        if (response.body is String) {
          errorMsg = response.body.toString();
        } else if (response.body is Map) {
          errorMsg =
              (response.body['message'] ??
                      response.statusText ??
                      'Unknown error')
                  .toString();
        } else {
          errorMsg = response.statusText ?? 'Unknown error';
        }
        debugPrint('Error fetching staff list: $errorMsg');
        throw Exception(errorMsg);
      }

      if (response.body != null && response.body is Map) {
        final status = response.body['status'];
        if ((status == 200 || status == '200') &&
            response.body['data'] != null &&
            response.body['data']['staffList'] != null) {
          final List<dynamic> list = response.body['data']['staffList'];
          return list.map((e) => StaffModel.fromJson(e)).toList();
        }
      }

      throw Exception('Invalid response format from server');
    } catch (e) {
      debugPrint('Error fetching staff list: $e');
      rethrow;
    }
  }

  Future<bool> assignStaff(String userId, String staffId) async {
    try {
      if (userId.isEmpty || staffId.isEmpty) {
        throw Exception('User ID and Staff ID are required');
      }

      final response = await post('/staff/staff-assignment', {
        'userId': userId,
        'staffId': staffId,
      });

      if (response.status.hasError) {
        final errorMsg =
            (response.body?['message'] ??
                    response.statusText ??
                    'Unknown error')
                .toString();
        debugPrint('Error assigning staff: $errorMsg');
        throw Exception(errorMsg);
      }

      if (response.body != null && response.body['status'] == 200) {
        return true;
      }

      throw Exception(
        (response.body?['message'] ?? 'Failed to assign staff').toString(),
      );
    } catch (e) {
      debugPrint('Error assigning staff: $e');
      rethrow;
    }
  }

  Future<bool> deleteStaff(String staffId) async {
    try {
      if (staffId.isEmpty) {
        throw Exception('Staff ID is required for deletion');
      }

      debugPrint('Deleting staff with ID: $staffId');
      final response = await delete('/staff/cancle/$staffId');

      debugPrint('Delete staff response status: ${response.statusCode}');
      debugPrint('Delete staff response body: ${response.body}');

      if (response.status.hasError) {
        final errorMsg =
            (response.body?['message'] ??
                    response.statusText ??
                    'Unknown error')
                .toString();
        debugPrint('Error deleting staff: $errorMsg');
        throw Exception(errorMsg);
      }

      if (response.body != null && response.body['status'] == 200) {
        return true;
      }

      throw Exception(
        (response.body?['message'] ?? 'Failed to delete staff').toString(),
      );
    } catch (e) {
      debugPrint('Error deleting staff: $e');
      rethrow;
    }
  }

  Future<({bool success, String? message})> uploadStaffDocument(String id, String type, List<int> bytes, String filename) async {
    try {
      final formData = FormData({
        'file': MultipartFile(bytes, filename: filename),
      });
      final response = await post('/staff/upload-doc/$id?type=$type', formData);
      if (response.statusCode == 200) {
        return (success: true, message: response.body?['message']?.toString());
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Upload failed');
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return (success: false, message: e.toString());
    }
  }

  Future<({bool success, String? message})> uploadStaffVideo(String id, List<int> bytes, String filename) async {
    try {
      final formData = FormData({
        'file': MultipartFile(bytes, filename: filename),
      });
      final response = await post('/staff/upload-video/$id', formData);
      if (response.statusCode == 200) {
        return (success: true, message: response.body?['message']?.toString());
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Video upload failed');
    } catch (e) {
      debugPrint('Error uploading video: $e');
      return (success: false, message: e.toString());
    }
  }
}
