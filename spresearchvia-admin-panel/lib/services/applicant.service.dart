import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api.service.dart';
import '../models/staff.model.dart';

class ApplicantService extends ApiService {
  Future<({bool success, String? applicantId, String? message})> registerApplicant(Map<String, dynamic> data) async {
    try {
      final response = await post('/staff/applicant/register', data);
      if (response.statusCode == 200 && response.body != null) {
        final appVal = response.body['data']['applicantId']?.toString();
        return (success: true, applicantId: appVal, message: response.body['message']?.toString());
      }
      return (success: false, applicantId: null, message: response.body?['message']?.toString() ?? 'Registration failed');
    } catch (e) {
      debugPrint('Error registering applicant: $e');
      return (success: false, applicantId: null, message: e.toString());
    }
  }

  Future<({bool success, StaffModel? applicant, String? message})> verifyOtp(String applicantId, String mobileOtp, String emailOtp) async {
    try {
      final response = await post('/staff/applicant/verify', {
        'applicantId': applicantId,
        'mobileOtp': mobileOtp,
        'emailOtp': emailOtp,
      });
      if (response.statusCode == 200 && response.body != null) {
        final staff = StaffModel.fromJson(response.body['data']['applicant'] as Map<String, dynamic>);
        return (success: true, applicant: staff, message: null);
      }
      return (success: false, applicant: null, message: response.body?['message']?.toString() ?? 'Verification failed');
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return (success: false, applicant: null, message: e.toString());
    }
  }

  Future<({bool success, String? message})> uploadApplicantFile(String id, String type, List<int> bytes, String filename) async {
    try {
      final formData = FormData({
        'file': MultipartFile(bytes, filename: filename),
      });
      final response = await post('/staff/applicant/upload-doc/$id?type=$type', formData);
      if (response.statusCode == 200) {
        return (success: true, message: response.body?['message']?.toString());
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'File upload failed');
    } catch (e) {
      debugPrint('Error uploading applicant file: $e');
      return (success: false, message: e.toString());
    }
  }

  Future<({bool success, String? message})> uploadApplicantVideo(String id, List<int> bytes, String filename) async {
    try {
      final formData = FormData({
        'file': MultipartFile(bytes, filename: filename),
      });
      final response = await post('/staff/applicant/upload-video/$id', formData);
      if (response.statusCode == 200) {
        return (success: true, message: response.body?['message']?.toString());
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Video upload failed');
    } catch (e) {
      debugPrint('Error uploading applicant video: $e');
      return (success: false, message: e.toString());
    }
  }

  Future<({List<StaffModel> applicants, String? error})> getApplicantsList() async {
    try {
      final response = await get('/staff/applicants', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data']['applicants'] as List<dynamic>? ?? [];
        final applicants = list.map((x) => StaffModel.fromJson(x as Map<String, dynamic>)).toList();
        return (applicants: applicants, error: null);
      }
      return (applicants: <StaffModel>[], error: (response.body?['message'] ?? 'Failed to load applicants').toString());
    } catch (e) {
      debugPrint('Error getting applicants list: $e');
      return (applicants: <StaffModel>[], error: e.toString());
    }
  }

  Future<bool> approveApplicant(String id, Map<String, dynamic> data) async {
    try {
      final response = await post('/staff/applicant/approve/$id', data);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error approving applicant: $e');
      return false;
    }
  }

  Future<({StaffModel? applicant, String? error})> getApplicantDetails(String id) async {
    try {
      final response = await get('/staff/applicant/$id', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final staff = StaffModel.fromJson(response.body['data']['applicant'] as Map<String, dynamic>);
        return (applicant: staff, error: null);
      }
      return (applicant: null, error: (response.body?['message'] ?? 'Failed to load details').toString());
    } catch (e) {
      debugPrint('Error getting applicant details: $e');
      return (applicant: null, error: e.toString());
    }
  }

  Future<({bool success, String? otpType, String? error})> initiateContinueApplication(String identifier) async {
    try {
      final response = await post('/staff/applicant/continue-init', {
        'identifier': identifier,
      });
      if (response.statusCode == 200 && response.body != null) {
        final otpType = response.body['data']['otpType'].toString();
        return (success: true, otpType: otpType, error: null);
      }
      return (success: false, otpType: null, error: (response.body?['message'] ?? 'Failed to send OTP').toString());
    } catch (e) {
      debugPrint('Error initiating continue: $e');
      return (success: false, otpType: null, error: e.toString());
    }
  }

  Future<({String? applicantId, String? error})> verifyContinueApplication(
    String identifier,
    String otp,
    String otpType,
  ) async {
    try {
      final response = await post('/staff/applicant/continue-verify', {
        'identifier': identifier,
        'otp': otp,
        'otpType': otpType,
      });
      if (response.statusCode == 200 && response.body != null) {
        final id = response.body['data']['applicantId'].toString();
        return (applicantId: id, error: null);
      }
      return (applicantId: null, error: (response.body?['message'] ?? 'Invalid OTP').toString());
    } catch (e) {
      debugPrint('Error verifying continue: $e');
      return (applicantId: null, error: e.toString());
    }
  }
}
