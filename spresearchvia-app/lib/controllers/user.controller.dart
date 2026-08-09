import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import '../core/config/api.config.dart';
import '../core/models/user.dart';
import '../core/utils/file_validator.dart';
import '../services/api_client.service.dart';
import '../services/api_exception.service.dart';
import '../services/secure_storage.service.dart';
import '../core/utils/error_message_handler.dart';
import '../services/snackbar.service.dart';

class UserController extends GetxController {
  /// Update user from backend response and persist to storage
  Future<void> updateUserFromBackend(Map<String, dynamic> userData) async {
    final clean = Map<String, dynamic>.from(userData);

    // Preserve locally stored email if not present in backend response
    if (clean['email'] == null || clean['email'].toString().isEmpty) {
      final storedData = await _storage.getUserData();
      if (storedData != null &&
          storedData['email'] != null &&
          storedData['email'].toString().isNotEmpty) {
        clean['email'] = storedData['email'];
      }
    }

    if (clean['_id'] == null &&
        clean['id'] == null &&
        clean['userId'] != null) {
      clean['_id'] = clean['userId'];
    }

    final user = User.fromJson(clean);
    currentUser.value = user;
    await _storage.saveUserData(clean);
    await _storage.saveUserId(user.id);
  }

  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  final isLoading = false.obs;
  final currentUser = Rxn<User>();
  final isRegistrationSkipped = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    _loadSkipFlag();
  }

  Future<void> _loadSkipFlag() async {
    isRegistrationSkipped.value = await _storage.isRegistrationSkipped();
  }

  Future<void> fetchLatestUserDetails() async {
    try {
      final uid = await userId;
      if (uid == null) return;

      final response = await _apiClient.get(ApiConfig.getUserDetails(uid));

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['data'] != null) {
          final backendData = responseData['data'];
          // Backend wraps user in 'userDetails' key for this endpoint
          final userMap = backendData['userDetails'] ?? backendData;
          
          await updateUserFromBackend(userMap);
        }
      }
    } catch (e) {
      Get.log('Error fetching latest user details: $e');
    }
  }

  void loadUserData() async {
    try {
      // 1. Load from storage for immediate display (fail-safe)
      final userData = await _storage.getUserData();

      if (userData != null && userData.isNotEmpty) {
        final merged = Map<String, dynamic>.from(userData);
        if ((merged['_id'] == null && merged['id'] == null) &&
            merged['userId'] != null) {
          merged['_id'] = merged['userId'];
        }
        currentUser.value = User.fromJson(merged);
      }

      // 2. Immediately fetch fresh data from backend (Source of Truth)
      await fetchLatestUserDetails();

    } catch (e) {
      Get.log('Error loading user data: $e');
      // If storage fails, we still try to fetch if we have a userId
      fetchLatestUserDetails();
    }
  }

  Future<String?> get userId => _storage.getUserId();

  Future<bool> updateProfile({
    PersonalInformation? personalInformation,
    AddressDetails? addressDetails,
    ContactDetails? contactDetails,
    String? gstin,
    String? firmName,
  }) async {
    try {
      final uid = await userId;
      if (uid == null) {
        SnackbarService.showWarning('User not logged in');
        return false;
      }

      isLoading.value = true;

      final requestData = <String, dynamic>{};

      if (personalInformation != null) {
        requestData['personalInformation'] = personalInformation.toJson();
        requestData['fullName'] = personalInformation.fullName;
      }
      if (addressDetails != null) {
        requestData['addressDetails'] = addressDetails.toJson();
      }
      if (contactDetails != null) {
        requestData['contactDetails'] = contactDetails.toJson();
      }
      if (gstin != null) {
        requestData['gstin'] = gstin;
      }
      if (firmName != null) {
        requestData['firmName'] = firmName;
      }

      final response = await _apiClient.put(
        ApiConfig.updateProfile(uid),
        data: requestData,
      );

      if (response.statusCode == 200) {
        SnackbarService.showSuccess('Profile updated successfully');
        await fetchLatestUserDetails(); // Refresh data
        return true;
      }

      return false;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changeProfileImage(File imageFile) async {
    try {
      final uid = await userId;
      if (uid == null) {
        SnackbarService.showWarning('User not logged in');
        return false;
      }

      final validationError = FileValidator.validateImageFile(imageFile);
      if (validationError != null) {
        SnackbarService.showWarning(validationError);
        return false;
      }

      isLoading.value = true;

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      });

      final response = await _apiClient.uploadFile(
        ApiConfig.uploadProfileImage(uid),
        formData: formData,
        queryParameters: {'type': 'image'},
      );

      if (response.statusCode == 200) {
        SnackbarService.showSuccess('Profile image updated successfully');
        await fetchLatestUserDetails();
        return true;
      }

      return false;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      ErrorMessageHandler.logError('Change Profile Image', error);
      SnackbarService.showError(
        ErrorMessageHandler.getUserFriendlyMessage(error),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<User>?> getUserList() async {
    try {
      isLoading.value = true;

      final response = await _apiClient.get(ApiConfig.userList);

      if (response.statusCode == 200) {
        final data = response.data;
        final userList = data['data'] ?? data['users'] ?? [];

        return (userList as List).map((json) => User.fromJson(json)).toList();
      }

      return null;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      ErrorMessageHandler.logError('Get User List', error);
      SnackbarService.showError(
        ErrorMessageHandler.getUserFriendlyMessage(error),
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteUser(String userIdToDelete) async {
    try {
      isLoading.value = true;

      final response = await _apiClient.delete(
        ApiConfig.deleteUser(userIdToDelete),
      );

      if (response.statusCode == 200) {
        SnackbarService.showSuccess('User deleted successfully');
        return true;
      }

      return false;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      ErrorMessageHandler.logError('Delete User', error);
      SnackbarService.showError(
        ErrorMessageHandler.getUserFriendlyMessage(error),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      final uid = await userId;
      if (uid == null) return;

      await _apiClient.put(
        ApiConfig.updateProfile(uid),
        data: {'fcmToken': token},
      );
    } catch (e) {
      Get.log('Error updating FCM token: $e');
    }
  }

  Future<void> refreshUserData() async {
    await fetchLatestUserDetails();
    await _loadSkipFlag();
  }

  Future<Map<String, dynamic>?> fetchRegistrationDetails() async {
    try {
      isLoading.value = true;
      final response = await _apiClient.get(ApiConfig.acquisitionRegistrationDetails);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      Get.log('Error fetching registration details: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
