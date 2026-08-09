import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../core/config/api.config.dart';
import '../core/utils/file_validator.dart';
import '../core/utils/validators.dart';
import '../services/snackbar.service.dart';
import 'package:path/path.dart' as path;
import '../services/api_client.service.dart';
import '../services/api_exception.service.dart';
import '../services/secure_storage.service.dart';
import 'user.controller.dart';


class KycController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  final isLoading = false.obs;
  final isAadharUploaded = false.obs;
  final isPanUploaded = false.obs;
  final isKycCompleted = false.obs;
  final kycError = RxnString();

  Future<String?> get userId => _storage.getUserId();

  Future<bool> uploadPanCard({
    required File panFile,
    required String panNumber,
  }) async {
    try {
      final uid = await _storage.getUserId();

      if (uid == null) {
        SnackbarService.showWarning('User not logged in');
        return false;
      }

      final panValidation = Validators.validatePAN(panNumber);
      if (panValidation != null) {
        SnackbarService.showWarning(panValidation);
        return false;
      }

      final fileValidation = FileValidator.validateDocumentFile(panFile);
      if (fileValidation != null) {
        SnackbarService.showWarning(fileValidation);
        return false;
      }

      isLoading.value = true;
      kycError.value = null;

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          panFile.path,
          filename: path.basename(panFile.path),
        ),
        'panNumber': panNumber.toUpperCase(),
      });

      final response = await _apiClient.uploadFile(
        ApiConfig.uploadPancard(uid),
        formData: formData,
      );

      if (response.statusCode == 200) {
        isPanUploaded.value = true;
        SnackbarService.showSuccess('PAN card uploaded successfully');
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().refreshUserData();
        }
        return true;
      }

      return false;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      kycError.value = error.message;
      SnackbarService.showError(error.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> uploadAadharCard({
    required File frontFile,
    required File backFile,
    required String aadharNumber,
  }) async {
    try {
      final uid = await _storage.getUserId();
      if (uid == null) {
        SnackbarService.showWarning('User not logged in');
        return false;
      }

      final aadharValidation = Validators.validateAadhar(aadharNumber);
      if (aadharValidation != null) {
        SnackbarService.showWarning(aadharValidation);
        return false;
      }

      final frontFileValidation = FileValidator.validateDocumentFile(frontFile);
      if (frontFileValidation != null) {
        SnackbarService.showWarning('Front image: $frontFileValidation');
        return false;
      }

      final backFileValidation = FileValidator.validateDocumentFile(backFile);
      if (backFileValidation != null) {
        SnackbarService.showWarning('Back image: $backFileValidation');
        return false;
      }

      isLoading.value = true;

      final formData = dio.FormData.fromMap({
        'files': [
          await dio.MultipartFile.fromFile(
            frontFile.path,
            filename: path.basename(frontFile.path),
          ),
          await dio.MultipartFile.fromFile(
            backFile.path,
            filename: path.basename(backFile.path),
          ),
        ],
        'aadhaarNumber': Validators.cleanAadhar(aadharNumber),
      });

      final response = await _apiClient.uploadFile(
        ApiConfig.uploadAadhar(uid),
        formData: formData,
      );

      if (response.statusCode == 200) {
        isAadharUploaded.value = true;
        SnackbarService.showSuccess('Aadhar card uploaded successfully');
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().refreshUserData();
        }
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

  Future<bool> completeDocumentKyc({
    required String email,
    required String name,
    required String signType,
  }) async {
    try {
      final uid = await _storage.getUserId();
      if (uid == null) {
        SnackbarService.showWarning('User not logged in');
        return false;
      }

      isLoading.value = true;

      final response = await _apiClient.post(
        ApiConfig.documentKYC(uid),
        data: {'email': email, 'name': name, 'sign_type': signType},
      );

      if (response.statusCode == 200) {
        isKycCompleted.value = true;
        SnackbarService.showSuccess('KYC verification initiated successfully');
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().refreshUserData();
        }
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

  Future<bool> uploadKycVideo(File videoFile) async {
    try {
      final uid = await _storage.getUserId();
      if (uid == null) {
        SnackbarService.showWarning('User not logged in');
        return false;
      }

      isLoading.value = true;

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          videoFile.path,
          filename: path.basename(videoFile.path),
        ),
      });

      
      final response = await _apiClient.uploadFile(
        ApiConfig.uploadKycVideo(uid),
        formData: formData,
      );

      if (response.statusCode == 200) {
        SnackbarService.showSuccess('Video verification uploaded successfully');

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

  void resetKycStatus() {
    isAadharUploaded.value = false;
    isPanUploaded.value = false;
    isKycCompleted.value = false;
  }
}
