import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api.service.dart';
import '../models/staff.model.dart';
import '../models/applicant.model.dart';

class ApplicantService extends ApiService {
  Future<({bool success, String? applicantId, String? emailAddress, String? message})> createAccount(String email, String password) async {
    try {
      final response = await post('/staff/applicant/create-account', {
        'emailAddress': email.trim().toLowerCase(),
        'password': password,
      });
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'] as Map<String, dynamic>?;
        final appId = data?['applicantId']?.toString();
        final emailVal = data?['emailAddress']?.toString() ?? email;
        return (success: true, applicantId: appId, emailAddress: emailVal, message: response.body['message']?.toString());
      }
      return (success: false, applicantId: null, emailAddress: null, message: response.body?['message']?.toString() ?? 'Failed to create account');
    } catch (e) {
      debugPrint('Error creating applicant account: $e');
      return (success: false, applicantId: null, emailAddress: null, message: e.toString());
    }
  }

  Future<({bool success, Map<String, dynamic>? applicant, String? token, int currentStep, String? message})> verifyAccountEmail(String applicantId, String emailOtp) async {
    try {
      final response = await post('/staff/applicant/verify-account-email', {
        'applicantId': applicantId,
        'emailOtp': emailOtp.trim(),
      });
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'] as Map<String, dynamic>?;
        final appData = data?['applicant'] as Map<String, dynamic>?;
        final token = data?['token']?.toString();
        final step = data?['currentStep'] is int ? data!['currentStep'] as int : int.tryParse(data?['currentStep']?.toString() ?? '1') ?? 1;
        return (success: true, applicant: appData, token: token, currentStep: step, message: response.body['message']?.toString());
      }
      return (success: false, applicant: null, token: null, currentStep: 1, message: response.body?['message']?.toString() ?? 'Email OTP verification failed');
    } catch (e) {
      debugPrint('Error verifying applicant email OTP: $e');
      return (success: false, applicant: null, token: null, currentStep: 1, message: e.toString());
    }
  }

  Future<({bool success, String? message})> resendEmailOtp(String applicantId, String email) async {
    try {
      final response = await post('/staff/applicant/resend-email-otp', {
        'applicantId': applicantId,
        'emailAddress': email.trim().toLowerCase(),
      });
      if (response.statusCode == 200 && response.body != null) {
        return (success: true, message: response.body['message']?.toString() ?? 'New code sent to your email');
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Failed to resend email code');
    } catch (e) {
      debugPrint('Error resending email OTP: $e');
      return (success: false, message: e.toString());
    }
  }

  Future<({bool success, Map<String, dynamic>? applicant, String? token, int currentStep, String? message})> continueLogin(String email, String password) async {
    try {
      final response = await post('/staff/applicant/continue-login', {
        'emailAddress': email.trim().toLowerCase(),
        'password': password,
      });
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'] as Map<String, dynamic>?;
        final appData = data?['applicant'] as Map<String, dynamic>?;
        final token = data?['token']?.toString();
        final step = data?['currentStep'] is int ? data!['currentStep'] as int : int.tryParse(data?['currentStep']?.toString() ?? '1') ?? 1;
        return (success: true, applicant: appData, token: token, currentStep: step, message: response.body['message']?.toString());
      }
      return (success: false, applicant: null, token: null, currentStep: 1, message: response.body?['message']?.toString() ?? 'Login failed');
    } catch (e) {
      debugPrint('Error in applicant continueLogin: $e');
      return (success: false, applicant: null, token: null, currentStep: 1, message: e.toString());
    }
  }

  Future<({bool success, String? message})> sendMobileOtp(String applicantId, String mobileNumber) async {
    try {
      final response = await post('/staff/applicant/send-mobile-otp', {
        'applicantId': applicantId,
        'mobileNumber': mobileNumber.trim(),
      });
      if (response.statusCode == 200 && response.body != null) {
        return (success: true, message: response.body['message']?.toString() ?? 'OTP sent to mobile');
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Failed to send mobile OTP');
    } catch (e) {
      debugPrint('Error sending mobile OTP: $e');
      return (success: false, message: e.toString());
    }
  }

  Future<({bool success, String? message})> verifyMobileOtp(String applicantId, String mobileNumber, String otp) async {
    try {
      final response = await post('/staff/applicant/verify-mobile-otp', {
        'applicantId': applicantId,
        'mobileNumber': mobileNumber.trim(),
        'otp': otp.trim(),
      });
      if (response.statusCode == 200 && response.body != null) {
        return (success: true, message: response.body['message']?.toString() ?? 'Mobile verified successfully');
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Mobile OTP verification failed');
    } catch (e) {
      debugPrint('Error verifying mobile OTP: $e');
      return (success: false, message: e.toString());
    }
  }

  Future<({bool success, Map<String, dynamic>? applicant, int currentStep, String? message})> saveStep(String applicantId, int step, Map<String, dynamic> stepData) async {
    try {
      final response = await put('/staff/applicant/save-step/$applicantId', {
        'step': step,
        'stepData': stepData,
      });
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'] as Map<String, dynamic>?;
        final appData = data?['applicant'] as Map<String, dynamic>?;
        final curStep = data?['currentStep'] is int ? data!['currentStep'] as int : int.tryParse(data?['currentStep']?.toString() ?? '$step') ?? step;
        return (success: true, applicant: appData, currentStep: curStep, message: response.body['message']?.toString());
      }
      return (success: false, applicant: null, currentStep: step, message: response.body?['message']?.toString() ?? 'Failed to save step');
    } catch (e) {
      debugPrint('Error saving applicant step: $e');
      return (success: false, applicant: null, currentStep: step, message: e.toString());
    }
  }

  Future<({bool success, Map<String, dynamic>? applicant, String? message})> finalizeApplication(String applicantId) async {
    try {
      final response = await post('/staff/applicant/finalize-application/$applicantId', {});
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'] as Map<String, dynamic>?;
        final appData = data?['applicant'] as Map<String, dynamic>?;
        return (success: true, applicant: appData, message: response.body['message']?.toString());
      }
      return (success: false, applicant: null, message: response.body?['message']?.toString() ?? 'Failed to finalize application');
    } catch (e) {
      debugPrint('Error finalizing application: $e');
      return (success: false, applicant: null, message: e.toString());
    }
  }

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

  Future<({bool success, String? message})> updateContactAndResendOtp(String applicantId, String mobileNumber, String emailAddress) async {
    try {
      final response = await post('/staff/applicant/update-contact', {
        'applicantId': applicantId,
        'mobileNumber': mobileNumber,
        'emailAddress': emailAddress,
      });
      if (response.statusCode == 200 && response.body != null) {
        return (success: true, message: response.body['message']?.toString() ?? 'Verification codes sent');
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Failed to update contact info');
    } catch (e) {
      debugPrint('Error updating contact and resending OTP: $e');
      return (success: false, message: e.toString());
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

  Future<({bool success, String? message, StaffModel? applicant})> uploadApplicantFile(String id, String type, List<int> bytes, String filename) async {
    try {
      final formData = FormData({
        'file': MultipartFile(bytes, filename: filename),
      });
      final response = await post('/staff/applicant/upload-doc/$id?type=$type', formData);
      if (response.statusCode == 200) {
        StaffModel? applicant;
        if (response.body != null && response.body['data'] != null && response.body['data']['applicant'] != null) {
          try {
            applicant = StaffModel.fromJson(response.body['data']['applicant'] as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error parsing applicant from upload response: $e');
          }
        }
        return (success: true, message: response.body?['message']?.toString(), applicant: applicant);
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'File upload failed', applicant: null);
    } catch (e) {
      debugPrint('Error uploading applicant file: $e');
      return (success: false, message: e.toString(), applicant: null);
    }
  }

  Future<({bool success, String? message, StaffModel? applicant})> uploadApplicantVideo(String id, List<int> bytes, String filename) async {
    try {
      final formData = FormData({
        'file': MultipartFile(bytes, filename: filename),
      });
      final response = await post('/staff/applicant/upload-video/$id', formData);
      if (response.statusCode == 200) {
        StaffModel? applicant;
        if (response.body != null && response.body['data'] != null && response.body['data']['applicant'] != null) {
          try {
            applicant = StaffModel.fromJson(response.body['data']['applicant'] as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error parsing applicant from video response: $e');
          }
        }
        return (success: true, message: response.body?['message']?.toString(), applicant: applicant);
      }
      return (success: false, message: response.body?['message']?.toString() ?? 'Video upload failed', applicant: null);
    } catch (e) {
      debugPrint('Error uploading applicant video: $e');
      return (success: false, message: e.toString(), applicant: null);
    }
  }

  Future<({List<StaffModel> applicants, String? error})> getApplicantsList({String stage = 'ALL', String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (stage.isNotEmpty) queryParams['stage'] = stage;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
      final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final url = '/staff/applicants${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await get(url, forceRefresh: true);
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

  Future<({List<ApplicantModel> applicants, String? error})> getApplicantsModelList({String stage = 'ALL', String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (stage.isNotEmpty) queryParams['stage'] = stage;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
      final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final url = '/staff/applicants${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await get(url, forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final list = response.body['data']['applicants'] as List<dynamic>? ?? [];
        final applicants = list.map((x) => ApplicantModel.fromJson(x as Map<String, dynamic>)).toList();
        return (applicants: applicants, error: null);
      }
      return (applicants: <ApplicantModel>[], error: (response.body?['message'] ?? 'Failed to load applicants').toString());
    } catch (e) {
      debugPrint('Error getting applicants model list: $e');
      return (applicants: <ApplicantModel>[], error: e.toString());
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

  Future<List<Map<String, dynamic>>> getPublicRoles() async {
    try {
      final response = await get('/staff/applicant/roles', forceRefresh: true);
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'];
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting public roles: $e');
      return [];
    }
  }
}
