import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spresearch_web/services/api.service.dart';
import '../config/app.config.dart';
import '../models/user_details.model.dart';

class UserDetailsService extends ApiService {
  // onInit handled by ApiService

  Future<UserDetailsModel?> getUserDetails(String userId, {bool forceRefresh = false}) async {
    try {
      final response = await get('/user/user-details/$userId', forceRefresh: forceRefresh);

      if (response.status.hasError) {
        debugPrint('Error fetching user details: ${response.statusText}');
        return null;
      }

      final responseData = response.body;
      if (responseData['status'] == 200 && responseData['data'] != null) {
        final userData = Map<String, dynamic>.from(
          responseData['data']['userDetails'] ?? {},
        );

        // Add kyc data from the parent data object if it exists (check various likely keys)
        final kycData =
            responseData['data']['userkycs'] ??
            responseData['data']['userKycs'] ??
            responseData['data']['userKyc'];

        if (kycData != null) {
          userData['userkycs'] = kycData;
        }

        return UserDetailsModel.fromJson(userData);
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }

  Future<bool> updateKycGateStatus(
    String userId,
    String gate, // 'documents', 'esign', 'video'
    String status, {
    String? reason,
  }) async {
    try {
      final body = {'gate': gate, 'status': status};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await put('/user/kyc/gate-status/$userId', body);
      return response.status.isOk;
    } catch (e) {
      debugPrint('Error updating KYC gate status: $e');
      return false;
    }
  }

  Future<bool> updateUser(
    String userId, {
    required String fullName,
    required String phone, // Changed to String to prevent data loss or parsing issues
    required String email,
    String? fatherName,
    String? dob,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      final data = {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        if (fatherName != null) 'fatherName': fatherName,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
        if (address != null) 'address1': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
      };

      debugPrint('Updating user $userId with admin endpoint: $data');

      final response = await put('/user/admin-update-user/$userId', data);

      if (response.status.hasError) {
        debugPrint(
          'Error updating user: ${response.statusText} (${response.statusCode})',
        );
        return false;
      }

      final responseData = response.body;
      return responseData != null &&
          (responseData['status'] == 200 || responseData['status'] == '200');
    } catch (e, stackTrace) {
      debugPrint('Error updating user: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<Uint8List?> downloadDigioDocument(String documentId) async {
    try {
      // 1. Get Token manually for the standalone http call
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // 2. Build URL manually
      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/user/kyc/document/download?document_id=$documentId',
      );

      debugPrint('Downloading via standalone http: $url');

      // 3. Use standard http package to get raw bytes without internal UTF8 decoding
      final response = await http.get(
        url,
        headers: {'Authorization': token ?? '', 'Accept': 'application/pdf'},
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Download error (HTTP ${response.statusCode}): ${response.body}',
        );
        return null;
      }

      // 4. Return raw bytes directly (Checklist Compliance)
      final bytes = response.bodyBytes;
      if (bytes.isNotEmpty) {
        return bytes;
      }

      return null;
    } catch (e) {
      debugPrint('Critical error in standalone download: $e');
      return null;
    }
  }
}
