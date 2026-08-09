import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spresearch_web/services/api.service.dart';
import '../models/user.model.dart';
import 'dart:convert';

class UserService extends ApiService {
  // onInit handled by ApiService

  Future<({List<UserModel> users, int totalCount})> getUsers({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    String? manager,
    String? planType,
    String? date,
    String? kycStatus,
  }) async {
    try {
      // Check if the logged-in user is a staff member
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_data');
      bool isStaff = false;

      if (userStr != null) {
        try {
          final userData = jsonDecode(userStr);
          // Check if this is a staff member (no userType field means staff)
          isStaff =
              userData['userType'] == null || userData['deparment'] != null;
        } catch (e) {
          debugPrint('Error parsing user data: $e');
        }
      }

      final query = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      if (search != null && search.isNotEmpty) {
        query['search'] = search;
      }
      if (status != null && status != 'All Statuses') {
        query['status'] = status;
      }
      if (manager != null && manager != 'All Managers') {
        query['manager'] = manager;
      }
      if (planType != null && planType != 'All Statuses') {
        query['planType'] = planType;
      }
      if (date != null && date.isNotEmpty) {
        query['date'] = date;
      }
      if (kycStatus != null && kycStatus.isNotEmpty) {
        query['kycStatus'] = kycStatus;
      }

      // Use different endpoint based on user type
      final endpoint = isStaff ? '/staff/assigned-users' : '/user/user-list';
      final response = await get(endpoint, query: query);

      if (response.status.hasError) {
        debugPrint('Error fetching users: ${response.statusText}');
        return (users: <UserModel>[], totalCount: 0);
      }

      final responseData = response.body['data'];
      final List<dynamic> data = responseData['userData'] ?? [];
      final totalCount = responseData['totalCount'] is int
          ? responseData['totalCount'] as int
          : int.tryParse(responseData['totalCount']?.toString() ?? '0') ?? 0;

      return (
        users: data.map((e) => UserModel.fromJson(e)).toList(),
        totalCount: totalCount,
      );
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return (users: <UserModel>[], totalCount: 0);
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await put('/user/admin-update-user/$userId', data);
      if (response.status.hasError) {
        debugPrint('Error updating user: ${response.statusText}');
        return false;
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  Future<bool> adminCreateUser(Map<String, dynamic> data) async {
    try {
      final response = await post('/user/admin-create', data);
      debugPrint(
        'Admin create user response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return false;
    }
  }

  Future<bool> suspendUser(String userId, {String? reason}) async {
    try {
      final response = await put('/user/suspend-user/$userId', {
        if (reason != null) 'reason': reason,
      });
      if (response.status.hasError) {
        debugPrint('Error suspending user: ${response.statusText}');
        return false;
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error suspending user: $e');
      return false;
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      final response = await put('/user/activate-user/$userId', {});
      if (response.status.hasError) {
        debugPrint('Error activating user: ${response.statusText}');
        return false;
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error activating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    // SEBI Compliance: No physical deletion. Using suspension.
    return await suspendUser(userId);
  }

  Future<bool> updateKycDocument(
    String userId,
    String docType,
    List<int> fileBytes,
    String filename,
  ) async {
    try {
      final formData = FormData({
        'file': MultipartFile(fileBytes, filename: filename),
      });

      final response = await post(
        '/user/kyc/admin/document/update-file/$userId',
        formData,
        query: {'docType': docType},
      );

      if (response.status.hasError) {
        debugPrint('Error updating KYC Document: ${response.statusText}');
        return false;
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating KYC Document: $e');
      return false;
    }
  }

  Future<String?> generateTempPin(String userId) async {
    try {
      final response = await put('/user/generate-temp-pin/$userId', {});
      if (response.status.hasError) {
        debugPrint('Error generating Temp PIN: ${response.statusText}');
        return null;
      }
      return response.body['data']?['tempPin'];
    } catch (e) {
      debugPrint('Error generating Temp PIN: $e');
      return null;
    }
  }
}
